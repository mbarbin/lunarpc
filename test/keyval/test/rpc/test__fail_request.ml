(*********************************************************************************)
(*  lunarpc - An opinionated, lightweight, HTTP/JSON RPC harness                 *)
(*  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: MIT                                                 *)
(*********************************************************************************)

(* @mdexp

   # RPC roundtrip: Fail request

   `Keyval_rpc.Fail_request`'s request decoder always raises, regardless of
   its input --- even a well-formed empty object, the one payload that
   would otherwise be valid for a `Unit` request. See
   [Malformed requests](../test__invalid_rpc.md) for how this surfaces
   through the server. *)

let%expect_test "invalid request" =
  let test json =
    require_does_raise (fun () ->
      Keyval_rpc.Fail_request.rpc.request_encoder.of_json json)
  in
  test (`Assoc []);
  [%expect {| (Failure "Deliberate request decode failure, for testing.") |}];
  test (`Int 42);
  [%expect {| (Failure "Deliberate request decode failure, for testing.") |}];
  ()
;;

let%expect_test "invalid response" =
  let test json =
    require_does_raise (fun () ->
      Keyval_rpc.Fail_request.rpc.response_encoder.of_json json)
  in
  test (`Int 42);
  [%expect {| (Json.Invalid_json "Expected object" 42) |}];
  ()
;;

let%expect_test "response: extra fields are ignored" =
  require
    (Keyval_rpc.Fail_request.Response.equal
       (Keyval_rpc.Fail_request.rpc.response_encoder.of_json (`Assoc [ "extra", `Int 1 ]))
       ());
  [%expect {||}];
  ()
;;

(* @mdexp

   ## [equal]

   Both [Unit], so this only checks that [equal] holds on the sole
   value of that type. *)

let%expect_test "equal" =
  require (Keyval_rpc.Fail_request.Request.equal () ());
  [%expect {||}];
  require (Keyval_rpc.Fail_request.Response.equal () ());
  [%expect {||}];
  ()
;;
