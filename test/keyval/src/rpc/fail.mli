(*_********************************************************************************)
(*_  lunarpc - An opinionated, lightweight, HTTP/JSON RPC harness                 *)
(*_  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*_  SPDX-License-Identifier: MIT                                                 *)
(*_********************************************************************************)

(** An RPC whose handler always raises. Exists to exercise the server's
    handling of unexpected handler failures ([Internal] errors) --- there is
    no other RPC in this example whose handler can fail. *)

module Request : sig
  type t = unit

  val equal : t -> t -> bool
end

module Response : sig
  type t = unit

  val equal : t -> t -> bool
end

include Rpc.S with module Request := Request and module Response := Response
