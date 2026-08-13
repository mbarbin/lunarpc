(*********************************************************************************)
(*  lunarpc - An opinionated, lightweight, HTTP/JSON RPC harness                 *)
(*  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: MIT                                                 *)
(*********************************************************************************)

type t = unit

let equal () () = true
let to_json (_ : t) : Json.t = `Assoc []

let of_json : Json.t -> t = function
  | `Assoc _ -> ()
  | json -> raise (Json.Invalid_json (json, "Expected object"))
;;

let schema () = `Assoc [ "type", `String "object" ]
