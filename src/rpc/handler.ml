(*********************************************************************************)
(*  lunarpc - An opinionated, lightweight, HTTP/JSON RPC harness                 *)
(*  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: MIT                                                 *)
(*********************************************************************************)

type t =
  | T :
      { spec :
          (module Rpc0.S with type Request.t = 'request and type Response.t = 'response)
      ; f : 'request Call.t -> 'response
      }
      -> t

let make spec ~f = T { spec; f }
