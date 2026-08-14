# Name

Unit tests for [Rpc.Name]'s validation: the first character must be a
lowercase ASCII letter, the rest ASCII alphanumeric, and the total
length between 1 and 64 characters.

## [of_string]

[of_string str] returns [Ok str] if the invariant holds, and an error
otherwise. This is meant to be used to validate untrusted entries.

## [v]

[v str] is a convenient wrapper to build a [t] or raise
[Invalid_argument]. This is typically handy for applying on trusted
literals --- on an invalid one, it raises rather than returning a
[result] to handle.
