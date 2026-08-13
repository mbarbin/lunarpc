(*********************************************************************************)
(*  lunarpc - An opinionated, lightweight, HTTP/JSON RPC harness                 *)
(*  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: MIT                                                 *)
(*********************************************************************************)

module Request = Rpc_unit
module Response = Rpc_unit

let rpc : _ Rpc.t =
  Rpc.create
    ~name:(Rpc.Name.v "fail")
    ~version:1
    ~description:
      "Always raises an exception. Exists to test the server's handling of unexpected \
       handler failures."
    ~request_encoder:(Rpc.Encoder.make (module Request))
    ~response_encoder:(Rpc.Encoder.make (module Response))
    ()
;;
