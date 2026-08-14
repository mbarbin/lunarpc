# RPC roundtrip: Get

`Rpc_quickcheck.run_exn` exercises an RPC's JSON encoding end to end: it
generates random requests and responses, checks them against the RPC's
JSON schema, and verifies that encoding to JSON and back is the
identity. Explicit `~requests` (and `~responses`) can be supplied to
also cover specific, hand-picked examples in addition to the generated
ones --- here, a couple of concrete keys.

`Keyval_rpc.Get` itself carries no generator (the `keyval` and
`keyval_rpc` libraries have no dependency on `lunarpc-quickcheck`); the
test builds the generators it needs locally.

## Invalid json

Roundtrip tests only ever feed [of_json] its own [to_json] output, so
they never exercise the decoders' error paths. These do: malformed
shapes are rejected by the decoder itself with [Json.Invalid_json];
a well-shaped [key] that fails [Keyval.Key]'s own invariant is
rejected downstream, as [Invalid_argument].

## Extra fields are ignored

The decoders iterate over whatever fields are present rather than
matching a fixed shape, so an unrecognized field --- from, say, a
newer client talking to an older server --- is silently skipped
rather than rejected.

## [equal]

Sanity-checks that [equal] actually discriminates values, rather than
e.g. always returning [true].
