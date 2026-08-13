(*********************************************************************************)
(*  lunarpc - An opinionated, lightweight, HTTP/JSON RPC harness                 *)
(*  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: MIT                                                 *)
(*********************************************************************************)

(* @mdexp

   # RPC roundtrip: Set

   Same roundtrip check as for [Get](test__get.md), applied to the
   `Set` RPC. No explicit examples are supplied here, so only the
   generated random requests and responses are checked. *)

module Set_ = struct
  module Request = struct
    include Keyval_rpc.Set_.Request

    let generator =
      let open Generator.Syntax in
      let+ key = Keyval_generators.Key.generator
      and+ value = Keyval_generators.Value.generator in
      { key; value }
    ;;
  end

  module Response = struct
    include Keyval_rpc.Set_.Response

    let generator = Generator.return ()
  end

  let rpc = Keyval_rpc.Set_.rpc
end

let%expect_test "roundtrip" =
  Rpc_quickcheck.run_exn (module Set_);
  [%expect {||}];
  ()
;;

(* @mdexp

   ## Invalid json

   The decoders iterate over whatever fields are present rather than
   matching a fixed shape, so only a genuinely missing or mistyped
   field is rejected --- see [Extra fields are ignored](#extra-fields-are-ignored)
   below for what that buys. *)

let%expect_test "invalid request" =
  let test json = require_does_raise (fun () -> Set_.rpc.request_encoder.of_json json) in
  test (`Int 42);
  [%expect {| (Json.Invalid_json "Expected object" 42) |}];
  test (`Assoc [ "key", `String "foo" ]);
  [%expect {| (Json.Invalid_json "Missing field: value" "{ \"key\": \"foo\" }") |}];
  test (`Assoc [ "key", `Int 1; "value", `String "bar" ]);
  [%expect {| (Json.Invalid_json "Expected string for key" 1) |}];
  test (`Assoc [ "key", `String ""; "value", `String "bar" ]);
  [%expect {| (Invalid_argument "\"\": invalid key") |}];
  ()
;;

let%expect_test "invalid response" =
  let test json = require_does_raise (fun () -> Set_.rpc.response_encoder.of_json json) in
  test (`Int 42);
  [%expect {| (Json.Invalid_json "Expected object" 42) |}];
  ()
;;

(* @mdexp

   ## Extra fields are ignored

   Fields the decoder doesn't recognize are silently skipped rather
   than rejected, same as an unknown key in a real client's payload
   (e.g. a newer client talking to an older server) should be. The
   request also isn't sensitive to field order --- [key]/[value] decode
   the same regardless of which comes first. *)

let%expect_test "extra fields are ignored" =
  require
    (Set_.Request.equal
       (Set_.rpc.request_encoder.of_json
          (`Assoc [ "key", `String "foo"; "value", `String "bar"; "extra", `Int 1 ]))
       { key = Keyval.Key.v "foo"; value = Keyval.Value.v "bar" });
  [%expect {||}];
  (* Reordered, with the extra field in between. *)
  require
    (Set_.Request.equal
       (Set_.rpc.request_encoder.of_json
          (`Assoc [ "value", `String "bar"; "extra", `Int 1; "key", `String "foo" ]))
       { key = Keyval.Key.v "foo"; value = Keyval.Value.v "bar" });
  [%expect {||}];
  require
    (Set_.Response.equal
       (Set_.rpc.response_encoder.of_json (`Assoc [ "extra", `Int 1 ]))
       ());
  [%expect {||}];
  ()
;;

(* @mdexp

   ## [equal]

   Sanity-checks that [equal] actually discriminates values, rather than
   e.g. always returning [true] --- in particular, that it does compare
   both fields of the request record, not just one. *)

let%expect_test "equal" =
  let a : Set_.Request.t = { key = Keyval.Key.v "foo"; value = Keyval.Value.v "x" } in
  require (Set_.Request.equal a a);
  [%expect {||}];
  require (not (Set_.Request.equal a { a with key = Keyval.Key.v "bar" }));
  [%expect {||}];
  require (not (Set_.Request.equal a { a with value = Keyval.Value.v "y" }));
  [%expect {||}];
  require (Set_.Response.equal () ());
  [%expect {||}];
  ()
;;
