(*********************************************************************************)
(*  lunarpc - An opinionated, lightweight, HTTP/JSON RPC harness                 *)
(*  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: MIT                                                 *)
(*********************************************************************************)

(* @mdexp

   # Multiple servers

   In this test we demonstrate that the testing API allows for running
   multiple servers in parallel, in case this is interesting for a
   particular test case.

   For the sake of the example here, we'll just run two servers and have a
   function to feed the keys from one server to the other.

   So it's easier to implement, we'll actually make use of the OCaml RPC
   interface for this, rather than pure cli. This way, this test can also
   serve as an example of mixing the RPC and cli interfaces in a test. *)

(* A util to push all bindings from server1 to server2. *)
let push_all_bindings ~connection1 ~connection2 =
  let keys = Keyval_client.list_keys connection1 in
  List.iter keys ~f:(fun key ->
    let value = Keyval_client.get connection1 ~key |> Option.get in
    Keyval_client.set connection2 ~key ~value ~owner:(Keyval.Owner.v "push_all_bindings"))
;;

(* A util to get all bindings, via multiple RPCs (this could also be served
   directly as an RPC, this is just for the sake of the example). *)
let all_bindings ~connection =
  let keys = Keyval_client.list_keys connection in
  List.map keys ~f:(fun key ->
    let value = Keyval_client.get connection ~key |> Option.get in
    key, value)
;;

let dyn_of_binding (key, value) =
  Dyn.record [ "key", Keyval.Key.to_dyn key; "value", Keyval.Value.to_dyn value ]
;;

let%expect_test "two servers" =
  let@ t = Rpc_test_harness.run in
  let@ { server = server1; client = cli1 } =
    Rpc_test_harness.with_server t ~config:Keyval_test.config
  in
  let@ { server = server2; client = cli2 } =
    Rpc_test_harness.with_server t ~config:Keyval_test.config
  in
  let@ connection1 = Rpc_test_harness.Server.with_connection server1 in
  let@ connection2 = Rpc_test_harness.Server.with_connection server2 in
  (* @mdexp ## Two empty servers

     At first, none of the servers have keys. *)
  cli1 [ [ "list-keys" ] ];
  (* @mdexp.snapshot { lang: "bash" } *)
  [%expect
    {|
    $ keyval list-keys
    set {}
    |}];
  cli2 [ [ "list-keys" ] ];
  (* @mdexp.snapshot { lang: "bash" } *)
  [%expect
    {|
    $ keyval list-keys
    set {}
    |}];
  (* @mdexp ## Populating the first server

     Let's populate server1 with a few keys. *)
  for i = 0 to 3 do
    cli1
      [ [ "set" ]; [ "--key"; Printf.sprintf "k%02d" i ]; [ "--value"; Int.to_string i ] ]
  done;
  cli1 [ [ "set" ]; [ "--key"; "foo" ]; [ "--value"; "bar" ] ];
  cli1 [ [ "list-keys" ] ];
  (* @mdexp.snapshot { lang: "bash" } *)
  [%expect
    {|
    $ keyval set --key k00 --value 0
    $ keyval set --key k01 --value 1
    $ keyval set --key k02 --value 2
    $ keyval set --key k03 --value 3
    $ keyval set --key foo --value bar
    $ keyval list-keys
    set { "foo"; "k00"; "k01"; "k02"; "k03" }
    |}];
  (* @mdexp ## Pushing bindings to the second server

     For the sake of the example, let's also have `foo` in server2.
     It will be replaced after we push all bindings from server1 to
     server2. *)
  cli2 [ [ "set" ]; [ "--key"; "foo" ]; [ "--value"; "OLD-VALUE" ] ];
  cli2 [ [ "set" ]; [ "--key"; "bar" ]; [ "--value"; "sna" ] ];
  (* @mdexp.snapshot { lang: "bash" } *)
  [%expect
    {|
    $ keyval set --key foo --value OLD-VALUE
    $ keyval set --key bar --value sna
    |}];
  (* @mdexp.code *)
  print_dyn (all_bindings ~connection:connection2 |> Dyn.list dyn_of_binding);
  [%expect {| [ { key = "bar"; value = "sna" }; { key = "foo"; value = "OLD-VALUE" } ] |}];
  (* @mdexp.end *)
  push_all_bindings ~connection1 ~connection2;
  [%expect {||}];
  (* @mdexp ## After the push

     After pushing, server2 has all the keys, and `foo` was
     overwritten with server1's value. *)
  cli2 [ [ "list-keys" ] ];
  (* @mdexp.snapshot { lang: "bash" } *)
  [%expect
    {|
    $ keyval list-keys
    set { "bar"; "foo"; "k00"; "k01"; "k02"; "k03" }
    |}];
  (* @mdexp.code *)
  print_dyn (all_bindings ~connection:connection2 |> Dyn.list dyn_of_binding);
  [%expect
    {|
    [ { key = "bar"; value = "sna" }
    ; { key = "foo"; value = "bar" }
    ; { key = "k00"; value = "0" }
    ; { key = "k01"; value = "1" }
    ; { key = "k02"; value = "2" }
    ; { key = "k03"; value = "3" }
    ]
    |}];
  (* @mdexp.end *)
  ()
;;
