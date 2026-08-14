# RPC roundtrip: Set

Same roundtrip check as for [Get](test__get.md), applied to the
`Set` RPC. No explicit examples are supplied here, so only the
generated random requests and responses are checked.

## Invalid json

The decoders iterate over whatever fields are present rather than
matching a fixed shape, so only a genuinely missing or mistyped
field is rejected --- see [Extra fields are ignored](#extra-fields-are-ignored)
below for what that buys.

## Extra fields are ignored

Fields the decoder doesn't recognize are silently skipped rather
than rejected, same as an unknown key in a real client's payload
(e.g. a newer client talking to an older server) should be. The
request also isn't sensitive to field order --- [key]/[value] decode
the same regardless of which comes first.

## [equal]

Sanity-checks that [equal] actually discriminates values, rather than
e.g. always returning [true] --- in particular, that it does compare
both fields of the request record, not just one.
