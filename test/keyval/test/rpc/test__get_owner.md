# RPC roundtrip: Get owner

Same roundtrip check as for [Get](test__get.md), applied to the
`Get_owner` RPC.

## Invalid json

Same shape-error coverage as [Get](test__get.md) for the request; the
response additionally rejects a well-shaped [owner] that fails
[Keyval.Owner]'s own invariant, as [Invalid_argument].

## Extra fields are ignored

## [equal]

Sanity-checks that [equal] actually discriminates values, rather than
e.g. always returning [true].
