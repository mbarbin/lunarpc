(*_********************************************************************************)
(*_  lunarpc - An opinionated, lightweight, HTTP/JSON RPC harness                 *)
(*_  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*_  SPDX-License-Identifier: MIT                                                 *)
(*_********************************************************************************)

include module type of Stdlib.StringLabels

val equal : t -> t -> bool
val hash : t -> int
val is_empty : t -> bool
val is_prefix : t -> prefix:string -> bool
val lsplit2 : t -> on:char -> (t * t) option
val rsplit2 : t -> on:char -> (t * t) option
val rstrip : ?drop:(char -> bool) -> t -> t
val split_lines : t -> t list
val to_string : t -> t
