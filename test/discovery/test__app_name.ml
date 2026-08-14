(*********************************************************************************)
(*  lunarpc - An opinionated, lightweight, HTTP/JSON RPC harness                 *)
(*  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: MIT                                                 *)
(*********************************************************************************)

(* @mdexp

   # App_name

   Unit tests for [Rpc_discovery.App_name]'s validation: non-empty, at
   most 64 characters, ASCII alphanumeric, ['-'], or ['_'] (so, notably,
   no path separators, ['.'], or whitespace). *)

(* @mdexp

   ## [of_string]

   [of_string str] returns [Ok str] if the invariant holds, and an error
   otherwise. *)

let%expect_test "invalid" =
  let test str =
    match Rpc_discovery.App_name.of_string str with
    | Ok app_name -> Printf.printf "Ok %s\n" (Rpc_discovery.App_name.to_string app_name)
    | Error (`Msg m) -> Printf.printf "Error: %s\n" m
  in
  test "cr";
  [%expect {| Ok cr |}];
  test "my-app_42";
  [%expect {| Ok my-app_42 |}];
  (* Empty. *)
  test "";
  [%expect {| Error: "": invalid Rpc_discovery.App_name |}];
  (* Path separator and extension dot are explicitly disallowed. *)
  test "cr/app";
  [%expect {| Error: "cr/app": invalid Rpc_discovery.App_name |}];
  test "cr.app";
  [%expect {| Error: "cr.app": invalid Rpc_discovery.App_name |}];
  test "cr app";
  [%expect {| Error: "cr app": invalid Rpc_discovery.App_name |}];
  (* Exactly the length limit is fine; one over is not. *)
  test (String.make 64 'a');
  [%expect {| Ok aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa |}];
  test (String.make 65 'a');
  [%expect
    {| Error: "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa... (65 characters total)": invalid Rpc_discovery.App_name |}];
  ()
;;

(* @mdexp

   ## [v]

   [v str] is a convenient wrapper to build a [t] or raise
   [Invalid_argument] --- on an invalid one, it raises rather than
   returning a [result] to handle. *)

let%expect_test "v raises on an invalid app_name" =
  require_does_raise (fun () -> Rpc_discovery.App_name.v "cr/app");
  [%expect {| (Invalid_argument "\"cr/app\": invalid Rpc_discovery.App_name") |}];
  ()
;;
