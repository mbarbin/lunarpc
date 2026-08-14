(*********************************************************************************)
(*  lunarpc - An opinionated, lightweight, HTTP/JSON RPC harness                 *)
(*  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: MIT                                                 *)
(*********************************************************************************)

(* @mdexp

   # Discovery_file

   [Discovery_file.t] is a [{ port : int }] value persisted to disk as a
   small json envelope ([{"type":"Tcp","port":N}]), used for file-based
   service discovery: servers [save] it, clients [load] it. *)

(* A fixed relative name, rather than [Filename.temp_file] --- the latter's
   randomized name (and dune's sandboxed [TMPDIR]) would otherwise leak a
   non-reproducible path into the error messages exercised below. *)
let scratch_path = Fpath.v "discovery_file_test_scratch.json"

let with_scratch_file ~f =
  Exn.protect
    ~f:(fun () -> f scratch_path)
    ~finally:(fun () ->
      if Sys.file_exists (Fpath.to_string scratch_path)
      then Sys.remove (Fpath.to_string scratch_path))
;;

(* @mdexp

   ## Roundtrip

   [save] followed by [load] recovers the same port. *)

let%expect_test "roundtrip" =
  with_scratch_file ~f:(fun path ->
    Rpc_discovery.Discovery_file.save { port = 4242 } ~path;
    let { Rpc_discovery.Discovery_file.port } = Rpc_discovery.Discovery_file.load ~path in
    print_dyn (Dyn.int port));
  [%expect {| 4242 |}];
  ()
;;

(* @mdexp

   ## [Json_format]

   The "expert API": the on-disk shape itself. *)

let%expect_test "json format" =
  print_json (Rpc_discovery.Discovery_file.Json_format.to_json { port = 4242 });
  [%expect {| { "type": "Tcp", "port": 4242 } |}];
  ()
;;

let%expect_test "json format: extra fields are ignored" =
  let ({ port } : Rpc_discovery.Discovery_file.t) =
    Rpc_discovery.Discovery_file.Json_format.of_json
      (`Assoc [ "type", `String "Tcp"; "port", `Int 4242; "extra", `Bool true ])
  in
  print_dyn (Dyn.int port);
  [%expect {| 4242 |}];
  ()
;;

(* @mdexp

   ## [load] failure paths

   Three distinct things can go wrong when loading, each reported with
   its own message via {!Err.raise}: the file doesn't exist, its
   content isn't valid JSON, or it is valid JSON but not in the expected
   shape. [Err.For_test.protect] prints the resulting CLI-style error
   message. *)

let%expect_test "load: file does not exist" =
  Err.For_test.protect (fun () ->
    let (_ : Rpc_discovery.Discovery_file.t) =
      Rpc_discovery.Discovery_file.load
        ~path:(Fpath.v "/nonexistent/path/to/a/discovery/file")
    in
    ());
  [%expect
    {|
    File "/nonexistent/path/to/a/discovery/file", line 1, characters 0-0:
    Error: Failed to read discovery file:
    Sys_error("/nonexistent/path/to/a/discovery/file: No such file or directory")
    [123]
    |}];
  ()
;;

let%expect_test "load: invalid json" =
  with_scratch_file ~f:(fun path ->
    Out_channel.write_all (Fpath.to_string path) ~data:"not json";
    Err.For_test.protect (fun () ->
      let (_ : Rpc_discovery.Discovery_file.t) =
        Rpc_discovery.Discovery_file.load ~path
      in
      ()));
  [%expect
    {|
    File "discovery_file_test_scratch.json", line 1, characters 0-0:
    Error: Failed to parse JSON: Yojson__Common.Json_error("Line 1, bytes
    0-8:\nInvalid token 'not json'")
    [123]
    |}];
  ()
;;

let%expect_test "load: valid json, wrong shape" =
  with_scratch_file ~f:(fun path ->
    Out_channel.write_all (Fpath.to_string path) ~data:"{}";
    Err.For_test.protect (fun () ->
      let (_ : Rpc_discovery.Discovery_file.t) =
        Rpc_discovery.Discovery_file.load ~path
      in
      ()));
  [%expect
    {|
    File "discovery_file_test_scratch.json", line 1, characters 0-0:
    Error: Invalid discovery file format: Failure("Missing field: type")
    [123]
    |}];
  ()
;;

let%expect_test "load: valid json, wrong \"type\"" =
  with_scratch_file ~f:(fun path ->
    Out_channel.write_all (Fpath.to_string path) ~data:{|{"type":"Udp","port":4242}|};
    Err.For_test.protect (fun () ->
      let (_ : Rpc_discovery.Discovery_file.t) =
        Rpc_discovery.Discovery_file.load ~path
      in
      ()));
  [%expect
    {|
    File "discovery_file_test_scratch.json", line 1, characters 0-0:
    Error: Invalid discovery file format: Failure("Unknown type: Udp")
    [123]
    |}];
  ()
;;
