# Multiple servers

In this test we demonstrate that the testing API allows for running
multiple servers in parallel, in case this is interesting for a
particular test case.

For the sake of the example here, we'll just run two servers and have a
function to feed the keys from one server to the other.

So it's easier to implement, we'll actually make use of the OCaml RPC
interface for this, rather than pure cli. This way, this test can also
serve as an example of mixing the RPC and cli interfaces in a test.

## Two empty servers

At first, none of the servers have keys.

```bash
$ keyval list-keys
set {}
```

```bash
$ keyval list-keys
set {}
```

## Populating the first server

Let's populate server1 with a few keys.

```bash
$ keyval set --key k00 --value 0
$ keyval set --key k01 --value 1
$ keyval set --key k02 --value 2
$ keyval set --key k03 --value 3
$ keyval set --key foo --value bar
$ keyval list-keys
set { "foo"; "k00"; "k01"; "k02"; "k03" }
```

## Pushing bindings to the second server

For the sake of the example, let's also have `foo` in server2.
It will be replaced after we push all bindings from server1 to
server2.

```bash
$ keyval set --key foo --value OLD-VALUE
$ keyval set --key bar --value sna
```

```ocaml
print_dyn (all_bindings ~connection:connection2 |> Dyn.list dyn_of_binding);
[%expect {| [ { key = "bar"; value = "sna" }; { key = "foo"; value = "OLD-VALUE" } ] |}];
```

## After the push

After pushing, server2 has all the keys, and `foo` was
overwritten with server1's value.

```bash
$ keyval list-keys
set { "bar"; "foo"; "k00"; "k01"; "k02"; "k03" }
```

```ocaml
print_dyn (all_bindings ~connection:connection2 |> Dyn.list dyn_of_binding);
[%expect
  {|
  [ { key = "bar"; value = "sna" }
  ; { key = "foo"; value = "bar" }
  ; { key = "k00"; value = "0" }
  ; { key = "k01"; value = "1" }
  ; { key = "k02"; value = "2" }
  ; { key = "k03"; value = "3" }
  ]
  |}];
```
