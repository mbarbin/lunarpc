(*********************************************************************************)
(*  lunarpc - An opinionated, lightweight, HTTP/JSON RPC harness                 *)
(*  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: MIT                                                 *)
(*********************************************************************************)

(* @mdexp

   # Service_name

   Unit tests for [Rpc_discovery.Service_name]'s validation: same
   invariant as [App_name](test__app_name.md) --- non-empty, at most 64
   characters, ASCII alphanumeric, ['-'], or ['_']. *)

let%expect_test "invalid" =
  let test str =
    match Rpc_discovery.Service_name.of_string str with
    | Ok service_name ->
      Printf.printf "Ok %s\n" (Rpc_discovery.Service_name.to_string service_name)
    | Error (`Msg m) -> Printf.printf "Error: %s\n" m
  in
  test "rpc";
  [%expect {| Ok rpc |}];
  test "";
  [%expect {| Error: "": invalid Rpc_discovery.Service_name |}];
  test "rpc/service";
  [%expect {| Error: "rpc/service": invalid Rpc_discovery.Service_name |}];
  test "rpc service";
  [%expect {| Error: "rpc service": invalid Rpc_discovery.Service_name |}];
  ()
;;

let%expect_test "v raises on an invalid service_name" =
  require_does_raise (fun () -> Rpc_discovery.Service_name.v "rpc/service");
  [%expect {| (Invalid_argument "\"rpc/service\": invalid Rpc_discovery.Service_name") |}];
  ()
;;
