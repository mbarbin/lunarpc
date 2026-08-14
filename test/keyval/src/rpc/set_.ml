(*********************************************************************************)
(*  lunarpc - An opinionated, lightweight, HTTP/JSON RPC harness                 *)
(*  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: MIT                                                 *)
(*********************************************************************************)

module Request = struct
  type t =
    { key : Keyval.Key.t
    ; value : Keyval.Value.t
    }

  let equal t1 t2 = Keyval.Key.equal t1.key t2.key && Keyval.Value.equal t1.value t2.value

  let to_json (t : t) : Json.t =
    `Assoc
      [ "key", `String (Keyval.Key.to_string t.key)
      ; "value", `String (Keyval.Value.to_string t.value)
      ]
  ;;

  let of_json (json : Json.t) : t =
    match json with
    | `Assoc fields ->
      let key_ref = ref None in
      let value_ref = ref None in
      let rec iter = function
        | [] -> ()
        | (name, value) :: rest ->
          (match name with
           | "key" ->
             key_ref
             := Some
                  (match value with
                   | `String s -> s
                   | _ -> raise (Json.Invalid_json (value, "Expected string for key")))
           | "value" ->
             value_ref
             := Some
                  (match value with
                   | `String s -> s
                   | _ -> raise (Json.Invalid_json (value, "Expected string for value")))
           | _ -> ());
          iter rest
      in
      iter fields;
      let require ref_val field_name =
        match !ref_val with
        | Some v -> v
        | None ->
          raise (Json.Invalid_json (json, Printf.sprintf "Missing field: %s" field_name))
      in
      { key = Keyval.Key.v (require key_ref "key")
      ; value = Keyval.Value.of_string (require value_ref "value")
      }
    | _ -> raise (Json.Invalid_json (json, "Expected object"))
  ;;

  let schema () =
    `Assoc
      [ "type", `String "object"
      ; ( "properties"
        , `Assoc
            [ "key", `Assoc [ "type", `String "string" ]
            ; "value", `Assoc [ "type", `String "string" ]
            ] )
      ; "required", `List [ `String "key"; `String "value" ]
      ]
  ;;
end

module Response = Rpc_unit

let rpc : _ Rpc.t =
  Rpc.create
    ~name:(Rpc.Name.v "set")
    ~version:1
    ~description:"Store or update a key-value pair in the memory database."
    ~request_encoder:(Rpc.Encoder.make (module Request))
    ~response_encoder:(Rpc.Encoder.make (module Response))
    ()
;;
