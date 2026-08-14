# Rpc_quickcheck catches a broken roundtrip

Every other roundtrip chapter in this book demonstrates
[Rpc_quickcheck.run_exn] passing --- which begs the question: would it
actually notice if an RPC's JSON encoding were broken? [Off_by_one]
answers that: its request decoder has a deliberate, minor bug ---
[count] comes back one higher than it went in --- so [to_json] then
[of_json] does not return the original value. [run_exn] generates
many requests and checks exactly that property, so it should raise on
the very first one it tries.

## Rpc_quickcheck catches a broken response roundtrip

[Off_by_one] only breaks the request; [Response_off_by_one] mirrors
it on the response, checking that [run_exn] catches a broken
roundtrip on either side, not just the request.

## Rpc_quickcheck catches an RPC that lies about its own schema

Roundtripping isn't the only property [run_exn] checks: it also
validates every encoded value against the RPC's own advertised JSON
Schema. [Request_schema_drift] roundtrips just fine (its request is
[int], encoded and decoded consistently as a JSON int) --- the bug is
that [schema] claims the request is a [string]. A schema like that is
actively misleading to a client or a schema-to-code generator relying
on it, so it's worth catching independently of the roundtrip check.

Same bug, on the response side this time: the request is fine on
every count, so [run_exn] gets all the way to validating the
response's schema before catching it.
