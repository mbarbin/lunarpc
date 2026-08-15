(*********************************************************************************)
(*  lunarpc - An opinionated, lightweight, HTTP/JSON RPC harness                 *)
(*  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: MIT                                                 *)
(*********************************************************************************)

(* @mdexp

   # Did-you-mean hints

   `get` and `delete` fail when the supplied key doesn't exist. Rather than
   leaving the user to guess a typo, the CLI looks up the current keys and
   attaches a "Did you mean ...?" hint via `Err.did_you_mean`, when one of
   them is close enough to what was typed. *)

let%expect_test "did you mean" =
  let@ t = Rpc_test_harness.run in
  let@ { server = _; client = keyval } =
    Rpc_test_harness.with_server t ~config:Keyval_test.config
  in
  keyval [ [ "set" ]; [ "--key"; "foo" ]; [ "--value"; "bar" ] ];
  keyval [ [ "set" ]; [ "--key"; "bar" ]; [ "--value"; "baz" ] ];
  (* @mdexp.snapshot { lang: "bash" } *)
  [%expect
    {|
    $ keyval set --key foo --value bar
    $ keyval set --key bar --value baz
    |}];
  (* @mdexp ## A close typo gets suggested *)
  keyval [ [ "get" ]; [ "--key"; "fooo" ] ];
  (* @mdexp.snapshot { lang: "bash" } *)
  [%expect
    {|
    $ keyval get --key fooo
    Error: No value for key [fooo].
    Hint: did you mean foo?
    [123]
    |}];
  keyval [ [ "delete" ]; [ "--key"; "fooo" ] ];
  (* @mdexp.snapshot { lang: "bash" } *)
  [%expect
    {|
    $ keyval delete --key fooo
    Error: Call to [delete] failed.
    No such key [fooo].
    Hint: did you mean foo?
    [123]
    |}];
  (* @mdexp ## No close match, no hint

     When nothing in the store is close enough to the supplied key, no hint
     is attached --- same behavior as before this feature. *)
  keyval [ [ "get" ]; [ "--key"; "zzz" ] ];
  (* @mdexp.snapshot { lang: "bash" } *)
  [%expect
    {|
    $ keyval get --key zzz
    Error: No value for key [zzz].
    [123]
    |}];
  ()
;;
