(*_********************************************************************************)
(*_  lunarpc - An opinionated, lightweight, HTTP/JSON RPC harness                 *)
(*_  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*_  SPDX-License-Identifier: MIT                                                 *)
(*_********************************************************************************)

(** {1 Including dune's Dyn module}

    This module is designed to shadow dune's [Dyn] module. As such it re-exports
    its original interface. *)

include module type of struct
  include Dyn
end

(** {1 Alternate syntax} *)

val to_sexp : Dyn.t -> Sexplib0.Sexp.t
