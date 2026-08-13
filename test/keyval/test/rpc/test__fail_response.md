# RPC roundtrip: Fail response

`Keyval_rpc.Fail_response`'s response encoder always raises (see
[Malformed requests](../test__invalid_rpc.md) for how that surfaces
through the server); its *decoder* is unaffected, so it still rejects
malformed json the same way any other `Unit` response would.

## [equal]

Both [Unit], so this only checks that [equal] holds on the sole
value of that type.
