(*********************************************************************************)
(*  lunarpc - An opinionated, lightweight, HTTP/JSON RPC harness                 *)
(*  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: MIT                                                 *)
(*********************************************************************************)

(* @mdexp

   # Malformed requests, and encoder/handler failures

   `lunarpc-server` responds to any RPC call whose request doesn't look like
   a well-formed lunarpc request --- missing or wrong content-type, or a body
   that isn't valid JSON --- with a `400` and a JSON error payload, before it
   even attempts to decode the request against the RPC's schema.

   It also catches exceptions raised further along: by the RPC's own request
   decoder, by the handler itself, or by the RPC's response encoder. Three
   dedicated RPCs --- `Fail`, `FailRequest`, `FailResponse` --- each fail at
   one of those three points on purpose, so we can see exactly how the
   server responds to each, instead of crashing.

   None of this is reachable through `Rpc_client` (it always sends
   well-formed requests), so here we talk to the server the way an arbitrary
   HTTP client would: with a plain `curl` POST. The server runs with
   `--verbose`, so its own log is available in
   `Rpc_test_harness.Server.stdout_path` if you need to debug this test. *)

let curl_post ~port ~route ?(headers = []) ~data () =
  (* Print the command as a human would type it, with the (non-deterministic)
     port replaced by a stable placeholder, before actually running it. *)
  let display_args =
    List.concat
      [ [ "curl"; "-X"; "POST" ]
      ; List.concat_map headers ~f:(fun header -> [ "-H"; Printf.sprintf "'%s'" header ])
      ; [ "-d"
        ; Printf.sprintf "'%s'" data
        ; Printf.sprintf "http://localhost:PORT/%s" route
        ]
      ]
  in
  Printf.printf "$ %s\n" (String.concat ~sep:" " display_args);
  let url = Printf.sprintf "http://localhost:%d/%s" port route in
  let exec_args =
    List.concat
      [ [ "curl"; "-s"; "-X"; "POST" ]
      ; List.concat_map headers ~f:(fun header -> [ "-H"; header ])
      ; [ "-d"; data; "-w"; "\n%{http_code}"; url ]
      ]
  in
  let command = exec_args |> List.map ~f:Filename.quote |> String.concat ~sep:" " in
  let ic = Unix.open_process_in command in
  let output = In_channel.input_all ic in
  (match Unix.close_process_in ic with
   | WEXITED 0 -> ()
   | WEXITED code -> Printf.printf "[curl exited with code %d]\n" code
   | WSIGNALED signal | WSTOPPED signal ->
     Printf.printf "[curl was killed by signal %d]\n" signal);
  match String.rsplit2 output ~on:'\n' with
  | Some (body, http_code) -> Printf.printf "HTTP %s\n%s\n" http_code body
  | None -> Printf.printf "%s\n" output
;;

let%expect_test "malformed requests" =
  let@ t = Rpc_test_harness.run in
  let@ { server; client = _ } =
    Rpc_test_harness.with_server t ~config:Keyval_test.config_verbose
  in
  let port = Rpc_test_harness.Server.listening_on_port server in
  (* @mdexp ## No content-type header

     `curl -d` sets `content-type: application/x-www-form-urlencoded` by
     default; an empty header value removes it. *)
  curl_post
    ~port
    ~route:"rpc/get/v1"
    ~headers:[ "content-type:" ]
    ~data:{|{"key":"foo"}|}
    ();
  (* @mdexp.snapshot { lang: "bash" } *)
  [%expect
    {|
    $ curl -X POST -H 'content-type:' -d '{"key":"foo"}' http://localhost:PORT/rpc/get/v1
    HTTP 400
    {"code":"malformed","msg":"no application type specified"}
    |}];
  (* @mdexp ## Wrong content-type *)
  curl_post
    ~port
    ~route:"rpc/get/v1"
    ~headers:[ "content-type: text/plain" ]
    ~data:{|{"key":"foo"}|}
    ();
  (* @mdexp.snapshot { lang: "bash" } *)
  [%expect
    {|
    $ curl -X POST -H 'content-type: text/plain' -d '{"key":"foo"}' http://localhost:PORT/rpc/get/v1
    HTTP 400
    {"code":"malformed","msg":"unknown application type","data":"text/plain"}
    |}];
  (* @mdexp ## Well-formed content-type, invalid JSON body *)
  curl_post
    ~port
    ~route:"rpc/get/v1"
    ~headers:[ "content-type: application/json" ]
    ~data:"not json"
    ();
  (* @mdexp.snapshot { lang: "bash" } *)
  [%expect
    {|
    $ curl -X POST -H 'content-type: application/json' -d 'not json' http://localhost:PORT/rpc/get/v1
    HTTP 400
    {"code":"malformed","msg":"could not decode json"}
    |}];
  (* @mdexp ## A well-formed request, for contrast

     Using `get`'s v2 route here, not v1: v1 raises on a missing key (see
     "RPC roundtrip: Get, v1"), which would turn this into another failure
     case instead of the clean success this section is meant to show. *)
  curl_post
    ~port
    ~route:"rpc/get/v2"
    ~headers:[ "content-type: application/json" ]
    ~data:{|{"key":"foo"}|}
    ();
  (* @mdexp.snapshot { lang: "bash" } *)
  [%expect
    {|
    $ curl -X POST -H 'content-type: application/json' -d '{"key":"foo"}' http://localhost:PORT/rpc/get/v2
    HTTP 200
    null
    |}];
  (* @mdexp ## A handler that raises

     `Fail`'s handler always raises; the server turns that into a `500`
     instead of crashing. *)
  curl_post
    ~port
    ~route:"rpc/fail/v1"
    ~headers:[ "content-type: application/json" ]
    ~data:"{}"
    ();
  (* @mdexp.snapshot { lang: "bash" } *)
  [%expect
    {|
    $ curl -X POST -H 'content-type: application/json' -d '{}' http://localhost:PORT/rpc/fail/v1
    HTTP 500
    {"code":"internal","msg":"handler failed","data":"Failure(\"Deliberate failure, for testing.\")"}
    |}];
  (* @mdexp ## A request decoder that raises

     `FailRequest`'s decoder always raises, even on a well-formed body ---
     an encoder bug, not a caller mistake. It surfaces identically to the
     "invalid JSON body" case above: the server can't tell the two apart,
     it only sees the decoder raise. *)
  curl_post
    ~port
    ~route:"rpc/failRequest/v1"
    ~headers:[ "content-type: application/json" ]
    ~data:"{}"
    ();
  (* @mdexp.snapshot { lang: "bash" } *)
  [%expect
    {|
    $ curl -X POST -H 'content-type: application/json' -d '{}' http://localhost:PORT/rpc/failRequest/v1
    HTTP 400
    {"code":"malformed","msg":"could not decode json"}
    |}];
  (* @mdexp ## A response encoder that raises

     `FailResponse`'s handler succeeds; only turning its result into JSON
     fails. This happens outside the handler's own try/with, so it falls
     through to the server's outermost catch-all --- a `500`, labeled the
     same as a handler failure above even though the handler itself never
     raised. *)
  curl_post
    ~port
    ~route:"rpc/failResponse/v1"
    ~headers:[ "content-type: application/json" ]
    ~data:"{}"
    ();
  (* @mdexp.snapshot { lang: "bash" } *)
  [%expect
    {|
    $ curl -X POST -H 'content-type: application/json' -d '{}' http://localhost:PORT/rpc/failResponse/v1
    HTTP 500
    {"code":"unknown","msg":"handler failed","data":"Failure(\"Deliberate response encode failure, for testing.\")"}
    |}];
  ()
;;
