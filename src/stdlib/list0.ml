(*********************************************************************************)
(*  lunarpc - An opinionated, lightweight, HTTP/JSON RPC harness                 *)
(*  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: MIT                                                 *)
(*********************************************************************************)

include Stdlib.ListLabels

let map t ~f = map ~f t

let dedup_and_sort t ~compare =
  let sorted = Stdlib.ListLabels.sort ~cmp:compare t in
  let rec dedup acc = function
    | [] -> rev acc
    | [ x ] -> rev (x :: acc)
    | x :: (y :: _ as rest) ->
      if compare x y = 0 then dedup acc rest else dedup (x :: acc) rest
  in
  dedup [] sorted
;;

let hd_exn = Stdlib.List.hd
