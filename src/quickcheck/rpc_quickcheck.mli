(*_********************************************************************************)
(*_  lunarpc - An opinionated, lightweight, HTTP/JSON RPC harness                 *)
(*_  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*_  SPDX-License-Identifier: MIT                                                 *)
(*_********************************************************************************)

(** Running roundtrip tests for RPC with quickcheck. *)

module type S = sig
  module Request : sig
    type t

    val generator : t Generator.t
    val equal : t -> t -> bool
  end

  module Response : sig
    type t

    val generator : t Generator.t
    val equal : t -> t -> bool
  end

  include Rpc.S with module Request := Request and module Response := Response
end

type ('request, 'response) t =
  (module S with type Request.t = 'request and type Response.t = 'response)

(** Run 2 quickcheck tests to go over requests and responses and make sure the
    generated inputs roundtrip correctly through serialization. *)
val run_exn
  :  ?requests:'request list
  -> ?responses:'response list
  -> ('request, 'response) t
  -> unit

(** {1 Individual tests} *)

val run_request_exn : ?examples:'request list -> ('request, 'response) t -> unit
val run_validate_request_exn : ?examples:'request list -> ('request, 'response) t -> unit
val run_response_exn : ?examples:'response list -> ('request, 'response) t -> unit

val run_validate_response_exn
  :  ?examples:'response list
  -> ('request, 'response) t
  -> unit

(**/**)

(** Internal access to the generic property-based test runner backing this
    module, exposed for [lunarpc-quickcheck]'s own test suite only (to check
    an invariant on a custom generator that isn't an RPC request/response
    pair). Do not use elsewhere. *)
module Private : sig
  val test_run
    :  ?examples:'a list
    -> (module Test.S with type t = 'a)
    -> f:('a -> unit)
    -> unit
end
