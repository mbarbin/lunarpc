(*********************************************************************************)
(*  lunarpc - An opinionated, lightweight, HTTP/JSON RPC harness                 *)
(*  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: MIT                                                 *)
(*********************************************************************************)

module type S = sig
  type t

  val to_string : t -> string
  val of_string : string -> (t, [ `Msg of string ]) Result.t
  val v : string -> t
  val equal : t -> t -> bool
  val compare : t -> t -> Ordering.t
  val hash : t -> int
  val to_dyn : t -> Dyn0.t
end

module type X = sig
  val module_name : string
  val invariant : string -> bool
end

module Make (X : X) = struct
  type t = string

  let equal = String0.equal
  let compare a b = String0.compare a b |> Ordering.of_int
  let hash = String0.hash
  let to_dyn = Dyn.string
  let to_string t = t

  let of_string s =
    if X.invariant s
    then Ok s
    else (
      let shown_s =
        if String0.length s > 40
        then
          String0.sub s ~pos:0 ~len:40
          ^ "..."
          ^ Printf.sprintf " (%d characters total)" (String0.length s)
        else s
      in
      Error
        (`Msg
            (Printf.sprintf
               "%S: invalid %s"
               shown_s
               (String0.uncapitalize_ascii X.module_name))))
  ;;

  let v s =
    match of_string s with
    | Ok t -> t
    | Error (`Msg m) -> raise (Invalid_argument m)
  ;;
end
