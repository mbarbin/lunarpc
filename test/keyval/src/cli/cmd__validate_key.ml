(*********************************************************************************)
(*  lunarpc - An opinionated, lightweight, HTTP/JSON RPC harness                 *)
(*  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: MIT                                                 *)
(*********************************************************************************)

let main =
  Command.make
    ~summary:"Verify the syntactic validity of a provided key."
    ~readme:(fun () ->
      "This command performs a static validation of the key and does not require a \
       connection to a running server.")
    (let open Command.Std in
     let+ key = Arg.pos ~pos:0 Param.string ~docv:"KEY" ~doc:"The key to validate." in
     match Keyval.Key.of_string key with
     | Ok (_ : Keyval.Key.t) -> ()
     | Error (`Msg m) -> Err.raise [ Pp.text m ])
;;
