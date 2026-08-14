(*_********************************************************************************)
(*_  lunarpc - An opinionated, lightweight, HTTP/JSON RPC harness                 *)
(*_  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*_  SPDX-License-Identifier: MIT                                                 *)
(*_********************************************************************************)

(** An RPC whose response encoder always raises, regardless of the handler's
    result --- the handler itself succeeds. Exists to exercise the server's
    handling of a response encoder bug, a failure mode distinct from a
    handler exception ([Fail]'s case): it happens after the handler has
    already returned, while turning its result into JSON. Deliberately
    excluded from the RPC roundtrip quickcheck tests, since encoding always
    fails by design. *)

module Request : sig
  type t = unit

  val equal : t -> t -> bool
end

module Response : sig
  type t = unit

  val equal : t -> t -> bool
end

include Rpc.S with module Request := Request and module Response := Response
