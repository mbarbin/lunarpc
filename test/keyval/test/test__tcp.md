# Connecting over TCP

In this test we connect to the server using explicitly the tcp option
rather than via a unix socket.

In practice for now this doesn't change anything since unix sockets are
not supported.

## Via the cli

First, let's store a binding to the store.

```bash
$ keyval set --key foo --value bar
$ keyval get --key foo
"bar"
```

## Via the OCaml client

Now let's access that binding using the RPC api.

```ocaml
let data = Keyval_client.get connection ~key:(Keyval.Key.v "foo") in
print_dyn (data |> Dyn.option Keyval.Value.to_dyn);
[%expect {| Some "bar" |}];
```
