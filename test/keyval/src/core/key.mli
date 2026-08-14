(*_********************************************************************************)
(*_  lunarpc - An opinionated, lightweight, HTTP/JSON RPC harness                 *)
(*_  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*_  SPDX-License-Identifier: MIT                                                 *)
(*_********************************************************************************)

type t

val compare : t -> t -> Ordering.t
val equal : t -> t -> bool
val hash : t -> int
val to_dyn : t -> Dyn.t
val to_string : t -> string
val of_string : string -> (t, [ `Msg of string ]) Result.t
val v : string -> t
