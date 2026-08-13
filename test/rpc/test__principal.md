# Principal

Unit tests for [Rpc.Principal]'s validation: non-empty, at most 64
characters, ASCII alphanumeric, ['-'], or ['_'] --- so, notably, no
whitespace.

## [of_string]

[of_string str] returns [Ok str] if the invariant holds, and an error
otherwise. This is meant to be used to validate untrusted entries.

## [v]

[v str] is a convenient wrapper to build a [t] or raise
[Invalid_argument]. This is typically handy for applying on trusted
literals --- on an invalid one, it raises rather than returning a
[result] to handle.
