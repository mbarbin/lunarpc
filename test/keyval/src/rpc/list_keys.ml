(*********************************************************************************)
(*  lunarpc - An opinionated, lightweight, HTTP/JSON RPC harness                 *)
(*  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: MIT                                                 *)
(*********************************************************************************)

module Request = Rpc_unit

module Response = struct
  type t = Keyval.Key.t list

  let equal = List.equal ~eq:Keyval.Key.equal

  let to_json (t : t) : Json.t =
    let keys =
      t |> List.map ~f:(fun key -> `Assoc [ "key", `String (Keyval.Key.to_string key) ])
    in
    `Assoc [ "keys", `List keys ]
  ;;

  let key_of_json (json : Json.t) : Keyval.Key.t =
    match json with
    | `Assoc fields ->
      let key_ref = ref None in
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
           | _ -> ());
          iter rest
      in
      iter fields;
      (match !key_ref with
       | Some s -> Keyval.Key.v s
       | None -> raise (Json.Invalid_json (json, "Missing field: key")))
    | _ -> raise (Json.Invalid_json (json, "Expected object"))
  ;;

  let of_json (json : Json.t) : t =
    match json with
    | `Assoc fields ->
      let keys_ref = ref None in
      let rec iter = function
        | [] -> ()
        | (name, value) :: rest ->
          (match name with
           | "keys" ->
             keys_ref
             := Some
                  (match value with
                   | `List keys -> List.map keys ~f:key_of_json
                   | _ -> raise (Json.Invalid_json (value, "Expected array for keys")))
           | _ -> ());
          iter rest
      in
      iter fields;
      (match !keys_ref with
       | Some v -> v
       | None -> raise (Json.Invalid_json (json, "Missing field: keys")))
    | _ -> raise (Json.Invalid_json (json, "Expected object"))
  ;;

  let schema () =
    `Assoc
      [ "type", `String "object"
      ; ( "properties"
        , `Assoc
            [ ( "keys"
              , `Assoc
                  [ "type", `String "array"
                  ; ( "items"
                    , `Assoc
                        [ "type", `String "object"
                        ; ( "properties"
                          , `Assoc [ "key", `Assoc [ "type", `String "string" ] ] )
                        ; "required", `List [ `String "key" ]
                        ] )
                  ] )
            ] )
      ; "required", `List [ `String "keys" ]
      ]
  ;;
end

let rpc : _ Rpc.t =
  Rpc.create
    ~name:(Rpc.Name.v "listKeys")
    ~version:1
    ~description:"Retrieve a list of all keys present in the memory database."
    ~request_encoder:(Rpc.Encoder.make (module Request))
    ~response_encoder:(Rpc.Encoder.make (module Response))
    ()
;;
