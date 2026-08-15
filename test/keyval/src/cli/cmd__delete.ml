(*********************************************************************************)
(*  lunarpc - An opinionated, lightweight, HTTP/JSON RPC harness                 *)
(*  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: MIT                                                 *)
(*********************************************************************************)

let main =
  Command.make
    ~summary:"Delete a binding."
    ~readme:(fun () ->
      "Deletes the binding for the given key from the server's in-memory database, if \
       one exists. Fails with an error if no such key is currently set.")
    (let open Command.Std in
     let+ () = Log_cli.set_config ()
     and+ connection_config = Rpc_discovery.Connection_config.arg
     and+ key =
       Arg.named
         [ "key" ]
         (Param.validated_string (module Keyval.Key))
         ~docv:"KEY"
         ~doc:"The name of the key to delete."
     in
     let port =
       Rpc_discovery.Connection_config.port
         connection_config
         ~service_id:Keyval_rpc.For_service_discovery.service_id
     in
     let@ connection = Keyval_client.with_connection ~port in
     match Keyval_client.delete connection ~key with
     | Deleted -> ()
     | No_such_key ->
       let candidates =
         Keyval_client.list_keys connection |> List.map ~f:Keyval.Key.to_string
       in
       Err.raise
         ~hints:(Err.did_you_mean (Keyval.Key.to_string key) ~candidates)
         Pp.O.
           [ Pp.text "Call to "
             ++ Pp_tty.kwd (module String) "delete"
             ++ Pp.text " failed."
           ; Pp.text "No such key " ++ Pp_tty.id (module Keyval.Key) key ++ Pp.text "."
           ])
;;
