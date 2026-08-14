(*********************************************************************************)
(*  lunarpc - An opinionated, lightweight, HTTP/JSON RPC harness                 *)
(*  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: MIT                                                 *)
(*********************************************************************************)

(* @mdexp

   # RPC roundtrip: Get owner

   Same roundtrip check as for [Get](test__get.md), applied to the
   `Get_owner` RPC. *)

module Get_owner = struct
  module Request = struct
    include Keyval_rpc.Get_owner.Request

    let generator = Keyval_generators.Key.generator
  end

  module Response = struct
    include Keyval_rpc.Get_owner.Response

    let generator =
      let open Generator.Syntax in
      Generator.union
        [ (let+ owner = Keyval_generators.Owner.generator in
           Some { owner })
        ; Generator.return No_such_key
        ]
    ;;
  end

  let rpc = Keyval_rpc.Get_owner.rpc
end

let%expect_test "roundtrip" =
  Rpc_quickcheck.run_exn (module Get_owner) ~requests:[ Keyval.Key.v "foo" ];
  [%expect {||}];
  ()
;;

(* @mdexp

   ## Invalid json

   Same shape-error coverage as [Get](test__get.md) for the request; the
   response additionally rejects a well-shaped [owner] that fails
   [Keyval.Owner]'s own invariant, as [Invalid_argument]. *)

let%expect_test "invalid request" =
  let test json =
    require_does_raise (fun () -> Get_owner.rpc.request_encoder.of_json json)
  in
  test (`Int 42);
  [%expect {| (Json.Invalid_json "Expected object" 42) |}];
  test (`Assoc [ "key", `String "" ]);
  [%expect {| (Invalid_argument "\"\": invalid key") |}];
  ()
;;

let%expect_test "invalid response" =
  let test json =
    require_does_raise (fun () -> Get_owner.rpc.response_encoder.of_json json)
  in
  test (`Int 42);
  [%expect {| (Json.Invalid_json "Expected object or null" 42) |}];
  test (`Assoc [ "owner", `Int 1 ]);
  [%expect {| (Json.Invalid_json "Expected string for owner" 1) |}];
  test (`Assoc [ "owner", `String "" ]);
  [%expect {| (Invalid_argument "\"\": invalid owner") |}];
  ()
;;

(* @mdexp

   ## Extra fields are ignored *)

let%expect_test "extra fields are ignored" =
  require
    (Get_owner.Request.equal
       (Get_owner.rpc.request_encoder.of_json
          (`Assoc [ "key", `String "foo"; "extra", `Int 1 ]))
       (Keyval.Key.v "foo"));
  [%expect {||}];
  require
    (Get_owner.Response.equal
       (Get_owner.rpc.response_encoder.of_json
          (`Assoc [ "owner", `String "alice"; "extra", `Int 1 ]))
       (Some { owner = Keyval.Owner.v "alice" }));
  [%expect {||}];
  ()
;;

(* @mdexp

   ## [equal]

   Sanity-checks that [equal] actually discriminates values, rather than
   e.g. always returning [true]. *)

let%expect_test "equal" =
  require (Get_owner.Request.equal (Keyval.Key.v "foo") (Keyval.Key.v "foo"));
  [%expect {||}];
  require (not (Get_owner.Request.equal (Keyval.Key.v "foo") (Keyval.Key.v "bar")));
  [%expect {||}];
  let some_alice : Get_owner.Response.t = Some { owner = Keyval.Owner.v "alice" } in
  let some_bob : Get_owner.Response.t = Some { owner = Keyval.Owner.v "bob" } in
  require (Get_owner.Response.equal some_alice some_alice);
  [%expect {||}];
  require (not (Get_owner.Response.equal some_alice some_bob));
  [%expect {||}];
  require (Get_owner.Response.equal No_such_key No_such_key);
  [%expect {||}];
  require (not (Get_owner.Response.equal some_alice No_such_key));
  [%expect {||}];
  ()
;;
