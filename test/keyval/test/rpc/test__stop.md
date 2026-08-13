# RPC roundtrip: Stop

`Keyval_rpc.Stop`'s request and response are both `Unit` (an empty
object): there is no valid payload to round trip beyond that, so unlike
its siblings in this directory, this chapter only covers the decoders'
error paths --- see [Stopping the server](../test__stop.md) for the
actual effect of this RPC.

## Extra fields are ignored

[Unit] decodes any JSON object, regardless of its fields --- there's
nothing to check, so nothing gets rejected.

## [equal]

Both [Unit], so this only checks that [equal] holds on the sole
value of that type.
