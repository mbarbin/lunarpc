(*_********************************************************************************)
(*_  lunarpc - An opinionated, lightweight, HTTP/JSON RPC harness                 *)
(*_  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*_  SPDX-License-Identifier: MIT                                                 *)
(*_********************************************************************************)

module Request : sig
  type t = Keyval.Key.t

  val equal : t -> t -> bool
end

module Response : sig
  type t = Keyval.Value.t option

  val equal : t -> t -> bool
end

include Rpc.S with module Request := Request and module Response := Response
