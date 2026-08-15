(*********************************************************************************)
(*  lunarpc - An opinionated, lightweight, HTTP/JSON RPC harness                 *)
(*  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: MIT                                                 *)
(*********************************************************************************)

(* @mdexp

   # Connecting over TCP

   In this test we connect to the server using explicitly the tcp option
   rather than via a unix socket.

   In practice for now this doesn't change anything since unix sockets are
   not supported. *)

let%expect_test "using tcp" =
  let@ t = Rpc_test_harness.run in
  let@ { server; client = keyval } =
    Rpc_test_harness.with_server t ~config:Keyval_test.config ~sockaddr_kind:Tcp_localhost
  in
  (* @mdexp ## Via the cli

     First, let's store a binding to the store. *)
  keyval [ [ "set" ]; [ "--key"; "foo" ]; [ "--value"; "bar" ] ];
  keyval [ [ "get" ]; [ "--key"; "foo" ] ];
  (* @mdexp.snapshot { lang: "bash" } *)
  [%expect
    {|
    $ keyval set --key foo --value bar
    $ keyval get --key foo
    "bar"
    |}];
  (* @mdexp ## Via the OCaml client

     Now let's access that binding using the RPC api. *)
  let@ connection = Rpc_test_harness.Server.with_connection server in
  (* @mdexp.code *)
  let data = Keyval_client.get connection ~key:(Keyval.Key.v "foo") in
  print_dyn (data |> Dyn.option Keyval.Value.to_dyn);
  [%expect {| Some "bar" |}];
  (* @mdexp.end *)
  ()
;;
