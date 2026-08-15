(*********************************************************************************)
(*  lunarpc - An opinionated, lightweight, HTTP/JSON RPC harness                 *)
(*  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: MIT                                                 *)
(*********************************************************************************)

let main =
  Command.group
    ~summary:"Keyval is a key=value in-memory store served over gRPCs."
    [ "delete", Cmd__delete.main
    ; "get", Cmd__get.main
    ; "get-owner", Cmd__get_owner.main
    ; "list-keys", Cmd__list_keys.main
    ; "set", Cmd__set.main
    ; "server", Cmd__server.main
    ; "validate-key", Cmd__validate_key.main
    ]
;;
