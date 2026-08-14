(*_********************************************************************************)
(*_  lunarpc - An opinionated, lightweight, HTTP/JSON RPC harness                 *)
(*_  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*_  SPDX-License-Identifier: MIT                                                 *)
(*_********************************************************************************)

(** Name of the application a service belongs to (e.g. ["keyval"]). Forms the
    top-level [.<app_name>] directory under the discovery root.

    Values are ASCII strings used as path components, with the invariant:

    - Non-empty, at most 64 characters.
    - Each character is ASCII alphanumeric, ['-'], or ['_'].

    This excludes path separators, ['.'], and whitespace, so values can be
    safely embedded into directory and file names without escaping. *)

type t (** @canonical Lunarpc_discovery.Rpc_discovery.App_name.t *)

val v : string -> t
val of_string : string -> (t, [ `Msg of string ]) result
val to_string : t -> string
val equal : t -> t -> bool
val compare : t -> t -> Ordering.t
val to_dyn : t -> Dyn.t
