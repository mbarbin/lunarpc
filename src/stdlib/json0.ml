(*********************************************************************************)
(*  lunarpc - An opinionated, lightweight, HTTP/JSON RPC harness                 *)
(*  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: MIT                                                 *)
(*********************************************************************************)

type t = Yojson.Basic.t

let equal = Yojson.Basic.equal
let pretty_to_string t = Yojson.Basic.pretty_to_string t ~std:true

let rec to_dyn : t -> Dyn.t = function
  | `Null -> Dyn.variant "Null" []
  | `Bool b -> Dyn.variant "Bool" [ Dyn.bool b ]
  | `Int i -> Dyn.variant "Int" [ Dyn.int i ]
  | `Float f -> Dyn.variant "Float" [ Dyn.float f ]
  | `String str -> Dyn.variant "String" [ Dyn.string str ]
  | `List ts -> Dyn.list to_dyn ts
  | `Assoc ts ->
    Dyn.variant
      "Assoc"
      [ Dyn.list (fun (field, t) -> Dyn.pair Dyn.string to_dyn (field, t)) ts ]
;;

exception Invalid_json of t * string

let () =
  Sexplib0.Sexp_conv.Exn_converter.add [%extension_constructor Invalid_json] (function
    | Invalid_json (t, msg) ->
      List [ Atom "Json.Invalid_json"; Atom msg; Atom (pretty_to_string t) ]
    | _ -> assert false)
;;
