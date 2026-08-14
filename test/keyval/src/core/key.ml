(*********************************************************************************)
(*  lunarpc - An opinionated, lightweight, HTTP/JSON RPC harness                 *)
(*  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: MIT                                                 *)
(*********************************************************************************)

type t = string

let compare a b = String.compare a b |> Ordering.of_int
let equal = String.equal
let hash = String.hash
let to_dyn = Dyn.string

let invariant t =
  (not (String.is_empty t))
  && String.for_all t ~f:(fun c -> Char.is_alphanum c || Char.equal c '_')
;;

let to_string t = t

let of_string s =
  if invariant s then Ok s else Error (`Msg (Printf.sprintf "%S: invalid key" s))
;;

let v str =
  match str |> of_string with
  | Ok t -> t
  | Error (`Msg m) -> invalid_arg m
;;
