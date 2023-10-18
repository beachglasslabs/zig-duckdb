# zig-duckdb

A thin wrapper for duckdb in zig.

The current implementation uses the dynamic library (libduckdb) released by
[duckdb](https://github.com/duckdb/duckdb).

This has only been used and tested on Linux.

Please sanitize your sql before passing to this library as this is subject to
sql injection attack if you are using strings passed in directly from users.
A future version will likely expose prepared statement so the variables will
be sanitized propertly.
