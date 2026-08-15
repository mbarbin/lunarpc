# Did-you-mean hints

`get` and `delete` fail when the supplied key doesn't exist. Rather than
leaving the user to guess a typo, the CLI looks up the current keys and
attaches a "Did you mean ...?" hint via `Err.did_you_mean`, when one of
them is close enough to what was typed.

```bash
$ keyval set --key foo --value bar
$ keyval set --key bar --value baz
```

## A close typo gets suggested

```bash
$ keyval get --key fooo
Error: No value for key [fooo].
Hint: did you mean foo?
[123]
```

```bash
$ keyval delete --key fooo
Error: Call to [delete] failed.
No such key [fooo].
Hint: did you mean foo?
[123]
```

## No close match, no hint

When nothing in the store is close enough to the supplied key, no hint
is attached --- same behavior as before this feature.

```bash
$ keyval get --key zzz
Error: No value for key [zzz].
[123]
```
