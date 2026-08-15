(*********************************************************************************)
(*  lunarpc - An opinionated, lightweight, HTTP/JSON RPC harness                 *)
(*  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: MIT                                                 *)
(*********************************************************************************)

module Binding = struct
  type t =
    { value : Keyval.Value.t
    ; owner : Keyval.Owner.t
    }
end

type t = { table : (Keyval.Key.t, Binding.t) Hashtbl.t }

let create () = { table = Hashtbl.create (module Keyval.Key) 16 }

let get t key =
  Hashtbl.find_opt t.table key |> Option.map ~f:(fun { Binding.value; _ } -> value)
;;

let get_v1 t key =
  (* The deprecated v1 behavior: raise rather than return an option. *)
  match get t key with
  | Some value -> value
  | None -> failwith (Printf.sprintf "No such key: %s" (Keyval.Key.to_string key))
;;

let get_owner t key : Keyval_rpc.Get_owner.Response.t =
  match Hashtbl.find_opt t.table key with
  | Some { Binding.owner; _ } -> Some { owner }
  | None -> No_such_key
;;

let set t ~principal { Keyval_rpc.Set_.Request.key; value } =
  (* [Principal.t] is a generic, backend-agnostic concept, so validating that
     it identifies an actual [Owner.t] is [keyval]'s alone to enforce: every
     caller of [set] (the cli defaults to the current unix login; any other
     client must supply one) is required to identify itself. *)
  let owner =
    match principal with
    | None -> Code_error.raise "Set requires a caller with a principal." []
    | Some principal ->
      (match Keyval.Owner.of_string (Rpc.Principal.to_string principal) with
       | Ok owner -> owner
       | Error (`Msg msg) ->
         Code_error.raise
           "Set's caller principal is not a valid owner."
           [ "msg", Dyn.string msg ])
  in
  Hashtbl.replace t.table key { Binding.value; owner }
;;

let delete t key =
  match Hashtbl.find_and_remove t.table key with
  | Some _ -> Keyval_rpc.Delete.Response.Deleted
  | None -> Keyval_rpc.Delete.Response.No_such_key
;;

let list_keys t =
  Hashtbl.to_seq_keys t.table
  |> List.of_seq
  |> List.sort ~compare:(fun a b -> Keyval.Key.compare a b |> Ordering.to_int)
;;

let fail () = failwith "Deliberate failure, for testing."

let handlers t : Rpc.Handler.t list =
  [ Rpc.Handler.make
      (module Keyval_rpc.Get)
      ~f:(fun call -> get t (Rpc.Call.request call))
  ; Rpc.Handler.make
      (module Keyval_rpc.Get_v1)
      ~f:(fun call -> get_v1 t (Rpc.Call.request call))
  ; Rpc.Handler.make
      (module Keyval_rpc.Set_)
      ~f:(fun call -> set t ~principal:(Rpc.Call.principal call) (Rpc.Call.request call))
  ; Rpc.Handler.make
      (module Keyval_rpc.Delete)
      ~f:(fun call -> delete t (Rpc.Call.request call))
  ; Rpc.Handler.make
      (module Keyval_rpc.List_keys)
      ~f:(fun (_ : unit Rpc.Call.t) -> list_keys t)
  ; Rpc.Handler.make
      (module Keyval_rpc.Get_owner)
      ~f:(fun call -> get_owner t (Rpc.Call.request call))
  ; Rpc.Handler.make (module Keyval_rpc.Fail) ~f:(fun (_ : unit Rpc.Call.t) -> fail ())
  ; Rpc.Handler.make (module Keyval_rpc.Fail_request) ~f:(fun (_ : unit Rpc.Call.t) -> ())
  ; Rpc.Handler.make
      (module Keyval_rpc.Fail_response)
      ~f:(fun (_ : unit Rpc.Call.t) -> ())
  ]
;;
