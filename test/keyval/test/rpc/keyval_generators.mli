(*_********************************************************************************)
(*_  lunarpc - An opinionated, lightweight, HTTP/JSON RPC harness                 *)
(*_  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*_  SPDX-License-Identifier: MIT                                                 *)
(*_********************************************************************************)

(** Quickcheck generators for the [keyval] core types, shared by the RPC
    roundtrip tests in this directory. Kept in the test tree so that the
    [keyval] and [keyval_rpc] libraries themselves have no dependency on
    [lunarpc-quickcheck]. *)

module Key : sig
  include module type of Keyval.Key

  val generator : t Generator.t
end

module Value : sig
  include module type of Keyval.Value

  val generator : t Generator.t
end

module Owner : sig
  include module type of Keyval.Owner

  val generator : t Generator.t
end
