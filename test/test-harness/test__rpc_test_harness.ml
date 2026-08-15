(*********************************************************************************)
(*  lunarpc - An opinionated, lightweight, HTTP/JSON RPC harness                 *)
(*  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: MIT                                                 *)
(*********************************************************************************)

(* @mdexp

   # Testing the test harness itself

   [Rpc_test_harness] is the library every other functional test in this
   suite is built on top of (see e.g.
   [the keyval CLI tests](../keyval/test/test__cli.md)); those exercise it
   thoroughly along its "happy path", but a few corners of its own API ---
   the parts that only matter for less common usage, like sharing a data
   directory across restarts, or cleaning up after a callback that raises
   --- aren't reached by any of them. This chapter targets those corners
   directly, reusing the `keyval` server/client executable as a real,
   already-built application to drive it with. *)

let executable = "./keyval.exe"

let config =
  Rpc_test_harness.Config.rpc_discovery
    ~service_id:Keyval_rpc.For_service_discovery.service_id
    ~run_server_command:(fun ~temp_dir:_ ->
      { Rpc_test_harness.Config.Process_command.executable
      ; program_name = "keyval-server"
      ; args = [ [ "server"; "run" ] ]
      ; hidden_args = []
      })
    ~run_client_command:
      { Rpc_test_harness.Config.Process_command.executable
      ; program_name = "keyval"
      ; args = []
      ; hidden_args = []
      }
    ()
  |> Rpc_test_harness.Config.create
;;

(* @mdexp

   ## [Process_env.build]

   With no overrides, [build] returns the ambient environment unchanged
   (as opposed to a copy filtered and re-concatenated, which would be
   observably the same set of bindings but is worth locking down as the
   actual code path taken). *)

let%expect_test "build with no overrides returns the ambient environment" =
  let sorted arr = arr |> Array.to_list |> List.sort ~compare:String.compare in
  require
    (List.equal
       ~eq:String.equal
       (sorted (Unix.environment ()))
       (sorted (Rpc_test_harness.Process_env.build Rpc_test_harness.Process_env.empty)));
  [%expect {||}]
;;

(* @mdexp

   ## [Config.rpc_discovery]: default [process_env]

   [?process_env] defaults to [Process_env.empty] when the caller doesn't
   supply one --- unlike every other test in this suite, which always
   pins down a [KEYVAL_USER] override. *)

let%expect_test "process_env defaults to empty" =
  let config_without_override =
    Rpc_test_harness.Config.rpc_discovery
      ~service_id:Keyval_rpc.For_service_discovery.service_id
      ~run_server_command:(fun ~temp_dir:_ ->
        { Rpc_test_harness.Config.Process_command.executable
        ; program_name = "keyval-server"
        ; args = [ [ "server"; "run" ] ]
        ; hidden_args = []
        })
      ~run_client_command:
        { Rpc_test_harness.Config.Process_command.executable
        ; program_name = "keyval"
        ; args = []
        ; hidden_args = []
        }
      ()
  in
  let module C = (val config_without_override : Rpc_test_harness.Config.S) in
  let sorted arr = arr |> Array.to_list |> List.sort ~compare:String.compare in
  require
    (List.equal
       ~eq:String.equal
       (sorted (Unix.environment ()))
       (sorted (Rpc_test_harness.Process_env.build C.process_env)));
  [%expect {||}]
;;

(* @mdexp

   ## [persistent_data_dir], shared across two [with_server] calls

   As documented on [persistent_data_dir], its result can be threaded
   through [?data_dir] to successive [with_server] calls so they share
   the same on-disk service-discovery root --- the piece of state
   [with_server] otherwise reallocates fresh every time. `keyval` itself
   is an in-memory store (see
   [server restarts](../keyval/test/test__server_restart.md)), so this
   doesn't demonstrate persisted key/value state, but it does show two
   independent servers can be started, one after the other, sharing the
   directory a [Data_dir.t] hands out. *)

let%expect_test "persistent_data_dir is reused across restarts" =
  let@ t = Rpc_test_harness.run in
  let data_dir = Rpc_test_harness.persistent_data_dir t in
  let root_directory = Rpc_test_harness.Data_dir.root_directory data_dir in
  print_dyn (Dyn.bool (Sys.is_directory (Absolute_path.to_string root_directory)));
  [%expect {| true |}];
  let () =
    let@ { client = keyval; _ } = Rpc_test_harness.with_server t ~data_dir ~config in
    keyval [ [ "list-keys" ] ]
  in
  [%expect
    {|
    $ keyval list-keys
    set {}
    |}];
  let () =
    let@ { client = keyval; _ } = Rpc_test_harness.with_server t ~data_dir ~config in
    keyval [ [ "list-keys" ] ]
  in
  [%expect
    {|
    $ keyval list-keys
    set {}
    |}]
;;

(* @mdexp

   ## [Server.pid], [Server.stdout_path], [Server.stderr_path]

   Once a server is up, these expose enough to debug it out-of-band: a
   pid to attach a debugger to, and the paths the harness redirected its
   stdout/stderr into (both created up front, so they exist as soon as
   the server does). *)

let%expect_test "server accessors" =
  let@ t = Rpc_test_harness.run in
  let@ { server; client = _ } = Rpc_test_harness.with_server t ~config in
  print_dyn (Dyn.bool (Rpc_test_harness.Server.pid server > 0));
  [%expect {| true |}];
  print_dyn (Dyn.bool (Sys.file_exists (Rpc_test_harness.Server.stdout_path server)));
  [%expect {| true |}];
  print_dyn (Dyn.bool (Sys.file_exists (Rpc_test_harness.Server.stderr_path server)));
  [%expect {| true |}]
;;

(* @mdexp

   ## Wrapping: an invocation that starts with a flag

   [run_client]'s cram-style header keeps the first argument group glued
   to the program name only when that group doesn't itself start with a
   flag (see [multi-line grouping](../keyval/test/test__args_groups.md)
   for the case where it does get glued). An empty argument list takes
   the same branch: there's no first group to glue anything to. *)

let%expect_test "an empty invocation doesn't get merged into the program name" =
  let@ t = Rpc_test_harness.run in
  let@ { client = keyval; _ } = Rpc_test_harness.with_server t ~config in
  keyval [];
  [%expect
    {|
    $ keyval
    keyval: required COMMAND name is missing, must be one of 'delete', 'get', 'get-owner', 'list-keys', 'server', 'set' or 'validate-key'.
    Usage: keyval COMMAND …
    Try 'keyval --help' for more information.
    [124]
    |}]
;;

(* @mdexp

   ## The server is torn down even when the callback raises

   [with_server]'s normal exit path ([graceful_shutdown]) always sends
   the server [SIGTERM] itself; the fallback path (its [~finally]) only
   needs to do that when the callback never got there --- e.g. because it
   raised. This checks the exception still propagates, and that the
   fallback path doesn't itself error out tearing the server down. *)

let%expect_test "with_server tears the server down when the callback raises" =
  let@ t = Rpc_test_harness.run in
  require_does_raise (fun () ->
    Rpc_test_harness.with_server t ~config (fun (_ : Rpc_test_harness.With_server.t) ->
      failwith "boom from the callback"));
  [%expect {| (Failure "boom from the callback") |}]
;;

(* @mdexp

   ## A client killed by a signal is reported, not silently dropped

   [run_client] runs the server's own [run_client_command] to build the
   client's [Config.Process_command.t] --- here it's swapped out for one
   that sends itself [SIGTERM], to reach the branch of [run_client] that
   handles a client that never got to exit normally. *)

let self_signaling_client_config =
  Rpc_test_harness.Config.rpc_discovery
    ~service_id:Keyval_rpc.For_service_discovery.service_id
    ~run_server_command:(fun ~temp_dir:_ ->
      { Rpc_test_harness.Config.Process_command.executable
      ; program_name = "keyval-server"
      ; args = [ [ "server"; "run" ] ]
      ; hidden_args = []
      })
    ~run_client_command:
      { Rpc_test_harness.Config.Process_command.executable = "/bin/sh"
      ; program_name = "sh"
      ; args = []
      ; hidden_args = [ "-c"; "kill -TERM $$" ]
      }
    ()
  |> Rpc_test_harness.Config.create
;;

let%expect_test "a client killed by a signal is reported" =
  let@ t = Rpc_test_harness.run in
  let@ { client; _ } =
    Rpc_test_harness.with_server t ~config:self_signaling_client_config
  in
  client ~offline:true [];
  [%expect
    {|
    $ sh
    Client killed by signal -11
    |}]
;;

(* @mdexp

   ## Tearing down a server that's already gone doesn't itself raise

   If the callback raises after the server process has already exited
   and been reaped by someone else (a crash, say), [with_server]'s
   fallback teardown still has to run --- and must tolerate both
   [Unix.kill] and [Unix.waitpid] failing against a pid that no longer
   exists, rather than masking the callback's own exception with one of
   its own. *)

let%expect_test "tearing down an already-gone server doesn't raise" =
  let@ t = Rpc_test_harness.run in
  require_does_raise (fun () ->
    Rpc_test_harness.with_server t ~config (fun { server; _ } ->
      let pid = Rpc_test_harness.Server.pid server in
      Unix.kill pid Sys.sigkill;
      ignore (Unix.waitpid [] pid : int * Unix.process_status);
      failwith "boom after the server is already gone"));
  [%expect {| (Failure "boom after the server is already gone") |}]
;;
