(*********************************************************************************)
(*  lunarpc - An opinionated, lightweight, HTTP/JSON RPC harness                 *)
(*  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: MIT                                                 *)
(*********************************************************************************)

(* @mdexp

   # Rpc_client: decode failure

   `Rpc_client.call` returns `Error _` rather than raising for a few
   distinct failure modes; two of them --- the HTTP call itself failing,
   and the server responding with a non-2xx status --- are already
   exercised incidentally elsewhere in this book (an unreachable server,
   and [Malformed requests](test__invalid_rpc.md)). This chapter covers
   the third: a well-formed, successful (2xx) response that simply isn't
   the shape the caller asked for --- e.g. a client built against a
   newer or different version of the RPC than the server implements.

   [Mismatched_get] reuses `Get`'s route and request encoder, but decodes
   the response as if it were `Get_owner`'s. Both are legitimate RPC
   specs on their own; pairing them like this is only ever a caller-side
   mistake, which is exactly what this simulates. *)

module Mismatched_get = struct
  module Request = Keyval_rpc.Get.Request
  module Response = Keyval_rpc.Get_owner.Response

  let rpc : (Request.t, Response.t) Rpc.t =
    Rpc.create
      ~name:(Rpc.Name.v "get")
      ~version:2
      ~description:
        "Same route and request as Keyval_rpc.Get, but decoding the response as if it \
         were Keyval_rpc.Get_owner's --- for testing Rpc_client's decode-failure \
         handling."
      ~request_encoder:Keyval_rpc.Get.rpc.request_encoder
      ~response_encoder:Keyval_rpc.Get_owner.rpc.response_encoder
      ()
  ;;
end

let%expect_test "decode failure" =
  let@ t = Rpc_test_harness.run in
  let@ { server; client = _ } =
    Rpc_test_harness.with_server t ~config:Keyval_test.config
  in
  let@ connection = Rpc_test_harness.Server.with_connection server in
  Keyval_client.set
    connection
    ~key:(Keyval.Key.v "foo")
    ~value:(Keyval.Value.v "bar")
    ~owner:(Keyval.Owner.v "test-user");
  (* [get] on an existing key returns [{"value": "bar"}] --- well-formed,
     successful, and simply missing the [owner] field [Get_owner]'s decoder
     requires. *)
  (match Rpc_client.call (module Mismatched_get) ~connection (Keyval.Key.v "foo") with
   | Ok (_ : Mismatched_get.Response.t) -> print_endline "unexpectedly succeeded"
   | Error err -> print_endline (Err.to_string_hum err));
  [%expect
    {|
    ("Decoding response failed."
     (Json.Invalid_json "Missing field: owner" "{ \"value\": \"bar\" }"))
    |}];
  ()
;;
