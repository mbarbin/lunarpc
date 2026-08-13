(*********************************************************************************)
(*  lunarpc - An opinionated, lightweight, HTTP/JSON RPC harness                 *)
(*  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: MIT                                                 *)
(*********************************************************************************)

type t = string

let equal = String.equal
let to_dyn = Dyn.string
let to_string t = t
let of_string t = t

(* [Value.of_string] can't actually fail (there's no invariant to check), so
   [v] never raises; it exists for parity with [Key.v]/[Owner.v]. *)
let v = of_string
