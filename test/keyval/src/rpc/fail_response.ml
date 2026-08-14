(*********************************************************************************)
(*  lunarpc - An opinionated, lightweight, HTTP/JSON RPC harness                 *)
(*  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: MIT                                                 *)
(*********************************************************************************)

module Request = Rpc_unit

module Response = struct
  include Rpc_unit

  let to_json (_ : t) : Json.t =
    failwith "Deliberate response encode failure, for testing."
  ;;
end

let rpc : _ Rpc.t =
  Rpc.create
    ~name:(Rpc.Name.v "failResponse")
    ~version:1
    ~description:
      "Response encoding always fails, regardless of the handler's result. Exists to \
       test the server's handling of a response encoder bug."
    ~request_encoder:(Rpc.Encoder.make (module Request))
    ~response_encoder:(Rpc.Encoder.make (module Response))
    ()
;;
