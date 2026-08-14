# Via_file, through Listening_config / Connection_config

[Via_file] (the file-based service discovery mechanics: creating the
discovery directory, writing/reading the discovery file) isn't
exposed directly --- these exercise it through the public
[Listening_config.advertize] / [Connection_config.port] entry points
that wrap it.

The scratch root is anchored at the current working directory with a
fixed name, rather than [Filename.temp_file]/[Filename.temp_dir]'s
randomized paths: nothing here needs to print or compare that path,
but it does need cleaning up on a machine-independent, predictable
location.

## Re-advertizing is idempotent

The discovery directory already exists on a second [advertize] (e.g.
the server restarted with the same identity) --- that must be a
no-op, not an error.

## A file blocking a required directory is a real error

If some segment of the discovery path exists but isn't a directory
(here, [.app] is a plain file, standing in for e.g. leftover state
from an unrelated process), [advertize] can't create what it needs
underneath it and must raise --- rather than, say, silently
proceeding or corrupting that file.
