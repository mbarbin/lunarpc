(*********************************************************************************)
(*  lunarpc - An opinionated, lightweight, HTTP/JSON RPC harness                 *)
(*  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: MIT                                                 *)
(*********************************************************************************)

let default_owner () =
  match Sys.getenv_opt "KEYVAL_USER" with
  | Some user -> Keyval.Owner.v user
  | None ->
    ((match Unix.getlogin () with
      | user -> Keyval.Owner.v user
      | exception Unix.Unix_error _ -> Keyval.Owner.v (Unix.getenv "USER"))
    [@coverage off])
;;

let main =
  Command.make
    ~summary:"Set a binding [key=value]."
    ~readme:(fun () ->
      "Stores a binding [key=value] in the server's in-memory database, creating it if \
       new, or overwriting the previous value if the key is already set.")
    (let open Command.Std in
     let+ () = Log_cli.set_config ()
     and+ connection_config = Rpc_discovery.Connection_config.arg
     and+ key =
       Arg.named
         [ "key" ]
         (Param.validated_string (module Keyval.Key))
         ~docv:"KEY"
         ~doc:"The name of the key."
     and+ value =
       Arg.named
         [ "value" ]
         (Param.stringable (module Keyval.Value))
         ~docv:"VALUE"
         ~doc:"The desired value."
     and+ owner =
       Arg.named_opt
         [ "as" ]
         (Param.validated_string (module Keyval.Owner))
         ~docv:"OWNER"
         ~doc:
           "Record this binding as set by OWNER, retrievable via get-owner. Defaults to \
            the KEYVAL_USER env var if set, otherwise the current unix login."
     in
     let port =
       Rpc_discovery.Connection_config.port
         connection_config
         ~service_id:Keyval_rpc.For_service_discovery.service_id
     in
     let owner =
       match owner with
       | Some owner -> owner
       | None -> default_owner ()
     in
     let@ connection = Keyval_client.with_connection ~port in
     Keyval_client.set connection ~key ~value ~owner)
;;
