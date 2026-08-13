# Call

Unit tests for [Call.t]'s header-carried metadata: [to_headers] (sending
side) and [create_with_headers] (receiving side). [create_with_headers]
reads headers via a [get : string -> string option] accessor, which the
server backs with its real transport headers; here we back it with a
plain assoc list instead, so the receiving side can be exercised in
isolation.

## [to_headers]

The transport headers carrying the call's metadata; empty when there is
none. This does not encode [request] --- that's the RPC's JSON body,
encoded separately via the spec's [request_encoder].

## [create_with_headers]

[create_with_headers request ~get] bundles the decoded [request] with the
call's metadata, read from the request's transport headers via [get]. A
header present but not a valid [Principal.t] is treated as absent.

## Roundtrip

[to_headers] followed by [create_with_headers] recovers the same
principal.
