(*_********************************************************************************)
(*_  lunarpc - An opinionated, lightweight, HTTP/JSON RPC harness                 *)
(*_  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*_  SPDX-License-Identifier: MIT                                                 *)
(*_********************************************************************************)

(** The identity of the caller that last [set] a binding, per
    [Keyval_rpc.Get_owner]. Non-empty, ASCII alphanumeric, ['-'], or ['_']
    (so, notably, no whitespace). *)

type t

val equal : t -> t -> bool
val hash : t -> int
val to_dyn : t -> Dyn.t
val to_string : t -> string
val of_string : string -> (t, [ `Msg of string ]) Result.t
val v : string -> t
