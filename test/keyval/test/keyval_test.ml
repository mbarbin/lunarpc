(*********************************************************************************)
(*  lunarpc - An opinionated, lightweight, HTTP/JSON RPC harness                 *)
(*  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: MIT                                                 *)
(*********************************************************************************)

let executable = "./keyval.exe"

(* [set]'s default owner, when [--as] isn't supplied, falls back to
   KEYVAL_USER before the (environment-dependent) unix login. Pin it to a
   stable value here so tests that don't care about ownership don't have to
   supply [--as] to get deterministic output. *)
let process_env = Rpc_test_harness.Process_env.make [ "KEYVAL_USER", "test-user" ]

let config =
  Rpc_test_harness.Config.rpc_discovery
    ~service_id:Keyval_rpc.For_service_discovery.service_id
    ~run_server_command:(fun ~temp_dir:_ ->
      { executable
      ; program_name = "keyval-server"
      ; args = [ [ "server"; "run" ] ]
      ; hidden_args = []
      })
    ~run_client_command:
      { executable; program_name = "keyval"; args = []; hidden_args = [] }
    ~process_env
    ()
  |> Rpc_test_harness.Config.create
;;

(* Same as [config], but runs the server with [--verbose], for tests that talk
   to it directly (e.g. via curl) rather than through the [keyval] cli, where
   seeing what the server is doing is useful when debugging. *)
let config_verbose =
  Rpc_test_harness.Config.rpc_discovery
    ~service_id:Keyval_rpc.For_service_discovery.service_id
    ~run_server_command:(fun ~temp_dir:_ ->
      { executable
      ; program_name = "keyval-server"
      ; args = [ [ "server"; "run" ]; [ "--verbose" ] ]
      ; hidden_args = []
      })
    ~run_client_command:
      { executable; program_name = "keyval"; args = []; hidden_args = [] }
    ~process_env
    ()
  |> Rpc_test_harness.Config.create
;;
