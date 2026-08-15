# Testing the test harness itself

[Rpc_test_harness] is the library every other functional test in this
suite is built on top of (see e.g.
[the keyval CLI tests](../keyval/test/test__cli.md)); those exercise it
thoroughly along its "happy path", but a few corners of its own API ---
the parts that only matter for less common usage, like sharing a data
directory across restarts, or cleaning up after a callback that raises
--- aren't reached by any of them. This chapter targets those corners
directly, reusing the `keyval` server/client executable as a real,
already-built application to drive it with.

## [Process_env.build]

With no overrides, [build] returns the ambient environment unchanged
(as opposed to a copy filtered and re-concatenated, which would be
observably the same set of bindings but is worth locking down as the
actual code path taken).

## [Config.rpc_discovery]: default [process_env]

[?process_env] defaults to [Process_env.empty] when the caller doesn't
supply one --- unlike every other test in this suite, which always
pins down a [KEYVAL_USER] override.

## [persistent_data_dir], shared across two [with_server] calls

As documented on [persistent_data_dir], its result can be threaded
through [?data_dir] to successive [with_server] calls so they share
the same on-disk service-discovery root --- the piece of state
[with_server] otherwise reallocates fresh every time. `keyval` itself
is an in-memory store (see
[server restarts](../keyval/test/test__server_restart.md)), so this
doesn't demonstrate persisted key/value state, but it does show two
independent servers can be started, one after the other, sharing the
directory a [Data_dir.t] hands out.

## [Server.pid], [Server.stdout_path], [Server.stderr_path]

Once a server is up, these expose enough to debug it out-of-band: a
pid to attach a debugger to, and the paths the harness redirected its
stdout/stderr into (both created up front, so they exist as soon as
the server does).

## Wrapping: an invocation that starts with a flag

[run_client]'s cram-style header keeps the first argument group glued
to the program name only when that group doesn't itself start with a
flag (see [multi-line grouping](../keyval/test/test__args_groups.md)
for the case where it does get glued). An empty argument list takes
the same branch: there's no first group to glue anything to.

## The server is torn down even when the callback raises

[with_server]'s normal exit path ([graceful_shutdown]) always sends
the server [SIGTERM] itself; the fallback path (its [~finally]) only
needs to do that when the callback never got there --- e.g. because it
raised. This checks the exception still propagates, and that the
fallback path doesn't itself error out tearing the server down.

## A client killed by a signal is reported, not silently dropped

[run_client] runs the server's own [run_client_command] to build the
client's [Config.Process_command.t] --- here it's swapped out for one
that sends itself [SIGTERM], to reach the branch of [run_client] that
handles a client that never got to exit normally.

## Tearing down a server that's already gone doesn't itself raise

If the callback raises after the server process has already exited
and been reaped by someone else (a crash, say), [with_server]'s
fallback teardown still has to run --- and must tolerate both
[Unix.kill] and [Unix.waitpid] failing against a pid that no longer
exists, rather than masking the callback's own exception with one of
its own.
