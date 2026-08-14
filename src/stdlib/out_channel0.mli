(*_********************************************************************************)
(*_  lunarpc - An opinionated, lightweight, HTTP/JSON RPC harness                 *)
(*_  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*_  SPDX-License-Identifier: MIT                                                 *)
(*_********************************************************************************)

include module type of struct
  include Stdlib.Out_channel
end

val create
  :  ?binary:bool
  -> ?append:bool
  -> ?fail_if_exists:bool
  -> ?perm:int
  -> string
  -> t

val with_file
  :  ?binary:bool
  -> ?append:bool
  -> ?fail_if_exists:bool
  -> ?perm:int
  -> string
  -> f:(t -> 'a)
  -> 'a

val newline : t -> unit
val output_line : t -> string -> unit
val write_all : string -> data:string -> unit
