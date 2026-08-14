(*********************************************************************************)
(*  lunarpc - An opinionated, lightweight, HTTP/JSON RPC harness                 *)
(*  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: MIT                                                 *)
(*********************************************************************************)

(* @mdexp

   # Instance_name

   Unit tests for [Rpc_discovery.Instance_name]'s validation: same
   invariant as [App_name](test__app_name.md) --- non-empty, at most 64
   characters, ASCII alphanumeric, ['-'], or ['_']. *)

let%expect_test "invalid" =
  let test str =
    match Rpc_discovery.Instance_name.of_string str with
    | Ok instance_name ->
      Printf.printf "Ok %s\n" (Rpc_discovery.Instance_name.to_string instance_name)
    | Error (`Msg m) -> Printf.printf "Error: %s\n" m
  in
  test "server";
  [%expect {| Ok server |}];
  test "";
  [%expect {| Error: "": invalid rpc_discovery.Instance_name |}];
  test "server.1";
  [%expect {| Error: "server.1": invalid rpc_discovery.Instance_name |}];
  ()
;;

let%expect_test "v raises on an invalid instance_name" =
  require_does_raise (fun () -> Rpc_discovery.Instance_name.v "server.1");
  [%expect {| (Invalid_argument "\"server.1\": invalid rpc_discovery.Instance_name") |}];
  ()
;;
