(*********************************************************************************)
(*  lunarpc - An opinionated, lightweight, HTTP/JSON RPC harness                 *)
(*  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: MIT                                                 *)
(*********************************************************************************)

(* @mdexp

   # Validating keys

   In this test we show how to use a client command that doesn't connect to the
   running server (offline mode). *)

let%expect_test "offline" =
  let@ t = Rpc_test_harness.run in
  let@ { server = _; client = keyval } =
    Rpc_test_harness.with_server t ~config:Keyval_test.config
  in
  (* @mdexp ## Connected by default

     By default, `Rpc_test_harness` adds to all commands invocation
     the necessary parameters to find the running server and connect to it.
     That's what happens below, when you list the known keys. *)
  keyval [ [ "list-keys" ] ];
  (* @mdexp.snapshot { lang: "bash" } *)
  [%expect
    {|
    $ keyval list-keys
    set {}
    |}];
  (* @mdexp ## A command with nothing to connect to

     Now, let's say you're trying to use a command that doesn't
     connect to the server. It would normally not expect any of the
     command line parameters related to service discovery. *)
  keyval [ [ "validate-key"; "my-key" ] ];
  (* @mdexp.snapshot { lang: "bash" } *)
  [%expect
    {|
    $ keyval validate-key my-key
    keyval: unknown option '--port'.
    Usage: keyval validate-key [OPTION]… KEY
    Try 'keyval validate-key --help' or 'keyval --help' for more information.
    [124]
    |}];
  (* @mdexp ## Opting out with `~offline:true`

     This is what the `~offline:true` parameter is about. Let's
     demonstrate it below --- starting with the command's own `--help`,
     which confirms it doesn't take any of the connection-related
     options. *)
  keyval ~offline:false [ [ "validate-key"; "--help=plain" ] ];
  (* @mdexp.snapshot { lang: "bash" } *)
  [%expect
    {|
    $ keyval validate-key --help=plain
    NAME
           keyval-validate-key - Verify the syntactic validity of a provided key.

    SYNOPSIS
           keyval validate-key [OPTION]… KEY

           This command performs a static validation of the key and does not
           require a connection to a running server.

    ARGUMENTS
           KEY (required)
               The key to validate.

    COMMON OPTIONS
           --help[=FMT] (default=auto)
               Show this help in format FMT. The value FMT must be one of auto,
               pager, groff or plain. With auto, the format is pager or plain
               whenever the TERM env var is dumb or undefined.

           --version
               Show version information.

    EXIT STATUS
           keyval validate-key exits with:

           0   on success.

           123 on indiscriminate errors reported on standard error.

           124 on command line parsing errors.

           125 on unexpected internal errors (bugs).

    SEE ALSO
           keyval(1)
    |}];
  (* @mdexp With `~offline:true`, the command runs without any connection
     parameters at all --- and, being an offline command, still performs
     its validation. An invalid key is rejected: *)
  keyval ~offline:true [ [ "validate-key"; "my-key" ] ];
  (* @mdexp.snapshot { lang: "bash" } *)
  [%expect
    {|
    $ keyval validate-key my-key
    Error: "my-key": invalid key
    [123]
    |}];
  (* @mdexp while a valid one is accepted silently. *)
  keyval ~offline:true [ [ "validate-key"; "my_key" ] ];
  (* @mdexp.snapshot { lang: "bash" } *)
  [%expect {| $ keyval validate-key my_key |}];
  (* @mdexp ## `~offline:true` on a command that does need a server

     If you're trying to use `~offline:true` with a command that
     actually does need to connect to the server, you'll be left with
     whatever connection specification is chosen by default. In this
     application, this is `localhost:8080`, which is not an address where
     a keyval server is listening during the tests. *)
  keyval ~offline:true [ [ "list-keys" ] ];
  (* @mdexp.snapshot { lang: "bash" } *)
  [%expect
    {|
    $ keyval list-keys
    Error: Service_discovery: no server found.
    { service_id = { app_name = "keyval"; service_name = "rpc" } }
    [123]
    |}];
  ()
;;
