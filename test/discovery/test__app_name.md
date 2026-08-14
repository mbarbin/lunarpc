# App_name

Unit tests for [Rpc_discovery.App_name]'s validation: non-empty, at
most 64 characters, ASCII alphanumeric, ['-'], or ['_'] (so, notably,
no path separators, ['.'], or whitespace).

## [of_string]

[of_string str] returns [Ok str] if the invariant holds, and an error
otherwise.

## [v]

[v str] is a convenient wrapper to build a [t] or raise
[Invalid_argument] --- on an invalid one, it raises rather than
returning a [result] to handle.
