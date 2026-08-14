# Rpc

Unit tests for [Rpc]'s two operations: [create], which builds an RPC
spec, and [route], which derives its URL path component.

## [create]

[create ~name ~version ~description ~request_encoder ~response_encoder ()]
builds an RPC spec. Raises [Invalid_argument] if [version] is negative or
null (versions start at [1]).

## [route]

[route t] returns the URL path component for this RPC, without a leading
slash.

For example, if [t.name = Name.v "listRepos"] and [t.version = 1], this
returns ["rpc/listRepos/v1"]. Versioning is local to each RPC: bump
[version] when the request/response shape changes in an incompatible
way.
