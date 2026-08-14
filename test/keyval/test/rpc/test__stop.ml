(*********************************************************************************)
(*  lunarpc - An opinionated, lightweight, HTTP/JSON RPC harness                 *)
(*  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: MIT                                                 *)
(*********************************************************************************)

(* @mdexp

   # RPC roundtrip: Stop

   `Keyval_rpc.Stop`'s request and response are both `Unit` (an empty
   object): there is no valid payload to round trip beyond that, so unlike
   its siblings in this directory, this chapter only covers the decoders'
   error paths --- see [Stopping the server](../test__stop.md) for the
   actual effect of this RPC. *)

let%expect_test "invalid request" =
  let test json =
    require_does_raise (fun () -> Keyval_rpc.Stop.rpc.request_encoder.of_json json)
  in
  test (`Int 42);
  [%expect {| (Json.Invalid_json "Expected object" 42) |}];
  ()
;;

let%expect_test "invalid response" =
  let test json =
    require_does_raise (fun () -> Keyval_rpc.Stop.rpc.response_encoder.of_json json)
  in
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
    (Keyval_rpc.Stop.Request.equal
       (Keyval_rpc.Stop.rpc.request_encoder.of_json (`Assoc [ "extra", `Int 1 ]))
       ());
  [%expect {||}];
  require
    (Keyval_rpc.Stop.Response.equal
       (Keyval_rpc.Stop.rpc.response_encoder.of_json (`Assoc [ "extra", `Int 1 ]))
       ());
  [%expect {||}];
  ()
;;

(* @mdexp

   ## [equal]

   Both [Unit], so this only checks that [equal] holds on the sole
   value of that type. *)

let%expect_test "equal" =
  require (Keyval_rpc.Stop.Request.equal () ());
  [%expect {||}];
  require (Keyval_rpc.Stop.Response.equal () ());
  [%expect {||}];
  ()
;;
