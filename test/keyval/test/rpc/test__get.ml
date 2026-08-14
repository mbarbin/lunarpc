(*********************************************************************************)
(*  lunarpc - An opinionated, lightweight, HTTP/JSON RPC harness                 *)
(*  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: MIT                                                 *)
(*********************************************************************************)

(* @mdexp

   # RPC roundtrip: Get

   `Rpc_quickcheck.run_exn` exercises an RPC's JSON encoding end to end: it
   generates random requests and responses, checks them against the RPC's
   JSON schema, and verifies that encoding to JSON and back is the
   identity. Explicit `~requests` (and `~responses`) can be supplied to
   also cover specific, hand-picked examples in addition to the generated
   ones --- here, a couple of concrete keys.

   `Keyval_rpc.Get` itself carries no generator (the `keyval` and
   `keyval_rpc` libraries have no dependency on `lunarpc-quickcheck`); the
   test builds the generators it needs locally. *)

module Get = struct
  module Request = struct
    include Keyval_rpc.Get.Request

    let generator = Keyval_generators.Key.generator
  end

  module Response = struct
    include Keyval_rpc.Get.Response

    let generator = Generator.option Keyval_generators.Value.generator
  end

  let rpc = Keyval_rpc.Get.rpc
end

let%expect_test "roundtrip" =
  Rpc_quickcheck.run_exn (module Get) ~requests:[ Keyval.Key.v "foo"; Keyval.Key.v "bar" ];
  [%expect {||}];
  ()
;;

(* @mdexp

   ## Invalid json

   Roundtrip tests only ever feed [of_json] its own [to_json] output, so
   they never exercise the decoders' error paths. These do: malformed
   shapes are rejected by the decoder itself with [Json.Invalid_json];
   a well-shaped [key] that fails [Keyval.Key]'s own invariant is
   rejected downstream, as [Invalid_argument]. *)

let%expect_test "invalid request" =
  let test json = require_does_raise (fun () -> Get.rpc.request_encoder.of_json json) in
  test (`Int 42);
  [%expect {| (Json.Invalid_json "Expected object" 42) |}];
  test (`Assoc []);
  [%expect {| (Json.Invalid_json "Missing field: key" {}) |}];
  test (`Assoc [ "key", `Int 1 ]);
  [%expect {| (Json.Invalid_json "Expected string for key" 1) |}];
  test (`Assoc [ "key", `String "" ]);
  [%expect {| (Invalid_argument "\"\": invalid key") |}];
  ()
;;

let%expect_test "invalid response" =
  let test json = require_does_raise (fun () -> Get.rpc.response_encoder.of_json json) in
  test (`Int 42);
  [%expect {| (Json.Invalid_json "Expected object or null" 42) |}];
  test (`Assoc []);
  [%expect {| (Json.Invalid_json "Missing field: value" {}) |}];
  test (`Assoc [ "value", `Int 1 ]);
  [%expect {| (Json.Invalid_json "Expected string for value" 1) |}];
  ()
;;

(* @mdexp

   ## Extra fields are ignored

   The decoders iterate over whatever fields are present rather than
   matching a fixed shape, so an unrecognized field --- from, say, a
   newer client talking to an older server --- is silently skipped
   rather than rejected. *)

let%expect_test "extra fields are ignored" =
  require
    (Get.Request.equal
       (Get.rpc.request_encoder.of_json
          (`Assoc [ "key", `String "foo"; "extra", `Int 1 ]))
       (Keyval.Key.v "foo"));
  [%expect {||}];
  require
    (Get.Response.equal
       (Get.rpc.response_encoder.of_json
          (`Assoc [ "value", `String "x"; "extra", `Int 1 ]))
       (Some (Keyval.Value.v "x")));
  [%expect {||}];
  ()
;;

(* @mdexp

   ## [equal]

   Sanity-checks that [equal] actually discriminates values, rather than
   e.g. always returning [true]. *)

let%expect_test "equal" =
  require (Get.Request.equal (Keyval.Key.v "foo") (Keyval.Key.v "foo"));
  [%expect {||}];
  require (not (Get.Request.equal (Keyval.Key.v "foo") (Keyval.Key.v "bar")));
  [%expect {||}];
  require (Get.Response.equal None None);
  [%expect {||}];
  require (Get.Response.equal (Some (Keyval.Value.v "x")) (Some (Keyval.Value.v "x")));
  [%expect {||}];
  require
    (not (Get.Response.equal (Some (Keyval.Value.v "x")) (Some (Keyval.Value.v "y"))));
  [%expect {||}];
  require (not (Get.Response.equal None (Some (Keyval.Value.v "x"))));
  [%expect {||}];
  ()
;;
