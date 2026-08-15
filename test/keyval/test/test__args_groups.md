# CLI argument grouping

The test cli reconstructs and prints the command line it invokes before
running it. When an invocation is long, it wraps across multiple lines,
grouping each option together with its own arguments rather than
breaking mid-option. This test locks down that layout, using a made-up,
unknown command just to keep the example focused on the line wrapping
itself.

## Wrapping a long invocation

```bash
$ keyval this that \
    --arg0 \
    --arg1 0 \
    --arg2 0 1 \
    --arg3 0 1 2 \
    --arg4 0 1 2 3 \
    --arg5 0 1 2 3 4 \
    --arg6 0 1 2 3 4 5 \
    --arg7 0 1 2 3 4 5 6 \
    --arg8 0 1 2 3 4 5 6 7 \
    --arg9 0 1 2 3 4 5 6 7 8 \
    --arg10 0 1 2 3 4 5 6 7 8 9 \
    --arg11 0 1 2 3 4 5 6 7 8 9 10 \
    --arg12 0 1 2 3 4 5 6 7 8 9 10 11 \
    --arg13 0 1 2 3 4 5 6 7 8 9 10 11 12 \
    --arg14 0 1 2 3 4 5 6 7 8 9 10 11 12 13 \
    --arg15 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 \
    --arg16 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 \
    --arg17 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 \
    --arg18 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 \
    --arg19 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18
keyval: unknown command 'this', must be one of 'delete', 'get', 'get-owner', 'list-keys', 'server', 'set' or 'validate-key'.
Usage: keyval COMMAND …
Try 'keyval --help' for more information.
[124]
```

## The pp margin

The wrapping above depends on the `Format` margin in effect when
the test cli renders a command line. Pinning it down here as its own
assertion makes that hidden dependency explicit: if this value ever
changes, the wrapping in the snapshot above would change with it.

```ocaml
print_dyn (Format.get_margin () |> Dyn.int);
[%expect {| 78 |}];
```
