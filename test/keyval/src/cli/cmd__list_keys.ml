(*********************************************************************************)
(*  lunarpc - An opinionated, lightweight, HTTP/JSON RPC harness                 *)
(*  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: MIT                                                 *)
(*********************************************************************************)

let main =
  Command.make
    ~summary:"Print the list of all known keys."
    ~readme:(fun () ->
      "Prints the set of all keys currently present in the server's in-memory database.")
    (let open Command.Std in
     let+ () = Log_cli.set_config ()
     and+ connection_config = Rpc_discovery.Connection_config.arg in
     let port =
       Rpc_discovery.Connection_config.port
         connection_config
         ~service_id:Keyval_rpc.For_service_discovery.service_id
     in
     let@ connection = Keyval_client.with_connection ~port in
     let keys = Keyval_client.list_keys connection in
     print_dyn (Dyn.set Keyval.Key.to_dyn keys);
     ())
;;
