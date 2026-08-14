# RPC roundtrip: Fail request

`Keyval_rpc.Fail_request`'s request decoder always raises, regardless of
its input --- even a well-formed empty object, the one payload that
would otherwise be valid for a `Unit` request. See
[Malformed requests](../test__invalid_rpc.md) for how this surfaces
through the server.

## [equal]

Both [Unit], so this only checks that [equal] holds on the sole
value of that type.
