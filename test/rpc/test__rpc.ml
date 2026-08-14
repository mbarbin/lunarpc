(*********************************************************************************)
(*  lunarpc - An opinionated, lightweight, HTTP/JSON RPC harness                 *)
(*  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: MIT                                                 *)
(*********************************************************************************)

(* @mdexp

   # Rpc

   Unit tests for [Rpc]'s two operations: [create], which builds an RPC
   spec, and [route], which derives its URL path component. *)

module Null = struct
  type t = unit

  let of_json : Json.t -> t = function
    | `Null -> ()
    | json -> raise (Json.Invalid_json (json, "Expected null"))
  ;;

  let to_json (() : t) : Json.t = `Null
  let schema () = `Assoc [ "type", `String "null" ]
end

let create_exn ~version =
  Rpc.create
    ~name:(Rpc.Name.v "ping")
    ~version
    ~description:"A no-op RPC used to exercise [Rpc.create]'s validation."
    ~request_encoder:(Rpc.Encoder.make (module Null))
    ~response_encoder:(Rpc.Encoder.make (module Null))
    ()
;;

(* @mdexp

   ## [create]

   [create ~name ~version ~description ~request_encoder ~response_encoder ()]
   builds an RPC spec. Raises [Invalid_argument] if [version] is negative or
   null (versions start at [1]). *)

let%expect_test "version must be strictly positive" =
  let test version =
    match create_exn ~version with
    | (_ : _ Rpc.t) -> print_endline "ok"
    | exception Invalid_argument msg -> Printf.printf "Invalid_argument: %s\n" msg
  in
  test 1;
  [%expect {| ok |}];
  test 2;
  [%expect {| ok |}];
  test 0;
  [%expect {| Invalid_argument: Rpc0.create: version must be strictly positive, got 0 |}];
  test (-1);
  [%expect {| Invalid_argument: Rpc0.create: version must be strictly positive, got -1 |}];
  ()
;;

(* @mdexp

   ## [route]

   [route t] returns the URL path component for this RPC, without a leading
   slash.

   For example, if [t.name = Name.v "listRepos"] and [t.version = 1], this
   returns ["rpc/listRepos/v1"]. Versioning is local to each RPC: bump
   [version] when the request/response shape changes in an incompatible
   way. *)

let%expect_test "route" =
  print_endline (Rpc.route (create_exn ~version:1));
  [%expect {| rpc/ping/v1 |}];
  print_endline (Rpc.route (create_exn ~version:2));
  [%expect {| rpc/ping/v2 |}];
  ()
;;
