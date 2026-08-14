(*_********************************************************************************)
(*_  lunarpc - An opinionated, lightweight, HTTP/JSON RPC harness                 *)
(*_  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*_  SPDX-License-Identifier: MIT                                                 *)
(*_********************************************************************************)

(** Ask the server to stop. The handler for this RPC lives in the [server]
    command itself, not in {!Keyval_server}, since only the former has
    access to the underlying [Tiny_httpd.t] to stop. The server responds to
    this call before shutting down (see [Tiny_httpd.stop]'s doc: it asks the
    server to stop, without an immediate effect on the in-flight request). *)

module Request : sig
  type t = unit

  val equal : t -> t -> bool
end

module Response : sig
  type t = unit

  val equal : t -> t -> bool
end

include Rpc.S with module Request := Request and module Response := Response
