(*_********************************************************************************)
(*_  lunarpc - An opinionated, lightweight, HTTP/JSON RPC harness                 *)
(*_  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*_  SPDX-License-Identifier: MIT                                                 *)
(*_********************************************************************************)

(** Validated string identifiers with structural identity.

    [Validated_string] gives us [to_string]/[of_string]/[v]; many call
    sites additionally need [equal]/[compare]/[hash]/[to_dyn] on the id
    type (set/map keys, conflict provenance, DAG traversal, test
    diagnostics). This functor layers those on without modifying the
    shared [Validated_string]. The caller supplies the [invariant] (via
    {!X}), so this is suitable for any validated-string id. *)

module type S = sig
  type t

  val to_string : t -> string
  val of_string : string -> (t, [ `Msg of string ]) Result.t
  val v : string -> t
  val equal : t -> t -> bool
  val compare : t -> t -> Ordering.t
  val hash : t -> int
  val to_dyn : t -> Dyn.t
end

module type X = sig
  (** The module name is used for error messages only. *)
  val module_name : string

  (** This is the validation function that should be run on the untrusted input
      string. Return [true] on valid input.

      By construction, [invariant t = true] is an invariant of any value of
      type [t], since it is verified during [of_string _]. *)
  val invariant : string -> bool
end

module Make (_ : X) : S with type t = string
