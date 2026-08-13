(*_********************************************************************************)
(*_  lunarpc - An opinionated, lightweight, HTTP/JSON RPC harness                 *)
(*_  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*_  SPDX-License-Identifier: MIT                                                 *)
(*_********************************************************************************)

include module type of struct
  include Stdlib.Int
end

val ( % ) : t -> t -> t
val ( * ) : t -> t -> t
val ( + ) : t -> t -> t
val ( - ) : t -> t -> t
val ( / ) : t -> t -> t
val ( < ) : t -> t -> bool
val ( <= ) : t -> t -> bool
val ( <> ) : t -> t -> bool
val ( = ) : t -> t -> bool
val ( > ) : t -> t -> bool
val ( >= ) : t -> t -> bool
val decr : int ref -> unit
val incr : int ref -> unit
val of_string : string -> t
val of_string_opt : string -> t option
val to_dyn : t -> Dyn.t
val zero : int
