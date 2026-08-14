(*********************************************************************************)
(*  lunarpc - An opinionated, lightweight, HTTP/JSON RPC harness                 *)
(*  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: MIT                                                 *)
(*********************************************************************************)

(* Some functions are copied from [Stdio.Out_channel] version [v0.17] which is
   released under MIT and may be found at [https://github.com/janestreet/stdio].

   See Stdio's LICENSE below:

   ----------------------------------------------------------------------------

   The MIT License

   Copyright (c) 2016--2024 Jane Street Group, LLC <opensource-contacts@janestreet.com>

   Permission is hereby granted, free of charge, to any person obtaining a copy
   of this software and associated documentation files (the "Software"), to deal
   in the Software without restriction, including without limitation the rights
   to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
   copies of the Software, and to permit persons to whom the Software is
   furnished to do so, subject to the following conditions:

   The above copyright notice and this permission notice shall be included in
   all copies or substantial portions of the Software.

   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
   OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
   SOFTWARE.

   ----------------------------------------------------------------------------

   When this is the case, we clearly indicate it next to the copied function. *)

include Stdlib.Out_channel

(* ---------------------------------------------------------------------------- *)
(* The following functions are copied from [Stdio.Out_channel] (MIT). See notice
   at the top of the file and project global notice for licensing information. *)

let create
      ?(binary = true)
      ?(append = false)
      ?(fail_if_exists = false)
      ?(perm = 0o666)
      file
  =
  let flags = [ Open_wronly; Open_creat ] in
  let flags = (if binary then Open_binary else Open_text) :: flags in
  let flags = (if append then Open_append else Open_trunc) :: flags in
  let flags = if fail_if_exists then Open_excl :: flags else flags in
  Stdlib.open_out_gen flags perm file
;;

let with_file ?binary ?append ?fail_if_exists ?perm file ~f =
  let t = create ?binary ?append ?fail_if_exists ?perm file in
  match f t with
  | v ->
    close t;
    v
  | exception e ->
    close_noerr t;
    raise e
;;

let newline t = output_string t "\n"

let output_line t line =
  output_string t line;
  newline t
;;

let write_all filename ~data = with_file filename ~f:(fun t -> output_string t data)

(* ---------------------------------------------------------------------------- *)
