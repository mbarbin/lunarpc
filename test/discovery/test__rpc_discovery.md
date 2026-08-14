# Rpc_discovery

Unit tests for the pure parts of [Connection_config] and
[Listening_config]: [equal], [to_args], and [port] on the [Tcp] case.
([Connection_config.port]'s [Discovery_via_file] case and
[Listening_config.advertize] go through the filesystem, via
[Via_file]; not covered here.)

## [Discovery_via_file.equal]

## [Connection_config]

[equal] discriminates both across constructors ([Tcp] vs
[Discovery_via_file]) and within each one.

## [Listening_config]
