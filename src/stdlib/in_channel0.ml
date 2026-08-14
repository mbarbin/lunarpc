(*********************************************************************************)
(*  lunarpc - An opinionated, lightweight, HTTP/JSON RPC harness                 *)
(*  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: MIT                                                 *)
(*********************************************************************************)

include Stdlib.In_channel

(* The following function is copied from [Stdio.In_channel] version [v0.17]
   which is released under MIT and may be found at
   [https://github.com/janestreet/stdio]. *)

let input_all t =
  (* We use 65536 because that is the size of OCaml's IO buffers. *)
  let chunk_size = 65536 in
  let buffer = Buffer.create chunk_size in
  let rec loop () =
    Buffer.add_channel buffer t chunk_size;
    loop ()
  in
  (try loop () with
   | End_of_file -> ());
  Buffer.contents buffer
;;

let read_all filename = with_open_text filename input_all
