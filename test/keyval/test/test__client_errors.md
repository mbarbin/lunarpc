# Rpc_client: decode failure

`Rpc_client.call` returns `Error _` rather than raising for a few
distinct failure modes; two of them --- the HTTP call itself failing,
and the server responding with a non-2xx status --- are already
exercised incidentally elsewhere in this book (an unreachable server,
and [Malformed requests](test__invalid_rpc.md)). This chapter covers
the third: a well-formed, successful (2xx) response that simply isn't
the shape the caller asked for --- e.g. a client built against a
newer or different version of the RPC than the server implements.

[Mismatched_get] reuses `Get`'s route and request encoder, but decodes
the response as if it were `Get_owner`'s. Both are legitimate RPC
specs on their own; pairing them like this is only ever a caller-side
mistake, which is exactly what this simulates.
