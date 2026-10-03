# Draft migrations

Files here are design work, not executable Goose migrations. The API loads only `migrations/core` and currently requires schema version 2.

`00003_catalog.sql` was an untracked work-in-progress file before repository cleanup. Its contents are preserved here. Promote it only with the corresponding catalog implementation, schema-version update and PostgreSQL integration checks. Do not change already applied migrations or reset existing databases.
