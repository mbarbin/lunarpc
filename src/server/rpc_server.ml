(*********************************************************************************)
(*  lunarpc - An opinionated, lightweight, HTTP/JSON RPC harness                 *)
(*  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: MIT                                                 *)
(*********************************************************************************)

type t = { handlers : Rpc.Handler.t list }
type rpc = Rpc : _ Rpc.t -> rpc

module Name_table = Stdlib.Hashtbl.Make (Rpc.Name)

let create_introspective_handlers ~(handlers : Rpc.Handler.t list) : Rpc.Handler.t list =
  let list_rpcs_handler =
    Rpc.Handler.make
      (module Rpc.List_rpcs)
      ~f:(fun call ->
        let (request : Rpc.List_rpcs.Request.t) = Rpc.Call.request call in
        let rpc_filter =
          match request.names with
          | All -> fun _ -> true
          | Only { names } ->
            let table = Name_table.create (List.length names) in
            List.iter names ~f:(fun name -> Name_table.add table name ());
            fun name -> Name_table.mem table name
        in
        (* Include both user-provided RPCs and introspective RPCs. *)
        let introspective_handlers = [ (module Rpc.List_rpcs : Rpc.S) ] in
        let all_rpcs =
          List.map handlers ~f:(fun (Rpc.Handler.T { spec; _ }) ->
            let module M = (val spec) in
            Rpc M.rpc)
          @ List.map introspective_handlers ~f:(fun spec ->
            let module M = (val spec) in
            Rpc M.rpc)
        in
        let rpcs =
          List.filter_map all_rpcs ~f:(fun (Rpc rpc) ->
            if rpc_filter rpc.name
            then
              Some
                { Rpc.Info.name = rpc.name
                ; version = rpc.version
                ; route = Rpc.route rpc
                ; description = rpc.description
                ; request_schema =
                    (if request.include_schemas
                     then Some (rpc.request_encoder.schema ())
                     else None)
                ; response_schema =
                    (if request.include_schemas
                     then Some (rpc.response_encoder.schema ())
                     else None)
                }
            else None)
        in
        { Rpc.List_rpcs.Response.rpcs })
  in
  [ list_rpcs_handler ]
;;

let create ~handlers =
  let introspective_handlers = create_introspective_handlers ~handlers in
  { handlers = handlers @ introspective_handlers }
;;

module Error_codes = struct
  type t =
    | Internal
    | Malformed
    | Unknown

  let to_msg_and_code = function
    | Malformed -> "malformed", 400
    | Internal -> "internal", 500
    | Unknown -> "unknown", 500
  ;;
end

let return_error (err : Error_codes.t) (msg : string) (data : Json.t)
  : Tiny_httpd.Response.t
  =
  let code, http_code = Error_codes.to_msg_and_code err in
  let json_body : string =
    Yojson.Basic.to_string
      ~std:true
      (`Assoc
          (List.concat
             [ [ "code", `String code; "msg", `String msg ]
             ; (match data with
                | `Null -> []
                | data -> [ "data", data ])
             ]))
  in
  Tiny_httpd.Response.make_raw
    ~headers:[ "content-type", "application/json" ]
    ~code:http_code
    json_body
;;

exception Fail of Error_codes.t * string * Json.t

let handle_rpc (rpc_handler : Rpc.Handler.t) (req : string Tiny_httpd.Request.t)
  : Tiny_httpd.Response.t
  =
  try
    let (T { spec; f }) = rpc_handler in
    let module M = (val spec) in
    let () =
      match Tiny_httpd.Request.get_header req "content-type" with
      | Some "application/json" -> ()
      | Some r -> raise_notrace (Fail (Malformed, "unknown application type", `String r))
      | None -> raise_notrace (Fail (Malformed, "no application type specified", `Null))
    in
    let request =
      try M.rpc.request_encoder.of_json (Yojson.Basic.from_string req.body) with
      | _ -> raise_notrace (Fail (Malformed, "could not decode json", `Null))
    in
    let res =
      try
        f (Rpc.Call.create_with_headers request ~get:(Tiny_httpd.Request.get_header req))
      with
      | exn ->
        raise_notrace
          (Fail (Internal, "handler failed", `String (Printexc.to_string exn)))
    in
    let res = Yojson.Basic.to_string ~std:true (M.rpc.response_encoder.to_json res) in
    Tiny_httpd.Response.make_string (Ok res)
  with
  | Fail (err, msg, json) -> return_error err msg json
  | exn -> return_error Unknown "handler failed" (`String (Printexc.to_string exn))
;;

let add_handler (server : Tiny_httpd.t) ~handler:(Rpc.Handler.T { spec; _ } as handler)
  : unit
  =
  let module M = (val spec) in
  Tiny_httpd.add_route_handler
    server
    ~meth:`POST
    Tiny_httpd.Route.(exact_path (Rpc.route M.rpc) return)
    (fun req -> handle_rpc handler req)
;;

let add_services (t : t) ~to_:httpd =
  List.iter t.handlers ~f:(fun handler -> add_handler httpd ~handler)
;;
