(*********************************************************************************)
(*  lunarpc - An opinionated, lightweight, HTTP/JSON RPC harness                 *)
(*  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: MIT                                                 *)
(*********************************************************************************)

(* @mdexp

   # Service_id

   Unit tests for [Rpc_discovery.Service_id]: the pair of an
   [App_name.t] and a [Service_name.t] identifying a service, with
   [equal]/[compare] following both fields lexicographically ([app_name]
   first). *)

let id ~app_name ~service_name : Rpc_discovery.Service_id.t =
  Rpc_discovery.Service_id.create
    ~app_name:(Rpc_discovery.App_name.v app_name)
    ~service_name:(Rpc_discovery.Service_name.v service_name)
;;

(* @mdexp

   ## [equal]

   Sanity-checks that [equal] actually discriminates values, rather than
   e.g. always returning [true] --- in particular, that it does compare
   both fields, not just one. *)

let%expect_test "equal" =
  let a = id ~app_name:"cr" ~service_name:"rpc" in
  require (Rpc_discovery.Service_id.equal a (id ~app_name:"cr" ~service_name:"rpc"));
  [%expect {||}];
  require (not (Rpc_discovery.Service_id.equal a (id ~app_name:"zz" ~service_name:"rpc")));
  [%expect {||}];
  require (not (Rpc_discovery.Service_id.equal a (id ~app_name:"cr" ~service_name:"zz")));
  [%expect {||}];
  ()
;;

(* @mdexp

   ## [compare]

   Lexicographic: [app_name] first, [service_name] only as a tie-breaker
   when [app_name] is equal. *)

let%expect_test "compare" =
  let test a b =
    print_dyn (Rpc_discovery.Service_id.compare a b |> Ordering.to_int |> Dyn.int)
  in
  let a = id ~app_name:"cr" ~service_name:"rpc" in
  test a (id ~app_name:"cr" ~service_name:"rpc");
  [%expect {| 0 |}];
  (* Same [app_name]: broken by [service_name]. *)
  test a (id ~app_name:"cr" ~service_name:"zz");
  [%expect {| -1 |}];
  test (id ~app_name:"cr" ~service_name:"zz") a;
  [%expect {| 1 |}];
  (* Different [app_name]: decided before [service_name] is even looked at,
     regardless of how [service_name] alone would compare. *)
  test a (id ~app_name:"zz" ~service_name:"aaa");
  [%expect {| -1 |}];
  ()
;;

(* @mdexp

   ## [to_dyn] *)

let%expect_test "to_dyn" =
  print_dyn (Rpc_discovery.Service_id.to_dyn (id ~app_name:"cr" ~service_name:"rpc"));
  [%expect {| { app_name = "cr"; service_name = "rpc" } |}];
  ()
;;
