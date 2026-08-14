# JSON schema validation

Every RPC request and response type exposes a `schema : unit -> Json.t`
describing its JSON Schema. `Rpc_quickcheck` uses it to validate that
generated values actually match their own declared schema, catching
drift between an encoder and the schema it advertises.

This chapter exercises that schema-validation machinery directly,
independent of any real RPC, using a small ad hoc `Lookup_key` RPC
(a `string -> string` lookup) as a fixture.

## Validating JSON against a schema

`validate_json` checks a JSON value against a compiled schema and reports
a human-readable error for mismatches: wrong type, missing required
property, or a bad value nested under a property path. This is the same
check `Rpc_quickcheck.run_validate_request_exn` and
`run_validate_response_exn` perform on generated values, here driven by
hand-picked examples instead.

## Extra fields are valid against the schema too

Every decoder in this codebase tolerates unknown fields (see e.g.
[List rpcs](../keyval/test/rpc/test__list_rpcs.md)); the schema it
advertises needs to agree, or a well-behaved caller validating its
payload against the schema before sending would reject something the
decoder would happily accept. JSON Schema's default for
`additionalProperties` when unspecified is `true`, which is exactly
what's wanted here --- so none of these schemas set it (an earlier
version of `Rpc.List_rpcs`'s did set it to `false`, which was this
inconsistency exactly).

## Roundtrip against a real RPC

Same as the [keyval RPC roundtrip](../keyval/test/rpc/test__get.md)
checks: `Rpc_quickcheck.run_exn` generates random requests and responses
for `Lookup_key`, checks them against its schema, and verifies that
encoding to JSON and back is the identity.
