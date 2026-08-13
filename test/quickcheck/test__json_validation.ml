(*********************************************************************************)
(*  lunarpc - An opinionated, lightweight, HTTP/JSON RPC harness                 *)
(*  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: MIT                                                 *)
(*********************************************************************************)

(* @mdexp

   # JSON schema validation

   Every RPC request and response type exposes a `schema : unit -> Json.t`
   describing its JSON Schema. `Rpc_quickcheck` uses it to validate that
   generated values actually match their own declared schema, catching
   drift between an encoder and the schema it advertises.

   This chapter exercises that schema-validation machinery directly,
   independent of any real RPC, using a small ad hoc `Lookup_key` RPC
   (a `string -> string` lookup) as a fixture. *)

let json_validator_exn schema =
  match Jsonschema.create_validator_from_json ~schema () with
  | Ok validator -> validator
  | Error compile_error ->
    let error = Format.asprintf "%a" Jsonschema.pp_compile_error compile_error in
    raise (Failure (Printf.sprintf "Invalid schema: %s" error))
;;

let validate_json validator json =
  match Jsonschema.validate validator json with
  | Ok () -> Ok ()
  | Error validation_error ->
    let error =
      Format.asprintf "%a" Jsonschema.pp_validation_error_verbose validation_error
    in
    Error (Printf.sprintf "Json schema validation error: %s" error)
;;

module Lookup_key = struct
  module Request = struct
    type t = string

    let equal = String.equal
    let generator = Generator.string_non_empty
    let to_json (t : t) : Json.t = `Assoc [ "key", `String t ]

    let of_json : Json.t -> t = function
      | `Assoc [ ("key", `String key) ] -> key
      | json -> raise (Json.Invalid_json (json, "Expected a single key string field"))
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
    type t = string

    let equal = String.equal
    let generator = Generator.string_non_empty
    let to_json (t : t) : Json.t = `Assoc [ "value", `String t ]

    let of_json : Json.t -> t = function
      | `Assoc [ ("value", `String value) ] -> value
      | json -> raise (Json.Invalid_json (json, "Expected a single key string field"))
    ;;

    let schema () =
      `Assoc
        [ "type", `String "object"
        ; "properties", `Assoc [ "value", `Assoc [ "type", `String "string" ] ]
        ; "required", `List [ `String "value" ]
        ]
    ;;
  end

  let rpc : _ Rpc.t =
    Rpc.create
      ~name:(Rpc.Name.v "lookupKey")
      ~version:1
      ~description:"Get the value attached to a key"
      ~request_encoder:(Rpc.Encoder.make (module Request))
      ~response_encoder:(Rpc.Encoder.make (module Response))
      ()
  ;;
end

(* @mdexp

   ## Validating JSON against a schema

   `validate_json` checks a JSON value against a compiled schema and reports
   a human-readable error for mismatches: wrong type, missing required
   property, or a bad value nested under a property path. This is the same
   check `Rpc_quickcheck.run_validate_request_exn` and
   `run_validate_response_exn` perform on generated values, here driven by
   hand-picked examples instead. *)

let%expect_test "validate" =
  let validator = json_validator_exn (Lookup_key.Request.schema ()) in
  let test json =
    print_dyn (validate_json validator json |> Dyn.result Dyn.unit Dyn.string)
  in
  test (`Int 42);
  [%expect
    {|
    Error
      "Json schema validation error: jsonschema validation failed with inline://schema\n\
      \  at '': type mismatch"
    |}];
  test (`Assoc []);
  [%expect
    {|
    Error
      "Json schema validation error: jsonschema validation failed with inline://schema\n\
      \  at '': missing properties key"
    |}];
  test (`Assoc [ "key", `Int 42 ]);
  [%expect
    {|
    Error
      "Json schema validation error: jsonschema validation failed with inline://schema#/properties/key\n\
      \  at '/key': type mismatch"
    |}];
  test (`Assoc [ "key", `String "42" ]);
  [%expect {| Ok () |}];
  ()
;;

(* @mdexp

   ## Extra fields are valid against the schema too

   Every decoder in this codebase tolerates unknown fields (see e.g.
   [List rpcs](../keyval/test/rpc/test__list_rpcs.md)); the schema it
   advertises needs to agree, or a well-behaved caller validating its
   payload against the schema before sending would reject something the
   decoder would happily accept. JSON Schema's default for
   `additionalProperties` when unspecified is `true`, which is exactly
   what's wanted here --- so none of these schemas set it (an earlier
   version of `Rpc.List_rpcs`'s did set it to `false`, which was this
   inconsistency exactly). *)

let%expect_test "extra fields are valid against a real RPC's schema" =
  let validator = json_validator_exn (Rpc.List_rpcs.rpc.request_encoder.schema ()) in
  print_dyn
    (validate_json validator (`Assoc [ "includeSchemas", `Bool true; "extra", `Int 1 ])
     |> Dyn.result Dyn.unit Dyn.string);
  [%expect {| Ok () |}];
  ()
;;

(* @mdexp

   ## Roundtrip against a real RPC

   Same as the [keyval RPC roundtrip](../keyval/test/rpc/test__get.md)
   checks: `Rpc_quickcheck.run_exn` generates random requests and responses
   for `Lookup_key`, checks them against its schema, and verifies that
   encoding to JSON and back is the identity. *)

let%expect_test "roundtrip" =
  Rpc_quickcheck.run_exn (module Lookup_key);
  [%expect {||}];
  ()
;;
