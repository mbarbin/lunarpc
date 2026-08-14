(*********************************************************************************)
(*  lunarpc - An opinionated, lightweight, HTTP/JSON RPC harness                 *)
(*  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: MIT                                                 *)
(*********************************************************************************)

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

let make (type a) (module M : S with type t = a) =
  { of_json = M.of_json; to_json = M.to_json; schema = M.schema }
;;
