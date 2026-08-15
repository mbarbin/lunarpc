(*_********************************************************************************)
(*_  lunarpc - An opinionated, lightweight, HTTP/JSON RPC harness                 *)
(*_  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*_  SPDX-License-Identifier: MIT                                                 *)
(*_********************************************************************************)

(** Running property-based tests. *)

module type S = sig
  type t

  val generator : t Generator.t
  val to_dyn : t -> Dyn.t
end

(** [run (module M) ~f] runs [f] on a sequence of randomly generated values of
    type [M.t]. If [f] raises on any input the exception is propagated; the
    offending value can be inspected through [M.to_dyn] when the test runner
    reports the failure.

    [examples] is an optional list of inputs to test first, before the random
    inputs. *)
val run : ?examples:'a list -> (module S with type t = 'a) -> f:('a -> unit) -> unit
