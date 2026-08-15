(*********************************************************************************)
(*  lunarpc - An opinionated, lightweight, HTTP/JSON RPC harness                 *)
(*  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: MIT                                                 *)
(*********************************************************************************)

(* @mdexp

   # RPC versioning: two independent handlers behind one name

   `get` has two versions registered side by side: v1 raises when the key
   is missing; v2 (the default, `Keyval_client.get`) returns `None`
   instead. They're separate handlers with separate routes (`rpc/get/v1`
   and `rpc/get/v2`) and separate response schemas --- bumping `version`
   doesn't migrate callers, it just lets both shapes coexist until v1's
   callers move off it.

   `Keyval_client.get_deprecated` (the v1 caller) carries OCaml's
   [@deprecated] attribute, so calling it below needs a local
   [@alert "-deprecated"] to silence the warning --- deliberately local,
   not a blanket file-level escape, so the one call this test exists to
   make is the only thing exempted. *)

let%expect_test "get v1 vs v2" =
  let@ t = Rpc_test_harness.run in
  let@ { server; client = keyval } =
    Rpc_test_harness.with_server t ~config:Keyval_test.config
  in
  (* @mdexp ## v2 (the default `get`), present or absent, never raises *)
  keyval [ [ "set" ]; [ "--key"; "foo" ]; [ "--value"; "bar" ] ];
  keyval [ [ "get" ]; [ "--key"; "foo" ] ];
  keyval [ [ "get" ]; [ "--key"; "unknown" ] ];
  (* @mdexp.snapshot { lang: "bash" } *)
  [%expect
    {|
    $ keyval set --key foo --value bar
    $ keyval get --key foo
    "bar"
    $ keyval get --key unknown
    Error: No value for key [unknown].
    [123]
    |}];
  let@ connection = Rpc_test_harness.Server.with_connection server in
  (* @mdexp ## v1, present, agrees with v2 *)
  (* @mdexp.code *)
  print_dyn
    (Keyval.Value.to_dyn
       ((Keyval_client.get_deprecated [@alert "-deprecated"])
          connection
          ~key:(Keyval.Key.v "foo")));
  [%expect {| "bar" |}];
  (* @mdexp.end *)
  (* @mdexp ## v1, absent, raises instead of returning `None` *)
  (* @mdexp.code *)
  (match
     (Keyval_client.get_deprecated [@alert "-deprecated"])
       connection
       ~key:(Keyval.Key.v "unknown")
   with
   | (_ : Keyval.Value.t) -> print_endline "unexpectedly succeeded"
   | exception _ -> print_endline "raised, as v1 does on a missing key");
  [%expect {| raised, as v1 does on a missing key |}];
  (* @mdexp.end *)
  ()
;;
