# Introspection: listRpcs

Every server built with `Rpc_server` automatically exposes a `listRpcs`
RPC --- no opt-in needed --- which lists every RPC the service exposes,
including itself. It's reachable exactly like any other RPC; here we
call it from OCaml, but a plain `curl -X POST .../rpc/listRpcs/v1 -d
'{}'` works just as well.

## Compact listing

By default, the listing is compact: name, version, route, and
description for every RPC, but no schemas. This is the shape an agent
sees first --- enough to know what's available before paying for the
full schema payload.

```json
{
  "rpcs": [
    {
      "name": "get",
      "version": 2,
      "route": "rpc/get/v2",
      "description": "Retrieve the value associated with a key from the memory database, or null if the key doesn't exist. Supersedes v1, which raised an error on a missing key: an absent value is normal here, not exceptional, so callers can distinguish it from an actual failure."
    },
    {
      "name": "get",
      "version": 1,
      "route": "rpc/get/v1",
      "description": "Retrieve the value associated with a key from the memory database. Raises if the key doesn't exist. Deprecated: use v2 instead, which returns null for a missing key rather than failing the call."
    },
    {
      "name": "set",
      "version": 1,
      "route": "rpc/set/v1",
      "description": "Store or update a key-value pair in the memory database."
    },
    {
      "name": "delete",
      "version": 1,
      "route": "rpc/delete/v1",
      "description": "Permanently delete a binding from the memory database, based on its key."
    },
    {
      "name": "listKeys",
      "version": 1,
      "route": "rpc/listKeys/v1",
      "description": "Retrieve a list of all keys present in the memory database."
    },
    {
      "name": "getOwner",
      "version": 1,
      "route": "rpc/getOwner/v1",
      "description": "Retrieve the owner that last set a key's binding. No_such_key means the key doesn't exist."
    },
    {
      "name": "fail",
      "version": 1,
      "route": "rpc/fail/v1",
      "description": "Always raises an exception. Exists to test the server's handling of unexpected handler failures."
    },
    {
      "name": "failRequest",
      "version": 1,
      "route": "rpc/failRequest/v1",
      "description": "Request decoding always fails, regardless of input. Exists to test the server's handling of a request encoder bug."
    },
    {
      "name": "failResponse",
      "version": 1,
      "route": "rpc/failResponse/v1",
      "description": "Response encoding always fails, regardless of the handler's result. Exists to test the server's handling of a response encoder bug."
    },
    {
      "name": "stop",
      "version": 1,
      "route": "rpc/stop/v1",
      "description": "Ask the server to stop, after responding to this call."
    },
    {
      "name": "listRpcs",
      "version": 1,
      "route": "rpc/listRpcs/v1",
      "description": "Retrieve schema information for all RPCs available in the service. This introspective RPC allows clients and agents to discover what RPCs are available and understand their request/response schemas."
    }
  ]
}
```

## Filtered listing, with schemas

Passing `names` narrows the listing to specific RPCs, and
`include_schemas:true` adds the full JSON Schema for the request and
the response --- everything an agent or a schema-to-code generator
needs to build a client for that one RPC, in a single call.

```json
{
  "rpcs": [
    {
      "name": "listKeys",
      "version": 1,
      "route": "rpc/listKeys/v1",
      "description": "Retrieve a list of all keys present in the memory database.",
      "requestSchema": { "type": "object" },
      "responseSchema": {
        "type": "object",
        "properties": {
          "keys": {
            "type": "array",
            "items": {
              "type": "object",
              "properties": { "key": { "type": "string" } },
              "required": [ "key" ]
            }
          }
        },
        "required": [ "keys" ]
      }
    }
  ]
}
```
