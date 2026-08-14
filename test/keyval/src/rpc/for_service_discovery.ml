(*********************************************************************************)
(*  lunarpc - An opinionated, lightweight, HTTP/JSON RPC harness                 *)
(*  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: MIT                                                 *)
(*********************************************************************************)

let app_name = Rpc_discovery.App_name.v "keyval"
let service_name = Rpc_discovery.Service_name.v "rpc"
let service_id = Rpc_discovery.Service_id.create ~app_name ~service_name
