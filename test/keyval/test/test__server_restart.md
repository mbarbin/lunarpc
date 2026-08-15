# Server restarts

In this test we show that two invocations of `with_server` run distinct
servers, and due to the particular nature of the `keyval` application,
the state is not persisted across restarts (our example is only an
in-memory database).

## First server

We start a first server, add a key, and read it back.

```bash
$ keyval list-keys
set {}
```

```bash
$ keyval set --key foo --value bar
```

```bash
$ keyval get --key foo
"bar"
```

```bash
$ keyval list-keys
set { "foo" }
```

## Second server

We then start a second, independent server: the key we set
above is gone.

```bash
$ keyval list-keys
set {}
```

```bash
$ keyval get --key foo
Error: No value for key [foo].
[123]
```
