# RPC roundtrip: List rpcs

`Rpc.List_rpcs` is generic --- defined in `lunarpc` itself, not
`keyval_rpc` --- and its payload is metadata about *other* RPCs
([Rpc.Info.t]: name, route, description, optional JSON schemas).
Rather than fabricate arbitrary names and schemas, its generators draw
directly from the real RPCs [Keyval_server.handlers] registers (plus
`List_rpcs` itself, which lists itself too), so every generated value
is exactly what a real server would produce.

## Invalid json

The request's [names] field, and each element of the response's
[rpcs] array, decode through [Rpc.Info.of_json] and [Rpc.Name.of_string]
respectively --- errors from either propagate as-is, on top of this
RPC's own shape checks.

## Extra fields are ignored

At the top level, and (via [Rpc.Info.of_json]) on each element of the
response's [rpcs] array.

## [equal]

Sanity-checks that [equal] actually discriminates values, rather than
e.g. always returning [true] --- for the request, that includes being
sensitive to [names]'s order (it is plain positional list equality,
not a set comparison), same as [List_keys](test__list_keys.md).
