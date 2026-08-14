(*_********************************************************************************)
(*_  lunarpc - An opinionated, lightweight, HTTP/JSON RPC harness                 *)
(*_  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*_  SPDX-License-Identifier: MIT                                                 *)
(*_********************************************************************************)

(** A handler for a specific RPC on the server side. *)

(** @canonical Lunarpc.Rpc.Handler.t *)
type t = private
  | T :
      { spec :
          (module Rpc0.S with type Request.t = 'request and type Response.t = 'response)
      ; f : 'request Call.t -> 'response
      }
      -> t

(** [make] builds a handler from its spec and a function of the call. Most
    handlers only need the request payload ({!Call.request}); handlers that
    attribute or authorize by principal also read {!Call.principal}. *)
val make
  :  (module Rpc0.S with type Request.t = 'request and type Response.t = 'response)
  -> f:('request Call.t -> 'response)
  -> t
