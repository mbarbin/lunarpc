(*_********************************************************************************)
(*_  lunarpc - An opinionated, lightweight, HTTP/JSON RPC harness                 *)
(*_  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*_  SPDX-License-Identifier: MIT                                                 *)
(*_********************************************************************************)

(** An RPC whose request decoder always raises, regardless of the JSON it is
    given. Exists to exercise the server's handling of a well-formed request
    that fails to decode due to a bug in the RPC's own encoder --- as opposed
    to a malformed request from the caller. Both surface identically: a
    [400] "could not decode json". Deliberately excluded from the RPC
    roundtrip quickcheck tests, since decoding always fails by design. *)

module Request : sig
  type t = unit

  val equal : t -> t -> bool
end

module Response : sig
  type t = unit

  val equal : t -> t -> bool
end

include Rpc.S with module Request := Request and module Response := Response
