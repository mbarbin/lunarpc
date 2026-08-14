(*_********************************************************************************)
(*_  lunarpc - An opinionated, lightweight, HTTP/JSON RPC harness                 *)
(*_  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*_  SPDX-License-Identifier: MIT                                                 *)
(*_********************************************************************************)

include module type of Stdlib.ArrayLabels

val create : len:int -> 'a -> 'a t
val filter : 'a t -> f:('a -> bool) -> 'a t
val filter_map : 'a t -> f:('a -> 'b option) -> 'b t
val is_empty : 'a t -> bool
val sort : 'a t -> compare:('a -> 'a -> int) -> unit
val sorted_copy : 'a t -> compare:('a -> 'a -> int) -> 'a t
