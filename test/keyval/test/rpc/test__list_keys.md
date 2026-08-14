# RPC roundtrip: List keys

Same roundtrip check as for [Get](test__get.md), applied to the
`List_keys` RPC. This one takes no request payload (a `Unit` request),
so no `~requests` need to be supplied explicitly --- only the generated
cases are checked.

## Invalid json

The response decoder validates two levels: the outer [{ keys: [...] }]
shape, and then each element of the array. Either can fail
independently.

## Extra fields are ignored

Both at the top level and on each element of [keys].

## [equal]

Sanity-checks that [equal] actually discriminates values, rather than
e.g. always returning [true] --- including that it is sensitive to
the keys' order (it is plain positional list equality, not a set
comparison).
