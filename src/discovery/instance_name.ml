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
  && String.for_all s ~f:(fun c ->
    Char.is_alphanum c || Char.equal c '-' || Char.equal c '_')
;;

include String_id.Make (struct
    let module_name = "Rpc_discovery.Instance_name"
    let invariant = invariant
  end)
