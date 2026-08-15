(*********************************************************************************)
(*  lunarpc - An opinionated, lightweight, HTTP/JSON RPC harness                 *)
(*  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: MIT                                                 *)
(*********************************************************************************)

(* @mdexp

   # Server restarts

   In this test we show that two invocations of `with_server` run distinct
   servers, and due to the particular nature of the `keyval` application,
   the state is not persisted across restarts (our example is only an
   in-memory database). *)

let%expect_test "testing server restart" =
  let@ t = Rpc_test_harness.run in
  (* @mdexp ## First server

     We start a first server, add a key, and read it back. *)
  let () =
    let@ { client = keyval; _ } =
      Rpc_test_harness.with_server t ~config:Keyval_test.config
    in
    keyval [ [ "list-keys" ] ];
    (* @mdexp.snapshot { lang: "bash" } *)
    [%expect
      {|
         $ keyval list-keys
         set {}
         |}];
    keyval [ [ "set" ]; [ "--key"; "foo" ]; [ "--value"; "bar" ] ];
    (* @mdexp.snapshot { lang: "bash" } *)
    [%expect {| $ keyval set --key foo --value bar |}];
    keyval [ [ "get" ]; [ "--key"; "foo" ] ];
    (* @mdexp.snapshot { lang: "bash" } *)
    [%expect
      {|
         $ keyval get --key foo
         "bar"
         |}];
    keyval [ [ "list-keys" ] ];
    (* @mdexp.snapshot { lang: "bash" } *)
    [%expect
      {|
         $ keyval list-keys
         set { "foo" }
         |}]
  in
  (* @mdexp ## Second server

     We then start a second, independent server: the key we set
     above is gone. *)
  let () =
    let@ { client = keyval; _ } =
      Rpc_test_harness.with_server t ~config:Keyval_test.config
    in
    keyval [ [ "list-keys" ] ];
    (* @mdexp.snapshot { lang: "bash" } *)
    [%expect
      {|
         $ keyval list-keys
         set {}
         |}];
    keyval [ [ "get" ]; [ "--key"; "foo" ] ];
    (* @mdexp.snapshot { lang: "bash" } *)
    [%expect
      {|
         $ keyval get --key foo
         Error: No value for key [foo].
         [123]
         |}]
  in
  ()
;;
