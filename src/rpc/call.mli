(*_********************************************************************************)
(*_  lunarpc - An opinionated, lightweight, HTTP/JSON RPC harness                 *)
(*_  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*_  SPDX-License-Identifier: MIT                                                 *)
(*_********************************************************************************)

(** An incoming RPC call: the decoded request payload, bundled with metadata
    about the call (currently just the calling {!Principal.t}, if any). A
    {!Handler.t}'s function receives one of these rather than the payload
    directly, so new per-call metadata can be threaded through without
    changing the [Handler.make] signature again. *)

type 'request t (** @canonical Lunarpc.Rpc.Call.t *)

(** [create_with_headers request ~get] bundles the decoded [request] with the
    call's metadata, read from the request's transport headers via [get]
    (e.g. the server's header accessor). A header present but not a valid
    {!Principal.t} is treated as absent. *)
val create_with_headers : 'request -> get:(string -> string option) -> 'request t

(** The decoded request payload. *)
val request : 'request t -> 'request

(** Who made this call, if the caller supplied a principal. *)
val principal : _ t -> Principal.t option

(** The transport headers carrying the call's metadata; empty when there is
    none. This does not encode [request] — that's the RPC's JSON body,
    encoded separately via the spec's [request_encoder]. Takes each piece of
    metadata as a labelled argument so new ones can be added here without
    changing the shape of this function. *)
val to_headers : ?principal:Principal.t -> unit -> (string * string) list
