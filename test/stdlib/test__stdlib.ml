(*********************************************************************************)
(*  lunarpc - An opinionated, lightweight, HTTP/JSON RPC harness                 *)
(*  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: MIT                                                 *)
(*********************************************************************************)

(* @mdexp

   # Stdlib

   Unit tests for a couple of [Lunarpc_stdlib]'s expect-test helpers:
   [phys_equal] and [require_equal]. *)

(* @mdexp

   ## [phys_equal]

   [phys_equal a b] is physical equality ([a == b]): two structurally
   equal but distinct values are not [phys_equal]. *)

let%expect_test "phys_equal" =
  let hello () = "Hello" ^ " World" in
  let h1 = hello () in
  print_dyn (phys_equal h1 h1 |> Dyn.bool);
  [%expect {| true |}];
  print_dyn (phys_equal h1 (hello ()) |> Dyn.bool);
  [%expect {| false |}];
  ()
;;

(* @mdexp

   ## [require_equal]

   [require_equal (module M) v1 v2] raises if [v1] and [v2] are not equal
   per [M.equal]; [require_not_equal] is the mirror image. Both failures
   are demonstrated here via [require_does_raise], which also shows what
   the raised [Code_error] looks like. *)

let%expect_test "require_equal" =
  require_equal (module Int) 1 1;
  [%expect {||}];
  require_not_equal (module Int) 1 2;
  [%expect {||}];
  require_does_raise (fun () -> require_equal (module Int) 1 2);
  [%expect {| ("(\"Values are not equal.\", { v1 = 1; v2 = 2 })") |}];
  require_does_raise (fun () -> require_not_equal (module Int) 1 1);
  [%expect {| ("(\"Values are equal.\", { v1 = 1; v2 = 1 })") |}];
  ()
;;
