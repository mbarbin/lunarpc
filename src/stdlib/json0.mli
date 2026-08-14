(*_********************************************************************************)
(*_  lunarpc - An opinionated, lightweight, HTTP/JSON RPC harness                 *)
(*_  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*_  SPDX-License-Identifier: MIT                                                 *)
(*_********************************************************************************)

type t = Yojson.Basic.t

val equal : t -> t -> bool
val to_dyn : t -> Dyn.t

(** An exception raised by deserializers when they can't parse an input
    according to its expected structure. *)
exception Invalid_json of t * string
