# Service_id

Unit tests for [Rpc_discovery.Service_id]: the pair of an
[App_name.t] and a [Service_name.t] identifying a service, with
[equal]/[compare] following both fields lexicographically ([app_name]
first).

## [equal]

Sanity-checks that [equal] actually discriminates values, rather than
e.g. always returning [true] --- in particular, that it does compare
both fields, not just one.

## [compare]

Lexicographic: [app_name] first, [service_name] only as a tie-breaker
when [app_name] is equal.

## [to_dyn]
