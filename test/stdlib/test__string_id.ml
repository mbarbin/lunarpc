(*********************************************************************************)
(*  lunarpc - An opinionated, lightweight, HTTP/JSON RPC harness                 *)
(*  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: MIT                                                 *)
(*********************************************************************************)

(* @mdexp

   # String_id

   Unit tests for [String_id.Make], exercised on a small ad hoc id type
   built for this chapter: non-empty, ASCII alphanumeric only. *)

module My_id = String_id.Make (struct
    let module_name = "Test.My_id"
    let invariant s = (not (String.is_empty s)) && String.for_all s ~f:Char.is_alphanum
  end)

(* @mdexp

   ## Example

   [v]/[to_string] round trip a valid value; [equal] follows the
   underlying string. *)

let%expect_test "example" =
  let a = My_id.v "abc123" in
  print_endline (My_id.to_string a);
  [%expect {| abc123 |}];
  print_dyn (My_id.equal a (My_id.v "abc123") |> Dyn.bool);
  [%expect {| true |}];
  print_dyn (My_id.equal a (My_id.v "different") |> Dyn.bool);
  [%expect {| false |}];
  ()
;;

(* @mdexp

   ## [compare]

   Structural, following the underlying string's ordering. *)

let%expect_test "compare" =
  let test a b =
    print_dyn (My_id.compare (My_id.v a) (My_id.v b) |> Ordering.to_int |> Dyn.int)
  in
  test "abc" "abc";
  [%expect {| 0 |}];
  test "abc" "abd";
  [%expect {| -1 |}];
  test "abd" "abc";
  [%expect {| 1 |}];
  ()
;;

(* @mdexp

   ## [of_string]

   [of_string str] returns [Ok str] if the invariant holds, and an error
   otherwise; the error message truncates a long shown value, to keep
   the message from becoming unwieldy. *)

let%expect_test "invalid" =
  let test str =
    match My_id.of_string str with
    | Ok id -> Printf.printf "Ok %s\n" (My_id.to_string id)
    | Error (`Msg m) -> Printf.printf "Error: %s\n" m
  in
  test "abc123";
  [%expect {| Ok abc123 |}];
  test "";
  [%expect {| Error: "": invalid test.My_id |}];
  (* 256 characters, mostly alphanumeric but with a space every 7th
     character --- long enough, and invalid enough, to exercise the
     truncation of the shown value in the error message. *)
  let long_invalid =
    String.init 256 ~f:(fun i ->
      if i mod 7 = 0 then ' ' else "abcdefghijklmnopqrstuvwxyz".[i mod 26])
  in
  test long_invalid;
  [%expect
    {| Error: " bcdefg ijklmn pqrstu wxyzab defghi klmn... (256 characters total)": invalid test.My_id |}];
  ()
;;
