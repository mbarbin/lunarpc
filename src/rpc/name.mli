(*_********************************************************************************)
(*_  lunarpc - An opinionated, lightweight, HTTP/JSON RPC harness                 *)
(*_  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*_  SPDX-License-Identifier: MIT                                                 *)
(*_********************************************************************************)

(** The name of an RPC.

    Names follow a strict camelCase identifier shape so they can be embedded
    as-is into URL routes and JSON wire payloads:

    - The first character must be a lowercase ASCII letter ([a..z]).
    - Remaining characters must be ASCII alphanumeric ([a..z], [A..Z],
      [0..9]).
    - The total length must be between 1 and 64 characters (inclusive).

    Examples of valid names: ["ping"], ["listRpcs"], ["createBranch"].
    Examples of invalid names: ["Ping"] (leading uppercase), ["list_rpcs"]
    (underscore), [""] (empty). *)

type t (** @canonical Lunarpc.Rpc.Name.t *)

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
