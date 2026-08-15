(*_********************************************************************************)
(*_  lunarpc - An opinionated, lightweight, HTTP/JSON RPC harness                 *)
(*_  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*_  SPDX-License-Identifier: MIT                                                 *)
(*_********************************************************************************)

module Connection : sig
  type t = Rpc_client.Connection.t
end

val with_connection : port:int -> (Connection.t -> 'a) -> 'a
val get : Connection.t -> key:Keyval.Key.t -> Keyval.Value.t option

(** Calls the deprecated v1 of ["get"], which raises if the key doesn't
    exist instead of returning [None]. Kept to demonstrate that RPC
    versions are independent handlers; prefer {!get}. *)
val get_deprecated : Connection.t -> key:Keyval.Key.t -> Keyval.Value.t
[@@deprecated
  "[since 2026-08] Use [get] instead: it returns [None] for a missing key rather than \
   raising."]

val get_owner : Connection.t -> key:Keyval.Key.t -> Keyval_rpc.Get_owner.Response.t
val delete : Connection.t -> key:Keyval.Key.t -> Keyval_rpc.Delete.Response.t
val list_keys : Connection.t -> Keyval.Key.t list

(** Ask the server to stop. Returns once the server has responded; the
    server actually shuts down shortly after. *)
val stop : Connection.t -> unit

(** [owner] is recorded as the owner of this binding, retrievable via
    [get_owner]; the server requires every [set] to supply one. *)
val set
  :  Connection.t
  -> key:Keyval.Key.t
  -> value:Keyval.Value.t
  -> owner:Keyval.Owner.t
  -> unit
