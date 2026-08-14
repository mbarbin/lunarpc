(*********************************************************************************)
(*  lunarpc - An opinionated, lightweight, HTTP/JSON RPC harness                 *)
(*  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: MIT                                                 *)
(*********************************************************************************)

type ('request, 'response) t =
  { name : Name.t
  ; version : int
  ; description : string
  ; request_encoder : 'request Encoder.t
  ; response_encoder : 'response Encoder.t
  }

let create ~name ~version ~description ~request_encoder ~response_encoder () =
  if version <= 0
  then
    invalid_arg
      (Printf.sprintf "Rpc0.create: version must be strictly positive, got %d" version);
  { name; version; description; request_encoder; response_encoder }
;;

let route t = Printf.sprintf "rpc/%s/v%d" (Name.to_string t.name) t.version

module type S = sig
  module Request : sig
    type t

    val equal : t -> t -> bool
  end

  module Response : sig
    type t

    val equal : t -> t -> bool
  end

  val rpc : (Request.t, Response.t) t
end
