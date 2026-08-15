# Tracking who set a binding

`set --as OWNER` records `OWNER` (an [Owner.t]: non-empty, alphanumeric,
`-`, or `_`) as the caller that set a binding, attached to the request
via `Rpc.Call.principal`. Every binding has an owner: the server requires one,
and the cli defaults to the `KEYVAL_USER` env var, falling back to the
current unix login. `get-owner` retrieves it later; it fails, the same
way `get`/`delete` do, when the key doesn't exist.

## Setting without `--as`

Falls back to `KEYVAL_USER`, pinned to a stable value for this test
suite via the server's environment.

```bash
$ keyval set --key foo --value bar
$ keyval get-owner --key foo
"test-user"
```

## Setting with an owner

```bash
$ keyval set --key foo --value bar2 --as alice
$ keyval get-owner --key foo
"alice"
```

## Overwriting changes the owner

```bash
$ keyval set --key foo --value bar3 --as bob
$ keyval get-owner --key foo
"bob"
```

## An unknown key

```bash
$ keyval get-owner --key unknown
Error: No such key [unknown].
[123]
```
