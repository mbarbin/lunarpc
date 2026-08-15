(*********************************************************************************)
(*  lunarpc - An opinionated, lightweight, HTTP/JSON RPC harness                 *)
(*  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: MIT                                                 *)
(*********************************************************************************)

type 'a t = 'a Base_quickcheck.Generator.t

let create f = Base_quickcheck.Generator.create (fun ~size ~random:_ -> f ~size)
let return = Base_quickcheck.Generator.return
let map = Base_quickcheck.Generator.map
let bind = Base_quickcheck.Generator.bind
let both = Base_quickcheck.Generator.both
let union = Base_quickcheck.Generator.union
let filter = Base_quickcheck.Generator.filter
let of_list = Base_quickcheck.Generator.of_list
let list = Base_quickcheck.Generator.list
let list_non_empty = Base_quickcheck.Generator.list_non_empty
let bool = Base_quickcheck.Generator.bool
let option = Base_quickcheck.Generator.option
let string_non_empty = Base_quickcheck.Generator.string_non_empty
let string_non_empty_of = Base_quickcheck.Generator.string_non_empty_of
let char_alphanum = Base_quickcheck.Generator.char_alphanum
let int_uniform_inclusive = Base_quickcheck.Generator.int_uniform_inclusive

module Syntax = struct
  let ( let+ ) x f = map x ~f
  let ( and+ ) = both
  let ( let* ) x f = bind x ~f
  let ( and* ) = both
end

module Private = struct
  let to_base_quickcheck t = t
end
