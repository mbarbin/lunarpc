(*_********************************************************************************)
(*_  lunarpc - An opinionated, lightweight, HTTP/JSON RPC harness                 *)
(*_  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*_  SPDX-License-Identifier: MIT                                                 *)
(*_********************************************************************************)

module Connection : sig
  type t
end

(** Unix sockets are not supported by the underlying deps used in this project,
    so we've removed that functionality, and require a [port] here. The server
    is assumed to be running on the localhost. [principal] is attached to
    every call on this connection (defaults to none; a per-call [principal]
    overrides it). *)
val with_connection : ?principal:Rpc.Principal.t -> port:int -> (Connection.t -> 'a) -> 'a

(** call a given RPC [encoding] defaults to [JSON]. [principal] identifies
    the caller (defaults to the connection's). *)
val call
  :  ?principal:Rpc.Principal.t
  -> (module Rpc.S with type Request.t = 'request and type Response.t = 'response)
  -> connection:Connection.t
  -> 'request
  -> ('response, Err.t) Result.t
