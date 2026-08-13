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
    | Deleted
    | No_such_key

  let equal t1 t2 =
    match t1, t2 with
    | Deleted, Deleted -> true
    | No_such_key, No_such_key -> true
    | (Deleted | No_such_key), _ -> false
  ;;

  let to_json (t : t) : Json.t =
    match t with
    | Deleted -> `String "Deleted"
    | No_such_key -> `String "No_such_key"
  ;;

  let of_json : Json.t -> t = function
    | `String "Deleted" -> Deleted
    | `String "No_such_key" -> No_such_key
    | json -> raise (Json.Invalid_json (json, "Expected a single string constructor"))
  ;;

  let schema () = `Assoc [ "type", `String "string" ]
end

let rpc : _ Rpc.t =
  Rpc.create
    ~name:(Rpc.Name.v "delete")
    ~version:1
    ~description:
      "Permanently delete a binding from the memory database, based on its key."
    ~request_encoder:(Rpc.Encoder.make (module Request))
    ~response_encoder:(Rpc.Encoder.make (module Response))
    ()
;;
