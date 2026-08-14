(*********************************************************************************)
(*  lunarpc - An opinionated, lightweight, HTTP/JSON RPC harness                 *)
(*  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: MIT                                                 *)
(*********************************************************************************)

type t =
  { name : Name.t
  ; version : int
  ; route : string
  ; description : string
  ; request_schema : Json.t option
  ; response_schema : Json.t option
  }

let equal
      t1
      ({ name; version; route; description; request_schema; response_schema } as t2)
  =
  phys_equal t1 t2
  || (Name.equal t1.name name
      && Int.equal t1.version version
      && String.equal t1.route route
      && String.equal t1.description description
      && Option.equal Json.equal t1.request_schema request_schema
      && Option.equal Json.equal t1.response_schema response_schema)
;;

let to_json (t : t) : Json.t =
  `Assoc
    (List.concat
       [ [ "name", `String (Name.to_string t.name)
         ; "version", `Int t.version
         ; "route", `String t.route
         ; "description", `String t.description
         ]
       ; (match t.request_schema with
          | None -> []
          | Some schema -> [ "requestSchema", schema ])
       ; (match t.response_schema with
          | None -> []
          | Some schema -> [ "responseSchema", schema ])
       ])
;;

let of_json (json : Json.t) : t =
  match json with
  | `Assoc fields ->
    let name_ref = ref None in
    let version_ref = ref None in
    let route_ref = ref None in
    let description_ref = ref None in
    let request_schema_ref = ref None in
    let response_schema_ref = ref None in
    let rec iter = function
      | [] -> ()
      | (name, value) :: rest ->
        (match name with
         | "name" ->
           name_ref
           := Some
                (match value with
                 | `String s ->
                   (match Name.of_string s with
                    | Ok n -> n
                    | Error (`Msg m) -> raise (Json.Invalid_json (value, m)))
                 | _ -> raise (Json.Invalid_json (value, "Expected string for name")))
         | "version" ->
           version_ref
           := Some
                (match value with
                 | `Int i -> i
                 | _ -> raise (Json.Invalid_json (value, "Expected int for version")))
         | "route" ->
           route_ref
           := Some
                (match value with
                 | `String s -> s
                 | _ -> raise (Json.Invalid_json (value, "Expected string for route")))
         | "description" ->
           description_ref
           := Some
                (match value with
                 | `String s -> s
                 | _ ->
                   raise (Json.Invalid_json (value, "Expected string for description")))
         | "requestSchema" -> request_schema_ref := Some value
         | "responseSchema" -> response_schema_ref := Some value
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
    { name = require name_ref "name"
    ; version = require version_ref "version"
    ; route = require route_ref "route"
    ; description = require description_ref "description"
    ; request_schema = !request_schema_ref
    ; response_schema = !response_schema_ref
    }
  | _ -> raise (Json.Invalid_json (json, "Expected object"))
;;

let schema () =
  `Assoc
    [ "type", `String "object"
    ; ( "required"
      , `List
          [ `String "name"; `String "version"; `String "route"; `String "description" ] )
    ; ( "properties"
      , `Assoc
          [ ( "name"
            , `Assoc
                [ "type", `String "string"; "description", `String "Name of the RPC" ] )
          ; ( "version"
            , `Assoc
                [ "type", `String "integer"
                ; "description", `String "Version of the RPC (local to this RPC)"
                ] )
          ; ( "route"
            , `Assoc
                [ "type", `String "string"
                ; "description", `String "RPC route path component"
                ] )
          ; ( "description"
            , `Assoc
                [ "type", `String "string"
                ; "description", `String "Human-readable RPC description"
                ] )
          ; ( "requestSchema"
            , `Assoc
                [ "type", `String "object"
                ; ( "description"
                  , `String
                      "JSON Schema for request. Only present when the listRpcs request \
                       had includeSchemas set to true." )
                ] )
          ; ( "responseSchema"
            , `Assoc
                [ "type", `String "object"
                ; ( "description"
                  , `String
                      "JSON Schema for response. Only present when the listRpcs request \
                       had includeSchemas set to true." )
                ] )
          ] )
    ]
;;
