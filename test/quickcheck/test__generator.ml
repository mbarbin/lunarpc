(*********************************************************************************)
(*  lunarpc - An opinionated, lightweight, HTTP/JSON RPC harness                 *)
(*  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: MIT                                                 *)
(*********************************************************************************)

(* @mdexp

   # Checking an invariant on a custom generator

   [Generator.create] and [Generator.Syntax.( let* )] are the two
   primitives needed to build a generator from scratch: [create] turns
   the current size parameter into a (deterministic) value, and [let*]
   chains it into further, genuinely random generators. Here they build
   [Range.t], a [{ lo; hi }] pair that is an interval by construction:
   [hi] is [lo] plus a non-negative offset, so [lo <= hi] should always
   hold, however [Range.t] values are generated.
   [Rpc_quickcheck.Private.test_run] then checks that invariant against
   many random samples. *)

module Range = struct
  type t =
    { lo : int
    ; hi : int
    }

  let to_dyn { lo; hi } = Dyn.record [ "lo", Dyn.int lo; "hi", Dyn.int hi ]

  (* [bound] grows with the generator's size parameter (via [create]), so
     [lo] is drawn from a wider spread on larger runs; [offset] is a
     genuinely random, always non-negative generator, chained in via
     [let*], so [hi = lo + offset] can never fall below [lo]. *)
  let generator =
    let open Generator.Syntax in
    let* bound = Generator.create (fun ~size -> size) in
    let* lo = Generator.int_uniform_inclusive (-bound) bound in
    let* offset = Generator.int_uniform_inclusive 0 bound in
    Generator.return { lo; hi = lo + offset }
  ;;
end

let%expect_test "invariant: lo <= hi" =
  Rpc_quickcheck.Private.test_run
    (module Range)
    ~f:(fun { Range.lo; hi } -> require (lo <= hi));
  [%expect {||}];
  ()
;;
