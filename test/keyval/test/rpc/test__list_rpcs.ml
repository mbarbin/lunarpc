(*********************************************************************************)
(*  lunarpc - An opinionated, lightweight, HTTP/JSON RPC harness                 *)
(*  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: MIT                                                 *)
(*********************************************************************************)

(* @mdexp

   # RPC roundtrip: List rpcs

   `Rpc.List_rpcs` is generic --- defined in `lunarpc` itself, not
   `keyval_rpc` --- and its payload is metadata about *other* RPCs
   ([Rpc.Info.t]: name, route, description, optional JSON schemas).
   Rather than fabricate arbitrary names and schemas, its generators draw
   directly from the real RPCs [Keyval_server.handlers] registers (plus
   `List_rpcs` itself, which lists itself too), so every generated value
   is exactly what a real server would produce. *)

let all_rpcs : (module Rpc.S) list =
  [ (module Keyval_rpc.Get : Rpc.S)
  ; (module Keyval_rpc.Get_v1 : Rpc.S)
  ; (module Keyval_rpc.Set_ : Rpc.S)
  ; (module Keyval_rpc.Delete : Rpc.S)
  ; (module Keyval_rpc.List_keys : Rpc.S)
  ; (module Keyval_rpc.Get_owner : Rpc.S)
  ; (module Keyval_rpc.Fail : Rpc.S)
  ; (module Keyval_rpc.Fail_request : Rpc.S)
  ; (module Keyval_rpc.Fail_response : Rpc.S)
  ; (module Keyval_rpc.Stop : Rpc.S)
  ; (module Rpc.List_rpcs : Rpc.S)
  ]
;;

let all_names = List.map all_rpcs ~f:(fun (module M : Rpc.S) -> M.rpc.name)

let info_of_rpc ~include_schemas (module M : Rpc.S) : Rpc.Info.t =
  { name = M.rpc.name
  ; version = M.rpc.version
  ; route = Rpc.route M.rpc
  ; description = M.rpc.description
  ; request_schema =
      (if include_schemas then Some (M.rpc.request_encoder.schema ()) else None)
  ; response_schema =
      (if include_schemas then Some (M.rpc.response_encoder.schema ()) else None)
  }
;;

module List_rpcs = struct
  module Request = struct
    include Rpc.List_rpcs.Request

    let generator =
      let open Generator.Syntax in
      let+ include_schemas = Generator.bool
      and+ names =
        Generator.union
          [ Generator.return Names.All
          ; (let+ names = Generator.list (Generator.of_list all_names) in
             Names.Only { names })
          ]
      in
      { include_schemas; names }
    ;;
  end

  module Response = struct
    include Rpc.List_rpcs.Response

    let generator =
      let open Generator.Syntax in
      let+ include_schemas = Generator.bool
      and+ rpcs = Generator.list (Generator.of_list all_rpcs) in
      { rpcs = List.map rpcs ~f:(info_of_rpc ~include_schemas) }
    ;;
  end

  let rpc = Rpc.List_rpcs.rpc
end

let%expect_test "roundtrip" =
  Rpc_quickcheck.run_exn
    (module List_rpcs)
    ~requests:
      [ { Rpc.List_rpcs.Request.include_schemas = false; names = All }
      ; { include_schemas = true; names = Only { names = all_names } }
      ]
    ~responses:
      [ { Rpc.List_rpcs.Response.rpcs =
            List.map all_rpcs ~f:(info_of_rpc ~include_schemas:false)
        }
      ; { rpcs = List.map all_rpcs ~f:(info_of_rpc ~include_schemas:true) }
      ];
  [%expect {||}];
  ()
;;

(* @mdexp

   ## Invalid json

   The request's [names] field, and each element of the response's
   [rpcs] array, decode through [Rpc.Info.of_json] and [Rpc.Name.of_string]
   respectively --- errors from either propagate as-is, on top of this
   RPC's own shape checks. *)

let%expect_test "invalid request" =
  let test json =
    require_does_raise (fun () -> List_rpcs.rpc.request_encoder.of_json json)
  in
  test (`Int 42);
  [%expect {| (Json.Invalid_json "Expected object" 42) |}];
  test (`Assoc [ "includeSchemas", `String "true" ]);
  [%expect {| (Json.Invalid_json "Expected boolean for includeSchemas" "\"true\"") |}];
  test (`Assoc [ "names", `String "not a list" ]);
  [%expect {| (Json.Invalid_json "Expected array for names" "\"not a list\"") |}];
  test (`Assoc [ "names", `List [ `Int 1 ] ]);
  [%expect {| (Json.Invalid_json "Expected string in names array" "[ 1 ]") |}];
  test (`Assoc [ "names", `List [ `String "Not valid!" ] ]);
  [%expect
    {| (Json.Invalid_json "\"Not valid!\": invalid Rpc.Name" "[ \"Not valid!\" ]") |}];
  ()
;;

let%expect_test "invalid response" =
  let test json =
    require_does_raise (fun () -> List_rpcs.rpc.response_encoder.of_json json)
  in
  test (`Int 42);
  [%expect {| (Json.Invalid_json "Expected object" 42) |}];
  test (`Assoc [ "rpcs", `String "not a list" ]);
  [%expect {| (Json.Invalid_json "Expected array for rpcs" "\"not a list\"") |}];
  test (`Assoc [ "rpcs", `List [ `Int 1 ] ]);
  [%expect {| (Json.Invalid_json "Expected object" 1) |}];
  test (`Assoc [ "rpcs", `List [ `Assoc [] ] ]);
  [%expect {| (Json.Invalid_json "Missing field: description" {}) |}];
  test
    (`Assoc
        [ ( "rpcs"
          , `List
              [ `Assoc
                  [ "name", `String "Not valid!"
                  ; "version", `Int 1
                  ; "route", `String "r"
                  ; "description", `String "d"
                  ]
              ] )
        ]);
  [%expect {| (Json.Invalid_json "\"Not valid!\": invalid Rpc.Name" "\"Not valid!\"") |}];
  ()
;;

(* @mdexp

   ## Extra fields are ignored

   At the top level, and (via [Rpc.Info.of_json]) on each element of the
   response's [rpcs] array. *)

let%expect_test "extra fields are ignored" =
  require
    (List_rpcs.Request.equal
       (List_rpcs.rpc.request_encoder.of_json
          (`Assoc [ "includeSchemas", `Bool true; "extra", `Int 1 ]))
       { include_schemas = true; names = All });
  [%expect {||}];
  let info = info_of_rpc ~include_schemas:false (List.hd_exn all_rpcs) in
  let info_json =
    match Rpc.Info.to_json info with
    | `Assoc fields -> `Assoc (fields @ [ "extra", `Int 1 ])
    | _ -> assert false
  in
  require
    (List_rpcs.Response.equal
       (List_rpcs.rpc.response_encoder.of_json
          (`Assoc [ "rpcs", `List [ info_json ]; "extra", `Int 1 ]))
       { rpcs = [ info ] });
  [%expect {||}];
  ()
;;

(* @mdexp

   ## [equal]

   Sanity-checks that [equal] actually discriminates values, rather than
   e.g. always returning [true] --- for the request, that includes being
   sensitive to [names]'s order (it is plain positional list equality,
   not a set comparison), same as [List_keys](test__list_keys.md). *)

let%expect_test "equal" =
  let a : List_rpcs.Request.t = { include_schemas = false; names = All } in
  require (List_rpcs.Request.equal a a);
  [%expect {||}];
  require (not (List_rpcs.Request.equal a { a with include_schemas = true }));
  [%expect {||}];
  require (not (List_rpcs.Request.equal a { a with names = Only { names = [] } }));
  [%expect {||}];
  let foo = Rpc.Name.v "foo"
  and bar = Rpc.Name.v "bar" in
  require
    (List_rpcs.Request.equal
       { a with names = Only { names = [ foo ] } }
       { a with names = Only { names = [ foo ] } });
  [%expect {||}];
  require
    (not
       (List_rpcs.Request.equal
          { a with names = Only { names = [ foo ] } }
          { a with names = Only { names = [ bar ] } }));
  [%expect {||}];
  require
    (not
       (List_rpcs.Request.equal
          { a with names = Only { names = [ foo; bar ] } }
          { a with names = Only { names = [ bar; foo ] } }));
  [%expect {||}];
  let info = info_of_rpc ~include_schemas:false (List.hd_exn all_rpcs) in
  require (List_rpcs.Response.equal { rpcs = [ info ] } { rpcs = [ info ] });
  [%expect {||}];
  require
    (not
       (List_rpcs.Response.equal
          { rpcs = [ info ] }
          { rpcs = [ { info with version = info.version + 1 } ] }));
  [%expect {||}];
  require (not (List_rpcs.Response.equal { rpcs = [ info ] } { rpcs = [] }));
  [%expect {||}];
  ()
;;
