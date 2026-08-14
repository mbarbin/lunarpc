(*********************************************************************************)
(*  lunarpc - An opinionated, lightweight, HTTP/JSON RPC harness                 *)
(*  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: MIT                                                 *)
(*********************************************************************************)

type t = exn

let sexp_of_t = Sexplib0.Sexp_conv.sexp_of_exn
let to_string = Printexc.to_string
let protect = Fun0.protect
