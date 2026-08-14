(*_********************************************************************************)
(*_  lunarpc - An opinionated, lightweight, HTTP/JSON RPC harness                 *)
(*_  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*_  SPDX-License-Identifier: MIT                                                 *)
(*_********************************************************************************)

(** Encoding a port into a file.

    A discovery file is a file on the local file system that contains some json
    value encoding for a port. It is used as simple service discovery via
    file strategy for a client to discover dynamically where the server is
    listening on the localhost. *)

type t = { port : int }

(** Load and parse discovery file from disk. This is done by clients. *)
val load : path:Fpath.t -> t

(** Save discovery file to disk. The responsibility of mkdir the parent is left
    for the caller to handle. This is done by servers. *)
val save : t -> path:Fpath.t -> unit

(** {1 Expert API}

    We expose the internal format used on disk if you need it. *)

module Json_format : sig
  (** This format is used to model and serialize the discovery data to a file
      that is read at runtime during the service-discovery via file strategy. *)

  type nonrec t = t

  include Rpc.Encoder.S with type t := t
end
