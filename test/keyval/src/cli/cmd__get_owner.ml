(*********************************************************************************)
(*  lunarpc - An opinionated, lightweight, HTTP/JSON RPC harness                 *)
(*  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: MIT                                                 *)
(*********************************************************************************)

let main =
  Command.make
    ~summary:"Get the owner that last set a key's binding."
    ~readme:(fun () ->
      "Looks up who last set the binding for a key, via the caller supplied to `set \
       --as`. Fails with an error if no such key is currently set.")
    (let open Command.Std in
     let+ () = Log_cli.set_config ()
     and+ connection_config = Rpc_discovery.Connection_config.arg
     and+ key =
       Arg.named
         [ "key" ]
         (Param.validated_string (module Keyval.Key))
         ~docv:"KEY"
         ~doc:"The name of the key to look up the owner of."
     in
     let port =
       Rpc_discovery.Connection_config.port
         connection_config
         ~service_id:Keyval_rpc.For_service_discovery.service_id
     in
     let@ connection = Keyval_client.with_connection ~port in
     let owner =
       match Keyval_client.get_owner connection ~key with
       | Some { owner } -> owner
       | No_such_key ->
         let candidates =
           Keyval_client.list_keys connection |> List.map ~f:Keyval.Key.to_string
         in
         Err.raise
           ~hints:(Err.did_you_mean (Keyval.Key.to_string key) ~candidates)
           Pp.O.
             [ Pp.text "No such key " ++ Pp_tty.id (module Keyval.Key) key ++ Pp.text "."
             ]
     in
     print_dyn (owner |> Keyval.Owner.to_dyn))
;;
