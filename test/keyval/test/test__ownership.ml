(*********************************************************************************)
(*  lunarpc - An opinionated, lightweight, HTTP/JSON RPC harness                 *)
(*  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: MIT                                                 *)
(*********************************************************************************)

(* @mdexp

   # Tracking who set a binding

   `set --as OWNER` records `OWNER` (an [Owner.t]: non-empty, alphanumeric,
   `-`, or `_`) as the caller that set a binding, attached to the request
   via `Rpc.Call.principal`. Every binding has an owner: the server requires one,
   and the cli defaults to the `KEYVAL_USER` env var, falling back to the
   current unix login. `get-owner` retrieves it later; it fails, the same
   way `get`/`delete` do, when the key doesn't exist. *)

let%expect_test "ownership" =
  let@ t = Rpc_test_harness.run in
  let@ { server = _; client = keyval } =
    Rpc_test_harness.with_server t ~config:Keyval_test.config
  in
  (* @mdexp ## Setting without `--as`

     Falls back to `KEYVAL_USER`, pinned to a stable value for this test
     suite via the server's environment. *)
  keyval [ [ "set" ]; [ "--key"; "foo" ]; [ "--value"; "bar" ] ];
  keyval [ [ "get-owner" ]; [ "--key"; "foo" ] ];
  (* @mdexp.snapshot { lang: "bash" } *)
  [%expect
    {|
    $ keyval set --key foo --value bar
    $ keyval get-owner --key foo
    "test-user"
    |}];
  (* @mdexp ## Setting with an owner *)
  keyval [ [ "set" ]; [ "--key"; "foo" ]; [ "--value"; "bar2" ]; [ "--as"; "alice" ] ];
  keyval [ [ "get-owner" ]; [ "--key"; "foo" ] ];
  (* @mdexp.snapshot { lang: "bash" } *)
  [%expect
    {|
    $ keyval set --key foo --value bar2 --as alice
    $ keyval get-owner --key foo
    "alice"
    |}];
  (* @mdexp ## Overwriting changes the owner *)
  keyval [ [ "set" ]; [ "--key"; "foo" ]; [ "--value"; "bar3" ]; [ "--as"; "bob" ] ];
  keyval [ [ "get-owner" ]; [ "--key"; "foo" ] ];
  (* @mdexp.snapshot { lang: "bash" } *)
  [%expect
    {|
    $ keyval set --key foo --value bar3 --as bob
    $ keyval get-owner --key foo
    "bob"
    |}];
  (* @mdexp ## An unknown key *)
  keyval [ [ "get-owner" ]; [ "--key"; "unknown" ] ];
  (* @mdexp.snapshot { lang: "bash" } *)
  [%expect
    {|
    $ keyval get-owner --key unknown
    Error: No such key [unknown].
    [123]
    |}];
  ()
;;
