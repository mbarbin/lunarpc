(*_********************************************************************************)
(*_  lunarpc - An opinionated, lightweight, HTTP/JSON RPC harness                 *)
(*_  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*_  SPDX-License-Identifier: MIT                                                 *)
(*_********************************************************************************)

(** Service discovery via file.

    This module provides a file-based service discovery mechanism where servers
    advertize their port to a well-known directory structure based on their
    service id, and clients scan that directory to find available servers. *)

(** Returns the root directory to use for service discovery. If [root_directory]
    is provided, uses that. Otherwise falls back to [$HOME] or the current
    working directory. *)
val default_root : root_directory:Absolute_path.t option -> Absolute_path.t

(** To be run on the server once it has initialized and is ready to accept new
    client connections. Creates the discovery directory if needed, writes the
    discovery file, and registers cleanup on exit. *)
val advertize_server
  :  root_directory:Absolute_path.t
  -> service_id:Service_id.t
  -> instance_name:Instance_name.t
  -> port:int
  -> unit

(** To be run on the client side to find a server that has advertized itself
    with {!advertize_server}. Scans the discovery directory for the service
    and returns the first valid discovery file found. Raises if no server is
    found. *)
val find_server
  :  root_directory:Absolute_path.t
  -> service_id:Service_id.t
  -> unit
  -> Discovery_file.t
