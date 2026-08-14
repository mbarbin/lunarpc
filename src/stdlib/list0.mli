(*_********************************************************************************)
(*_  lunarpc - An opinionated, lightweight, HTTP/JSON RPC harness                 *)
(*_  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*_  SPDX-License-Identifier: MIT                                                 *)
(*_********************************************************************************)

include module type of Stdlib.ListLabels

val dedup_and_sort : 'a list -> compare:('a -> 'a -> int) -> 'a list
val equal : eq:('a -> 'a -> bool) -> 'a list -> 'a list -> bool
val filter_opt : 'a option list -> 'a list
val hd_exn : 'a list -> 'a
val map : 'a list -> f:('a -> 'b) -> 'b list
