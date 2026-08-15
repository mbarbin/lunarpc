(*********************************************************************************)
(*  lunarpc - An opinionated, lightweight, HTTP/JSON RPC harness                 *)
(*  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: MIT                                                 *)
(*********************************************************************************)

let main =
  Command.make
    ~summary:"Get the value attached to a key."
    ~readme:(fun () ->
      "Looks up the value currently associated with a key on the server. Fails with an \
       error if no value is set for that key.")
    (let open Command.Std in
     let+ () = Log_cli.set_config ()
     and+ connection_config = Rpc_discovery.Connection_config.arg
     and+ key =
       Arg.named
         [ "key" ]
         (Param.validated_string (module Keyval.Key))
         ~docv:"KEY"
         ~doc:"The name of the key to lookup."
     in
     let port =
       Rpc_discovery.Connection_config.port
         connection_config
         ~service_id:Keyval_rpc.For_service_discovery.service_id
     in
     let@ connection = Keyval_client.with_connection ~port in
     let value =
       match Keyval_client.get connection ~key with
       | Some t -> t
       | None ->
         let candidates =
           Keyval_client.list_keys connection |> List.map ~f:Keyval.Key.to_string
         in
         Err.raise
           ~hints:(Err.did_you_mean (Keyval.Key.to_string key) ~candidates)
           Pp.O.
             [ Pp.text "No value for key "
               ++ Pp_tty.id (module Keyval.Key) key
               ++ Pp.text "."
             ]
     in
     print_dyn (value |> Keyval.Value.to_dyn);
     ())
;;
