(*_********************************************************************************)
(*_  lunarpc - An opinionated, lightweight, HTTP/JSON RPC harness                 *)
(*_  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*_  SPDX-License-Identifier: MIT                                                 *)
(*_********************************************************************************)

(** Cycle-breaker for the [Rpc] library. Contains the core spec record and
    module type [S] that other submodules ([Handler], [List_rpcs]) need to
    reference. Re-exported at the top of [rpc.ml] via [include]; not exposed
    as a submodule externally. *)

(** @canonical Lunarpc.Rpc.t *)
type ('request, 'response) t = private
  { name : Name.t
  ; version : int
  ; description : string
  ; request_encoder : 'request Encoder.t
  ; response_encoder : 'response Encoder.t
  }

(** [create ~name ~version ~description ~request_encoder ~response_encoder ()]
    builds an RPC spec. Raises [Invalid_argument] if [version] is negative or
    null (versions start at [1]). *)
val create
  :  name:Name.t
  -> version:int
  -> description:string
  -> request_encoder:'request Encoder.t
  -> response_encoder:'response Encoder.t
  -> unit
  -> ('request, 'response) t

(** [route t] returns the URL path component for this RPC, without a leading slash.

    For example, if [t.name = Name.v "listRepos"] and [t.version = 1], this
    returns ["rpc/listRepos/v1"]. Versioning is local to each RPC: bump
    [version] when the request/response shape changes in an incompatible way.
    The server can register handlers for multiple versions of the same RPC
    side by side.

    {b Slash conventions:}
    - Routes are path components, not absolute paths
    - They do NOT start with a leading slash
    - They are meant to be composed into full URLs by the client
    - Example: [sprintf "http://%s:%d/%s" host port (route rpc)]
      produces ["http://localhost:8080/rpc/listRepos/v1"]

    This convention prevents double slashes when composing URLs and is
    standard practice in web frameworks where routes are path components. *)
val route : _ t -> string

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
