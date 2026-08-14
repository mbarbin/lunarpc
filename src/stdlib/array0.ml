(*********************************************************************************)
(*  lunarpc - An opinionated, lightweight, HTTP/JSON RPC harness                 *)
(*  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: MIT                                                 *)
(*********************************************************************************)

include Stdlib.ArrayLabels

let create ~len a = make len a
let is_empty t = length t = 0
let sort t ~compare = sort t ~cmp:compare

let sorted_copy t ~compare =
  let t = copy t in
  sort t ~compare;
  t
;;

let filter_map t ~f =
  let r = ref [||] in
  let k = ref 0 in
  for i = 0 to length t - 1 do
    match f (unsafe_get t i) with
    | None -> ()
    | Some a ->
      if !k = 0 then r := create ~len:(length t) a;
      unsafe_set !r !k a;
      Stdlib.incr k
  done;
  if !k = length t then !r else if !k > 0 then sub !r ~pos:0 ~len:!k else [||]
;;

let filter t ~f = filter_map t ~f:(fun a -> if f a then Some a else None)
