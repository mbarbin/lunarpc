# RPC roundtrip: Get, v1

`Keyval_rpc.Get_v1` is the deprecated first version of the ["get"] RPC:
same name as `Keyval_rpc.Get`, but registered as its own handler under
`version = 1`, with a response schema that has no room for "missing" ---
the v1 handler raises instead. `Keyval_rpc.Get` (`version = 2`) is what
replaced it, once returning `null` for a missing key turned out to be
the better fit than failing the call.

This pair exists to demonstrate that versions of the same RPC name are
independent, side-by-side handlers: each has its own route
(`rpc/get/v1` vs `rpc/get/v2`), its own schema, and its own server-side
function.

## Invalid json

Same decoder-error coverage as [Get](test__get.md), plus one thing
specific to v1: unlike v2, its response has no [null] case, so a
missing value must fail to decode rather than come back as absent.

## Extra fields are ignored

## [equal]

Sanity-checks that [equal] actually discriminates values, rather than
e.g. always returning [true].
