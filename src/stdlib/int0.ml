(*********************************************************************************)
(*  lunarpc - An opinionated, lightweight, HTTP/JSON RPC harness                 *)
(*  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: MIT                                                 *)
(*********************************************************************************)

include Stdlib.Int

let ( % ) = Stdlib.( mod )
let ( * ) = Stdlib.( * )
let ( + ) = Stdlib.( + )
let ( - ) = Stdlib.( - )
let ( / ) = Stdlib.( / )
let ( < ) = Stdlib.( < )
let ( <= ) = Stdlib.( <= )
let ( <> ) = Stdlib.( <> )
let ( = ) = Stdlib.( = )
let ( > ) = Stdlib.( > )
let ( >= ) = Stdlib.( >= )
let decr = Stdlib.decr
let incr = Stdlib.incr
let of_string = int_of_string
let of_string_opt = int_of_string_opt
let to_dyn = Dyn.int
let zero = 0
