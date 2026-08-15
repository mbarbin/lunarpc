(*********************************************************************************)
(*  lunarpc - An opinionated, lightweight, HTTP/JSON RPC harness                 *)
(*  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: MIT                                                 *)
(*********************************************************************************)

(* @mdexp

   # RPC roundtrip: Fail

   Same roundtrip check as for [Get](test__get.md), applied to the `Fail`
   RPC. Both its request and response are `Unit`, so this only checks the
   JSON encoding --- see [Malformed requests](../test__invalid_rpc.md)
   for what actually happens when this RPC's handler raises. *)

module Fail = struct
  module Request = struct
    include Keyval_rpc.Fail.Request

    let generator = Generator.return ()
  end

  module Response = struct
    include Keyval_rpc.Fail.Response

    let generator = Generator.return ()
  end

  let rpc = Keyval_rpc.Fail.rpc
end

let%expect_test "roundtrip" =
  Rpc_quickcheck.run_exn (module Fail);
  [%expect {||}];
  ()
;;

(* @mdexp

   ## Invalid json

   Both [Unit]: anything other than a JSON object is rejected. *)

let%expect_test "invalid request" =
  let test json = require_does_raise (fun () -> Fail.rpc.request_encoder.of_json json) in
  test (`Int 42);
  [%expect {| (Json.Invalid_json "Expected object" 42) |}];
  ()
;;

let%expect_test "invalid response" =
  let test json = require_does_raise (fun () -> Fail.rpc.response_encoder.of_json json) in
  test (`Int 42);
  [%expect {| (Json.Invalid_json "Expected object" 42) |}];
  ()
;;

(* @mdexp

   ## Extra fields are ignored

   [Unit] decodes any JSON object, regardless of its fields --- there's
   nothing to check, so nothing gets rejected. *)

let%expect_test "extra fields are ignored" =
  require
    (Fail.Request.equal
       (Fail.rpc.request_encoder.of_json (`Assoc [ "extra", `Int 1 ]))
       ());
  [%expect {||}];
  require
    (Fail.Response.equal
       (Fail.rpc.response_encoder.of_json (`Assoc [ "extra", `Int 1 ]))
       ());
  [%expect {||}];
  ()
;;

(* @mdexp

   ## [equal]

   Both [Unit], so this only checks that [equal] holds on the sole
   value of that type. *)

let%expect_test "equal" =
  require (Fail.Request.equal () ());
  [%expect {||}];
  require (Fail.Response.equal () ());
  [%expect {||}];
  ()
;;
