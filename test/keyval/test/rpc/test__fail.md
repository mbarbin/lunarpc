# RPC roundtrip: Fail

Same roundtrip check as for [Get](test__get.md), applied to the `Fail`
RPC. Both its request and response are `Unit`, so this only checks the
JSON encoding --- see [Malformed requests](../../test__invalid_rpc.md)
for what actually happens when this RPC's handler raises.

## Invalid json

Both [Unit]: anything other than a JSON object is rejected.

## Extra fields are ignored

[Unit] decodes any JSON object, regardless of its fields --- there's
nothing to check, so nothing gets rejected.

## [equal]

Both [Unit], so this only checks that [equal] holds on the sole
value of that type.
