(*_********************************************************************************)
(*_  lunarpc - An opinionated, lightweight, HTTP/JSON RPC harness                 *)
(*_  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*_  SPDX-License-Identifier: MIT                                                 *)
(*_********************************************************************************)

module Char = Char0
module Code_error = Code_error0
module Dyn = Dyn0
module Exn = Exn0
module Fun = Fun0
module Int = Int0
module Json = Json0
module List = List0
module Ordering = Ordering0
module Sexp = Sexplib0.Sexp
module String = String0
module String_id = String_id0

val phys_equal : 'a -> 'a -> bool
val print_dyn : Dyn.t -> unit

(** {1 Expect test helpers} *)

(** [require cond] raises if [cond] is false. *)
val require : bool -> unit

(** [require_does_raise f] raises if [f ()] does not raise, and prints the
    exception if it does. *)
val require_does_raise : (unit -> 'a) -> unit

(** To use [require_equal] and [require_not_equal], the type must provide
    [equal] and [to_dyn]. *)
module With_equal_and_dyn : sig
  module type S = sig
    type t

    val equal : t -> t -> bool
    val to_dyn : t -> Dyn.t
  end
end

(** [require_equal (module M) v1 v2] raises if [v1] and [v2] are not equal. *)
val require_equal : (module With_equal_and_dyn.S with type t = 'a) -> 'a -> 'a -> unit

val require_not_equal : (module With_equal_and_dyn.S with type t = 'a) -> 'a -> 'a -> unit
