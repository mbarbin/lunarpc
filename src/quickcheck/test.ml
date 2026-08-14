(*********************************************************************************)
(*  lunarpc - An opinionated, lightweight, HTTP/JSON RPC harness                 *)
(*  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: MIT                                                 *)
(*********************************************************************************)

module type S = sig
  type t

  val generator : t Generator.t
  val to_dyn : t -> Dyn.t
end

let run (type a) ?examples (module M : S with type t = a) ~f =
  let module M = struct
    type t = M.t

    let quickcheck_generator = Generator.Private.to_base_quickcheck M.generator
    let quickcheck_shrinker = Base_quickcheck.Shrinker.atomic
    let sexp_of_t t = Dyn.to_sexp (M.to_dyn t)
  end
  in
  match
    Base_quickcheck.Test.run
      ?examples
      (module M)
      ~f:(fun a ->
        f a;
        Ok ())
  with
  | Ok () -> ()
  | Error err -> Base.Error.raise err
;;
