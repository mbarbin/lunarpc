(lang dune 3.20)

(name lunarpc)

(generate_opam_files)

(license MIT)

(authors "Mathieu Barbin")

(maintainers "Mathieu Barbin <opensource@mbarbin.org>")

(source
 (github mbarbin/lunarpc))

(documentation "https://mbarbin.github.io/lunarpc/")

(implicit_transitive_deps false)

(package
 (name lunarpc-stdlib)
 (synopsis "Extending OCaml's Stdlib for the lunarpc project")
 (depends
  (ocaml
   (>= 5.2))
  (dyn
   (>= 3.20))
  (fpath-sexp0
   (>= 0.4.0))
  (ordering
   (>= 3.20))
  (pp
   (>= 2.0.0))
  (pplumbing-err
   (>= 0.0.17))
  (sexplib0
   (>= v0.17))
  (yojson
   (>= 3.0.0))))

(package
 (name lunarpc)
 (synopsis "Core RPC protocol/specification library for lunarpc")
 (depends
  (ocaml
   (>= 5.2))
  (lunarpc-stdlib
   (= :version))))

(package
 (name lunarpc-client)
 (synopsis "A library to build lunarpc HTTP/JSON clients")
 (depends
  (ocaml
   (>= 5.2))
  (curl
   (>= 0.9.2))
  (ezcurl
   (>= 0.3))
  (lunarpc
   (= :version))
  (lunarpc-stdlib
   (= :version))
  (pplumbing-log
   (>= 0.0.17))
  (yojson
   (>= 3.0.0))))

(package
 (name lunarpc-discovery)
 (synopsis "A library to help discover lunarpc servers running on localhost")
 (depends
  (ocaml
   (>= 5.2))
  (cmdlang
   (>= 0.0.11))
  (loc
   (>= 0.3.3))
  (lunarpc
   (= :version))
  (lunarpc-stdlib
   (= :version))
  (yojson
   (>= 3.0.0))))

(package
 (name lunarpc-server)
 (synopsis "A library to build lunarpc HTTP/JSON servers")
 (depends
  (ocaml
   (>= 5.2))
  (lunarpc
   (= :version))
  (lunarpc-stdlib
   (= :version))
  (nofunc-stdset
   (>= 0.1.0))
  (tiny_httpd
   (>= 0.19))
  (yojson
   (>= 3.0.0))))

(package
 (name lunarpc-test-harness)
 (synopsis "A library to help writing tests for lunarpc applications")
 (depends
  (ocaml
   (>= 5.2))
  (lunarpc-client
   (= :version))
  (lunarpc-discovery
   (= :version))
  (lunarpc-stdlib
   (= :version))
  (nofunc-stdset
   (>= 0.1.0))))

(package
 (name lunarpc-quickcheck)
 (synopsis "Property-based testing helpers for lunarpc interfaces")
 (depends
  (ocaml
   (>= 5.2))
  (base
   (>= v0.17))
  (base_quickcheck
   (>= v0.17))
  (jsonschema
   (>= 0.1.0))
  (lunarpc
   (= :version))
  (lunarpc-stdlib
   (= :version))
  (sexplib0
   (>= v0.17))
  (yojson
   (>= 3.0.0))))

(package
 (name lunarpc-tests)
 (synopsis "Tests and end-to-end examples for lunarpc")
 (depends
  (ocaml
   (>= 5.2))
  (base
   (>= v0.17))
  (cmdlang
   (>= 0.0.11))
  (cmdlang-cmdliner-err-runner
   (>= 0.0.17))
  (dune-build-info
   (>= 3.20))
  (jsonschema
   (>= 0.1.0))
  (lunarpc
   (= :version))
  (lunarpc-client
   (= :version))
  (lunarpc-discovery
   (= :version))
  (lunarpc-quickcheck
   (= :version))
  (lunarpc-server
   (= :version))
  (lunarpc-stdlib
   (= :version))
  (lunarpc-test-harness
   (= :version))
  (mdexp
   (>= 0.0.20260814))
  (nofunc-stdhtbl
   (>= 0.1.0))
  (parsexp
   (>= v0.17))
  (pp
   (>= 2.0.0))
  (pplumbing-err
   (>= 0.0.17))
  (pplumbing-log
   (>= 0.0.17))
  (pplumbing-log-cli
   (>= 0.0.17))
  (pplumbing-pp-tty
   (>= 0.0.17))
  (ppx_expect
   (>= v0.17))
  (ppxlib
   (>= 0.33))
  (tiny_httpd
   (>= 0.19))))

(package
 (name lunarpc-dev)
 (synopsis "Package to regroup dev targets, documentation, and more")
 (allow_empty)
 (depends
  (ocaml
   (>= 5.2))
  (ocamlformat
   (= 0.29.0))
  (bisect_ppx
   (>= 2.8.3))
  (lunarpc
   (= :version))
  (lunarpc-client
   (= :version))
  (lunarpc-discovery
   (= :version))
  (lunarpc-quickcheck
   (= :version))
  (lunarpc-server
   (= :version))
  (lunarpc-stdlib
   (= :version))
  (lunarpc-test-harness
   (= :version))
  (lunarpc-tests
   (= :version))
  (mdexp
   (>= 0.0.20260814))
  (ppx_expect
   (>= v0.17))
  (ppx_js_style
   (>= v0.17))
  (ppxlib
   (>= 0.33))
  (odoc
   (>= 2.4.4))
  (sherlodoc
   (>= 0.2))))
