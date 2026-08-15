(*********************************************************************************)
(*  lunarpc - An opinionated, lightweight, HTTP/JSON RPC harness                 *)
(*  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: MIT                                                 *)
(*********************************************************************************)

module Connection = struct
  type t =
    { client : Ezcurl.t
    ; host : string
    ; port : int
    ; principal : Rpc.Principal.t option
    }
end

let with_connection ?principal ~port f =
  Ezcurl.with_client
    ~set_opts:(fun _curl -> ())
    (fun client -> f { Connection.client; host = "localhost"; port; principal })
;;

let truncate_string str ~max =
  String.sub str ~pos:0 ~len:(Int.min max (String.length str))
;;

let call
      (type request response)
      ?principal
      (spec : (module Rpc.S with type Request.t = request and type Response.t = response))
      ~(connection : Connection.t)
      (request : request)
  =
  (* A per-call [principal] overrides the connection's default. *)
  let principal =
    match principal with
    | Some principal -> Some principal
    | None -> connection.principal
  in
  let module M = (val spec) in
  let (request_data : string) =
    M.rpc.request_encoder.to_json request |> Yojson.Basic.to_string ~std:true
  in
  let url : string =
    Printf.sprintf "http://%s:%d/%s" connection.host connection.port (Rpc.route M.rpc)
  in
  Log.debug (fun () ->
    [ Pp.textf "Issuing HTTP POST on %s (body_size=%d)" url (String.length request_data) ]);
  match
    Ezcurl.post
      ~client:connection.client
      ~url
      ~params:[]
      ~content:(`String request_data)
      ~headers:(("content-type", "application/json") :: Rpc.Call.to_headers ?principal ())
      ()
  with
  | Error (code, msg) ->
    Error
      (Err.create
         [ Pp.text "Http call failed."
         ; Err.sexp
             (List
                [ List
                    [ Atom "code"
                    ; Atom (Int.to_string (Curl.errno code))
                    ; Atom (Curl.strerror code)
                    ]
                ; Atom msg
                ])
         ])
  | Ok { code; body; _ } when code >= 200 && code < 300 ->
    Log.debug (fun () ->
      [ Pp.textf "Got success response with code=%d" code
      ; Pp.text (truncate_string body ~max:64)
      ]);
    (match M.rpc.response_encoder.of_json (Yojson.Basic.from_string body) with
     | res -> Ok res
     | exception exn ->
       Error (Err.create [ Pp.text "Decoding response failed."; Err.exn exn ]))
  | Ok { code; body; _ } ->
    Log.err (fun () ->
      [ Pp.textf "Got failed response with code=%d" code
      ; Pp.text (truncate_string body ~max:64)
      ]);
    Error
      (Err.create
         [ Pp.text "Rpc call failed"
         ; Err.sexp (List [ List [ Atom "code"; Atom (Int.to_string code) ]; Atom body ])
         ])
;;
