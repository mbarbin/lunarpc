## 0.0.2026XXXX (unreleased)

### Added

- Add `lunarpc-generator`, a minimal property-based testing generator library split out of `lunarpc-quickcheck` so consumers that only need `Generator`/`Test` (not the RPC-specific `Rpc_quickcheck`) don't have to depend on `lunarpc`/`jsonschema` (@mbarbin).

### Changed

- `lunarpc-quickcheck` now depends on `lunarpc-generator` instead of bundling its own copy of `Generator`/`Test`; `Rpc_quickcheck.Private.test_run` is removed now that `Test.run` is directly available (@mbarbin).
