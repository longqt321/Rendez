# Rendez backend (local development)

Run `make demo` from the repository root to build and start the API, Vietnamese/English Tesseract OCR and PostgreSQL in Docker. It applies migrations through version 5, seeds sample data and waits for API readiness. No system PostgreSQL or host Tesseract is required.

For host Go development, run `make db migrate seed api`. OCR then requires the `tesseract` executable and `vie`/`eng` language data on PATH. Stop the Docker API before binding the same port. `make api-dev` additionally exposes the fixed development fixture login; the normal binary never exposes `/dev/login`.

Database and upload images use separate persistent named volumes. `make down` stops the stack without deleting either. `DATABASE_URL`, `APP_ENV`, `HTTP_ADDR` and `UPLOAD_DIR` configure host runs; `.env.example` is a reference, not auto-loaded. Defaults in the backend Makefile are local-only.

## Docker test environment

Run `make integration` from the repository root. Only Docker Compose and Go are required; no system PostgreSQL installation or running dev database is needed.

`docker-compose.test.yml` starts a fresh PostgreSQL 18.4 in a unique Compose project with a dynamically assigned loopback port. Data lives in tmpfs. The runner applies migrations through the real integration tests and checks readiness, sessions and Admin access. It overrides database URLs, so an exported development/system `DATABASE_URL` is not used. Containers, test storage and the project network are removed on success, failure or normal interruption. A forced kill or Docker daemon failure can prevent cleanup; use `docker compose -f backend/docker-compose.test.yml -p <project-name> down --remove-orphans` for the printed test project only.

`make -C backend verify-m1` runs normal/dev tests and the same Docker integration suite. Each rerun starts clean; the development `rendez_core` database and volume are untouched.

## Recreate the development container

Run `make db-recreate` from the root if the dev container needs replacement. It recreates the container and keeps the named volume. Deleting a container alone does not reset PostgreSQL data. Use `make integration` for a completely fresh disposable test database; no dev-volume deletion is needed.

The Makefile provides disposable local DATABASE_URL, HTTP_ADDR and APP_ENV defaults. Export variables to override; .env.example is a reference, not auto-loaded. The service refuses startup before its Goose migrations are installed. Active migrations live only in migrations/core. The previous inactive Gin/GORM backend was removed during repository cleanup; it remains in Git history. Draft SQL in migrations/drafts is not executed.

## First live Flutter integration

`make demo` at the repository root starts Docker PostgreSQL, applies migrations 1–5, seeds two example venues/menu items and runs the normal API. The demo admin is `longqt321@rendez.local` / `123123123`; seed is restricted to APP_ENV=development and preserves catalog records and updates the local demo admin password to the seeded value. Email/password registration always creates a User. Passwords use salted PBKDF2-SHA256; login reuses the existing opaque sessions, without JWT/refresh tokens.

Endpoints: POST /v1/auth/register, POST /v1/auth/login, GET /v1/me, DELETE /v1/auth/session, GET /v1/places, GET /v1/places/{id}, GET /v1/favorites, PUT/DELETE /v1/favorites/{id}. Register accepts email/password/display_name; login accepts email/password. Register/login returns token and user. Catalog reads only published places; favorites are owner-scoped and idempotent.

Run `make integration-ui` after `make mobile-deps` to launch a real HTTP server backed by disposable Docker PostgreSQL and exercise the actual Flutter client/providers. No mocked HTTP response or in-memory repository is used for this test. The standard widget suite still contains legacy prototype UI checks; it is not the integration proof.

## Contributions and Admin

Active contract: [local completion spec](../docs/specs/000-local-completion/spec.md). Catalog, auth and favorites retain their `/v1` API. New routes provide lookups, Admin place CRUD, multipart contributions, owner history/private images, OCR retry/draft save/review and public approved menu images.

Uploads decode/re-encode 1–5 JPEG/PNG files, each under 10 MiB, at least 100×100 and at most 20 million pixels. Images have random storage names and no EXIF metadata. File writes are removed if the associated DB transaction fails. Uploaded originals are never served as an unrestricted static directory.

Tesseract runs synchronously within a 25-second budget for all images. Failure stays pending with an error; manual edits remain available. Admin approval/rejection locks contribution and place in one transaction, writes the reviewer/time and rejects repeat decisions. Approval upserts reviewed menu names; bill totals never become menu prices. Hidden places remain hidden on approval.

`make integration` tests actual Docker PostgreSQL and Tesseract, including ownership, draft privacy, approval races, invalid uploads and OCR failure. If host Tesseract is absent, the test runner builds the same API image and invokes its real OCR through stdin. Tests use temporary upload storage and a separate tmpfs database; persistent dev volumes are untouched.
