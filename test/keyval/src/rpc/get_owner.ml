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
  type t =
    | Some of { owner : Keyval.Owner.t }
    | No_such_key

  let equal t1 t2 =
    match t1, t2 with
    | Some { owner = owner1 }, Some { owner = owner2 } -> Keyval.Owner.equal owner1 owner2
    | No_such_key, No_such_key -> true
    | (Some _ | No_such_key), _ -> false
  ;;

  let to_json : t -> Json.t = function
    | Some { owner } -> `Assoc [ "owner", `String (Keyval.Owner.to_string owner) ]
    | No_such_key -> `Null
  ;;

  let of_json (json : Json.t) : t =
    match json with
    | `Null -> No_such_key
    | `Assoc fields ->
      let owner_ref = ref None in
      let rec iter = function
        | [] -> ()
        | (name, value) :: rest ->
          (match name with
           | "owner" ->
             owner_ref
             := Some
                  (match value with
                   | `String s -> s
                   | _ -> raise (Json.Invalid_json (value, "Expected string for owner")))
           | _ -> ());
          iter rest
      in
      iter fields;
      (match !owner_ref with
       | Some s -> Some { owner = Keyval.Owner.v s }
       | None -> raise (Json.Invalid_json (json, "Missing field: owner")))
    | _ -> raise (Json.Invalid_json (json, "Expected object or null"))
  ;;

  let schema () =
    `Assoc
      [ ( "oneOf"
        , `List
            [ `Assoc
                [ "type", `String "object"
                ; "properties", `Assoc [ "owner", `Assoc [ "type", `String "string" ] ]
                ; "required", `List [ `String "owner" ]
                ]
            ; `Assoc [ "type", `String "null" ]
            ] )
      ]
  ;;
end

let rpc : _ Rpc.t =
  Rpc.create
    ~name:(Rpc.Name.v "getOwner")
    ~version:1
    ~description:
      "Retrieve the owner that last set a key's binding. No_such_key means the key \
       doesn't exist."
    ~request_encoder:(Rpc.Encoder.make (module Request))
    ~response_encoder:(Rpc.Encoder.make (module Response))
    ()
;;
