(*_********************************************************************************)
(*_  lunarpc - An opinionated, lightweight, HTTP/JSON RPC harness                 *)
(*_  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*_  SPDX-License-Identifier: MIT                                                 *)
(*_********************************************************************************)

(** Retrieve the owner that most recently [set] a key's binding, per
    {!Lunarpc.Rpc.Call.principal}. Every binding has an owner (the server
    requires one on [set]), so [No_such_key] unambiguously means the key
    doesn't exist. *)

module Request : sig
  type t = Keyval.Key.t

  val equal : t -> t -> bool
end

module Response : sig
  type t =
    | Some of { owner : Keyval.Owner.t }
    | No_such_key

  val equal : t -> t -> bool
end

include Rpc.S with module Request := Request and module Response := Response
