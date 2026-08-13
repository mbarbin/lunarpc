(*********************************************************************************)
(*  lunarpc - An opinionated, lightweight, HTTP/JSON RPC harness                 *)
(*  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: MIT                                                 *)
(*********************************************************************************)

type 'request t =
  { request : 'request
  ; principal : Principal.t option
  }

let request t = t.request
let principal t = t.principal

(* The single header carrying the calling principal. *)
let principal_header = "x-rpc-principal"

let to_headers ?principal () =
  match principal with
  | None -> []
  | Some principal -> [ principal_header, Principal.to_string principal ]
;;

let principal_of_headers ~get =
  match get principal_header with
  | None -> None
  | Some s ->
    (match Principal.of_string s with
     | Ok principal -> Some principal
     | Error (`Msg _) -> None)
;;

let create_with_headers request ~get = { request; principal = principal_of_headers ~get }
