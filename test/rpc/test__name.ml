(*********************************************************************************)
(*  lunarpc - An opinionated, lightweight, HTTP/JSON RPC harness                 *)
(*  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: MIT                                                 *)
(*********************************************************************************)

(* @mdexp

   # Name

   Unit tests for [Rpc.Name]'s validation: the first character must be a
   lowercase ASCII letter, the rest ASCII alphanumeric, and the total
   length between 1 and 64 characters. *)

(* @mdexp

   ## [of_string]

   [of_string str] returns [Ok str] if the invariant holds, and an error
   otherwise. This is meant to be used to validate untrusted entries. *)

let%expect_test "invalid" =
  let test str =
    match Rpc.Name.of_string str with
    | Ok name -> Printf.printf "Ok %s\n" (Rpc.Name.to_string name)
    | Error (`Msg m) -> Printf.printf "Error: %s\n" m
  in
  test "ping";
  [%expect {| Ok ping |}];
  (* Leading uppercase. *)
  test "Ping";
  [%expect {| Error: "Ping": invalid rpc.Name |}];
  (* Underscore is not alphanumeric. *)
  test "list_rpcs";
  [%expect {| Error: "list_rpcs": invalid rpc.Name |}];
  (* Empty. *)
  test "";
  [%expect {| Error: "": invalid rpc.Name |}];
  (* Leading digit. *)
  test "1abc";
  [%expect {| Error: "1abc": invalid rpc.Name |}];
  (* Whitespace. *)
  test "list rpcs";
  [%expect {| Error: "list rpcs": invalid rpc.Name |}];
  (* Exactly the length limit is fine; one over is not. *)
  test (String.make 64 'a');
  [%expect {| Ok aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa |}];
  test (String.make 65 'a');
  [%expect
    {| Error: "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa... (65 characters total)": invalid rpc.Name |}];
  ()
;;

(* @mdexp

   ## [v]

   [v str] is a convenient wrapper to build a [t] or raise
   [Invalid_argument]. This is typically handy for applying on trusted
   literals --- on an invalid one, it raises rather than returning a
   [result] to handle. *)

let%expect_test "v raises on an invalid name" =
  require_does_raise (fun () -> Rpc.Name.v "Ping");
  [%expect {| (Invalid_argument "\"Ping\": invalid rpc.Name") |}];
  ()
;;
