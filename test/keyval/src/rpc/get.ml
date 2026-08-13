(*********************************************************************************)
(*  lunarpc - An opinionated, lightweight, HTTP/JSON RPC harness                 *)
(*  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: MIT                                                 *)
(*********************************************************************************)

module Request = struct
  type t = Keyval.Key.t

  let equal = Keyval.Key.equal
  let to_json (t : t) : Json.t = `Assoc [ "key", `String (Keyval.Key.to_string t) ]

  let of_json (json : Json.t) : t =
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

  let schema () =
    `Assoc
      [ "type", `String "object"
      ; "properties", `Assoc [ "key", `Assoc [ "type", `String "string" ] ]
      ; "required", `List [ `String "key" ]
      ]
  ;;
end

module Response = struct
  type t = Keyval.Value.t option

  let equal = Option.equal Keyval.Value.equal

  let to_json : t -> Json.t = function
    | Some value -> `Assoc [ "value", `String (Keyval.Value.to_string value) ]
    | None -> `Null
  ;;

  let of_json (json : Json.t) : t =
    match json with
    | `Null -> None
    | `Assoc fields ->
      let value_ref = ref None in
      let rec iter = function
        | [] -> ()
        | (name, value) :: rest ->
          (match name with
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
      (match !value_ref with
       | Some s -> Some (Keyval.Value.of_string s)
       | None -> raise (Json.Invalid_json (json, "Missing field: value")))
    | _ -> raise (Json.Invalid_json (json, "Expected object or null"))
  ;;

  let schema () =
    `Assoc
      [ ( "oneOf"
        , `List
            [ `Assoc
                [ "type", `String "object"
                ; "properties", `Assoc [ "value", `Assoc [ "type", `String "string" ] ]
                ; "required", `List [ `String "value" ]
                ]
            ; `Assoc [ "type", `String "null" ]
            ] )
      ]
  ;;
end

let rpc : _ Rpc.t =
  Rpc.create
    ~name:(Rpc.Name.v "get")
    ~version:2
    ~description:
      "Retrieve the value associated with a key from the memory database, or null if the \
       key doesn't exist. Supersedes v1, which raised an error on a missing key: an \
       absent value is normal here, not exceptional, so callers can distinguish it from \
       an actual failure."
    ~request_encoder:(Rpc.Encoder.make (module Request))
    ~response_encoder:(Rpc.Encoder.make (module Response))
    ()
;;
