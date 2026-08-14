(*********************************************************************************)
(*  lunarpc - An opinionated, lightweight, HTTP/JSON RPC harness                 *)
(*  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: MIT                                                 *)
(*********************************************************************************)

(* @mdexp

   # Rpc_quickcheck catches a broken roundtrip

   Every other roundtrip chapter in this book demonstrates
   [Rpc_quickcheck.run_exn] passing --- which begs the question: would it
   actually notice if an RPC's JSON encoding were broken? [Off_by_one]
   answers that: its request decoder has a deliberate, minor bug ---
   [count] comes back one higher than it went in --- so [to_json] then
   [of_json] does not return the original value. [run_exn] generates
   many requests and checks exactly that property, so it should raise on
   the very first one it tries. *)

module Off_by_one = struct
  module Request = struct
    type t = { count : int }

    let equal t1 t2 = Int.equal t1.count t2.count

    let generator =
      Generator.map (Generator.int_uniform_inclusive 0 1_000) ~f:(fun count -> { count })
    ;;

    let to_json (t : t) : Json.t = `Assoc [ "count", `Int t.count ]

    (* Deliberate bug: decoding adds one to the count that was encoded. *)
    let of_json : Json.t -> t = function
      | `Assoc [ ("count", `Int count) ] -> { count = count + 1 }
      | json -> raise (Json.Invalid_json (json, "Expected a single count int field"))
    ;;

    let schema () =
      `Assoc
        [ "type", `String "object"
        ; "properties", `Assoc [ "count", `Assoc [ "type", `String "integer" ] ]
        ; "required", `List [ `String "count" ]
        ]
    ;;
  end

  module Response = struct
    type t = unit

    let equal () () = true
    let generator = Generator.return ()
    let to_json (_ : t) : Json.t = `Null

    let of_json : Json.t -> t = function
      | `Null -> ()
      | json -> raise (Json.Invalid_json (json, "Expected null"))
    ;;

    let schema () = `Assoc [ "type", `String "null" ]
  end

  let rpc : _ Rpc.t =
    Rpc.create
      ~name:(Rpc.Name.v "offByOne")
      ~version:1
      ~description:
        "A deliberately buggy RPC (its request decoder adds one to the count it \
         decodes), used to check that Rpc_quickcheck.run_exn actually catches a broken \
         roundtrip rather than passing vacuously."
      ~request_encoder:(Rpc.Encoder.make (module Request))
      ~response_encoder:(Rpc.Encoder.make (module Response))
      ()
  ;;
end

(* Backtraces embedded in a failure would make its expect block fragile
   (tied to line numbers elsewhere in the tree), so they are turned off
   for the duration of [f]. *)
let without_backtraces f =
  let was_recording = Printexc.backtrace_status () in
  Printexc.record_backtrace false;
  Exn.protect ~f ~finally:(fun () -> Printexc.record_backtrace was_recording)
;;

let%expect_test "run_exn catches the roundtrip bug" =
  without_backtraces (fun () ->
    require_does_raise (fun () -> Rpc_quickcheck.run_exn (module Off_by_one)));
  [%expect
    {|
    ("Base_quickcheck.Test.run: test failed" (input (Assoc ((count (Int 800)))))
     (error
      ( "(\"Values are not equal.\",\
       \n { v1 = Assoc [ (\"count\", Int 800) ]; v2 = Assoc [ (\"count\", Int 801) ] })")))
    |}];
  ()
;;

(* @mdexp

   ## Rpc_quickcheck catches a broken response roundtrip

   [Off_by_one] only breaks the request; [Response_off_by_one] mirrors
   it on the response, checking that [run_exn] catches a broken
   roundtrip on either side, not just the request. *)

module Response_off_by_one = struct
  module Request = struct
    type t = unit

    let equal () () = true
    let generator = Generator.return ()
    let to_json (_ : t) : Json.t = `Null

    let of_json : Json.t -> t = function
      | `Null -> ()
      | json -> raise (Json.Invalid_json (json, "Expected null"))
    ;;

    let schema () = `Assoc [ "type", `String "null" ]
  end

  module Response = struct
    type t = { count : int }

    let equal t1 t2 = Int.equal t1.count t2.count

    let generator =
      Generator.map (Generator.int_uniform_inclusive 0 1_000) ~f:(fun count -> { count })
    ;;

    let to_json (t : t) : Json.t = `Assoc [ "count", `Int t.count ]

    (* Deliberate bug: decoding adds one to the count that was encoded. *)
    let of_json : Json.t -> t = function
      | `Assoc [ ("count", `Int count) ] -> { count = count + 1 }
      | json -> raise (Json.Invalid_json (json, "Expected a single count int field"))
    ;;

    let schema () =
      `Assoc
        [ "type", `String "object"
        ; "properties", `Assoc [ "count", `Assoc [ "type", `String "integer" ] ]
        ; "required", `List [ `String "count" ]
        ]
    ;;
  end

  let rpc : _ Rpc.t =
    Rpc.create
      ~name:(Rpc.Name.v "responseOffByOne")
      ~version:1
      ~description:
        "A deliberately buggy RPC (its response decoder adds one to the count it \
         decodes), used to check that Rpc_quickcheck.run_exn catches a broken response \
         roundtrip, not just a broken request one."
      ~request_encoder:(Rpc.Encoder.make (module Request))
      ~response_encoder:(Rpc.Encoder.make (module Response))
      ()
  ;;
end

let%expect_test "run_exn catches the response roundtrip bug" =
  without_backtraces (fun () ->
    require_does_raise (fun () -> Rpc_quickcheck.run_exn (module Response_off_by_one)));
  [%expect
    {|
    ("Base_quickcheck.Test.run: test failed" (input (Assoc ((count (Int 800)))))
     (error
      ( "(\"Values are not equal.\",\
       \n { v1 = Assoc [ (\"count\", Int 800) ]; v2 = Assoc [ (\"count\", Int 801) ] })")))
    |}];
  ()
;;

(* @mdexp

   ## Rpc_quickcheck catches an RPC that lies about its own schema

   Roundtripping isn't the only property [run_exn] checks: it also
   validates every encoded value against the RPC's own advertised JSON
   Schema. [Request_schema_drift] roundtrips just fine (its request is
   [int], encoded and decoded consistently as a JSON int) --- the bug is
   that [schema] claims the request is a [string]. A schema like that is
   actively misleading to a client or a schema-to-code generator relying
   on it, so it's worth catching independently of the roundtrip check. *)

module Request_schema_drift = struct
  module Request = struct
    type t = int

    let equal = Int.equal
    let generator = Generator.int_uniform_inclusive 0 100
    let to_json (t : t) : Json.t = `Int t

    let of_json : Json.t -> t = function
      | `Int i -> i
      | json -> raise (Json.Invalid_json (json, "Expected int"))
    ;;

    (* Deliberate bug: this RPC's requests are plain ints, not strings. *)
    let schema () = `Assoc [ "type", `String "string" ]
  end

  module Response = struct
    type t = unit

    let equal () () = true
    let generator = Generator.return ()
    let to_json (_ : t) : Json.t = `Null

    let of_json : Json.t -> t = function
      | `Null -> ()
      | json -> raise (Json.Invalid_json (json, "Expected null"))
    ;;

    let schema () = `Assoc [ "type", `String "null" ]
  end

  let rpc : _ Rpc.t =
    Rpc.create
      ~name:(Rpc.Name.v "requestSchemaDrift")
      ~version:1
      ~description:
        "A deliberately buggy RPC (its schema claims the request is a string, but it's \
         actually an int), used to check that Rpc_quickcheck.run_exn validates encoded \
         values against their own schema, not just roundtrips."
      ~request_encoder:(Rpc.Encoder.make (module Request))
      ~response_encoder:(Rpc.Encoder.make (module Response))
      ()
  ;;
end

let%expect_test "run_exn catches request schema drift" =
  without_backtraces (fun () ->
    require_does_raise (fun () -> Rpc_quickcheck.run_exn (module Request_schema_drift)));
  [%expect
    {|
    7
    ("Base_quickcheck.Test.run: test failed" (input (Int 7))
     (error
      ( "(\"Json schema validation error.\",\
       \n { error =\
       \n     \"jsonschema validation failed with inline://schema\\n\\\
       \n     \\  at '': type mismatch\"\
       \n })")))
    |}];
  ()
;;

(* @mdexp

   Same bug, on the response side this time: the request is fine on
   every count, so [run_exn] gets all the way to validating the
   response's schema before catching it. *)

module Response_schema_drift = struct
  module Request = struct
    type t = unit

    let equal () () = true
    let generator = Generator.return ()
    let to_json (_ : t) : Json.t = `Null

    let of_json : Json.t -> t = function
      | `Null -> ()
      | json -> raise (Json.Invalid_json (json, "Expected null"))
    ;;

    let schema () = `Assoc [ "type", `String "null" ]
  end

  module Response = struct
    type t = int

    let equal = Int.equal
    let generator = Generator.int_uniform_inclusive 0 100
    let to_json (t : t) : Json.t = `Int t

    let of_json : Json.t -> t = function
      | `Int i -> i
      | json -> raise (Json.Invalid_json (json, "Expected int"))
    ;;

    (* Deliberate bug: this RPC's responses are plain ints, not strings. *)
    let schema () = `Assoc [ "type", `String "string" ]
  end

  let rpc : _ Rpc.t =
    Rpc.create
      ~name:(Rpc.Name.v "responseSchemaDrift")
      ~version:1
      ~description:
        "A deliberately buggy RPC (its schema claims the response is a string, but it's \
         actually an int), used to check that Rpc_quickcheck.run_exn validates the \
         response against its own schema too."
      ~request_encoder:(Rpc.Encoder.make (module Request))
      ~response_encoder:(Rpc.Encoder.make (module Response))
      ()
  ;;
end

let%expect_test "run_exn catches response schema drift" =
  without_backtraces (fun () ->
    require_does_raise (fun () -> Rpc_quickcheck.run_exn (module Response_schema_drift)));
  [%expect
    {|
    7
    ("Base_quickcheck.Test.run: test failed" (input (Int 7))
     (error
      ( "(\"Json schema validation error.\",\
       \n { error =\
       \n     \"jsonschema validation failed with inline://schema\\n\\\
       \n     \\  at '': type mismatch\"\
       \n })")))
    |}];
  ()
;;
