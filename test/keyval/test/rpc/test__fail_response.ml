(*********************************************************************************)
(*  lunarpc - An opinionated, lightweight, HTTP/JSON RPC harness                 *)
(*  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: MIT                                                 *)
(*********************************************************************************)

(* @mdexp

   # RPC roundtrip: Fail response

   `Keyval_rpc.Fail_response`'s response encoder always raises (see
   [Malformed requests](../test__invalid_rpc.md) for how that surfaces
   through the server); its *decoder* is unaffected, so it still rejects
   malformed json the same way any other `Unit` response would. *)

let%expect_test "invalid request" =
  let test json =
    require_does_raise (fun () ->
      Keyval_rpc.Fail_response.rpc.request_encoder.of_json json)
  in
  test (`Int 42);
  [%expect {| (Json.Invalid_json "Expected object" 42) |}];
  ()
;;

let%expect_test "invalid response" =
  let test json =
    require_does_raise (fun () ->
      Keyval_rpc.Fail_response.rpc.response_encoder.of_json json)
  in
  test (`Int 42);
  [%expect {| (Json.Invalid_json "Expected object" 42) |}];
  ()
;;

let%expect_test "extra fields are ignored" =
  require
    (Keyval_rpc.Fail_response.Request.equal
       (Keyval_rpc.Fail_response.rpc.request_encoder.of_json (`Assoc [ "extra", `Int 1 ]))
       ());
  [%expect {||}];
  require
    (Keyval_rpc.Fail_response.Response.equal
       (Keyval_rpc.Fail_response.rpc.response_encoder.of_json
          (`Assoc [ "extra", `Int 1 ]))
       ());
  [%expect {||}];
  ()
;;

(* @mdexp

   ## [equal]

   Both [Unit], so this only checks that [equal] holds on the sole
   value of that type. *)

let%expect_test "equal" =
  require (Keyval_rpc.Fail_response.Request.equal () ());
  [%expect {||}];
  require (Keyval_rpc.Fail_response.Response.equal () ());
  [%expect {||}];
  ()
;;
