(*********************************************************************************)
(*  lunarpc - An opinionated, lightweight, HTTP/JSON RPC harness                 *)
(*  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: MIT                                                 *)
(*********************************************************************************)

module List = List0
module Sexp = Sexplib0.Sexp
include Dyn

let to_sexp =
  let module S = Sexplib0.Sexp_conv in
  let rec aux (dyn : Dyn.t) : Sexp.t =
    match[@coverage off] dyn with
    | Opaque -> Atom "<opaque>"
    | Unit -> List []
    | Int i -> S.sexp_of_int i
    | Int32 i -> S.sexp_of_int32 i
    | Record fields ->
      List (List.map fields ~f:(fun (field, t) -> Sexp.List [ Atom field; aux t ]))
    | Variant (v, args) ->
      (* Special pretty print of variants holding records. *)
      (match args with
       | [] -> Atom v
       | [ Record fields ] ->
         List
           (Atom v
            :: List.map fields ~f:(fun (field, t) -> Sexp.List [ Atom field; aux t ]))
       | _ -> List (Atom v :: List.map args ~f:aux))
    | Bool b -> S.sexp_of_bool b
    | String a -> S.sexp_of_string a
    | Bytes a -> S.sexp_of_bytes a
    | Int64 i -> S.sexp_of_int64 i
    | Nativeint i -> S.sexp_of_nativeint i
    | Char c -> S.sexp_of_char c
    | Float f -> S.sexp_of_float f
    | Option o -> S.sexp_of_option aux o
    | List l -> S.sexp_of_list aux l
    | Array a -> S.sexp_of_array aux a
    | Tuple t -> List (List.map t ~f:aux)
    | Map m -> List (List.map m ~f:(fun (k, v) -> Sexp.List [ aux k; aux v ]))
    | Set s -> List (List.map s ~f:aux)
  in
  aux
;;
