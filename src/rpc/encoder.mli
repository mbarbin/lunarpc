(*_********************************************************************************)
(*_  lunarpc - An opinionated, lightweight, HTTP/JSON RPC harness                 *)
(*_  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*_  SPDX-License-Identifier: MIT                                                 *)
(*_********************************************************************************)

(** @canonical Lunarpc.Rpc.Encoder.t *)
type 'a t =
  { of_json : Json.t -> 'a
  ; to_json : 'a -> Json.t
  ; schema : unit -> Json.t
  }

module type S = sig
  type t

  val of_json : Json.t -> t
  val to_json : t -> Json.t
  val schema : unit -> Json.t
end

val make : (module S with type t = 'a) -> 'a t
