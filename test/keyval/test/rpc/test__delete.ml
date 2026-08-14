(*********************************************************************************)
(*  lunarpc - An opinionated, lightweight, HTTP/JSON RPC harness                 *)
(*  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: MIT                                                 *)
(*********************************************************************************)

(* @mdexp

   # RPC roundtrip: Delete

   Same roundtrip check as for [Get](test__get.md), applied to the
   `Delete` RPC. *)

module Delete = struct
  module Request = struct
    include Keyval_rpc.Delete.Request

    let generator = Keyval_generators.Key.generator
  end

  module Response = struct
    include Keyval_rpc.Delete.Response

    let generator =
      Generator.union [ Generator.return Deleted; Generator.return No_such_key ]
    ;;
  end

  let rpc = Keyval_rpc.Delete.rpc
end

let%expect_test "roundtrip" =
  (* @mdexp There used to be a bug in the deserialization of `Unit`; the
     explicit `~requests` below regression-test it. *)
  Rpc_quickcheck.run_exn
    (module Delete)
    ~requests:[ Keyval.Key.v "foo"; Keyval.Key.v "bar" ]
    ~responses:[];
  [%expect {||}];
  ()
;;

(* @mdexp

   ## Invalid json

   The response is a bare string constructor: anything other than exactly
   ["Deleted"] or ["No_such_key"] --- including a case mismatch --- is
   rejected. *)

let%expect_test "invalid request" =
  let test json =
    require_does_raise (fun () -> Delete.rpc.request_encoder.of_json json)
  in
  test (`Int 42);
  [%expect {| (Json.Invalid_json "Expected object" 42) |}];
  test (`Assoc [ "key", `String "" ]);
  [%expect {| (Invalid_argument "\"\": invalid key") |}];
  ()
;;

let%expect_test "invalid response" =
  let test json =
    require_does_raise (fun () -> Delete.rpc.response_encoder.of_json json)
  in
  test (`Int 42);
  [%expect {| (Json.Invalid_json "Expected a single string constructor" 42) |}];
  test (`String "deleted");
  [%expect {| (Json.Invalid_json "Expected a single string constructor" "\"deleted\"") |}];
  test (`String "Not_a_constructor");
  [%expect
    {|
    (Json.Invalid_json "Expected a single string constructor"
     "\"Not_a_constructor\"")
    |}];
  ()
;;

(* @mdexp

   ## Extra fields are ignored

   Only the request has fields to speak of --- the response is a bare
   string constructor, with nothing to be lenient about. *)

let%expect_test "extra fields are ignored" =
  require
    (Delete.Request.equal
       (Delete.rpc.request_encoder.of_json
          (`Assoc [ "key", `String "foo"; "extra", `Int 1 ]))
       (Keyval.Key.v "foo"));
  [%expect {||}];
  ()
;;

(* @mdexp

   ## [equal]

   Sanity-checks that [equal] actually discriminates values, rather than
   e.g. always returning [true]. *)

let%expect_test "equal" =
  require (Delete.Request.equal (Keyval.Key.v "foo") (Keyval.Key.v "foo"));
  [%expect {||}];
  require (not (Delete.Request.equal (Keyval.Key.v "foo") (Keyval.Key.v "bar")));
  [%expect {||}];
  require (Delete.Response.equal Deleted Deleted);
  [%expect {||}];
  require (Delete.Response.equal No_such_key No_such_key);
  [%expect {||}];
  require (not (Delete.Response.equal Deleted No_such_key));
  [%expect {||}];
  ()
;;
