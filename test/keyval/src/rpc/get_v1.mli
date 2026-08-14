(*_********************************************************************************)
(*_  lunarpc - An opinionated, lightweight, HTTP/JSON RPC harness                 *)
(*_  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*_  SPDX-License-Identifier: MIT                                                 *)
(*_********************************************************************************)

(** The original ["get"] RPC (version 1): raises on a missing key rather than
    returning an optional value. Kept around, alongside {!Get} (version 2),
    to demonstrate that versions of the same RPC are independent handlers
    the server can register side by side.

    Deprecated: superseded by {!Get}, which returns [null] for a missing key
    instead of failing, so callers can tell "absent" apart from "the server
    broke." *)

module Request : sig
  type t = Keyval.Key.t

  val equal : t -> t -> bool
end

module Response : sig
  type t = Keyval.Value.t

  val equal : t -> t -> bool
end

include Rpc.S with module Request := Request and module Response := Response
