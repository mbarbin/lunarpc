(*********************************************************************************)
(*  lunarpc - An opinionated, lightweight, HTTP/JSON RPC harness                 *)
(*  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: MIT                                                 *)
(*********************************************************************************)

(* @mdexp

   # Call

   Unit tests for [Call.t]'s header-carried metadata: [to_headers] (sending
   side) and [create_with_headers] (receiving side). [create_with_headers]
   reads headers via a [get : string -> string option] accessor, which the
   server backs with its real transport headers; here we back it with a
   plain assoc list instead, so the receiving side can be exercised in
   isolation. *)

let get_of_headers headers key = List.assoc_opt key headers

(* @mdexp

   ## [to_headers]

   The transport headers carrying the call's metadata; empty when there is
   none. This does not encode [request] --- that's the RPC's JSON body,
   encoded separately via the spec's [request_encoder]. *)

let%expect_test "to_headers" =
  print_dyn (Dyn.list (Dyn.pair Dyn.string Dyn.string) (Rpc.Call.to_headers ()));
  [%expect {| [] |}];
  print_dyn
    (Dyn.list
       (Dyn.pair Dyn.string Dyn.string)
       (Rpc.Call.to_headers ~principal:(Rpc.Principal.v "alice") ()));
  [%expect {| [ ("x-rpc-principal", "alice") ] |}];
  ()
;;

(* @mdexp

   ## [create_with_headers]

   [create_with_headers request ~get] bundles the decoded [request] with the
   call's metadata, read from the request's transport headers via [get]. A
   header present but not a valid [Principal.t] is treated as absent. *)

let%expect_test "create_with_headers" =
  let test headers =
    let call = Rpc.Call.create_with_headers "payload" ~get:(get_of_headers headers) in
    print_dyn (Dyn.option Rpc.Principal.to_dyn (Rpc.Call.principal call));
    (* The request payload passes through untouched, regardless of headers. *)
    assert (String.equal (Rpc.Call.request call) "payload")
  in
  test [];
  [%expect {| None |}];
  test [ "content-type", "application/json" ];
  [%expect {| None |}];
  test [ "x-rpc-principal", "alice" ];
  [%expect {| Some "alice" |}];
  test [ "content-type", "application/json"; "x-rpc-principal", "bob" ];
  [%expect {| Some "bob" |}];
  (* Not a valid [Principal.t]: contains a space and an exclamation mark. *)
  test [ "x-rpc-principal", "not a principal!" ];
  [%expect {| None |}];
  test [ "x-rpc-principal", "" ];
  [%expect {| None |}];
  ()
;;

(* @mdexp

   ## Roundtrip

   [to_headers] followed by [create_with_headers] recovers the same
   principal. *)

let%expect_test "roundtrip" =
  let test principal =
    let headers = Rpc.Call.to_headers ?principal () in
    let call = Rpc.Call.create_with_headers () ~get:(get_of_headers headers) in
    print_dyn (Dyn.option Rpc.Principal.to_dyn (Rpc.Call.principal call))
  in
  test None;
  [%expect {| None |}];
  test (Some (Rpc.Principal.v "alice"));
  [%expect {| Some "alice" |}];
  ()
;;
