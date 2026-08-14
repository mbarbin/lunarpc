# Checking an invariant on a custom generator

[Generator.create] and [Generator.Syntax.( let* )] are the two
primitives needed to build a generator from scratch: [create] turns
the current size parameter into a (deterministic) value, and [let*]
chains it into further, genuinely random generators. Here they build
[Range.t], a [{ lo; hi }] pair that is an interval by construction:
[hi] is [lo] plus a non-negative offset, so [lo <= hi] should always
hold, however [Range.t] values are generated.
[Rpc_quickcheck.Private.test_run] then checks that invariant against
many random samples.
