(*********************************************************************************)
(*  lunarpc - An opinionated, lightweight, HTTP/JSON RPC harness                 *)
(*  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: MIT                                                 *)
(*********************************************************************************)

module Connection = struct
  type t = Rpc_client.Connection.t
end

let with_connection ~port f = Rpc_client.with_connection ~port f

let call ?principal t spec ~request =
  match Rpc_client.call ?principal spec ~connection:t request with
  | Ok res -> res
  | Error err ->
    Err.raise [ Pp.text "RPC to lunarpc server failed."; Err.sexp (err |> Err.sexp_of_t) ]
;;

let get t ~key = call t (module Keyval_rpc.Get) ~request:key
let get_deprecated t ~key = call t (module Keyval_rpc.Get_v1) ~request:key
let get_owner t ~key = call t (module Keyval_rpc.Get_owner) ~request:key
let delete t ~key = call t (module Keyval_rpc.Delete) ~request:key
let list_keys t = call t (module Keyval_rpc.List_keys) ~request:()
let stop t = call t (module Keyval_rpc.Stop) ~request:()

let set t ~key ~value ~owner =
  let principal = Rpc.Principal.v (Keyval.Owner.to_string owner) in
  call
    ~principal
    t
    (module Keyval_rpc.Set_)
    ~request:{ Keyval_rpc.Set_.Request.key; value }
;;
