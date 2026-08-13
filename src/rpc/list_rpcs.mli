(*_********************************************************************************)
(*_  lunarpc - An opinionated, lightweight, HTTP/JSON RPC harness                 *)
(*_  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*_  SPDX-License-Identifier: MIT                                                 *)
(*_********************************************************************************)

(** The introspective [listRpcs] RPC. Returns metadata about every RPC
    available on the server (including this one). *)

module Request : sig
  module Names : sig
    type t =
      | All
      | Only of { names : Name.t list }

    val equal : t -> t -> bool
  end

  type t =
    { include_schemas : bool
    ; names : Names.t
    }

  val equal : t -> t -> bool

  include Encoder.S with type t := t
end

module Response : sig
  (** @canonical Lunarpc.Rpc.List_rpcs.Response.t *)
  type t = { rpcs : Info.t list }

  val equal : t -> t -> bool

  include Encoder.S with type t := t
end

include Rpc0.S with module Request := Request and module Response := Response
