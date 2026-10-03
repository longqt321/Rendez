# Rendez backend (local development)

Requires Docker Compose and Go 1.26 or newer. Run from the repository root:

~~~sh
make -C backend local-db
make -C backend migrate
make -C backend seed-dev
make -C backend run-dev
~~~

The dev build exposes POST /dev/login for the fixed user and admin fixtures. It requires APP_ENV=development. The normal build (make -C backend run) has no development login route. Both builds use real database-backed opaque sessions; the database stores token hashes, not bearer tokens.

In another terminal, check health and create a session:

~~~sh
curl -i http://127.0.0.1:8080/health/live
curl -i http://127.0.0.1:8080/health/ready
curl -i -X POST http://127.0.0.1:8080/dev/login -H 'Content-Type: application/json' -d '{"fixture":"user"}'
~~~

Pass the returned bearer to GET /v1/me; revoke it with DELETE /v1/auth/session. Stop the API with Ctrl-C. make -C backend local-down stops PostgreSQL without removing its volume.

make -C backend verify-m1 runs normal-build tests plus a real PostgreSQL session test in a temporary database. make -C backend test-integration runs the migration/readiness test in another temporary database. Neither resets rendez_core.

The Makefile provides disposable local DATABASE_URL, HTTP_ADDR and APP_ENV defaults. Export variables to override; .env.example is a reference, not auto-loaded. The service refuses startup before its Goose migrations are installed. Active migrations live only in migrations/core. The previous inactive Gin/GORM backend was removed during repository cleanup; it remains in Git history. Draft SQL in migrations/drafts is not executed.
