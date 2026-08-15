# RPC versioning: two independent handlers behind one name

`get` has two versions registered side by side: v1 raises when the key
is missing; v2 (the default, `Keyval_client.get`) returns `None`
instead. They're separate handlers with separate routes (`rpc/get/v1`
and `rpc/get/v2`) and separate response schemas --- bumping `version`
doesn't migrate callers, it just lets both shapes coexist until v1's
callers move off it.

`Keyval_client.get_deprecated` (the v1 caller) carries OCaml's
[@deprecated] attribute, so calling it below needs a local
[@alert "-deprecated"] to silence the warning --- deliberately local,
not a blanket file-level escape, so the one call this test exists to
make is the only thing exempted.

## v2 (the default `get`), present or absent, never raises

```bash
$ keyval set --key foo --value bar
$ keyval get --key foo
"bar"
$ keyval get --key unknown
Error: No value for key [unknown].
[123]
```

## v1, present, agrees with v2

```ocaml
print_dyn
  (Keyval.Value.to_dyn
     ((Keyval_client.get_deprecated [@alert "-deprecated"])
        connection
        ~key:(Keyval.Key.v "foo")));
[%expect {| "bar" |}];
```

## v1, absent, raises instead of returning `None`

```ocaml
(match
   (Keyval_client.get_deprecated [@alert "-deprecated"])
     connection
     ~key:(Keyval.Key.v "unknown")
 with
 | (_ : Keyval.Value.t) -> print_endline "unexpectedly succeeded"
 | exception _ -> print_endline "raised, as v1 does on a missing key");
[%expect {| raised, as v1 does on a missing key |}];
```
