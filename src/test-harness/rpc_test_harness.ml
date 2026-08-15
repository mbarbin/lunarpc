(*********************************************************************************)
(*  lunarpc - An opinionated, lightweight, HTTP/JSON RPC harness                 *)
(*  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: MIT                                                 *)
(*********************************************************************************)

module Unix = UnixLabels

module Process_env : sig
  type t

  val make : (string * string) list -> t
  val empty : t
  val build : t -> string array
end = struct
  type t = (string * string) list

  let make bindings = bindings
  let empty = []

  let build t =
    if List.is_empty t
    then Unix.environment ()
    else (
      let override_keys = Set.of_list (module String) (List.map t ~f:fst) in
      let base =
        Unix.environment ()
        |> Array.to_list
        |> List.filter ~f:(fun entry ->
          match String.lsplit2 entry ~on:'=' with
          | Some (key, _) -> not (Set.mem key override_keys)
          | None -> true)
      in
      let extra_strings = List.map t ~f:(fun (k, v) -> k ^ "=" ^ v) in
      Array.of_list (base @ extra_strings))
  ;;
end

module Config = struct
  module Process_command = struct
    type t =
      { executable : string
      ; program_name : string
      ; args : string list list
      ; hidden_args : string list
      }

    let to_executable_list { executable; program_name = _; args; hidden_args } =
      List.concat [ [ executable ]; List.concat args; hidden_args ]
    ;;
  end

  module Client_invocation = struct
    type t =
      | Connect_to of { connection_config : Rpc_discovery.Connection_config.t }
      | Offline
  end

  module Server_env = struct
    type t =
      { listening_config : Rpc_discovery.Listening_config.t
      ; temp_dir : string
      }

    let listening_config t = t.listening_config
    let temp_dir t = t.temp_dir
  end

  module type S = sig
    val service_id : Rpc_discovery.Service_id.t
    val run_server_command : server_env:Server_env.t -> Process_command.t

    val run_client_command
      :  client_invocation:Client_invocation.t
      -> args:string list list
      -> Process_command.t

    val process_output : string -> string
    val process_args : string list list -> string list list
    val process_env : Process_env.t
  end

  type t = (module S)

  let create s = s

  let rpc_discovery
        ~service_id
        ~run_server_command
        ~run_client_command
        ?(process_output = Fun.id)
        ?(process_args = Fun.id)
        ?(process_env = Process_env.empty)
        ()
    : (module S)
    =
    let module Config : S = struct
      let service_id = service_id
      let process_env = process_env

      let run_server_command ~server_env =
        let { Process_command.executable; program_name; args; hidden_args } =
          run_server_command ~temp_dir:(Server_env.temp_dir server_env)
        in
        { Process_command.executable
        ; program_name
        ; args
        ; hidden_args =
            hidden_args
            @ Rpc_discovery.Listening_config.to_args
                (Server_env.listening_config server_env)
        }
      ;;

      let run_client_command ~client_invocation ~args =
        let { Process_command.executable; program_name; args = client_args; hidden_args } =
          run_client_command
        in
        let connection_args =
          match (client_invocation : Client_invocation.t) with
          | Offline -> []
          | Connect_to { connection_config } ->
            Rpc_discovery.Connection_config.to_args connection_config
        in
        { Process_command.executable
        ; program_name
        ; args = List.concat [ args; client_args ]
        ; hidden_args = List.concat [ hidden_args; connection_args ]
        }
      ;;

      let process_output = process_output
      let process_args = process_args
    end
    in
    (module Config)
  ;;
end

module Sockaddr_kind = struct
  type t = Tcp_localhost
end

let remove_dir_if_exists dir =
  if Sys.file_exists dir && Sys.is_directory dir
  then (
    let rec remove_dir path =
      if Sys.is_directory path
      then (
        Sys.readdir path
        |> Array.iter ~f:(fun name -> remove_dir (Filename.concat path name));
        Unix.rmdir path)
      else Unix.unlink path
    in
    remove_dir dir)
;;

type t =
  { root_test_dir : string
  ; (* Parent of every short-path subdirectory handed out by this run. We keep
       a dedicated root in [/tmp] so that server temp dirs (used for Unix
       domain socket paths) stay under macOS's 104-byte [sun_path] limit, even
       when the regular [TMPDIR] set by dune is deep. *)
    root_short_dir : string
  }

module Data_dir = struct
  type t =
    { test_dir : string
    ; temp_dir : string
    }

  let create parent =
    { test_dir = Filename.temp_dir ~temp_dir:parent.root_test_dir "d" ""
    ; temp_dir = Filename.temp_dir ~temp_dir:parent.root_short_dir "d" ""
    }
  ;;

  let root_directory t = Absolute_path.v t.test_dir
end

let persistent_data_dir t = Data_dir.create t

let run f =
  let root_test_dir = Filename.temp_dir "rpc_test" "" in
  let root_short_dir = Filename.temp_dir ~temp_dir:"/tmp" "jt" "" in
  Exn.protect
    ~f:(fun () -> f { root_test_dir; root_short_dir })
    ~finally:(fun () ->
      remove_dir_if_exists root_test_dir;
      remove_dir_if_exists root_short_dir)
;;

module Server = struct
  type nonrec t =
    { test : t
    ; config : Config.t
    ; connection_config : Rpc_discovery.Connection_config.t
    ; listening_on_port : int
    ; pid : int
    ; stdout_path : string
    ; stderr_path : string
    }

  let listening_on_port t = t.listening_on_port
  let pid t = t.pid
  let stdout_path t = t.stdout_path
  let stderr_path t = t.stderr_path

  let with_connection { listening_on_port = port; _ } f =
    Rpc_client.with_connection ~port f
  ;;
end

(* If we end up splitting the command, traditionally we show it with quoted end
   of lines markers. *)
let command_pp_to_string pp =
  let buffer = Buffer.create 23 in
  let formatter = Format.formatter_of_buffer buffer in
  Format.fprintf formatter "%a%!" Pp.to_fmt pp;
  let contents =
    Buffer.contents buffer
    |> String.split_lines
    |> List.map ~f:String.rstrip
    |> String.concat ~sep:" \\\n"
  in
  contents
;;

let build_cram_like ~program_name ~args =
  let command_pp =
    let groups =
      match args with
      | (first_arg :: _ as first_group) :: rest
        when not (String.is_prefix first_arg ~prefix:"-") ->
        (* When the first group doesn't start with a flag, keep it together
           with the program name so the command reads naturally on one line:
           e.g. [$ cr change branch-name] rather than [$ cr \<newline> change ...]. *)
        (program_name :: first_group) :: rest
      | _ -> [ program_name ] :: args
    in
    let groups =
      List.map groups ~f:(fun group ->
        Pp.hbox (Pp.concat_map group ~sep:Pp.space ~f:Pp.verbatim))
    in
    Pp.concat [ Pp.verbatim "$ "; Pp.hvbox ~indent:2 (Pp.concat ~sep:Pp.space groups) ]
  in
  command_pp_to_string command_pp
;;

let run_client
      { Server.test = _
      ; config
      ; listening_on_port
      ; connection_config
      ; pid = _
      ; stdout_path = _
      ; stderr_path = _
      }
      ?(offline = false)
      ?(use_connection_config = false)
      args
  =
  let module C = (val config : Config.S) in
  let client_invocation : Config.Client_invocation.t =
    if offline
    then Offline
    else
      Connect_to
        { connection_config =
            (if use_connection_config
             then connection_config
             else Tcp { host = `Localhost; port = listening_on_port })
        }
  in
  (* Print the cram header from the original (possibly deterministic) args. *)
  let display_command = C.run_client_command ~client_invocation ~args in
  let cram_like =
    build_cram_like ~program_name:display_command.program_name ~args:display_command.args
  in
  print_endline cram_like;
  (* Apply reverse mapping to args before execution. *)
  let mapped_args = C.process_args args in
  let exec_command = C.run_client_command ~client_invocation ~args:mapped_args in
  let executable_list = exec_command |> Config.Process_command.to_executable_list in
  (* Execute the process, capturing stdout and stderr so both pass through
     the configured forward mapping. Ordering between the two streams is not
     preserved — the captured stdout is flushed first, then stderr. *)
  let temp_stdout = Filename.temp_file "rpc_client" ".stdout" in
  let temp_stderr = Filename.temp_file "rpc_client" ".stderr" in
  Exn.protect
    ~f:(fun () ->
      match executable_list with
      | [] -> assert false
      | prog :: rest ->
        let stdout_fd =
          Unix.openfile temp_stdout ~mode:[ O_WRONLY; O_CREAT; O_TRUNC ] ~perm:0o666
        in
        let stderr_fd =
          Unix.openfile temp_stderr ~mode:[ O_WRONLY; O_CREAT; O_TRUNC ] ~perm:0o666
        in
        let env = Process_env.build C.process_env in
        let pid =
          Exn.protect
            ~finally:(fun () ->
              Unix.close stdout_fd;
              Unix.close stderr_fd)
            ~f:(fun () ->
              Unix.create_process_env
                ~prog
                ~args:(Array.of_list (prog :: rest))
                ~env
                ~stdin:Unix.stdin
                ~stdout:stdout_fd
                ~stderr:stderr_fd)
        in
        let _, status = Unix.waitpid ~mode:[] pid in
        let flush_output () =
          let out = In_channel.read_all temp_stdout |> C.process_output in
          if not (String.is_empty out) then print_string out;
          let err = In_channel.read_all temp_stderr |> C.process_output in
          if not (String.is_empty err) then prerr_string err
        in
        (match status with
         | WEXITED 0 -> flush_output ()
         | WEXITED code ->
           flush_output ();
           prerr_endline (Printf.sprintf "[%d]\n" code)
         | WSIGNALED signal ->
           flush_output ();
           prerr_endline (Printf.sprintf "Client killed by signal %d" signal)
         | WSTOPPED _ ->
           (* Unreachable: [Unix.waitpid ~mode:[]] never returns [WSTOPPED]
              --- that requires the caller to pass [WUNTRACED], which we
              don't. Kept for exhaustiveness against [Unix.process_status]. *)
           (flush_output ();
            prerr_endline "Client stopped")
           [@coverage off]))
    ~finally:(fun () ->
      if Sys.file_exists temp_stdout then Sys.remove temp_stdout;
      if Sys.file_exists temp_stderr then Sys.remove temp_stderr)
;;

module With_server = struct
  type t =
    { server : Server.t
    ; client : ?offline:bool -> ?use_connection_config:bool -> string list list -> unit
    }
end

let with_server ?(sockaddr_kind = Sockaddr_kind.Tcp_localhost) ?data_dir (t : t) ~config f
  =
  let module C = (val config : Config.S) in
  let { Data_dir.test_dir; temp_dir } =
    match data_dir with
    | Some dir -> dir
    | None -> Data_dir.create t
  in
  let root_directory = Absolute_path.v test_dir in
  let listening_config : Rpc_discovery.Listening_config.t =
    match sockaddr_kind with
    | Tcp_localhost ->
      { specification = Tcp { port = `Chosen_by_OS }
      ; discovery_via_file = { root_directory }
      }
  in
  let server_stdout = Filename.concat test_dir "server.stdout" in
  let server_stderr = Filename.concat test_dir "server.stderr" in
  let server_pid =
    match
      C.run_server_command ~server_env:{ listening_config; temp_dir }
      |> Config.Process_command.to_executable_list
    with
    | [] -> assert false
    | prog :: args ->
      let stdout_fd =
        Unix.openfile server_stdout ~mode:[ O_WRONLY; O_CREAT; O_TRUNC ] ~perm:0o666
      in
      let stderr_fd =
        Unix.openfile server_stderr ~mode:[ O_WRONLY; O_CREAT; O_TRUNC ] ~perm:0o666
      in
      let env = Process_env.build C.process_env in
      Exn.protect
        ~f:(fun () ->
          Unix.create_process_env
            ~prog
            ~args:(Array.of_list (prog :: args))
            ~env
            ~stdin:Unix.stdin
            ~stdout:stdout_fd
            ~stderr:stderr_fd)
        ~finally:(fun () ->
          Unix.close stdout_fd;
          Unix.close stderr_fd)
  in
  let read_server_stderr () =
    if Sys.file_exists server_stderr
    then In_channel.read_all server_stderr
    else ("<no stderr file>" [@coverage off])
    (* Unreachable: [server_stderr] is opened with [O_CREAT] above, before
       the server is even spawned, so by the time anything below could call
       [read_server_stderr], the file already exists on disk. *)
  in
  let server_stopped = ref false in
  let stop_server () =
    if not !server_stopped
    then (
      server_stopped := true;
      (try Unix.kill ~pid:server_pid ~signal:Sys.sigterm with
       | Unix.Unix_error _ -> ());
      try ignore (Unix.waitpid ~mode:[] server_pid : int * Unix.process_status) with
      | _ -> ())
  in
  let connection_config : Rpc_discovery.Connection_config.t =
    match listening_config.specification with
    | Tcp { port = `Supplied port } ->
      (* Unreachable via [with_server]: [listening_config] above always
         picks [`Chosen_by_OS]. Kept in case a future [sockaddr_kind] needs
         a fixed port. *)
      Tcp { host = `Localhost; port }
      [@coverage off]
    | Tcp { port = `Chosen_by_OS } ->
      Discovery_via_file listening_config.discovery_via_file
  in
  (* Poll for the server to become ready instead of a blind sleep. *)
  let poll_for_server_port () =
    let poll_interval = 0.05 in
    let max_wait = 5.0 in
    let start_time = Unix.gettimeofday () in
    let rec poll () =
      match
        Rpc_discovery.Connection_config.port connection_config ~service_id:C.service_id
      with
      | port -> port
      | exception exn ->
        let elapsed = Unix.gettimeofday () -. start_time in
        if Float.( >= ) elapsed max_wait
        then
          Printf.ksprintf
            failwith
            "Server did not become ready within %.1fs (pid=%d).\n\
             Test dir: %s\n\
             Last error: %s\n\
             Server stderr:\n\
             %s"
            max_wait
            server_pid
            test_dir
            (Exn.to_string exn)
            (read_server_stderr ())
        else (
          Unix.sleepf poll_interval;
          poll ())
    in
    poll ()
  in
  let graceful_shutdown () =
    Unix.kill ~pid:server_pid ~signal:Sys.sigterm;
    server_stopped := true;
    match Unix.waitpid ~mode:[] server_pid with
    | _, WEXITED 0 -> ()
    | _, WSIGNALED signal when signal = Sys.sigterm -> ()
    | _, WEXITED code ->
      prerr_endline (Printf.sprintf "Server exited with code %d" code);
      prerr_endline (read_server_stderr ())
    | _, (WSIGNALED signal | WSTOPPED signal) ->
      prerr_endline (Printf.sprintf "Server killed by signal %d" signal);
      prerr_endline (read_server_stderr ())
  in
  Exn.protect
    ~f:(fun () ->
      let listening_on_port = poll_for_server_port () in
      let server =
        { Server.test = t
        ; config
        ; connection_config
        ; listening_on_port
        ; pid = server_pid
        ; stdout_path = server_stdout
        ; stderr_path = server_stderr
        }
      in
      let client ?offline ?use_connection_config args =
        run_client server ?offline ?use_connection_config args
      in
      f { With_server.server; client };
      graceful_shutdown ())
    ~finally:stop_server
;;
