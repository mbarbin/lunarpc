(*_********************************************************************************)
(*_  lunarpc - An opinionated, lightweight, HTTP/JSON RPC harness                 *)
(*_  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*_  SPDX-License-Identifier: MIT                                                 *)
(*_********************************************************************************)

val config : Rpc_test_harness.Config.t

(** Same as [config], but runs the server with [--verbose]. *)
val config_verbose : Rpc_test_harness.Config.t
