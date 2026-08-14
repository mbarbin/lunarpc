(*********************************************************************************)
(*  lunarpc - An opinionated, lightweight, HTTP/JSON RPC harness                 *)
(*  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: MIT                                                 *)
(*********************************************************************************)

(* @mdexp

   # Rpc_discovery

   Unit tests for the pure parts of [Connection_config] and
   [Listening_config]: [equal], [to_args], and [port] on the [Tcp] case.
   ([Connection_config.port]'s [Discovery_via_file] case and
   [Listening_config.advertize] go through the filesystem, via
   [Via_file]; not covered here.) *)

let root_a = Absolute_path.v "/tmp/lunarpc-a"
let root_b = Absolute_path.v "/tmp/lunarpc-b"

(* @mdexp

   ## [Discovery_via_file.equal] *)

let%expect_test "Discovery_via_file.equal" =
  require
    (Rpc_discovery.Discovery_via_file.equal
       { root_directory = root_a }
       { root_directory = root_a });
  [%expect {||}];
  require
    (not
       (Rpc_discovery.Discovery_via_file.equal
          { root_directory = root_a }
          { root_directory = root_b }));
  [%expect {||}];
  ()
;;

(* @mdexp

   ## [Connection_config]

   [equal] discriminates both across constructors ([Tcp] vs
   [Discovery_via_file]) and within each one. *)

let tcp port : Rpc_discovery.Connection_config.t = Tcp { host = `Localhost; port }

let via_file root : Rpc_discovery.Connection_config.t =
  Discovery_via_file { root_directory = root }
;;

let%expect_test "Connection_config.equal" =
  require (Rpc_discovery.Connection_config.equal (tcp 8080) (tcp 8080));
  [%expect {||}];
  require (not (Rpc_discovery.Connection_config.equal (tcp 8080) (tcp 9090)));
  [%expect {||}];
  require (Rpc_discovery.Connection_config.equal (via_file root_a) (via_file root_a));
  [%expect {||}];
  require
    (not (Rpc_discovery.Connection_config.equal (via_file root_a) (via_file root_b)));
  [%expect {||}];
  require (not (Rpc_discovery.Connection_config.equal (tcp 8080) (via_file root_a)));
  [%expect {||}];
  ()
;;

let%expect_test "Connection_config.to_args" =
  print_dyn (Dyn.list Dyn.string (Rpc_discovery.Connection_config.to_args (tcp 8080)));
  [%expect {| [ "--port"; "8080" ] |}];
  print_dyn
    (Dyn.list Dyn.string (Rpc_discovery.Connection_config.to_args (via_file root_a)));
  [%expect {| [ "--discovery-root"; "/tmp/lunarpc-a" ] |}];
  ()
;;

let%expect_test "Connection_config.port: Tcp ignores service_id" =
  let service_id =
    Rpc_discovery.Service_id.create
      ~app_name:(Rpc_discovery.App_name.v "app")
      ~service_name:(Rpc_discovery.Service_name.v "svc")
  in
  print_dyn (Dyn.int (Rpc_discovery.Connection_config.port (tcp 8080) ~service_id));
  [%expect {| 8080 |}];
  ()
;;

(* @mdexp

   ## [Listening_config] *)

let%expect_test "Listening_config.Specification.equal" =
  let open Rpc_discovery.Listening_config in
  require
    (Specification.equal (Tcp { port = `Chosen_by_OS }) (Tcp { port = `Chosen_by_OS }));
  [%expect {||}];
  require
    (Specification.equal (Tcp { port = `Supplied 8080 }) (Tcp { port = `Supplied 8080 }));
  [%expect {||}];
  require
    (not
       (Specification.equal
          (Tcp { port = `Supplied 8080 })
          (Tcp { port = `Supplied 9090 })));
  [%expect {||}];
  require
    (not
       (Specification.equal
          (Tcp { port = `Chosen_by_OS })
          (Tcp { port = `Supplied 8080 })));
  [%expect {||}];
  ()
;;

let%expect_test "Listening_config.equal" =
  let open Rpc_discovery.Listening_config in
  let t specification root : t =
    { specification; discovery_via_file = { root_directory = root } }
  in
  let chosen_by_os = Specification.Tcp { port = `Chosen_by_OS } in
  let supplied = Specification.Tcp { port = `Supplied 8080 } in
  require (equal (t chosen_by_os root_a) (t chosen_by_os root_a));
  [%expect {||}];
  require (not (equal (t chosen_by_os root_a) (t supplied root_a)));
  [%expect {||}];
  require (not (equal (t chosen_by_os root_a) (t chosen_by_os root_b)));
  [%expect {||}];
  ()
;;

let%expect_test "Listening_config.to_args" =
  let open Rpc_discovery.Listening_config in
  let t specification root : t =
    { specification; discovery_via_file = { root_directory = root } }
  in
  print_dyn (Dyn.list Dyn.string (to_args (t (Tcp { port = `Chosen_by_OS }) root_a)));
  [%expect {| [ "--port-chosen-by-os"; "--root-directory"; "/tmp/lunarpc-a" ] |}];
  print_dyn (Dyn.list Dyn.string (to_args (t (Tcp { port = `Supplied 8080 }) root_a)));
  [%expect {| [ "--port"; "8080"; "--root-directory"; "/tmp/lunarpc-a" ] |}];
  ()
;;

let%expect_test "Listening_config.port" =
  let open Rpc_discovery.Listening_config in
  let t specification : t =
    { specification; discovery_via_file = { root_directory = root_a } }
  in
  print_dyn (Dyn.int (port (t (Tcp { port = `Chosen_by_OS }))));
  [%expect {| 0 |}];
  print_dyn (Dyn.int (port (t (Tcp { port = `Supplied 8080 }))));
  [%expect {| 8080 |}];
  ()
;;
