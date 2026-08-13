(*********************************************************************************)
(*  lunarpc - An opinionated, lightweight, HTTP/JSON RPC harness                 *)
(*  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: MIT                                                 *)
(*********************************************************************************)

(* @mdexp

   # RPC roundtrip: List keys

   Same roundtrip check as for [Get](test__get.md), applied to the
   `List_keys` RPC. This one takes no request payload (a `Unit` request),
   so no `~requests` need to be supplied explicitly --- only the generated
   cases are checked. *)

module List_keys = struct
  module Request = struct
    include Keyval_rpc.List_keys.Request

    let generator = Generator.return ()
  end

  module Response = struct
    include Keyval_rpc.List_keys.Response

    let generator =
      let open Generator.Syntax in
      let+ keys = Generator.list Keyval_generators.Key.generator in
      List.dedup_and_sort keys ~compare:(fun a b ->
        Keyval.Key.compare a b |> Ordering.to_int)
    ;;
  end

  let rpc = Keyval_rpc.List_keys.rpc
end

let%expect_test "roundtrip" =
  Rpc_quickcheck.run_exn (module List_keys);
  [%expect {||}];
  ()
;;

(* @mdexp

   ## Invalid json

   The response decoder validates two levels: the outer [{ keys: [...] }]
   shape, and then each element of the array. Either can fail
   independently. *)

let%expect_test "invalid request" =
  let test json =
    require_does_raise (fun () -> List_keys.rpc.request_encoder.of_json json)
  in
  test (`Int 42);
  [%expect {| (Json.Invalid_json "Expected object" 42) |}];
  ()
;;

let%expect_test "invalid response" =
  let test json =
    require_does_raise (fun () -> List_keys.rpc.response_encoder.of_json json)
  in
  test (`Int 42);
  [%expect {| (Json.Invalid_json "Expected object" 42) |}];
  test (`Assoc [ "keys", `String "not a list" ]);
  [%expect {| (Json.Invalid_json "Expected array for keys" "\"not a list\"") |}];
  test (`Assoc [ "keys", `List [ `Int 1 ] ]);
  [%expect {| (Json.Invalid_json "Expected object" 1) |}];
  test (`Assoc [ "keys", `List [ `Assoc [ "key", `String "" ] ] ]);
  [%expect {| (Invalid_argument "\"\": invalid key") |}];
  ()
;;

(* @mdexp

   ## Extra fields are ignored

   Both at the top level and on each element of [keys]. *)

let%expect_test "extra fields are ignored" =
  require
    (List_keys.Request.equal
       (List_keys.rpc.request_encoder.of_json (`Assoc [ "extra", `Int 1 ]))
       ());
  [%expect {||}];
  require
    (List_keys.Response.equal
       (List_keys.rpc.response_encoder.of_json
          (`Assoc
              [ "keys", `List [ `Assoc [ "key", `String "foo"; "extra", `Int 1 ] ]
              ; "extra", `Int 1
              ]))
       [ Keyval.Key.v "foo" ]);
  [%expect {||}];
  ()
;;

(* @mdexp

   ## [equal]

   Sanity-checks that [equal] actually discriminates values, rather than
   e.g. always returning [true] --- including that it is sensitive to
   the keys' order (it is plain positional list equality, not a set
   comparison). *)

let%expect_test "equal" =
  require (List_keys.Request.equal () ());
  [%expect {||}];
  let foo = Keyval.Key.v "foo"
  and bar = Keyval.Key.v "bar" in
  require (List_keys.Response.equal [] []);
  [%expect {||}];
  require (List_keys.Response.equal [ foo; bar ] [ foo; bar ]);
  [%expect {||}];
  require (not (List_keys.Response.equal [ foo; bar ] [ bar; foo ]));
  [%expect {||}];
  require (not (List_keys.Response.equal [ foo ] [ foo; bar ]));
  [%expect {||}];
  require (not (List_keys.Response.equal [ foo ] [ bar ]));
  [%expect {||}];
  ()
;;
