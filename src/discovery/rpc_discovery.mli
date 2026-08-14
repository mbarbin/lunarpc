(*_********************************************************************************)
(*_  lunarpc - An opinionated, lightweight, HTTP/JSON RPC harness                 *)
(*_  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*_  SPDX-License-Identifier: MIT                                                 *)
(*_********************************************************************************)

(** A simple service discovery via file. This supports only tcp
    servers running on localhost. *)

module App_name = App_name
module Discovery_file = Discovery_file
module Instance_name = Instance_name
module Service_id = Service_id
module Service_name = Service_name

(** Configuration for discovery via the file-based strategy. *)
module Discovery_via_file : sig
  type t = { root_directory : Absolute_path.t }

  val equal : t -> t -> bool
end

module Connection_config : sig
  (** The client side of the discovery answers the question: "Where is the
      service running?"

      The intended usage for this library is to add {!arg} to you command line
      parameters, and resolve the {!t} using {!port} in the body of your
      client command. *)

  type t =
    | Tcp of
        { host : [ `Localhost ]
        ; port : int
        }
    | Discovery_via_file of Discovery_via_file.t

  val equal : t -> t -> bool

  (** Build command-line arguments for connection config. Default is
      [Discovery_via_file] using the standard discovery directory. Use [--port]
      to bypass discovery. *)
  val arg : t Command.Arg.t

  (** Extract the port from the connection config. For [Discovery_via_file], the
      [service_id] is used to scan the discovery directory for available
      servers. For [Tcp], the [service_id] is ignored. *)
  val port : t -> service_id:Service_id.t -> int

  (** Returns the arguments that a client command needs to be supplied to
      rebuild [t] via {!arg}. This is used by tests and by
      [Lunarpc_test_harness.Rpc_test_harness.Config.rpc_discovery] to create the right
      invocations for clients whose cli uses {!arg}. *)
  val to_args : t -> string list
end

(** Command-line argument for [--root-directory] with default fallback to [$HOME]
    or current working directory. This is the root directory for service
    discovery and runtime data. Use this for commands that need a root directory
    but don't need the full {!Listening_config}. *)
val root_directory_arg : Absolute_path.t Command.Arg.t

module Listening_config : sig
  (** The server side of the discovery specifies where to serve, and how to
      advertize that information so clients can find you.

      The intended usage for this library is to add {!arg} to you command line
      parameters, and resolve the {!t} using {!port} in the body of your
      server command. Also, you should call {!advertize} after starting to
      serve, to save the discovery information to a file that clients will load. *)

  module Specification : sig
    type t = Tcp of { port : [ `Chosen_by_OS | `Supplied of int ] }

    val equal : t -> t -> bool
  end

  type t =
    { specification : Specification.t
    ; discovery_via_file : Discovery_via_file.t
    }

  val equal : t -> t -> bool

  (** Build command-line arguments for listening config. *)
  val arg : t Command.Arg.t

  val port : t -> int

  (** To be run on the server after starting to listen for connections.
      Advertizes the server in the discovery directory. *)
  val advertize
    :  t
    -> service_id:Service_id.t
    -> instance_name:Instance_name.t
    -> port:int
    -> unit

  (** Returns the arguments that a server needs to be supplied to rebuild [t] via
      {!arg}. This is used by tests and by [Rpc_test_harness.Config.rpc_discovery]
      to create the right invocations for servers whose cli uses {!arg}. *)
  val to_args : t -> string list
end
