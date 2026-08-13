(*_********************************************************************************)
(*_  lunarpc - An opinionated, lightweight, HTTP/JSON RPC harness                 *)
(*_  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*_  SPDX-License-Identifier: MIT                                                 *)
(*_********************************************************************************)

(** Rpc is a model of unary RPCs that can be defined in the context of a
    client/server applications, with the aim of supporting several possible
    exchange backends. *)

module Call = Call
module Encoder = Encoder
module Handler = Handler
module Info = Info
module List_rpcs = List_rpcs
module Name = Name
module Principal = Principal

include module type of Rpc0 (** @inline *)
