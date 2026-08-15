# Summary

[Introduction](README.md)

# Stdlib

- [Stdlib](stdlib/test__stdlib.md)
- [String_id](stdlib/test__string_id.md)

# Discovery

- [App_name](discovery/test__app_name.md)
- [Service_name](discovery/test__service_name.md)
- [Instance_name](discovery/test__instance_name.md)
- [Service_id](discovery/test__service_id.md)
- [Discovery_file](discovery/test__discovery_file.md)
- [Rpc_discovery](discovery/test__rpc_discovery.md)
- [Via_file](discovery/test__via_file.md)

# Rpc

- [Call headers](rpc/test__call.md)
- [Building an RPC spec](rpc/test__rpc.md)
- [Name](rpc/test__name.md)
- [Principal](rpc/test__principal.md)

# Keyval

- [CLI](keyval/test/test__cli.md)
- [CLI argument grouping](keyval/test/test__args_groups.md)
- [Validate key](keyval/test/test__validate_key.md)
- [Connecting via the OCaml client](keyval/test/test__connection.md)
- [Connecting over TCP](keyval/test/test__tcp.md)
- [Multiple servers](keyval/test/test__multiple_servers.md)
- [Server restarts](keyval/test/test__server_restart.md)
- [Introspection: listRpcs](keyval/test/test__list_rpcs.md)
- [Did-you-mean hints](keyval/test/test__did_you_mean.md)
- [Malformed requests](keyval/test/test__invalid_rpc.md)
- [Tracking who set a binding](keyval/test/test__ownership.md)
- [Stopping the server](keyval/test/test__stop.md)
- [Rpc_client: decode failure](keyval/test/test__client_errors.md)

# Keyval RPC roundtrips

- [Get](keyval/test/rpc/test__get.md)
- [Get, v1](keyval/test/rpc/test__get_v1.md)
- [Set](keyval/test/rpc/test__set_.md)
- [Delete](keyval/test/rpc/test__delete.md)
- [List keys](keyval/test/rpc/test__list_keys.md)
- [Fail](keyval/test/rpc/test__fail.md)
- [Get owner](keyval/test/rpc/test__get_owner.md)
- [Fail request](keyval/test/rpc/test__fail_request.md)
- [Fail response](keyval/test/rpc/test__fail_response.md)
- [Stop](keyval/test/rpc/test__stop.md)
- [List rpcs](keyval/test/rpc/test__list_rpcs.md)

# Quickcheck

- [JSON schema validation](quickcheck/test__json_validation.md)
- [Checking an invariant on a custom generator](generator/test__generator.md)
- [Rpc_quickcheck catches a broken roundtrip](quickcheck/test__rpc_quickcheck.md)

# Test harness

- [Testing the test harness itself](test-harness/test__rpc_test_harness.md)
