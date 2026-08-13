# String_id

Unit tests for [String_id.Make], exercised on a small ad hoc id type
built for this chapter: non-empty, ASCII alphanumeric only.

## Example

[v]/[to_string] round trip a valid value; [equal] follows the
underlying string.

## [compare]

Structural, following the underlying string's ordering.

## [of_string]

[of_string str] returns [Ok str] if the invariant holds, and an error
otherwise; the error message truncates a long shown value, to keep
the message from becoming unwieldy.
