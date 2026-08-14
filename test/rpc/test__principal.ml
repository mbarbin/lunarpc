(*********************************************************************************)
(*  lunarpc - An opinionated, lightweight, HTTP/JSON RPC harness                 *)
(*  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: MIT                                                 *)
(*********************************************************************************)

(* @mdexp

   # Principal

   Unit tests for [Rpc.Principal]'s validation: non-empty, at most 64
   characters, ASCII alphanumeric, ['-'], or ['_'] --- so, notably, no
   whitespace. *)

(* @mdexp

   ## [of_string]

   [of_string str] returns [Ok str] if the invariant holds, and an error
   otherwise. This is meant to be used to validate untrusted entries. *)

let%expect_test "invalid" =
  let test str =
    match Rpc.Principal.of_string str with
    | Ok principal -> Printf.printf "Ok %s\n" (Rpc.Principal.to_string principal)
    | Error (`Msg m) -> Printf.printf "Error: %s\n" m
  in
  test "alice";
  [%expect {| Ok alice |}];
  test "service-account_42";
  [%expect {| Ok service-account_42 |}];
  (* Empty. *)
  test "";
  [%expect {| Error: "": invalid rpc.Principal |}];
  (* Whitespace is explicitly disallowed. *)
  test "alice smith";
  [%expect {| Error: "alice smith": invalid rpc.Principal |}];
  (* '@' and '.', typical of an email address, are not alphanumeric/'-'/'_'. *)
  test "alice@example.com";
  [%expect {| Error: "alice@example.com": invalid rpc.Principal |}];
  (* Exactly the length limit is fine; one over is not. *)
  test (String.make 64 'a');
  [%expect {| Ok aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa |}];
  test (String.make 65 'a');
  [%expect
    {| Error: "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa... (65 characters total)": invalid rpc.Principal |}];
  ()
;;

(* @mdexp

   ## [v]

   [v str] is a convenient wrapper to build a [t] or raise
   [Invalid_argument]. This is typically handy for applying on trusted
   literals --- on an invalid one, it raises rather than returning a
   [result] to handle. *)

let%expect_test "v raises on an invalid principal" =
  require_does_raise (fun () -> Rpc.Principal.v "alice smith");
  [%expect {| (Invalid_argument "\"alice smith\": invalid rpc.Principal") |}];
  ()
;;
