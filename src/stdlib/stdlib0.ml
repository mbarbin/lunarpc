(*********************************************************************************)
(*  lunarpc - An opinionated, lightweight, HTTP/JSON RPC harness                 *)
(*  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: MIT                                                 *)
(*********************************************************************************)

module Absolute_path = Absolute_path0
module Array = Array0
module Char = Char0
module Code_error = Code_error0
module Dyn = Dyn0
module Err = Err0
module Exn = Exn0
module Float = Float0
module Fpath = Fpath0
module Fun = Fun0
module Fsegment = Fsegment0
module In_channel = In_channel0
module Int = Int0
module Json = Json0
module List = List0
module Out_channel = Out_channel0
module Option = Option0
module Ordering = Ordering0
module Pp = Pp0
module Sexp = Sexplib0.Sexp
module String = String0
module String_id = String_id0

let ( let@ ) f k = f k
let phys_equal (type t) (a : t) (b : t) = a == b
let print pp = Format.printf "%a@." Pp.to_fmt pp
let print_dyn dyn = print (Dyn.pp dyn)
let print_endline = Stdlib.print_endline
let print_json json = print_endline (Json.pretty_to_string json)
let require cond = if not cond then Code_error.raise "Require failed." []

let require_does_raise f =
  match f () with
  | _ -> Code_error.raise "Did not raise." []
  | exception e -> print_endline (Sexp.to_string_hum (Exn.sexp_of_t e))
;;

module With_equal_and_dyn = struct
  module type S = sig
    type t

    val equal : t -> t -> bool
    val to_dyn : t -> Dyn.t
  end
end

let require_equal
      (type a)
      (module M : With_equal_and_dyn.S with type t = a)
      (v1 : a)
      (v2 : a)
  =
  if not (M.equal v1 v2)
  then Code_error.raise "Values are not equal." [ "v1", M.to_dyn v1; "v2", M.to_dyn v2 ]
;;

let require_not_equal
      (type a)
      (module M : With_equal_and_dyn.S with type t = a)
      (v1 : a)
      (v2 : a)
  =
  if M.equal v1 v2
  then Code_error.raise "Values are equal." [ "v1", M.to_dyn v1; "v2", M.to_dyn v2 ]
;;
