(*********************************************************************************)
(*  lunarpc - An opinionated, lightweight, HTTP/JSON RPC harness                 *)
(*  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: MIT                                                 *)
(*********************************************************************************)

type t = { port : int }

module Json_format : sig
  type nonrec t = t

  include Rpc.Encoder.S with type t := t
end = struct
  type nonrec t = t

  let to_json ({ port } : t) : Json.t =
    `Assoc [ "type", `String "Tcp"; "port", `Int port ]
  ;;

  let of_json (json : Json.t) : t =
    match json with
    | `Assoc fields ->
      let find_field name =
        List.find_map fields ~f:(fun (n, v) ->
          if String.equal n name then Some v else None)
      in
      let type_str =
        match find_field "type" with
        | Some (`String s) -> s
        | Some (_ : Json.t) -> failwith "Expected string for field: type"
        | None -> failwith "Missing field: type"
      in
      (match type_str with
       | "Tcp" ->
         let port =
           match find_field "port" with
           | Some (`Int i) -> i
           | Some (_ : Json.t) -> failwith "Expected int for port"
           | None -> failwith "Missing field: port"
         in
         { port }
       | _ -> failwith (Printf.sprintf "Unknown type: %s" type_str))
    | _ -> failwith "Expected JSON object"
  ;;

  let schema () : Json.t =
    `Assoc
      [ "type", `String "object"
      ; ( "properties"
        , `Assoc
            [ "type", `Assoc [ "type", `String "string"; "enum", `List [ `String "Tcp" ] ]
            ; "port", `Assoc [ "type", `String "integer" ]
            ] )
      ; "required", `List [ `String "type"; `String "port" ]
      ]
  ;;
end

let load ~path =
  let path_str = Fpath.to_string path in
  let contents =
    match In_channel.read_all path_str with
    | contents -> contents
    | exception exn ->
      Err.raise
        ~loc:(Loc.of_file ~path)
        [ Pp.textf "Failed to read discovery file: %s" (Exn.to_string exn) ]
  in
  let json =
    match Yojson.Basic.from_string contents with
    | json -> json
    | exception exn ->
      Err.raise
        ~loc:(Loc.of_file ~path)
        [ Pp.textf "Failed to parse JSON: %s" (Exn.to_string exn) ]
  in
  match Json_format.of_json json with
  | t -> t
  | exception exn ->
    Err.raise
      ~loc:(Loc.of_file ~path)
      [ Pp.textf "Invalid discovery file format: %s" (Exn.to_string exn) ]
;;

let save t ~path =
  Out_channel.write_all
    (Fpath.to_string path)
    ~data:(Yojson.Basic.to_string (Json_format.to_json t) ^ "\n")
;;
