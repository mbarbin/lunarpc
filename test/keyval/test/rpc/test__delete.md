# RPC roundtrip: Delete

Same roundtrip check as for [Get](test__get.md), applied to the
`Delete` RPC.

There used to be a bug in the deserialization of `Unit`; the
explicit `~requests` below regression-test it.

## Invalid json

The response is a bare string constructor: anything other than exactly
["Deleted"] or ["No_such_key"] --- including a case mismatch --- is
rejected.

## Extra fields are ignored

Only the request has fields to speak of --- the response is a bare
string constructor, with nothing to be lenient about.

## [equal]

Sanity-checks that [equal] actually discriminates values, rather than
e.g. always returning [true].
