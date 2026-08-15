(*_********************************************************************************)
(*_  lunarpc - An opinionated, lightweight, HTTP/JSON RPC harness                 *)
(*_  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*_  SPDX-License-Identifier: MIT                                                 *)
(*_********************************************************************************)

(** Serving RPCs on the server side. *)

type t

(** Create a new RPC server serving user-provided RPCs along with
    introspective handlers that allow querying information about the RPCs served
    (list them, get their schema, etc.). *)
val create : handlers:Rpc.Handler.t list -> t

(** {1 Backend}

    At the moment this library has built-in support for tiny-httpd and that's
    it. *)
val add_services : t -> to_:Tiny_httpd.t -> unit
