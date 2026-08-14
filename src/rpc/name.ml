(*********************************************************************************)
(*  lunarpc - An opinionated, lightweight, HTTP/JSON RPC harness                 *)
(*  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: MIT                                                 *)
(*********************************************************************************)

let max_length = 64

let invariant s =
  let len = String.length s in
  len >= 1
  && len <= max_length
  && (match s.[0] with
      | 'a' .. 'z' -> true
      | _ -> false)
  && String.for_all s ~f:Char.is_alphanum
;;

include String_id.Make (struct
    let module_name = "Rpc.Name"
    let invariant = invariant
  end)
