(*********************************************************************************)
(*  lunarpc - An opinionated, lightweight, HTTP/JSON RPC harness                 *)
(*  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: MIT                                                 *)
(*********************************************************************************)

(* @mdexp

   # Stopping the server

   The `stop` RPC asks the server to stop. It responds successfully before
   actually shutting down (`Tiny_httpd.stop` "might not have an immediate
   effect"), so the caller of `stop` itself always gets a clean response.

   `Rpc_client.Connection.t` doesn't hold a live socket --- it's just a host,
   port, and caller, reused to issue a fresh HTTP request per call --- so it
   remains a perfectly well-typed value after the server is gone. The next
   *call* on it is what fails. *)

let%expect_test "stop" =
  let@ t = Rpc_test_harness.run in
  let@ { server; client = _ } =
    Rpc_test_harness.with_server t ~config:Keyval_test.config
  in
  let@ connection = Rpc_test_harness.Server.with_connection server in
  Keyval_client.set
    connection
    ~key:(Keyval.Key.v "foo")
    ~value:(Keyval.Value.v "bar")
    ~owner:(Keyval.Owner.v "test-user");
  (* @mdexp ## The stop call itself succeeds *)
  (* @mdexp.code *)
  Keyval_client.stop connection;
  [%expect {||}];
  (* @mdexp.end *)
  (* @mdexp ## Give the server a moment to actually shut down

     Then any further RPC on the same, still well-typed `connection` fails:
     there is no server left to answer it. Exactly how it fails --- refused
     outright, or reset mid-request while sending or while receiving ---
     depends on precisely when in the shutdown the call lands, so rather
     than pin down one of those, we poll until *some* failure shows up. *)
  (* @mdexp.code *)
  let rec wait_until_stopped ~deadline =
    match Keyval_client.get connection ~key:(Keyval.Key.v "foo") with
    | (_ : Keyval.Value.t option) ->
      if Float.( > ) (Unix.gettimeofday ()) deadline
      then failwith "Server did not stop within the deadline."
      else (
        Unix.sleepf 0.02;
        wait_until_stopped ~deadline)
    | exception _ -> ()
  in
  wait_until_stopped ~deadline:(Unix.gettimeofday () +. 5.);
  print_endline "Subsequent RPC call failed, as expected.";
  [%expect {| Subsequent RPC call failed, as expected. |}];
  (* @mdexp.end *)
  ()
;;
