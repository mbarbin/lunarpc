(*_********************************************************************************)
(*_  lunarpc - An opinionated, lightweight, HTTP/JSON RPC harness                 *)
(*_  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*_  SPDX-License-Identifier: MIT                                                 *)
(*_********************************************************************************)

(** @canonical Lunarpc_discovery.Rpc_discovery.Service_id.t *)
type t = private
  { app_name : App_name.t
  ; service_name : Service_name.t
  }

val compare : t -> t -> Ordering.t
val equal : t -> t -> bool
val create : app_name:App_name.t -> service_name:Service_name.t -> t
val to_dyn : t -> Dyn.t
