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

## Docker test environment

Run `make integration` from the repository root. Only Docker Compose and Go are required; no system PostgreSQL installation or running dev database is needed.

`docker-compose.test.yml` starts a fresh PostgreSQL 18.4 in a unique Compose project with a dynamically assigned loopback port. Data lives in tmpfs. The runner applies migrations through the real integration tests and checks readiness, sessions and Admin access. It overrides database URLs, so an exported development/system `DATABASE_URL` is not used. Containers, test storage and the project network are removed on success, failure or normal interruption. A forced kill or Docker daemon failure can prevent cleanup; use `docker compose -f backend/docker-compose.test.yml -p <project-name> down --volumes --remove-orphans` for the printed test project only.

`make -C backend verify-m1` runs normal/dev tests and the same Docker integration suite. Each rerun starts clean; the development `rendez_core` database and volume are untouched.

## Recreate the development container

Run `make db-recreate` from the root if the dev container needs replacement. It recreates the container and keeps the named volume. Deleting a container alone does not reset PostgreSQL data. Use `make integration` for a completely fresh disposable test database; no dev-volume deletion is needed.

The Makefile provides disposable local DATABASE_URL, HTTP_ADDR and APP_ENV defaults. Export variables to override; .env.example is a reference, not auto-loaded. The service refuses startup before its Goose migrations are installed. Active migrations live only in migrations/core. The previous inactive Gin/GORM backend was removed during repository cleanup; it remains in Git history. Draft SQL in migrations/drafts is not executed.
