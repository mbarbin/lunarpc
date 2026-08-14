(*********************************************************************************)
(*  lunarpc - An opinionated, lightweight, HTTP/JSON RPC harness                 *)
(*  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: MIT                                                 *)
(*********************************************************************************)

(* @mdexp

   # Via_file, through Listening_config / Connection_config

   [Via_file] (the file-based service discovery mechanics: creating the
   discovery directory, writing/reading the discovery file) isn't
   exposed directly --- these exercise it through the public
   [Listening_config.advertize] / [Connection_config.port] entry points
   that wrap it.

   The scratch root is anchored at the current working directory with a
   fixed name, rather than [Filename.temp_file]/[Filename.temp_dir]'s
   randomized paths: nothing here needs to print or compare that path,
   but it does need cleaning up on a machine-independent, predictable
   location. *)

let scratch_root =
  Absolute_path.v (Filename.concat (Sys.getcwd ()) "via_file_test_scratch")
;;

let rec remove_if_exists path =
  if Sys.file_exists path
  then
    if Sys.is_directory path
    then (
      Sys.readdir path
      |> Array.iter ~f:(fun name -> remove_if_exists (Filename.concat path name));
      Unix.rmdir path)
    else Sys.remove path
;;

let with_scratch_root ~f =
  let root = Absolute_path.to_string scratch_root in
  remove_if_exists root;
  Unix.mkdir root 0o755;
  Exn.protect ~f:(fun () -> f scratch_root) ~finally:(fun () -> remove_if_exists root)
;;

let listening_config root_directory : Rpc_discovery.Listening_config.t =
  { specification = Tcp { port = `Chosen_by_OS }
  ; discovery_via_file = { root_directory }
  }
;;

let connection_config root_directory : Rpc_discovery.Connection_config.t =
  Discovery_via_file { root_directory }
;;

let service_id =
  Rpc_discovery.Service_id.create
    ~app_name:(Rpc_discovery.App_name.v "app")
    ~service_name:(Rpc_discovery.Service_name.v "svc")
;;

let instance_name = Rpc_discovery.Instance_name.v "instance"

(* @mdexp

   ## Re-advertizing is idempotent

   The discovery directory already exists on a second [advertize] (e.g.
   the server restarted with the same identity) --- that must be a
   no-op, not an error. *)

let%expect_test "advertize is idempotent" =
  with_scratch_root ~f:(fun root_directory ->
    Rpc_discovery.Listening_config.advertize
      (listening_config root_directory)
      ~service_id
      ~instance_name
      ~port:4242;
    Rpc_discovery.Listening_config.advertize
      (listening_config root_directory)
      ~service_id
      ~instance_name
      ~port:4242;
    print_dyn
      (Dyn.int
         (Rpc_discovery.Connection_config.port
            (connection_config root_directory)
            ~service_id)));
  [%expect {| 4242 |}];
  ()
;;

(* @mdexp

   ## A file blocking a required directory is a real error

   If some segment of the discovery path exists but isn't a directory
   (here, [.app] is a plain file, standing in for e.g. leftover state
   from an unrelated process), [advertize] can't create what it needs
   underneath it and must raise --- rather than, say, silently
   proceeding or corrupting that file. *)

let%expect_test "advertize: blocked by a file where a directory should be" =
  with_scratch_root ~f:(fun root_directory ->
    Out_channel.write_all
      (Filename.concat (Absolute_path.to_string root_directory) ".app")
      ~data:"";
    let raised_err =
      match
        Rpc_discovery.Listening_config.advertize
          (listening_config root_directory)
          ~service_id
          ~instance_name
          ~port:4242
      with
      | () -> false
      | exception Err.E _ -> true
    in
    require raised_err);
  [%expect {||}];
  ()
;;
