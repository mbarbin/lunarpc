(*_********************************************************************************)
(*_  lunarpc - An opinionated, lightweight, HTTP/JSON RPC harness                 *)
(*_  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*_  SPDX-License-Identifier: MIT                                                 *)
(*_********************************************************************************)

type t = exn

val sexp_of_t : t -> Sexplib0.Sexp.t
val to_string : exn -> string
val protect : f:(unit -> 'a) -> finally:(unit -> unit) -> 'a
