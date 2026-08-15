(*********************************************************************************)
(*  lunarpc - An opinionated, lightweight, HTTP/JSON RPC harness                 *)
(*  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: MIT                                                 *)
(*********************************************************************************)

let run_cmd =
  Command.make
    ~summary:"Run the server."
    ~readme:(fun () ->
      "Starts a keyval server listening for RPC connections, using the connection \
       parameters given via the listening arguments, and advertizes itself for service \
       discovery. Runs until interrupted.")
    (let open Command.Std in
     let+ listening_config = Rpc_discovery.Listening_config.arg
     and+ verbose = Arg.flag [ "verbose" ] ~doc:"Be more verbose." in
     let keyval_server = Keyval_server.create () in
     (* [Stop]'s handler needs the [Tiny_httpd.t] to ask it to stop, but that
        value doesn't exist until after the handler list is built. Tie the
        knot with a ref, populated below, right after [Tiny_httpd.create]. *)
     let server_ref : Tiny_httpd.t option ref = ref None in
     let stop_handler =
       Rpc.Handler.make
         (module Keyval_rpc.Stop)
         ~f:(fun (_ : unit Rpc.Call.t) ->
           match !server_ref with
           | Some server -> Tiny_httpd.stop server
           | None ->
             Code_error.raise "Stop handler invoked before the server was created." [])
     in
     let handlers = Keyval_server.handlers keyval_server @ [ stop_handler ] in
     let rpc_server = Rpc_server.create ~handlers in
     let server =
       Tiny_httpd.create
         ~port:
           (match listening_config.specification with
            | Tcp { port = `Supplied port } -> port
            | Tcp { port = `Chosen_by_OS } -> 0)
         ()
     in
     server_ref := Some server;
     Rpc_server.add_services rpc_server ~to_:server;
     Sys.set_signal Sys.sigterm (Signal_handle (fun (_ : int) -> Tiny_httpd.stop server));
     (try
        Tiny_httpd.run_exn server ~after_init:(fun () ->
          let port = Tiny_httpd.port server in
          Rpc_discovery.Listening_config.advertize
            listening_config
            ~service_id:Keyval_rpc.For_service_discovery.service_id
            ~instance_name:(Rpc_discovery.Instance_name.v "server")
            ~port;
          if verbose
          then
            print_endline
              (Printf.sprintf "Listening for connections on port [%d]." port)
            [@coverage off])
      with
      | Unix.Unix_error (Unix.EINTR, _, _) -> ());
     ())
;;

let main =
  Command.group
    ~summary:"Manage the server."
    ~readme:(fun () -> "Commands to run and otherwise manage a keyval server.")
    [ "run", run_cmd ]
;;
