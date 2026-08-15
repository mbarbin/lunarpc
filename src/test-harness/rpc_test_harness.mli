(*_********************************************************************************)
(*_  lunarpc - An opinionated, lightweight, HTTP/JSON RPC harness                 *)
(*_  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*_  SPDX-License-Identifier: MIT                                                 *)
(*_********************************************************************************)

(** A library to help writing tests for rpc applications.

    {1 Testing environment}

    This is built with expect-tests in mind. To use the rest of this API, you
    need to introduce a new test environment to the scope. This is done via the
    {!run} function. This function will run the given function [f] with a fresh
    environment of type {!t}, and clean up the environment at the end.

    The test environment owns the parent temporary directory that holds every
    subdirectory handed out to servers during the run. All of these are cleaned
    up when {!run} returns. By default, every {!with_server} call allocates a
    fresh subdirectory, so multiple servers running concurrently (or running
    back-to-back) within a single {!run} are isolated from one another.

    To exercise a server restart / persistence path, allocate a single
    {!Data_dir.t} via {!persistent_data_dir} and pass it to successive
    {!with_server} calls via their [?data_dir] argument — they will then share
    the same service discovery root and the same on-disk state. *)

type t

val run : (t -> unit) -> unit

(** {1 Data directories}

    A {!Data_dir.t} is a pair of directories (the service discovery root and
    the short-path temp dir) that backs one or more server instances. The
    default behaviour of {!with_server} is to allocate a fresh one per call,
    but callers can allocate a persistent one via {!persistent_data_dir} and
    reuse it across calls to test persistence and restart behaviour. *)

module Data_dir : sig
  type t

  (** The [--root-directory] passed to servers run against this data dir
      (the server's "root directory for service discovery and runtime
      data"; in production this is the directory holding [server/] and
      [service-discovery/]). Exposed so tests that need to manipulate
      that on-disk state directly (e.g. a git-backed store) can locate
      it. *)
  val root_directory : t -> Absolute_path.t
end

(** Allocate a persistent data directory under the current test run. The
    returned value can be passed to successive {!with_server} calls to share
    state across restarts. The underlying directory is cleaned up when the
    enclosing {!run} returns. *)
val persistent_data_dir : t -> Data_dir.t

(** {1 Socket kinds}

    The tests support both kind of sockaddr, unix sockets and tcp connections,
    in both cases to connect to a server running on the localhost where the
    expect tests are running. *)

module Sockaddr_kind : sig
  (** Choosing the kind of sockaddr to use.

      Here is what happens in each mode:

      {2 Unix_socket}

      The library creates a temporary file in the file system, and supplies
      parameters to the server and client command pointing to it, to use it as a
      unix socket.

      {2 Tcp_localhost}

      The library creates a temporary directory in the file system, and supplies
      parameters to the server and client command pointing to it. This temporary
      directory will serve as a discovery root for service discovery.

      The server command is expected to let the OS choose an available port,
      listen on the given port and advertize the port to the discovery directory.
      The client command uses the discovery directory to find the port and
      initiate a connection. *)

  type t =
    (*_ Note from mbarbin: Unix sockets are not (yet?) supported by the
      underlying libraries used in this project, so for now we've
      removed that functionality.

      {[
        | Unix_socket
      ]}
    *)
    | Tcp_localhost
end

(** {1 Process environment overrides}

    Extra environment variables to pass to spawned server and client processes.
    When {!Process_env.build} is applied, these are merged into the current
    process environment, overriding any existing variables with the same name. *)

module Process_env : sig
  type t

  (** An environment with the given bindings. *)
  val make : (string * string) list -> t

  (** Same as [make []]. An environment with no bindings. *)
  val empty : t

  (** Build a Unix-style environment array by merging [t] into the current
      process environment. Variables in [t] override any existing variables with
      the same key. Returns [Unix.environment ()] unchanged when [t] is empty. *)
  val build : t -> string array
end

(** {1 Config}

    A configuration of type {!Config.t} is required by the library to know how
    to run your server and client commands. Build one by implementing the
    {!Config.S} interface and passing it to {!Config.create}.

    For simple cases where your server and client accept standard
    {!module:Lunarpc_discovery.Rpc_discovery} command line parameters, use
    {!Config.rpc_discovery} to build a {!Config.S} value. *)

module Config : sig
  type t

  module Process_command : sig
    (** A command that the library must run to start server and client
        processes. [executable] must be the path to the executable to run,
        searching $PATH for it if necessary.

        Do not forget to list the executable as a test dependency in your [dune]
        file. For example, if your executable is "m_app", you should have
        something like this in your dune file:

        {v
          (library
            (name my_app_test)
            (inline_tests (deps %{bin:my_app}))
          ...)
        v} *)
    type t =
      { executable : string
      ; program_name : string
      ; args : string list list
      ; hidden_args : string list
      }
  end

  (** The environment provided by the test framework when starting a server.
      Contains the parameters needed to build the server command. *)
  module Server_env : sig
    type t

    (** The listening configuration for service discovery. *)
    val listening_config : t -> Rpc_discovery.Listening_config.t

    (** A temporary directory with a short path (in [/tmp]) that the server
        may use for files requiring short paths, such as Unix domain sockets
        on macOS where the sun_path limit is 104 bytes. The directory is
        created and cleaned up by the test framework. *)
    val temp_dir : t -> string
  end

  module Client_invocation : sig
    (** In the tests, sometimes we run client commands that needs to connect to
        the server, and sometimes we run client commands that do not, and only
        perform other kinds of actions. This type is used to distinguish
        between these cases. *)
    type t =
      | Connect_to of { connection_config : Rpc_discovery.Connection_config.t }
      | Offline
  end

  module type S = sig
    (** The service id for the server being tested. *)
    val service_id : Rpc_discovery.Service_id.t

    (** This should return a valid command line to run a server that listens to
        the sockaddr as specified. *)
    val run_server_command : server_env:Server_env.t -> Process_command.t

    (** Once the server is running, this library will allow running client
        commands given some arguments. This function specifies the complete
        command to run. In particular it should add any required parameters
        in order for the command to connect to the server as specified. *)
    val run_client_command
      :  client_invocation:Client_invocation.t
      -> args:string list list
      -> Process_command.t

    (** Forward-map the captured output of a client command (e.g. replace
        non-deterministic values with stable labels). *)
    val process_output : string -> string

    (** Reverse-map the arguments supplied to a client command (e.g. replace
        deterministic labels back to real values before execution). *)
    val process_args : string list list -> string list list

    (** Extra environment variables to set when spawning server and client
        processes. These are merged into the current process environment,
        overriding any existing variables with the same name. *)
    val process_env : Process_env.t
  end

  val create : (module S) -> t

  (** A convenience wrapper to build a {!S} value for servers and clients that
      accept standard {!module:Lunarpc_discovery.Rpc_discovery} command line parameters. The
      wrapper appends the appropriate discovery arguments to [hidden_args]
      automatically. *)
  val rpc_discovery
    :  service_id:Rpc_discovery.Service_id.t
    -> run_server_command:(temp_dir:string -> Process_command.t)
    -> run_client_command:Process_command.t
    -> ?process_output:(string -> string)
    -> ?process_args:(string list list -> string list list)
    -> ?process_env:Process_env.t
    -> unit
    -> (module S)
end

(** {1 Server}

    The rest of the API is used to run one or several server(s) and connect to
    it, either by running your app's cli, or in OCaml directly via
    {!Server.with_connection}. *)

module Server : sig
  (** A server running that you can connect to during tests. *)
  type t

  val listening_on_port : t -> int

  (** Process ID of the running server. *)
  val pid : t -> int

  (** Path to file containing server's stdout output. *)
  val stdout_path : t -> string

  (** Path to file containing server's stderr output. *)
  val stderr_path : t -> string

  (** Initiates a connection to the running server so you can perform RPCs written
      in OCaml. *)
  val with_connection : t -> (Rpc_client.Connection.t -> unit) -> unit
end

module With_server : sig
  (** This is what is introduced to the scope with the {!with_server} function. *)
  type t =
    { server : Server.t
    ; client : ?offline:bool -> ?use_connection_config:bool -> string list list -> unit
      (** [client ?offline args] is a convenient wrapper for {!run_client},
          applied to the given server, and directly introduced to the scope. *)
    }
end

(** Takes care of starting a server, running [f] and stopping the server at the
    end. [sockaddr_kind] defaults to [Unix_socket].

    When [data_dir] is omitted, a fresh data directory is allocated under the
    current run, isolating this server from any other {!with_server} call.
    Supply a [data_dir] obtained from {!persistent_data_dir} (and reuse it
    across calls) to exercise server restarts and persistence. *)
val with_server
  :  ?sockaddr_kind:Sockaddr_kind.t
  -> ?data_dir:Data_dir.t
  -> t
  -> config:Config.t
  -> (With_server.t -> unit)
  -> unit

(** [run_client server ?offline args] runs a client process that will connect to
    the given server. [offline:true] should be used for commands that do not
    connect to the server, and defaults to [false]. The [args] are flatten
    before the actual invocation, the grouping is only useful to make the
    code more readable (e.g. you can group together a flag with it's
    required argument, etc.). *)
val run_client
  :  Server.t
  -> ?offline:bool
  -> ?use_connection_config:bool
  -> string list list
  -> unit
