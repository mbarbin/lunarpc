(*_********************************************************************************)
(*_  lunarpc - An opinionated, lightweight, HTTP/JSON RPC harness                 *)
(*_  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*_  SPDX-License-Identifier: MIT                                                 *)
(*_********************************************************************************)

(** Metadata describing a single RPC: its name, route, and human-readable
    description, plus JSON schemas for its request and response when
    requested via [List_rpcs.Request.include_schemas]. This is the per-RPC
    payload carried by the introspective [List_rpcs] RPC. *)

(** @canonical Lunarpc.Rpc.Info.t *)
type t =
  { name : Name.t
  ; version : int
  ; route : string
  ; description : string
  ; request_schema : Json.t option
  ; response_schema : Json.t option
  }

val equal : t -> t -> bool
val to_json : t -> Json.t
val of_json : Json.t -> t

(** JSON Schema describing the on-wire shape of a single [Info.t]. *)
val schema : unit -> Json.t
