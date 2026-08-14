(*_********************************************************************************)
(*_  lunarpc - An opinionated, lightweight, HTTP/JSON RPC harness                 *)
(*_  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*_  SPDX-License-Identifier: MIT                                                 *)
(*_********************************************************************************)

(** The identity of the caller making an RPC request (e.g. a username or
    service account id), carried by {!Call.t}.

    Non-empty, at most 64 characters, ASCII alphanumeric, ['-'], or ['_']
    (so, notably, no whitespace) — safe to embed as an HTTP header value
    without escaping. *)

type t (** @canonical Lunarpc.Rpc.Principal.t *)

(** Given that [t = string] in the implementation, this function is just the
    identity. *)
val to_string : t -> string

(** [of_string str] returns [Ok str] if the invariant holds, and an error
    otherwise. This is meant to be used to validate untrusted entries. *)
val of_string : string -> (t, [ `Msg of string ]) Result.t

(** [v str] is a convenient wrapper to build a [t] or raise
    [Invalid_argument]. This is typically handy for applying on trusted
    literals. *)
val v : string -> t

val equal : t -> t -> bool
val compare : t -> t -> Ordering.t
val hash : t -> int
val to_dyn : t -> Dyn.t
