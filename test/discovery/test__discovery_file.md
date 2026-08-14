# Discovery_file

[Discovery_file.t] is a [{ port : int }] value persisted to disk as a
small json envelope ([{"type":"Tcp","port":N}]), used for file-based
service discovery: servers [save] it, clients [load] it.

## Roundtrip

[save] followed by [load] recovers the same port.

## [Json_format]

The "expert API": the on-disk shape itself.

## [load] failure paths

Three distinct things can go wrong when loading, each reported with
its own message via {!Err.raise}: the file doesn't exist, its
content isn't valid JSON, or it is valid JSON but not in the expected
shape. [Err.For_test.protect] prints the resulting CLI-style error
message.
