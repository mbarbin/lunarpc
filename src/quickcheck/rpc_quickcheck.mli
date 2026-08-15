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
