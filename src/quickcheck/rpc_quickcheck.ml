(*********************************************************************************)
(*  lunarpc - An opinionated, lightweight, HTTP/JSON RPC harness                 *)
(*  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: MIT                                                 *)
(*********************************************************************************)

module type S = sig
  module Request : sig
    type t

    val generator : t Generator.t
    val equal : t -> t -> bool
  end

  module Response : sig
    type t

    val generator : t Generator.t
    val equal : t -> t -> bool
  end

  include Rpc.S with module Request := Request and module Response := Response
end

type ('request, 'response) t =
  (module S with type Request.t = 'request and type Response.t = 'response)

let json_validator_exn (encoder : _ Rpc.Encoder.t) =
  match Jsonschema.create_validator_from_json ~schema:(encoder.schema ()) () with
  | Ok validator -> validator
  | Error compile_error ->
    let error = Format.asprintf "%a" Jsonschema.pp_compile_error compile_error in
    raise (Failure (Printf.sprintf "Invalid schema: %s" error))
;;

let validate_json_exn validator json =
  match Jsonschema.validate validator json with
  | Ok () -> ()
  | Error validation_error ->
    let error =
      Format.asprintf "%a" Jsonschema.pp_validation_error_verbose validation_error
    in
    print_endline (Yojson.Basic.pretty_to_string json : string);
    Code_error.raise "Json schema validation error." [ "error", error |> Dyn.string ]
;;

let run_validate_request_exn (type request response) ?examples (t : (request, response) t)
  =
  let module M = (val t : S with type Request.t = request and type Response.t = response)
  in
  let module Request = struct
    include M.Request

    let to_dyn t = Json.to_dyn (M.rpc.request_encoder.to_json t)
  end
  in
  let json_validator = json_validator_exn M.rpc.request_encoder in
  Test.run
    (module Request)
    ?examples
    ~f:(fun request ->
      let json = M.rpc.request_encoder.to_json request in
      validate_json_exn json_validator json)
;;

let run_request_exn (type request response) ?examples (t : (request, response) t) =
  let module M = (val t : S with type Request.t = request and type Response.t = response)
  in
  let module Request = struct
    include M.Request

    let to_dyn t = Json.to_dyn (M.rpc.request_encoder.to_json t)
  end
  in
  Test.run
    (module Request)
    ?examples
    ~f:(fun request ->
      let json = M.rpc.request_encoder.to_json request in
      let request' = M.rpc.request_encoder.of_json json in
      require_equal (module Request) request request')
;;

let run_validate_response_exn
      (type request response)
      ?examples
      (t : (request, response) t)
  =
  let module M = (val t : S with type Request.t = request and type Response.t = response)
  in
  let module Response = struct
    include M.Response

    let to_dyn t = Json.to_dyn (M.rpc.response_encoder.to_json t)
  end
  in
  let json_validator = json_validator_exn M.rpc.response_encoder in
  Test.run
    (module Response)
    ?examples
    ~f:(fun response ->
      let json = M.rpc.response_encoder.to_json response in
      validate_json_exn json_validator json)
;;

let run_response_exn (type request response) ?examples (t : (request, response) t) =
  let module M = (val t : S with type Request.t = request and type Response.t = response)
  in
  let module Response = struct
    include M.Response

    let to_dyn t = Json.to_dyn (M.rpc.response_encoder.to_json t)
  end
  in
  Test.run
    (module Response)
    ?examples
    ~f:(fun response ->
      let json = M.rpc.response_encoder.to_json response in
      let response' = M.rpc.response_encoder.of_json json in
      require_equal (module Response) response response')
;;

let run_exn ?requests ?responses t =
  run_request_exn ?examples:requests t;
  run_validate_request_exn ?examples:requests t;
  run_response_exn ?examples:responses t;
  run_validate_response_exn ?examples:responses t;
  ()
;;
