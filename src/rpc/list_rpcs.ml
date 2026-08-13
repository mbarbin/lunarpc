(*********************************************************************************)
(*  lunarpc - An opinionated, lightweight, HTTP/JSON RPC harness                 *)
(*  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: MIT                                                 *)
(*********************************************************************************)

module Request = struct
  module Names = struct
    type t =
      | All
      | Only of { names : Name.t list }

    let equal t1 t2 =
      match t1, t2 with
      | All, All -> true
      | Only { names = n1 }, Only { names = n2 } -> List.equal ~eq:Name.equal n1 n2
      | All, Only _ | Only _, All -> false
    ;;
  end

  type t =
    { include_schemas : bool
    ; names : Names.t
    }

  let equal t1 ({ include_schemas; names } as t2) =
    phys_equal t1 t2
    || (Bool.equal t1.include_schemas include_schemas && Names.equal t1.names names)
  ;;

  let to_json (t : t) : Json.t =
    let fields = [] in
    let fields =
      if t.include_schemas then ("includeSchemas", `Bool true) :: fields else fields
    in
    let fields =
      match t.names with
      | All -> fields
      | Only { names } ->
        ("names", `List (List.map names ~f:(fun name -> `String (Name.to_string name))))
        :: fields
    in
    `Assoc (List.rev fields)
  ;;

  let of_json (json : Json.t) : t =
    match json with
    | `Assoc fields ->
      let include_schemas_ref = ref false in
      let names_ref = ref Names.All in
      let rec iter = function
        | [] -> ()
        | (name, value) :: rest ->
          (match name with
           | "includeSchemas" ->
             include_schemas_ref
             := (match value with
                  | `Bool v -> v
                  | _ ->
                    raise
                      (Json.Invalid_json (value, "Expected boolean for includeSchemas")))
           | "names" ->
             let names =
               match value with
               | `List names ->
                 List.map names ~f:(function
                   | `String s ->
                     (match Name.of_string s with
                      | Ok n -> n
                      | Error (`Msg m) -> raise (Json.Invalid_json (value, m)))
                   | _ ->
                     raise (Json.Invalid_json (value, "Expected string in names array")))
               | _ -> raise (Json.Invalid_json (value, "Expected array for names"))
             in
             names_ref := Names.Only { names }
           | _ -> ());
          iter rest
      in
      iter fields;
      { include_schemas = !include_schemas_ref; names = !names_ref }
    | _ -> raise (Json.Invalid_json (json, "Expected object"))
  ;;

  let schema () =
    `Assoc
      [ "$schema", `String "http://json-schema.org/draft-07/schema#"
      ; "title", `String "ListRpcsRequest"
      ; "description", `String "Request to retrieve service schema information"
      ; "type", `String "object"
      ; ( "properties"
        , `Assoc
            [ ( "includeSchemas"
              , `Assoc
                  [ "type", `String "boolean"
                  ; ( "description"
                    , `String
                        "If true, include full JSON schemas inline. If false, only \
                         include schema references/paths." )
                  ; "default", `Bool false
                  ] )
            ; ( "names"
              , `Assoc
                  [ "type", `String "array"
                  ; ( "description"
                    , `String
                        "Optional filter: only return information for RPCs with these \
                         names. If omitted, return all RPCs." )
                  ; "items", `Assoc [ "type", `String "string" ]
                  ] )
            ] )
      ]
  ;;
end

module Response = struct
  type t = { rpcs : Info.t list }

  let equal t1 ({ rpcs } as t2) =
    phys_equal t1 t2 || List.equal ~eq:Info.equal t1.rpcs rpcs
  ;;

  let to_json (t : t) : Json.t =
    `Assoc [ "rpcs", `List (List.map t.rpcs ~f:Info.to_json) ]
  ;;

  let of_json (json : Json.t) : t =
    match json with
    | `Assoc fields ->
      let rpcs_ref = ref None in
      let rec iter = function
        | [] -> ()
        | (name, value) :: rest ->
          (match name with
           | "rpcs" ->
             rpcs_ref
             := Some
                  (match value with
                   | `List rpcs -> List.map rpcs ~f:Info.of_json
                   | _ -> raise (Json.Invalid_json (value, "Expected array for rpcs")))
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
      { rpcs = require rpcs_ref "rpcs" }
    | _ -> raise (Json.Invalid_json (json, "Expected object"))
  ;;

  let schema () =
    `Assoc
      [ "$schema", `String "http://json-schema.org/draft-07/schema#"
      ; "title", `String "ListRpcsResponse"
      ; "description", `String "List of all RPCs exposed by the service"
      ; "type", `String "object"
      ; "required", `List [ `String "rpcs" ]
      ; ( "properties"
        , `Assoc
            [ ( "rpcs"
              , `Assoc
                  [ "type", `String "array"
                  ; "description", `String "List of RPCs exposed by the service"
                  ; "items", Info.schema ()
                  ] )
            ] )
      ]
  ;;
end

let rpc : _ Rpc0.t =
  Rpc0.create
    ~name:(Name.v "listRpcs")
    ~version:1
    ~description:
      "Retrieve schema information for all RPCs available in the service. This \
       introspective RPC allows clients and agents to discover what RPCs are available \
       and understand their request/response schemas."
    ~request_encoder:(Encoder.make (module Request))
    ~response_encoder:(Encoder.make (module Response))
    ()
;;
