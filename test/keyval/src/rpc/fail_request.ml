(*********************************************************************************)
(*  lunarpc - An opinionated, lightweight, HTTP/JSON RPC harness                 *)
(*  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: MIT                                                 *)
(*********************************************************************************)

module Request = struct
  include Rpc_unit

  let of_json (_ : Json.t) : t =
    failwith "Deliberate request decode failure, for testing."
  ;;
end

module Response = Rpc_unit

let rpc : _ Rpc.t =
  Rpc.create
    ~name:(Rpc.Name.v "failRequest")
    ~version:1
    ~description:
      "Request decoding always fails, regardless of input. Exists to test the server's \
       handling of a request encoder bug."
    ~request_encoder:(Rpc.Encoder.make (module Request))
    ~response_encoder:(Rpc.Encoder.make (module Response))
    ()
;;
