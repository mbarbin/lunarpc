# Hello CLI Test Helpers

In this test we demonstrate how to exercise the command line interface of a
lunarpc application talking to a server, from an expect test. The goal is to
be sort of like a cram test, but using your favorite programming language
instead of bash.

## A cram like test framework

In the following, we show how to use the test helper library, in conjunction
to the `mdexp` tool to produce markdown files that stay in sync.

Let's jump in!

## Using the cli

### Missing keys

At first, there are no keys in the server.

```bash
$ keyval list-keys
set {}
```

The cli exit with code [123] if we're trying to get an invalid key.

```bash
$ keyval get --key foo
Error: No value for key [foo].
[123]
```

Same for delete.

```bash
$ keyval delete --key foo
Error: Call to [delete] failed.
No such key [foo].
[123]
```

### Setting and getting a value

Now let's try to add a binding to the keyval store.

```bash
$ keyval set --key foo --value bar
```

Now we can get the value back.

```bash
$ keyval get --key foo
"bar"
```

We can delete it.

```bash
$ keyval delete --key foo
```

And now it's gone.

```bash
$ keyval get --key foo
Error: No value for key [foo].
[123]
```

### Listing keys

Let's add it back!

```bash
$ keyval set --key foo --value bar
```

Let's list the keys again!

```bash
$ keyval list-keys
set { "foo" }
```

### Overwriting a value

We can overwrite an existing key.

```bash
$ keyval set --key foo --value baz
$ keyval get --key foo
"baz"
```

### Many keys at once

Let's set some more keys.

```bash
$ keyval set --key k00 --value 0
$ keyval set --key k01 --value 1
$ keyval set --key k02 --value 2
$ keyval set --key k03 --value 3
$ keyval set --key k04 --value 4
$ keyval set --key k05 --value 5
$ keyval set --key k06 --value 6
$ keyval set --key k07 --value 7
$ keyval set --key k08 --value 8
$ keyval set --key k09 --value 9
$ keyval set --key k10 --value 10
$ keyval list-keys
set
  { "foo"
  ; "k00"
  ; "k01"
  ; "k02"
  ; "k03"
  ; "k04"
  ; "k05"
  ; "k06"
  ; "k07"
  ; "k08"
  ; "k09"
  ; "k10"
  }
```

### Reading them back

Let's verify multiple keys in sequence.

```bash
$ keyval get --key k00
"0"
$ keyval get --key k01
"1"
$ keyval get --key k02
"2"
$ keyval get --key k03
"3"
$ keyval get --key k04
"4"
$ keyval get --key k05
"5"
$ keyval get --key k06
"6"
$ keyval get --key k07
"7"
$ keyval get --key k08
"8"
$ keyval get --key k09
"9"
$ keyval get --key k10
"10"
```
