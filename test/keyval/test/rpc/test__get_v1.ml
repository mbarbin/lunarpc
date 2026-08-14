(*********************************************************************************)
(*  lunarpc - An opinionated, lightweight, HTTP/JSON RPC harness                 *)
(*  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: MIT                                                 *)
(*********************************************************************************)

(* @mdexp

   # RPC roundtrip: Get, v1

   `Keyval_rpc.Get_v1` is the deprecated first version of the ["get"] RPC:
   same name as `Keyval_rpc.Get`, but registered as its own handler under
   `version = 1`, with a response schema that has no room for "missing" ---
   the v1 handler raises instead. `Keyval_rpc.Get` (`version = 2`) is what
   replaced it, once returning `null` for a missing key turned out to be
   the better fit than failing the call.

   This pair exists to demonstrate that versions of the same RPC name are
   independent, side-by-side handlers: each has its own route
   (`rpc/get/v1` vs `rpc/get/v2`), its own schema, and its own server-side
   function. *)

module Get_v1 = struct
  module Request = struct
    include Keyval_rpc.Get_v1.Request

    let generator = Keyval_generators.Key.generator
  end

  module Response = struct
    include Keyval_rpc.Get_v1.Response

    let generator = Keyval_generators.Value.generator
  end

  let rpc = Keyval_rpc.Get_v1.rpc
end

let%expect_test "roundtrip" =
  Rpc_quickcheck.run_exn
    (module Get_v1)
    ~requests:[ Keyval.Key.v "foo"; Keyval.Key.v "bar" ];
  [%expect {||}];
  ()
;;

(* @mdexp

   ## Invalid json

   Same decoder-error coverage as [Get](test__get.md), plus one thing
   specific to v1: unlike v2, its response has no [null] case, so a
   missing value must fail to decode rather than come back as absent. *)

let%expect_test "invalid request" =
  let test json =
    require_does_raise (fun () -> Get_v1.rpc.request_encoder.of_json json)
  in
  test (`Int 42);
  [%expect {| (Json.Invalid_json "Expected object" 42) |}];
  test (`Assoc [ "key", `String "" ]);
  [%expect {| (Invalid_argument "\"\": invalid key") |}];
  ()
;;

let%expect_test "invalid response" =
  let test json =
    require_does_raise (fun () -> Get_v1.rpc.response_encoder.of_json json)
  in
  test (`Int 42);
  [%expect {| (Json.Invalid_json "Expected object" 42) |}];
  test (`Assoc []);
  [%expect {| (Json.Invalid_json "Missing field: value" {}) |}];
  (* Unlike [Get] (v2), [null] is not a valid response here. *)
  test `Null;
  [%expect {| (Json.Invalid_json "Expected object" null) |}];
  ()
;;

(* @mdexp

   ## Extra fields are ignored *)

let%expect_test "extra fields are ignored" =
  require
    (Get_v1.Request.equal
       (Get_v1.rpc.request_encoder.of_json
          (`Assoc [ "key", `String "foo"; "extra", `Int 1 ]))
       (Keyval.Key.v "foo"));
  [%expect {||}];
  require
    (Get_v1.Response.equal
       (Get_v1.rpc.response_encoder.of_json
          (`Assoc [ "value", `String "x"; "extra", `Int 1 ]))
       (Keyval.Value.v "x"));
  [%expect {||}];
  ()
;;

(* @mdexp

   ## [equal]

   Sanity-checks that [equal] actually discriminates values, rather than
   e.g. always returning [true]. *)

let%expect_test "equal" =
  require (Get_v1.Request.equal (Keyval.Key.v "foo") (Keyval.Key.v "foo"));
  [%expect {||}];
  require (not (Get_v1.Request.equal (Keyval.Key.v "foo") (Keyval.Key.v "bar")));
  [%expect {||}];
  require (Get_v1.Response.equal (Keyval.Value.v "x") (Keyval.Value.v "x"));
  [%expect {||}];
  require (not (Get_v1.Response.equal (Keyval.Value.v "x") (Keyval.Value.v "y")));
  [%expect {||}];
  ()
;;
