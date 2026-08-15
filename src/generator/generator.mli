(*_********************************************************************************)
(*_  lunarpc - An opinionated, lightweight, HTTP/JSON RPC harness                 *)
(*_  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*_  SPDX-License-Identifier: MIT                                                 *)
(*_********************************************************************************)

(** A generator of random values of type ['a].

    [Generator] is a thin abstraction layer over the underlying quickcheck
    backend ([Base_quickcheck]). It lives in the [lunarpc-quickcheck] library,
    used from test code only, so that the production libraries (e.g.
    [lunarpc-stdlib]) never pull in [base]/[base_quickcheck]; generators for a
    given type are defined where they are used, alongside the tests. *)

type 'a t

(** {1 Building generators} *)

(** [create f] is a generator that produces a value by calling [f] with the
    current size parameter. The size parameter is an upper bound on the
    "complexity" of the value to generate (e.g. the length of a list); see
    {!list} and similar combinators. *)
val create : (size:int -> 'a) -> 'a t

(** A generator that always produces the given value. *)
val return : 'a -> 'a t

(** {1 Combining generators} *)

val map : 'a t -> f:('a -> 'b) -> 'b t
val bind : 'a t -> f:('a -> 'b t) -> 'b t
val both : 'a t -> 'b t -> ('a * 'b) t

(** Pick uniformly at random from the given generators, then sample from the
    chosen one. *)
val union : 'a t list -> 'a t

(** Discard values that do not satisfy the predicate. If [f] rejects too many
    values the generator may run out of budget; prefer constructing values
    that are always valid by construction when possible. *)
val filter : 'a t -> f:('a -> bool) -> 'a t

(** A generator that draws uniformly from a fixed list of values. *)
val of_list : 'a list -> 'a t

(** {1 Primitive generators} *)

val bool : bool t
val option : 'a t -> 'a option t
val list : 'a t -> 'a list t
val list_non_empty : 'a t -> 'a list t
val string_non_empty : string t
val string_non_empty_of : char t -> string t
val char_alphanum : char t
val int_uniform_inclusive : int -> int -> int t

(** {1 Let syntax}

    Convenience operators to write applicative- and monad-style generators.

    {[
    let open Generator.Syntax in
    let+ x = gen_x
    and+ y = gen_y in
    { x; y }
    ]} *)

module Syntax : sig
  val ( let+ ) : 'a t -> ('a -> 'b) -> 'b t
  val ( and+ ) : 'a t -> 'b t -> ('a * 'b) t
  val ( let* ) : 'a t -> ('a -> 'b t) -> 'b t
  val ( and* ) : 'a t -> 'b t -> ('a * 'b) t
end

(**/**)

(** Internal access to the backing implementation, exposed for the companion
    test runner only. Do not use elsewhere. *)
module Private : sig
  val to_base_quickcheck : 'a t -> 'a Base_quickcheck.Generator.t
end
