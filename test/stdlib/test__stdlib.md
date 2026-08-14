# Stdlib

Unit tests for a couple of [Lunarpc_stdlib]'s expect-test helpers:
[phys_equal] and [require_equal].

## [phys_equal]

[phys_equal a b] is physical equality ([a == b]): two structurally
equal but distinct values are not [phys_equal].

## [require_equal]

[require_equal (module M) v1 v2] raises if [v1] and [v2] are not equal
per [M.equal]; [require_not_equal] is the mirror image. Both failures
are demonstrated here via [require_does_raise], which also shows what
the raised [Code_error] looks like.
