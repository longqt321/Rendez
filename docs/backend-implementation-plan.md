# Rendez backend implementation plan — Phase 3

Documentation only. Milestones, files and commands below describe future implementation; they have not been implemented or executed as part of this planning task.

## 1. Executive summary

Build a usable local Rendez before adding federation or OCR. M0–M6 deliver Flutter → Go → PostgreSQL and private persistent files, including real sessions, discovery, generic prices, favorites, immutable contributions and manual Admin approval/rejection. M7 adds federation to the existing session entry point. M8 adds OCR assistance to the existing review path. M9 contains individually triggered operational/product extensions, not an infrastructure checklist.

Inputs: [SRS v1](SRS_PBL6.pdf), [product reconciliation](product-reconciliation.md), and [complete architecture, Sections 1–41](backend-architecture.md). Precedence is approved reconciliation §§13–14 → architecture business/data/security invariants → Phase 3 local-first/YAGNI strategy → architecture mechanisms. Milestone numbers here replace architecture §41's sequencing suggestions for implementation purposes. Earlier documents remain unchanged.

Retain the existing backend module name, entry-point location, build-file locations and useful error/shutdown patterns. Replace its incompatible, mostly unwired Gin/GORM/password/JWT paths instead of maintaining parallel stacks. Preserve existing uncommitted work and databases before that future conversion.

Three reductions make this practical for two developers:

- Development login issues real opaque sessions; authorization is never mocked.
- Manual prices need items, immutable observations and current selections, not the entire contribution/publication/version system.
- Community review needs immutable intake and one attributable final reviewed snapshot. Admin can edit locally and submit reviewed fields with the decision; server-side draft versioning can wait.

Local completion is not full SRS or production acceptance. Real provider login, OCR-specific capabilities, transparency-ranking policy, optional public source-image delivery and deployment obligations remain explicitly recorded.

## 2. Phase 3 principles

1. **Local first:** no M0–M6 runtime dependency on identity providers, OCR, maps/geocoding, object storage, SaaS, remote fonts or remote fixture images. Downloading/building tools and dependencies is setup, not the disconnected runtime demonstration.
2. **One identity/session boundary:** User owns personal resources; Admin has User capabilities plus explicit administrative operations. Federation later changes only how a Rendez user is authenticated before session creation.
3. **Ponytail/full:** direct feature handlers and SQL first. Add a transaction function for actual multi-write behavior. No speculative interface, service/repository hierarchy, worker, configuration, package or table.
4. **Preserve semantics:** approved observations are immutable; current price is a selection; observed_at differs from reviewed_at; receipts do not become advertised prices. Unknown is null, not zero. No generic verified flag.
5. **Constrain durable facts:** PK/FK/UNIQUE/CHECK and short transactions. Go validation supplies useful feedback; database checks protect integrity across concurrency and alternate writers. That distinction justifies necessary overlap.
6. **Incremental contracts/tests:** handwritten OpenAPI starts at M1, before its handlers. No HTTP code generation. Standard Go testing/httptest and real PostgreSQL prove behavior; no SQL mocks.
7. **Do not invent policy:** source dates, types, coverage and history are facts. Score/freshness labels remain unavailable until approved. Search relevance remains independent; BR-08 remains a recorded policy gap.
8. **Single-host ceiling:** local evidence survives container recreation. A rare crash orphan is acceptable; silently losing an acknowledged contribution or exposing private files is not.
9. **Capabilities over screens:** preserve Flutter/Riverpod, integrated discovery/details, receipt breakdown, favorites feedback/Undo and contribution history. Admin stays in the same Flutter app. No social backend or visual redesign.

## 3. Definition of “local core complete”

Before M7/M8, all of these must work together:

- Documented startup creates an isolated local core database, runs incremental migrations and loads deterministic non-sensitive fixtures.
- Guest browses/searches eligible places; drafts remain private, formerly public hidden places are unavailable, and absent prices/coordinates are honest missing values.
- Development User/Admin receive real random opaque sessions; DB stores only digests. Live session, active account, current role and ownership govern all protected APIs.
- Admin manages places and sourced generic goods/service prices. New observations preserve approved history and explicit units.
- Favorites persist, including idempotent save/remove, Undo and safe unavailable placeholders.
- User uploads actual JPEG/PNG evidence, submits for an existing place or linked new draft, and sees awaiting-review status.
- Admin sees private originals, enters reviewed structured data, approves/rejects atomically and supplies rejection reasons. No fake OCR or simulated success.
- Approved receipts provide dated total/guest spending examples separately from advertised prices. Missing totals/guests do not produce estimates; receipt originals remain private after approval.
- Flutter completes §22 with external networking unavailable, including restart persistence and pending/rejected updates preserving approved data.
- The normal production artifact cannot register development login.

No public receipt derivative, remote venue photo or font is necessary for this gate. Use explicit image placeholders and bundled typography. M6 includes native sharing of public place name/address; a deployed deep link is conditional and needs no social subsystem.

## 4. Repository observations

These current implementation observations supplement, rather than rewrite, the original reconciliation, which excluded backend inspection.

| Inspected source | Actual behavior / implication |
|---|---|
| `backend/go.mod` | Module `rendez-backend`, Go 1.26.0; Gin, GORM, JWT, pgx, UUID, godotenv and indirect dependencies. No chi/sqlc/Goose setup. Preserve module name; prune actual unused dependencies. |
| `backend/cmd/api/main.go` | Only `GET /health` is registered. Gin router, GORM ping, log package, HTTP timeouts and signal shutdown. Auth handlers are not wired. Keep `cmd/api`, improve live/ready, deadlines and pool closure. |
| `backend/internal/platform/db/db.go` | GORM connection with pool limits/retry loop. Replace with bounded pgxpool initialization. Do not carry SQL argument logging forward. |
| `backend/config/config.go` | `Load()` defaults to development, loads dotenv, requires JWT secret and predeclares OCR/map/upload settings. Replace with explicit environment and only currently needed settings. |
| `backend/internal/auth/{handler,service,password}.go` | Gin/GORM email/password registration, JWT access plus refresh tokens, refresh rotation and profile lookup. Logout deletes a refresh record, not a still-valid access JWT. Incompatible with approved session semantics. |
| `backend/pkg/jwt/jwt.go`, `pkg/middleware/auth.go` | Token contains user/role; middleware uses claims rather than current DB role/session. SHA-256 is a reusable standard-library pattern; the JWT system is not. |
| `backend/pkg/response/{response,errors}.go` | Useful safe Vietnamese error-envelope idea, but Gin-bound, uppercase codes, arbitrary details and no required request_id/retryable. Adapt into one small net/http helper. |
| `backend/pkg/middleware/{logger,recover}.go` | Correlation/timing and panic recovery exist. Replace with slog route-template logging and avoid logging arbitrary panic/request payloads. |
| `backend/internal/model/*.go` | Required email/password, `Place.Verified`, food-shaped `MenuItem`, float64 prices, public-shaped image paths and premature OCR JSONB. Not authoritative API models. `ErrCannotReviewOwnAction` is only a constant, not an approved four-eyes business rule. |
| `backend/migrations/000001…000007` | golang-migrate paired files create users/refresh tokens, places, menu/prices/images, favorites, contributions and OCR upfront, including cascade deletes. Do not replay as the new Goose schema. |
| `backend/Makefile` | Unconditional `.env` include, golang-migrate and `@latest` installation hint. Replace with reproducible commands and pinned tools. |
| `backend/docker-compose.yml`, `docker/Dockerfile` | PostgreSQL 16 and persistent DB/upload volumes; production-mode API with default JWT secret. Go 1.24 builder differs from module 1.26. Keep file paths/volume idea, correct environment/toolchain/exposure. |
| Existing Go tests | Password and JWT unit tests only. No proof of HTTP auth, ownership or publication. Replace obsolete tests with new boundary tests. |
| `mobile/lib/core/providers/app_providers.dart` | `AuthNotifier` starts authenticated and ignores credentials. `BookmarksNotifier` has global seeded IDs; `ContributionsNotifier` stores local summaries; `filteredPlacesProvider` reads fixtures. Keep Riverpod, replace authoritative data. |
| `mobile/lib/core/models/place.dart` | `Place` requires min/max price, distance, coordinates, rating and `isVerified`; `MenuItem` has only name/price/category. `latestBill` returns the first entry. Needs nullable, generic, sourced contracts. |
| `mobile/lib/core/models/bill_item.dart` | `RealBill.costPerPerson` substitutes whole total when guests are zero. Replace with unavailable; partial lines must not invent a receipt total. |
| `mobile/lib/core/models/user.dart` | `UserProfile` has no role; contributions lack owner/source/place ID and processing distinctions. Use server identity/status. |
| `ExploreScreen` | Repeats results 50 times; refresh delays 500 ms. Keep grid, replace with real fetch/pagination. |
| `ContributeScreen` | Stock-photo toggle, prefilled rows, invalid text parsed as zero; submit stores only a summary and current timestamp. No actual upload or immutable evidence. |
| `PlaceDetailScreen`, `BillBreakdownCard`, `MenuTabView` | Passed mock Place, boolean/unconditional trust labels, only latest receipt rendered, no price units/source dates. Revalidate by ID and render facts. |
| `BookmarksScreen`, `BouncingHeartButton` | Useful feedback/Undo, but mock lookup and global toggles. Preserve interaction with desired-state requests and account scoping. |
| `MainScaffold` and detail/search actions | Decorative map/social routes and report/directions success placeholders. No implemented Admin surface. Omit deferred actions rather than give false success. |
| `mobile/pubspec.yaml`, `AppTheme`, `MockData` | Riverpod/grid/intl/Google Fonts/cached images; no direct business HTTP/session/picker API. Font fetching and Unsplash fixtures would violate the offline gate. A warmed cache is insufficient. |
| Frontend baseline | Reconciliation reports incorrect imports in six files. Resolve during M6 and run analyzer; no current build pass is claimed. Device networking/picker permissions need verification. |

Git currently reports `backend/` and `docs/` as untracked. They are existing work, not disposable files. Future M0 checkpoints them and checks whether legacy migrations have been applied anywhere. No legacy database reset is authorized by this plan.

## 5. Dependency policy

| When | Dependency/tool | Reason and limit |
|---|---|---|
| M0 runtime | Go stdlib, chi, pgx/pgxpool | Standard HTTP/JSON/context/crypto/errors/slog; selected router and PostgreSQL driver. No ORM. |
| M0 development | Docker Compose, PostgreSQL, Goose, sqlc, Make | Reproducible local environment and incremental schema/queries. Pin compatible versions at implementation; no `@latest`. Match module Go baseline in Docker. |
| M1 | Existing google/uuid if needed | Reuse UUID parsing/generation; bearers use crypto/rand, not concatenated UUIDs. |
| M2 | PostgreSQL unaccent | Actual Vietnamese matching need. No text-search service/trigram yet. |
| Tests | testing, httptest, actual PostgreSQL | No SQL mocks or giant fixtures. Add a small shared test DB helper only when setup repeats. |
| M1+ | Handwritten `backend/openapi.yaml` | Current contracts only; no client/server generation. Representative assertions first; architecture's test-only OpenAPI validator can validate expanded M5 contracts. |
| M6 Flutter | Existing Riverpod/layout/intl plus actual transport/platform needs | Direct HTTP dependency already transitive for JSON/multipart; minimal native picker, secure-storage and native-share plugins when integrated. Pin supported versions after Android/iOS checks. No framework migration or location SDK merely for selected-origin coordinates. |
| M7 | Provider verification/client packages justified by spike | No provider code/configuration before this. |
| M8 | One benchmarked OCR integration | No multi-provider framework. |

Before M7, runtime needs only API, PostgreSQL, persistent local files and Flutter/OS capabilities. Prepare images, SDKs, modules, packages and fonts before disconnecting external networking. Test-only contract parsing is not a SaaS dependency.

No Redis, broker, search server, PostGIS, object-storage SDK, map API, local passwords or JWT/refresh family. No JSONB is needed in the local schema below: the hybrid policy permits heterogeneous attributes when actually needed, not an empty escape hatch now.

## 6. Minimal initial package layout

Reuse existing entry point/configuration/build locations. M0 only:

```text
backend/
  cmd/api/main.go
  cmd/api/main_test.go
  config/config.go
  internal/platform/db/db.go
  internal/platform/db/db_test.go
  internal/platform/httpx/http.go
  migrations/core/00001_bootstrap.sql
  sqlc.yaml
  Makefile
  docker-compose.yml
  docker/Dockerfile
  .env.example
  README.md
```

`httpx/http.go` contains small shared strict JSON/error/logging helpers. Split only for actual complexity. No global domain/model package. The new `migrations/core` active path deliberately excludes legacy migrations and targets a separate database; the old files/data remain untouched. Bootstrap exercises Goose without domain tables. sqlc starts with no feature entries; `make generate` reports no current queries at M0 rather than inventing a table.

M1 adds auth; M2 places; M4 favorites; M5 contributions. Each starts with a handler, SQL, feature-private generated queries and meaningful tests. Prices/search/distance stay in places; upload/review stay in contributions. No empty users/evidence/OCR/report packages.

Cross-table approval queries live in contributions and use one pgx transaction. Do not import another feature's private generated package or start nested transactions. No generic unit-of-work abstraction.

## 7. Milestone overview

| Milestone | Runnable result | Dependencies | Gate |
|---|---|---|---|
| M0 | API, DB, migrations, health | Local tools | Local core |
| M1 | Dev User/Admin → real opaque session | M0 | Local core |
| M2 | Admin places → Guest discovery/detail/distance | M1 | Local core |
| M3 | Sourced manual prices → current/history | M2 | Local core |
| M4 | Persistent owner-scoped favorites | M2; M3 cards | Local core |
| M5 | Private submission → manual decision → public data | M1–M4 | Local core |
| M6 | Existing Flutter completes offline journey | M0–M5 | Local-core completion |
| M7 | Google/Apple into existing users/sessions | M6 and spike | Post-local |
| M8 | OCR assists existing review | M6 and benchmark | Post-local |
| M9 | Triggered operational/product additions | Relevant slice | Conditional |

### Shared commands and contracts

Commands below are **planned Makefile targets**, not claims about the current Makefile. Run from repository root. M0 introduces these exact target contracts, allowing subsequent agents to implement a milestone without inventing a test runner:

| Target | Required behavior |
|---|---|
| `make -C backend tools` | Check/install pinned Goose/sqlc in ignored backend tool directory. |
| `make -C backend local-db` | Start isolated core PostgreSQL; bounded readiness wait. |
| `make -C backend migrate` | Goose up on core database and migrations/core only; no reset. |
| `make -C backend local-up` | Build/start API after migrations, wait readiness, preserve volumes. Explicit dev build from M1. |
| `make -C backend local-down` | Stop without deleting volumes. |
| `make -C backend seed-dev` | M1+: explicitly load deterministic development fixtures; reruns do not erase edits. |
| `make -C backend generate` | Generate only current sqlc feature entries; review regeneration diff. |
| `make -C backend test` | Standard unit tests; from M1 include default and dev-tag builds. |
| `make -C backend test-integration TEST_RUN='…'` | Dedicated test Compose project/database, migrate, real DB tests with `-count=1`; fail if setup fails. Never reset developer data. |
| `make -C backend verify-m0` … `verify-m5` | Introduce each target in its milestone: run its vertical test, errors/contracts and generation check. Nonzero exit on failure. |
| `make -C backend verify-local-core` | M6 real HTTP journey plus restart persistence; no external calls. Flutter device acceptance remains separate. |

Integration tests use `-tags=integration` and explicit TEST_DATABASE_URL restricted to the dedicated test DB. A helper may reset only that DB after checking its test-only name. Normal startup never drops volumes. A missing DB fails integration targets rather than silently skipping. Use `-race` for contested writes. Exact test names below are implementation requirements.

Business paths have `/v1`; health and literal `/dev/login` are exceptions. Success is direct JSON, not inherited Gin `{data:…}`. Collections use `{items,next_cursor}` or discovery `{items,next_offset}`. UUID strings, integer VND, decimal-string quantities, RFC3339 timestamps; date-only observations include precision and calendar date. Default page size 20/max 50, empty arrays and explicit nulls.

One error envelope: `{error:{code,message,request_id,retryable,details?}}`; details only allowlisted field/code pairs. Statuses: 400 malformed/cursor; 401 missing/expired session; 403 wrong role; private 404; formerly public 410 `place_unavailable`; 409 revision/state/retry conflict; 413 size; 415 media; 422 domain validation; 428 missing precondition; 503 dependency unavailable; 504 timeout; 500 unexpected. DB failure is not invalid authentication. Never return raw SQL, paths, secrets or private payloads.

Admin mutations use explicit expected_revision; DELETE can use its query parameter. Missing →428, stale →409. Lock aggregate rows for changes. Sensitive publication rechecks active Admin/session inside its transaction. Lock order: users sorted → session → place → contribution → assets sorted → items sorted. Logout and operator role/active changes use compatible locks. No external calls inside transactions.

## 8. M0 detailed implementation plan — Runnable skeleton

**Goal/why:** repeatable real database-backed process before domain work. Covers SRS §2.5.1/2.5.2, NFR-18/19/20/21/22/23 foundations, SEC-05/10. Infrastructure evidence only.

**Dependencies:** Docker/Compose, compatible Go, pinned Goose/sqlc. **Non-goals:** domain tables, auth, uploads/providers/workers and full OpenAPI.

**Conversion:** first checkpoint existing untracked work and identify any applied legacy migrations. Leave old migrations/volumes intact; create a separate core DB/volume/project. No automatic import of verified flags, floating prices, password users or OCR rows. A real legacy-data import needs its own reviewed mapping before replacing that database; isolated local development can proceed meanwhile. After checkpoint, remove incompatible unwired Gin/GORM/auth/JWT/model packages from the active build instead of retaining dead dependencies. This is future M0 work, not done by this document.

**Tables/migration/indexes:** only Goose metadata, `00001_bootstrap.sql`, no domain tables/indexes. Bootstrap exercises migration-from-empty and schema compatibility. No fake sqlc queries.

**Files:** §6 files; update go.mod/go.sum, main/config/db/Makefile/Compose/Dockerfile; add small HTTP helper, process/DB tests, secret-free example and README. Use PostgreSQL 18 for the separate core target; never mount an existing PostgreSQL 16 data directory into it. Match Docker Go builder to module-compatible version instead of reopening toolchain choice.

**Config:** explicit APP_ENV allowlist development/test/production, HTTP_ADDR and DATABASE_URL only. No default development mode. Fixed bounded pool/timeouts initially; no future knobs. Local Compose credentials are labeled local-only, host ports loopback-bound. No committed real secret. Production public TLS remains a launch obligation; local HTTP is confined to controlled loopback/emulator development.

| API | Auth | Request → response | Failure / transaction |
|---|---|---|---|
| GET /health/live | Guest | None → `{status:"ok"}` | No DB call/transaction |
| GET /health/ready | Guest | None → `{status:"ready"}` after bounded DB/schema check | 503 DB loss/incompatible schema/shutdown, no internals |

**SQL/behavior:** ping and Goose version query only. Close partial pools on startup errors. Bounded HTTP header/body/idle settings; readiness false before shutdown, drain HTTP, close pool last. JSON 404/405. slog logs route template, generated request ID, method/status/duration, not raw query/body/credential or arbitrary panic contents.

**Tests:** config and safe error/routing httptest; real PostgreSQL `TestM0Postgres` migration-from-empty/readiness. DB stopped → live 200/ready 503 within deadline. Signal shutdown must terminate cleanly.

```sh
make -C backend tools
make -C backend local-db
make -C backend migrate
make -C backend local-up
curl --fail http://127.0.0.1:8080/health/live
curl --fail http://127.0.0.1:8080/health/ready
make -C backend test
make -C backend test-integration TEST_RUN='TestM0'
make -C backend verify-m0
```

**Acceptance/commit boundary:** clean isolated DB migrates, API responds correctly, tests/shutdown pass without provider configuration. verify-m0 includes empty test DB and DB-offline checks. Likely failures: toolchain mismatch, stale migration paths, reused volume, dotenv reliance, false readiness. Defer all domain/storage/provider machinery. Commit one runnable plumbing conversion, with existing work recoverable.

## 9. M1 detailed implementation plan — Development auth and real sessions

**Goal/why:** exercise authenticated workflows without provider registration. Covers local FR-02/03, BR-09, SEC-01/03/05/06/09/11, approved §13.9/13.12. FR-01 and genuine provider authentication remain M7; no-password policy supersedes password-shaped SEC-02 implementation.

**Dependencies:** M0. **Non-goals:** identities/attempts, OAuth/JWKS/PKCE, linking, provider refresh/keyring, recent provider reauthentication, role-management UI.

| New table | Columns / constraints | Indexes |
|---|---|---|
| users | id UUID PK; display_name nonblank ≤200 chars; role CHECK user/admin; active boolean; created_at timestamptz | PK |
| sessions | id UUID PK; user_id FK users RESTRICT; token_hash bytea UNIQUE length 32; created_at, authenticated_at, expires_at; nullable revoked_at; expiry > creation | Hash uniqueness; user_id |

Migration `00002_sessions.sql`. No email/password/identity placeholder. Fixed seven-day maximum session lifetime from architecture §21, no sliding renewal. DB time checks expiry.

**Files:** internal/auth/handler.go (profile/logout/session creation), middleware.go (typed principal/live lookup/Admin guard), dev.go and dev_disabled.go (complementary build tags), queries.sql, generated internal/db, auth_test.go. Modify main, sqlc config, Makefile and explicit seed command; introduce openapi.yaml before handlers. A small `-seed-dev` branch in the existing executable suffices.

**Dev gate:** only an explicit `dev` build contains development login/seeding. Normal artifact cannot expose it by changing an environment variable. Dev build requires APP_ENV=development and refuses production. Seed fixed UUIDs for fixture keys user/admin; never accept arbitrary IDs/roles/email. Integration fixtures create a second ordinary owner directly for isolation tests. Seeds are development-only and non-destructive.

| API | Auth | Essential request → response | Errors / retry |
|---|---|---|---|
| POST /dev/login | Dev only | `{fixture:"user" or "admin"}` →201 bearer, token_type, expires_at, safe user id/name/role | 422 unknown key; 503 DB; normal artifact 404. New session per intentional login. |
| GET /v1/me | User | Bearer → id, display_name, role, session_expires_at | 401 invalid/expired/revoked; DB 503 |
| DELETE /v1/auth/session | Presented bearer | None →204 | Repeated/invalid bearer 204; valid-token DB revocation failure 503 |

**SQL/transactions:** crypto/rand generates 32 bytes, base64url bearer; SHA-256 digest only persisted. Lock active user when issuing session. Middleware joins nonrevoked/unexpired session to active user/current role, no role cache. Logout persists revocation under lock; subsequent requests deny. Later sensitive writes use the same locked authorization check. `/me` never accepts target user ID. Raw bearer returned once, no decryptable replay storage; lost login response means login again.

**Validation/tests:** strict JSON rejects extra user_id/role/trailing documents. Unit tests cover token generation/digest shape and guard responses. Real DB `TestM1Sessions` covers both roles, expiry, revocation, role/active changes, DB outage distinction. Default-build tests prove /dev/login absent even with development environment; dev-build tests prove production refusal. Never print bearer in tests/logs.

```sh
make -C backend migrate
make -C backend seed-dev
make -C backend local-up
make -C backend generate
make -C backend test
make -C backend test-integration TEST_RUN='TestM1'
make -C backend verify-m1
```

verify-m1 logs in both fixtures, checks /me/guards, revokes and rechecks, then tests normal artifact route absence. **Acceptance/commit:** one session mechanism and live RBAC work without providers. Failure modes: environment-only gate, token role caching, DB errors as 401, seeds overwriting users. Defer all federation/recent-auth mechanisms. Commit session schema, API/contracts and runnable verification together.

## 10. M2 detailed implementation plan — Place catalog and discovery

**Goal/why:** a Guest discovers real published places, including places without price data. This gives all later contributions/prices stable targets. Covers FR-04/06/08/12, category portion of FR-07, BR-01/02/03/14, SEC-03/07, NFR-02/03/09/10, approved §13.1/13.8/13.10. Price filtering starts M3; no claim it is already implemented.

**Dependencies:** M1 live Admin guard; deterministic development catalog. **Non-goals:** prices, galleries, reports, social, maps, geocoding, score, freshness policy, nationwide coverage, catalog-management UI.

| New table | Columns and constraints | Indexes |
|---|---|---|
| categories | code text PK, name_vi nonblank, enabled boolean | PK only |
| pricing_units | code text PK, dimension nonblank, label_vi nonblank, enabled boolean | PK only |
| places | id UUID PK; name ≤200/address ≤500 nonblank; city_code nonblank; category_code nullable FK categories RESTRICT; opening_hours nullable bounded text; lat/lon nullable paired finite coordinates in valid ranges; publication_state CHECK draft/published/hidden; revision bigint positive; created_by, updated_by FK users RESTRICT; created_at/updated_at; first_published_at nullable; deleted_at nullable; state_reason nullable | Public category/name/id partial B-tree; Admin state/created_at/id index |

Published requires non-null category and first_published_at; deleted implies hidden; hide/delete require nonblank reason. No user-location history, verified flag, price/rating or JSONB field. name/address are required even on proposed drafts; category may remain unknown until publication. Ordinary IDs/relations are never physically deleted through the API.

**Migration:** `00003_catalog.sql` creates these tables and PostgreSQL unaccent. Seed content is separate development data, not a hard-coded domain enum. Use one configured supported city code/label/timezone, with illustrative Đà Nẵng development fixtures and small demo categories, clearly not the approved launch list. Pricing unit fixtures include item, person, room_hour and table_hour. Enforce supported city and enabled catalog references in the write transaction. Do not add a cities CRUD subsystem.

**Files:** internal/places/handler.go, queries.sql, generated internal/db, places_test.go; modify main routing, config for current supported-city descriptor, sqlc.yaml, OpenAPI, seed-dev fixtures and Makefile verify-m2. Search/distance SQL stays here. Return no invented image URL; detail opening hours can be null.

| API | Auth | Essential request → response | Errors / transaction/idempotency |
|---|---|---|---|
| GET /v1/catalog | Guest | None → supported city, enabled categories/units, currently supported filters/sorts | 503; no unsupported controls advertised |
| GET /v1/places | Guest | q, category, origin_lat/lon, radius_m, sort=relevance/distance, offset/limit → items with id/name/address/category, nullable coordinates/distance, distance_method, next_offset | 422 unsupported filters/sort/invalid origin; 503/504 |
| GET /v1/places/{id} | Guest | ID, optional origin pair → eligible basic detail/revision and nullable distance | Draft/unknown 404; formerly public unavailable 410, generic only |
| GET /v1/admin/places | Admin | State/q, cursor/limit → private catalog including drafts/hidden, revisions | 401/403/400/503; stable created_at/id cursor |
| GET /v1/admin/places/{id} | Admin | ID → editable detail/revision | 404 unknown |
| POST /v1/admin/places | Admin | Client-generated id, name/address/category?/coordinates?/opening_hours? →201 draft record/revision | Duplicate ID 409; GET that ID to reconcile uncertain success; no automatic POST retry/new ID |
| PATCH /v1/admin/places/{id} | Admin | expected_revision, allowlisted facts and/or publication_state; reason for hide → updated record/revision | 428 missing, 409 stale/state, 422 fields; locked place transaction |
| DELETE /v1/admin/places/{id} | Admin | expected_revision and reason →204 tombstone | Already deleted desired state 204; otherwise locked revision check; never cascade history |

**Search SQL:** published/nondeleted eligibility applies before every filter/order/page. Trim empty q to browse. Bound q to 120 characters; normalize UTF-8/case/accents consistently in PostgreSQL, including đ and composed/decomposed text. Parameterized literal substring LIKE escapes %, _ and escape character. Match name/address/category label. Relevance: exact normalized name, name prefix, name substring, other matching fields, normalized name then UUID; no q means name/UUID. Never interpolate ORDER BY from input; use allowlisted static sqlc query variants.

**Distance:** paired origin and venue coordinates; otherwise distance_m=null. Haversine with clamped intermediate value and mean Earth radius 6,371,008.8 m, computed in PostgreSQL before radius/sort/pagination. Explicit nearest/radius without origin is 422. Radius positive ≤100 km. Unknown venue coordinates remain in ordinary browse but cannot match a radius. City choice is not an origin. Do not store/log request origin. No routing API, travel time or PostGIS.

**Paging:** default 20/max 50, bounded offset ≤5,000; limit+1 determines next_offset, no fabricated total. Fixed-data ties deterministic; later publications may shift pages, so clients deduplicate and restart after filters/refresh. Admin cursor validates fixed sort/filter context. No search projection/index until measured.

**Writes/auth:** strict JSON excludes caller-supplied creator/role/revision increment. Create always draft; only explicit Admin publish with valid catalog/city makes it public. Basic updates/hide/delete lock active Admin/session then place; increment revision and record last actor/time/reason. Never return hidden fields in Guest errors. M5 extends publication checks for community origin; that origin cannot be created through M2 APIs.

**Tests:** unit coordinate/query/field validation and literal wildcard escaping. Real DB `TestM2Catalog`: Admin create→publish→Guest browse/detail→hide→Guest 410/list absence→delete; draft 404; ordinary User denied. `TestM2VietnameseSearch` tests Đà Nẵng/da nang, đ/Đ, NFC/NFD, mixed case, literal `%/_`, category and no-match. `TestM2DistancePagination` includes missing origin, coincident points and nearest result outside first unsorted page. Record representative query timing/EXPLAIN on fixed synthetic one-city data; do not claim SRS performance from two fixtures.

```sh
make -C backend migrate
make -C backend seed-dev
make -C backend local-up
curl --fail http://127.0.0.1:8080/v1/catalog
curl --fail 'http://127.0.0.1:8080/v1/places?q=da%20nang'
make -C backend generate
make -C backend test
make -C backend test-integration TEST_RUN='TestM2'
make -C backend verify-m2
```

**Acceptance/commit:** Admin and Guest vertical path works without prices/providers; Vietnamese matching and null distance are tested. Likely failures: unaccent/collation behavior, SQL wildcard injection semantics, sort after LIMIT, hidden leakage, stale updates, incompatible query normalization. Commit schema, endpoints, fixtures/contracts/tests together. Defer price predicates until M3, all spatial/search infrastructure and full audit-history machinery. Last-change attribution is deliberately not a complete catalog event log.

## 11. M3 detailed implementation plan — Manual price publication

**Goal/why:** Rendez's core price value works before community intake/OCR. Admin explicitly confirms a documented source and creates immutable priced facts. Covers structured/date/unit portion FR-05, price portion FR-07, FR-16, BR-03/04/07, NFR-08/10/14/18/19/25, approved §13.2–13.4/13.10/13.11. Receipt-based FR-09 arrives M5; public source photos are not fabricated.

**Dependencies:** M2 places/units, M1 sessions. **Non-goals:** contributions, OCR, review drafts/versions, separate publications/provenance table, score/freshness thresholds, universal venue min/max or visit prediction.

### Minimum schema

| New table | Columns and constraints | Indexes |
|---|---|---|
| price_items | id UUID PK; place_id FK places RESTRICT; unit_code FK pricing_units RESTRICT; created_at | place_id/id |
| price_observations | id UUID PK; item_id FK price_items RESTRICT; display_name nonblank ≤200; amount_vnd bigint CHECK 0..10^12; basis_quantity numeric(12,3) finite >0; conditions nullable bounded text; source_description nonblank ≤2,000; observed_at nullable plus precision CHECK instant/date/unknown; reviewed_by FK users RESTRICT; reviewed_at timestamptz | item_id/reviewed_at/id; UNIQUE(item_id,id) for selection FK |
| current_prices | item_id PK/FK price_items; observation_id nullable; selected_by FK users; selected_at; reason nonblank | Composite FK (item_id,observation_id) → price_observations(item_id,id) |

Migration `00004_manual_prices.sql`. Current selection is a separate row, not a mutable flag on historical observations. This **one narrow composite FK is retained** because wrong-item selection corrupts prices; it is acyclic and ordinary, unlike the target's larger cyclic/version/publication graph. No additional provenance table: each manual observation already records its source, source date and confirmation actor/time. Fixed currency VND is explicit in DTO; no multi-currency column needed yet.

Unit is stable per item identity. A different basis quantity is permitted and explicit (e.g. price for two hours); a different unit/variant requires a new item, not silently repurposing an existing one. Observation names/amount/basis/conditions/source/date/reviewer are insert-only. Date precision unknown means observed_at null; date uses city-local day start internally and returns calendar date/precision. Review date never fills unknown observation time. Do not label selected data fresh.

**Files:** extend places/handler.go and queries.sql, add places/prices.go for multi-write operation/arithmetic and prices_test.go. Extend generated queries, migration, OpenAPI/catalog advertised filters, seed-dev and verify-m3. No menu service/repository or future evidence package.

| API | Auth | Request → response | Errors / transaction/idempotency |
|---|---|---|---|
| POST /v1/admin/places/{id}/price-observations | Admin | expected_revision; client observation id; existing item_id OR new item id/unit; name, amount_vnd, basis_quantity, conditions?, source_description, observed_at/precision, select_current, reason →201 item/observation IDs, selection and place revision | 422 invalid/mixed unit; 409 stale/duplicate observation ID; explicit confirmation operation |
| GET /v1/places/{id}/prices | Guest | item cursor/limit → selected eligible observations with unit/basis, source/observed/reviewed dates, nullable freshness classification | 404/410 parent; [] if no selection |
| GET /v1/places/{id}/prices/{item_id}/history | Guest | Cursor → immutable approved observations, selected flag, source/date | 404 wrong place/item; 410 unavailable place; reviewed_at/id keyset |
| PATCH /v1/admin/places/{id}/prices/{item_id} | Admin | expected_revision, selected observation_id or null (retire), reason → new current selection/place revision | 422 wrong source/item; 409 stale; 428 missing. Never edits historical facts. |
| Existing GET places/detail | Guest | Extend price_basis/unit/min/max predicates and explicitly based price summary | Invalid combinations 422; missing evidence does not match priced filter |

**Manual publication transaction:** authenticate/recheck Admin/session; lock place then relevant item; check revision/nondeleted target and unit. A duplicate observation ID returns 409 observation_exists without reapplying any selection. Recover an ambiguous response by fetching the item history and current selection; compare the persisted observation ID/facts before deciding whether another intentional operation is needed. Do not generate a fresh ID automatically. This explicit-conflict contract avoids storing a second command snapshot or hash for manual entry. Create item if requested; append observation; optionally update current_prices; increment place revision; commit. No network calls. Existing hidden place stays hidden. The endpoint itself is an explicit Admin confirmation; no unreviewed data is inserted into observations and no second mandatory Admin person is invented.

**Selections:** verify source belongs to item/place and is eligible. Replacing a known newer observed date with older/unknown evidence requires explicit reason acknowledging the older source; otherwise 409 `older_source_requires_confirmation`. Equal dates still require current revision and explicit selection. Partial batch/menu does not retire unmentioned items. Retire clears selection, preserves history. No automatic previous-price fallback. At M3 a mistaken source can be deselected or place hidden; source-specific withdrawal arrives with M5 publication access.

**Exact prices/filter:** reject fractional VND, negatives, overflow, NaN/infinity and malformed decimal quantities; zero is genuinely free. `price_basis=listed_unit_price` and unit_code required with min/max. Match any current observation in that same unit, comparing amount/basis using PostgreSQL numeric exact arithmetic. Never compare room-hour against person/item or receipt spending. Price summaries aggregate only comparable units and include basis/date; omit a universal minPrice/maxPrice. Other price bases are 422 until implemented. Public query joins place eligibility and current selection, not “latest inserted”.

**Tests:** unit money/decimal/date validation, unknown vs zero, older-source guard. Real DB `TestM3PriceHistory` first price→newer price→old queryable; room-hour and item fixtures; same ID repeat returns conflict with no duplicate observation or selection change; recover through history; retire without history deletion. `TestM3PriceAtomicity` failure between observation insertion and selection rolls back both, concurrent revisions serialize, foreign-item FK fails. `TestM3PriceFilters` exact basis scaling, mixed-unit exclusion, no-data browse inclusion and priced-filter exclusion.

```sh
make -C backend migrate
make -C backend seed-dev
make -C backend generate
make -C backend test
make -C backend test-integration TEST_RUN='TestM3'
make -C backend verify-m3
```

verify-m3 runs Admin first/new price and Guest current/history through HTTP, including revision conflicts. **Acceptance/commit:** immutable sourced prices and comparable filtering work with no contribution/OCR tables. Failures: destructive UPDATE, unqualified ranges, wrong-item pointer, invented date, missing-history rollback, replay selecting old data again. Commit only price schema/API/tests. Defer public images, receipt examples, future provenance/version machinery and policy labels.

## 12. M4 detailed implementation plan — Favorites

**Goal/why:** first durable personal business feature; prove ownership before private evidence. Covers FR-10/11, BR-09, SEC-01/06, NFR-18/19, approved §13.1/13.12.

**Dependencies:** M1/M2 and M3 card summaries. **Non-goals:** public saved collections, recommendations, social graph, generic favorite repository/service.

**Table/migration:** `00005_favorites.sql`: favorites(user_id FK users RESTRICT, place_id FK places RESTRICT, saved_at timestamptz), composite PK(user_id,place_id). Index(user_id,saved_at,place_id) for list paging; place_id index for place-related queries if actually used. No synthetic favorite ID or duplicated place name/price.

**Files:** internal/favorites/handler.go, queries.sql, generated internal/db and favorites_test.go; main/sqlc/OpenAPI/verify-m4. Direct queries suffice.

| API | Auth | Request → response | Errors / transaction/idempotency |
|---|---|---|---|
| GET /v1/me/favorites | User | cursor/limit → items,next_cursor; available cards or `{id,available:false,label:"Địa điểm không còn khả dụng"}` | 401/400/503; no hidden name/address/price/image |
| PUT /v1/me/favorites/{place_id} | User | No body →200 `{saved:true}` | 404 draft/unknown, 410 formerly public unavailable; insert-on-conflict |
| DELETE /v1/me/favorites/{place_id} | User | No body →204 | Absent favorite succeeds; unavailable removal allowed |

**SQL/auth:** owner comes exclusively from principal. List uses saved_at/place_id keyset and includes unavailable tombstones, rather than inner-joining them away. PUT locks/checks eligible place and inserts on conflict; hide and save serialize on place, so no accidental admission of a draft. DELETE always owner-scoped. Admin can access own favorites, not arbitrary users'. No caller user_id field.

**Tests:** minimal cursor validation; real DB `TestM4Favorites`: repeat PUT has one row and stable saved_at; absent DELETE 204; second User cannot see/change first user's set; hide leaves safe placeholder removable by owner. `TestM4Undo` sends DELETE then PUT as ordered desired states and confirms persisted result.

```sh
make -C backend migrate
make -C backend generate
make -C backend test
make -C backend test-integration TEST_RUN='TestM4'
make -C backend verify-m4
```

**Acceptance/commit:** save/list/remove/retry remain durable/owner-scoped, including unavailable target. Failure modes: unordered toggle endpoint, caller user_id, hidden data leakage, favorites disappearing on hide. Defer global favorites counts/recommendations; Flutter optimistic serialization comes M6. Commit table, direct API and ownership tests together.

## 13. M5 detailed implementation plan — Contributions without OCR

**Goal/why:** complete private evidence → manual Admin review → approved public facts, entirely locally. Covers FR-13/16/17/18/21/23, manual-entry/correction intent of FR-15/22, structural/basic-value portion FR-19, reasons from FR-20 and approved §13.12, BR-04/11/12/13/14, SEC-01/03/06/07/08, NFR-07/13/14/15/18/19. Receipt examples implement approved FR-09 interpretation.

**Important coverage limit:** image/metadata/basic reviewed-value checks run automatically, followed by manual Admin confirmation. OCR extractability is explicitly `not_run` in this phase. This follows Phase 3's manual-first direction and UC-10 fallback; it does not claim full OCR FR-14/15/19/22 compliance. A malformed pre-intake upload is a 4xx, not an invented persisted rejected contribution. Accepted valid evidence can go directly to manual review.

**Dependencies:** M1–M4, persistent local filesystem. **Non-goals:** OCR packages/jobs/runs, asynchronous workers, leases, extraction versions, generic automatic-check table, global admin_actions, server-side editable review drafts, replacement chains, public-image delivery/derivatives, object storage.

### Tables and migrations introduced now

Use `00006_contributions.sql` only. No target-schema bulk import.

| Table/change | Columns and constraints | Indexes / reason |
|---|---|---|
| assets | id UUID PK supplied as client upload ID; owner_id FK users RESTRICT; storage_key UNIQUE generated by backend; sha256 bytea length 32; media_type CHECK JPEG/PNG; encoded_size positive ≤10 MiB; width/height positive within limits; validated_at; created_at | owner_id/created_at/id. No public flag or URL; every asset here is a private validated original. |
| contributions | id UUID PK supplied by client; submitter_id FK users; place_id FK places; kind CHECK menu/receipt; submitted_place_name/address immutable snapshots; submitted_observed_at/precision; captured_at nullable plus captured_precision CHECK instant/date/unknown; submitted_guest_count nullable 1..1000; submitted_at; validation_version nonblank; image_validation=passed, extraction_state=not_run | owner/submitted_at/id; place_id. For receipt require observation date and capture time/date metadata; menu may explicitly have unknown observation date. No editable state enum yet. |
| contribution_assets | contribution_id FK contributions RESTRICT; asset_id UNIQUE FK assets RESTRICT; position 1..5; PK(contribution_id,position) | Unique asset prevents attaching one original to multiple immutable submissions. Owner match and 1..5 count checked transactionally. |
| moderation_decisions | contribution_id PK/FK contributions RESTRICT; request_id UUID UNIQUE; command_hash bytea length 32; outcome CHECK approved/rejected; reviewed_by FK users; reviewed_at; reason nonblank; reviewed_observed_at/precision; coverage CHECK unknown/partial/complete; receipt_total_vnd nullable 0..10^12; guest_count nullable 1..1000; reconciliation_note nullable; source_description bounded; withdrawn_at/by/reason nullable all-or-none | reviewed_at/contribution_id for history. One immutable final decision/header; only separately named access-withdrawal columns may change. |
| receipt_lines | contribution_id FK moderation_decisions RESTRICT; position positive; display_name bounded; quantity nullable positive finite numeric(12,3); unit_amount_vnd nullable; line_total_vnd nullable, money bounds; PK(contribution_id,position) | Approved receipt breakdown only; unknown values stay null. No forced arithmetic equality with total. |
| places alteration | origin CHECK admin/community, existing rows backfilled admin | Needed now to guard community publication; do not rewrite existing IDs/state. |
| price_observations alteration | nullable contribution_id FK moderation_decisions RESTRICT; source_kind CHECK admin_observation/menu, existing backfilled admin_observation; manual implies null contribution, menu implies non-null | contribution_id index for history/withdrawal. No receipt source kind allowed for advertised price observations. |

Observation fields in M3 remain immutable. Menu approval copies reviewed source description/date/reviewer into observations in the same transaction and links their decision; these are frozen snapshots, not independent editable duplicates. Public reads additionally require a linked approved, nonwithdrawn decision for community observations. Same-place/outcome/date consistency is enforced in the locked insertion operation and real DB tests; do not add a cross-table trigger graph. No JSONB copy of the command.

Contribution state is projected from its final decision: no decision → awaiting_review, otherwise approved/rejected. An outcome is immutable even after public access withdrawal. No processing state exists until actual OCR M8; migration can add typed processing facts then. Manual review state is not hidden in an overloaded verified boolean.

**Why no separate evidence/publications/versions:** intake is the immutable evidence header; ordered assets supply source bytes; decision is the final reviewed header; menu observations/receipt lines are immutable reviewed facts. Access withdrawal is a separately named field group, not a changed approval outcome. That supplies source lineage and public eligibility without a second lifecycle. Split only when multiple independently published versions/access grants or saved collaborative reviews actually appear.

**Admin editing:** fields remain an in-memory Flutter form until final confirm. Decision request carries the complete reviewed snapshot, not a pointer to mutable draft rows. Editing and approval are one atomic backend operation. On validation/conflict the UI retains entered fields. App termination before confirmation loses unsaved review work; this deliberate ceiling does not alter submitted evidence or an approved version.

**Resubmission:** correction creates a new contribution ID with newly uploaded original assets (bytes can be identical). Preserve old records/decisions; do not edit or auto-supersede earlier submissions. Existing unpublished target may be reused only by a submitter already owning a contribution for that draft; ordinary users cannot discover arbitrary drafts. No replaces_id chain is needed. Concurrent reviews remain protected by place revision/source-date selection rules.

### Private image path

**Files:** contributions/handler.go, upload.go, review.go, queries.sql, generated internal/db, contributions_test.go/upload_test.go; extend places queries to filter decision visibility/receipts; update OpenAPI/main/config/Compose/Makefile/README. Add local consented/synthetic JPEG/PNG testdata only now. No storage interface: a concrete configured filesystem root is sufficient.

Add STORAGE_ROOT configuration and persistent mount now. Root service-only, random generated keys, no user filenames/paths, no static file server. Body cap 11 MiB including multipart; single file ≤10 MiB; JPEG/PNG decoded ≤20 megapixels, each dimension ≤10,000; at most five pages/submission. Normal JSON capped at 1 MiB, ≤500 reviewed lines, bounded Unicode names/notes. Limits are architecture operational defaults, not freshness thresholds.

Flow: authenticate → cap/parse request → bounded format/dimension/full decode validation → write validated original bytes to random temporary file in destination filesystem → fsync/close → atomic non-overwriting rename and directory sync → insert DB asset metadata → acknowledge. At most two concurrent image decodes in-process; no queue subsystem. Validate before allocating from claimed dimensions; malformed/truncated/HTML/SVG/PDF/unsupported formats are rejected. Original EXIF never sets venue coordinates or grants public access.

On known DB failure after rename, delete the new file where practical. If commit result is uncertain, first query by upload ID; do not delete bytes that may have an acknowledged DB row. Crash may leave an unreferenced file; no lease/reservation workflow. No automatic deletion of attached/rejected/old evidence. Start with an operator-run orphan cleanup when accumulated orphans warrant it: stop writes, dry-run compare keys with DB, delete only old unreferenced temporary/final files after conservative grace. Grace is operational, not evidence expiry; no concurrent attachment sweeper until actually needed.

Private bytes endpoint checks owner or live Admin role every time, streams from generated key, sends private/no-store, correct content type and nosniff. Do not put private files into Flutter's cached_network_image disk cache. Receipt approval never makes its image public; all local-core originals are private, including menus. Guest sees structured data and an honest source-image unavailable state. Public menu/receipt source representations require the later explicit privacy-safe delivery slice; full image-display FR-05 is not falsely marked done here.

### APIs introduced now

| API | Auth | Essential request → response | Errors / transaction/idempotency |
|---|---|---|---|
| POST /v1/uploads | User | multipart file + client_upload_id →201 asset id, type, dimensions/size | 413/415/422; 503 storage/DB. Same owner/id and same validated hash →existing result; changed bytes 409; private IDs do not confer ownership. |
| GET /v1/uploads/{client_upload_id} | Owner | None → upload id/ready or attached status/metadata | Outside owner 404; recover lost response without uploading again |
| GET /v1/assets/{id} | Owner or Admin | None → private binary image | 401/404; missing accepted bytes 503 incident, not rejection |
| POST /v1/contributions | User | id; place_id OR proposed name/address/category?; kind; ordered own asset IDs; observed_at/precision; captured_at/precision for receipt; optional guests →201 id, place_id, awaiting_review, submitted_at, status URL | 422 invalid; 404 private/unknown target; 410 unavailable public target; 409 reused/conflicting source/ID; atomic draft+submission+links |
| GET /v1/me/contributions | User | Cursor/limit → own summaries/state/dates/reason | Owner-scoped submitted_at/id keyset; 401/400/503 |
| GET /v1/me/contributions/{id} | Owner | None → immutable submitted facts/assets plus safe final reviewed facts/reason | Other owner 404; awaiting/rejected records return 200 |
| GET /v1/admin/contributions | Admin | state, cursor/limit → manual queue with target/type/date | No fabricated processing queue; same bounded paging |
| GET /v1/admin/contributions/{id} | Admin | None → source facts/private asset IDs, decision if any, current place revision/prices | 404; source missing is explicit unavailable, no approval allowed |
| POST /v1/admin/contributions/{id}/decision | Admin | request_id; expected_place_revision; outcome/reason; for approve reviewed source/date/coverage plus menu lines/mappings/selections OR receipt header/lines | 200 persisted decision/state/place revision; 428/409/422; one final atomic decision |
| POST /v1/admin/contributions/{id}/withdraw | Admin | expected_place_revision, reason →200 withdrawn access state | Only approved; desired-state replay succeeds; atomic pointer clearing, no outcome rewrite |
| GET /v1/places/{id}/receipts | Guest | Cursor/limit → approved nonwithdrawn dated receipt headers/lines, nullable spending; image null | 404/410; date/id keyset, no originals/submitter/rejection fields |

Existing detail/list gain a nullable typed receipt example and `price_basis=receipt_per_person` filter; no separate cost endpoint. Admin uploads use the same User-capable intake, then explicitly confirms with live Admin role. No duplicate menu CRUD pipeline. Required place management remains M2; it now guards community publication.

**Receipt metadata detail:** retain actual observation date and capture date separately; capture time may be the same supplied date only when the contributor explicitly says so. Do not fill either from upload/server time. Use captured_precision to represent date-only capture honestly. Admin-reviewed observation may correct the claim, but original submitted values remain. Receipt unknown date is invalid; unknown menu observation is legal. Future-date check uses architecture's one-day input-clock allowance, not a freshness cutoff.

### Key transactions and validation

**Intake:** validate strict request and image records; recheck active submitter; lock target place (or create community draft), own asset rows in ID order. Verify 1..5 unique validated originals owned by submitter and unattached, readable locally; insert intake/header/links together. New-place name/address must be real input, not “Chưa cập nhật”; Admin later supplies enabled category/city before publication. A community draft is never public merely because intake succeeded. On DB rollback no orphan draft/contribution/link survives; uploaded files remain private for retry.

Use client contribution UUID for durable recovery. On repeat ID, first perform owner-scoped lookup and compare typed immutable submission fields plus ordered asset IDs: same payload returns same record even after assets attach or Admin decides; different payload 409. This removes the need for a payload hash on every write. Suggestions/corrections by the contributor are optional assistance and not required; pre-OCR UI can omit item entry entirely.

**Approval:** before transaction verify local source bytes exist and are readable; no active cleanup deletes attached files. Recheck live Admin/session and active submitter under compatible locks; lock place then contribution then assets/items. If decision already exists, same request_id/semantic command hash returns persisted outcome without reapplying selections; conflicting command 409. Hash only the normalized decision command, with deterministic order and no transient headers. This limited hash is justified by lost responses to a multi-row publication command, not a platform-wide middleware requirement.

Require no prior final decision, expected place revision, nondeleted target, original assets and valid source. Validate every exposed value and strip unrelated private text. Menu lines require item mapping/new identity, name, integer VND, positive basis and stable unit; only explicit mappings/selections affect current data. Receipt lines may be incomplete but must not include invalid numbers; header total/guest values stay nullable. Reconcile mismatched receipt total versus summed lines with a note instead of forcing equality or inventing missing lines.

Insert immutable decision and reviewed receipt lines OR menu observations. Verify mapped items belong to target place. For menu, replace only chosen current selections with source-date guard from M3; unmentioned items remain. For receipt, insert **zero advertised price observations**. Increment place revision. Publish a complete community draft only as part of its approved contribution transaction; leave existing hidden place hidden. Commit all or none; no source data/version pointer can change during this operation.

**Rejection:** live Admin, pending record, expected revision, nonblank reason; insert immutable rejection decision only. No public price/selection/place-publication change. Draft stays draft. Do not fabricate rejection for disk/DB failure. Different Admin decisions serialize on contribution/place; one wins and the other reloads.

**Withdrawal:** approved outcome remains immutable. Set access withdrawal actor/time/reason, clear current pointers originating from it and increment place revision in one transaction. No automatic historical fallback. Public receipt/history/current queries exclude withdrawn sources. Existing public place can remain visible without prices. M2 hide/delete remains an emergency whole-place access action.

**Receipt example:** select most recent observed approved nonwithdrawn receipt with known total and positive guest count, deterministic ID tie-break. Exact total/guest arithmetic; display nearest integer VND, compare filter bounds against exact numeric quotient. Do not average menus/receipts or equate receipt line purchases with current advertised prices. Receipts lacking total/guest remain valid historical evidence with unavailable spend per person. Empty evidence is insufficient evidence, not an unsafe venue.

### Tests, commands and boundary

Unit: image decoder limits/corruption, strict metadata/money/guest/date validation, semantic decision hashing, receipt rounding/missing values. Test byte limits independently of Content-Length and verify no untrusted path is used.

Real PostgreSQL tests:

- `TestM5Intake`: uploaded private menu→existing target and new draft→owner history; duplicate requests recover, conflicting IDs and other users' assets fail; DB failure rolls back draft/header/links.
- `TestM5Approval`: manual review→menu selection→Guest visible; pending/new rejected menu leaves approved price unchanged; partial menu retains other items; old source requires explicit override; community draft requires approved linked decision.
- `TestM5Receipts`: approved total/guests gives dated example; partial/unknown values remain null; receipt approval creates no menu observations; public response never exposes original/owner/reason.
- `TestM5Concurrency`: two Admin decisions, two submissions updating one place, logout/demotion versus approval; unique final decision/revisions/locks enforce one result. Inject error after each approval write and assert all-or-none state. Repeat after uncertain response must not reselect a historical price.
- `TestM5PrivacyStorage`: guest/other owner denied original before and after approval; missing file yields 503 and blocks approval, not rejection; failed DB insert cleanup, crash orphan tolerance and persistent mount restart.
- `TestM5Withdrawal`: clears only affected pointers, preserves private history, excludes public source with no fallback.

```sh
make -C backend migrate
make -C backend seed-dev
make -C backend local-up
make -C backend generate
make -C backend test
make -C backend test-integration TEST_RUN='TestM5'
make -C backend verify-m5
```

verify-m5 performs actual multipart/JSON/private-byte/Admin/public HTTP calls with local files and both real roles, including approve and reject branches. Add contract validation for the implemented multipart/error/nullable receipt shapes if the handwritten assertions no longer suffice; no future endpoint specification.

**Acceptance/commit boundary:** complete private contribution/manual decision flow and dated receipt example work without OCR/network providers; source/approved history immutable; concurrency rollback and private access proven. M5 can be delivered as two dependent commits (private intake, then decision/public reads), but milestone completion requires both. Failure modes: public originals, loss of observed date, editable evidence, orphan draft, duplicate decision, hidden unhide, receipt-as-menu, older pending overwriting newer approval, DB/fs ambiguity. Defer all OCR/version/lease/derivative machinery and document the deliberate limits.

## 14. M6 detailed implementation plan — Local end-to-end Flutter integration

**Goal/why:** replace prototype authority with real local APIs while preserving useful interactions. Covers UI/integration portions of FR-02–13/16–18/21/23, manual correction FR-15/22, NFR-01–04/06–12/14/16–19/24/25, SEC-01/03/06/09/11 and approved §13.1–13.12. OCR-specific UX is not simulated as complete. Native external sharing remains in scope without social features.

**Dependencies:** completed M0–M5 and available Android/iOS tooling. **Tables/migrations:** none. **Backend endpoints:** none beyond M0–M5; fix contract defects in their owning feature if integration reveals them, without prebuilding M7/M8. **Non-goals:** UI redesign, router/state-management replacement, chat/friends/RSVP/reviews/map, report backend, OCR/provider login, generalized Flutter clean-architecture scaffold.

### Files and adaptation order

All paths in this table are future M6 changes, not modifications made in Phase 3.

| Current path/class | Expected change |
|---|---|
| `mobile/lib/core/network/api_client.dart` (new) | One small transport for base URL, bearer injection to Rendez origin only, JSON/multipart, bounded timeout and typed error decoding. No generic service locator/interceptor hierarchy. |
| `mobile/lib/core/models/{place,bill_item,user}.dart` | Explicit API parsing for place IDs/revision/nullable fields, generic priced items, receipt header/lines and roles/contribution facts. Distinguish unknown/free and observed/reviewed dates. No server isVerified/minPrice substitute. |
| `mobile/lib/core/providers/app_providers.dart` | Keep Riverpod; async server queries with query/origin/page keys, session bootstrap and owner-scoped favorites/history. Direct API methods suffice initially; split by actual feature complexity, not one repository class per endpoint. |
| `mobile/lib/features/auth/auth_profile_screen.dart` | Guest/restoring/User/Admin states; development build fixture switch; /me validation and logout. Remove mock password success. Normal build does not expose fixture controls. |
| `mobile/lib/features/navigation/main_scaffold.dart` | Preserve compact discovery/profile access; gate personal/Admin actions and resume intended place action after login. Hide deferred map/social entrances. Do not introduce a new routing framework. |
| `mobile/lib/features/explore/explore_screen.dart` | Real fetch/refresh/unique pagination; loading/error/no matches, never repeated fixtures. |
| `mobile/lib/features/explore/widgets/{search_header,advanced_filter_sheet,filter_chips_bar}.dart` | Catalog categories, explicit price basis/unit, synchronized reset, query debounce and stale-result suppression. No unsupported vibes/facilities/verification controls. Explicit known origin selection; no map required. |
| `mobile/lib/features/explore/widgets/{masonry_place_card,bouncing_heart_button}.dart` | Preserve design/animation. Nullable honest summaries, units/source dates, request-origin distance and desired-state favorites. |
| `mobile/lib/features/place_detail/place_detail_screen.dart` | Navigate by place ID, reload availability/current data, maintain tabs, display category/source dates and nullable images. Native sharing of public name/address; optional configured public link only when real. Remove false directions/report/invitation success. |
| `mobile/lib/features/place_detail/widgets/{menu_tab_view,bill_breakdown_card}.dart` | Generic units/conditions, current vs historical source dates, receipt total vs line sum vs per-person example. No unconditional VERIFIED or public original image. Show an explicit private/unavailable image state; retain breakdown. |
| `mobile/lib/core/utils/currency_formatter.dart` | Keep VND formatting; remove unconditional /người from generic ranges. Render unit/basis from contract. |
| `mobile/lib/features/bookmarks/bookmarks_screen.dart` | Server-owned paginated list, unavailable placeholders, per-place serialized PUT/DELETE and Undo; no MockData join. |
| `mobile/lib/features/contribute/contribute_screen.dart` | Actual photo picker and local preview/upload, menu/receipt choice, existing ID/new draft target, required receipt dates, optional guests. No prefilled mock prices; contributor correction not required. Submit stable IDs only after validation/upload succeeds. |
| `mobile/lib/features/auth/widgets/contribution_history_sheet.dart` | Owner-scoped async history/detail, manual-review/approved/rejected outcomes, safe reasons and retry/error states. No fake OCR polling when awaiting manual review. |
| `mobile/lib/features/admin/admin_screen.dart`, `review_screen.dart` (new) | Same-app role-gated compact place management/manual prices and contribution queue/review. Display private source beside editable reviewed fields; explicit approve/reject/hide confirmations. No separate Admin website. Split additional widget only when it reduces real duplication. |
| `mobile/lib/core/theme/app_theme.dart`, `main.dart`, `pubspec.yaml` | Bundle existing intended font assets/license and disable runtime fetching. Use local placeholders for missing photo/avatar. Direct HTTP/picker/secure-storage/share dependencies only when used. Base URL supplied with dart-define. |
| Android manifests/network config; iOS Info.plist and relevant build settings | Correct permissions and debug-only local transport access needed by actual client/picker; keep release HTTPS behavior. Android INTERNET permission must exist in effective release manifest. No map/provider settings. |
| `mobile/test/widget_test.dart`, new `mobile/integration_test/local_core_test.dart` | Replace mock-authority expectations with DTO/error/provider/UX and actual local journey coverage. Keep useful existing formatter/interaction tests. |

Fix the reported imports before integration testing. `PlanInviteSheet` need not be integrated just because its import is broken; deferred code can be removed from the build or have its import corrected without gaining backend scope.

### Session, interaction and failure behavior

Store bearer/expiry in OS-protected secure storage; never preferences/logs/routes. Bootstrap /me determines current role. 401 clears the session once; 503 does not falsely sign out. Logout clears all owner caches, image bytes, pending authenticated actions and credentials even when server unavailable, but does not claim remote revocation succeeded. Switching fixture first invalidates old state and preferably revokes its session. Stale responses from a former session cannot repopulate current state.

Guest favorite/contribute prompts login and returns to the intended place/action after successful session creation; cancellation stays Guest. Backend remains authoritative even if UI route guards are bypassed. Admin inspection needs authenticated image bytes in memory, not cached public URLs or bearer query parameters.

Favorites maintain one pending desired state per place, serialize writes, reconcile obsolete responses and rollback on confirmed failure. Undo is a new desired state. A timed-out write is reconciled with a GET before declaring failure. Contribution keeps client upload/submission IDs through retries; disable duplicate taps. A lost submission response retries/retrieves the same ID; it must not create a second draft under a new ID. Leaving an unsent form discards only local work; submitted records have no edit-in-place action.

Admin edits locally and sends one complete decision. 409 reloads current server facts and asks for reassessment; never automatically reapply stale approval. Rejection requires a reason. Preserve unsent field text on 422/network errors. No public success before commit. Source-file outage is an operational unavailable state, not a rejection.

Discovery resets text/controller/category/price/origin consistently; debounce search and ignore superseded responses. Normal browsing works with origin absent. A known place can be selected as origin using coordinates already returned by the API; device GPS acquisition is not necessary to satisfy the selected-origin path. Distance labels explicitly say approximate straight-line distance.

### Offline acceptance and tests

No remote font/image/analytics request can be required. Disable Google Fonts fetching and bundle typography before acceptance; no Unsplash network fallback. Local contributed evidence comes from consented/synthetic device files. Public venue images/avatar can be null with designed placeholders. Native share opens the OS sheet with public text without fetching remote preview content. Do not send original images, tokens or internal moderation facts to share targets.

Unit/widget tests: DTO null/zero/unit/date parsing, error mapping, guest continuation, auth cache clearing, favorites Undo ordering, upload validation failure and Admin 409 form retention. Real backend: `TestM6LocalCore` repeats §22 against actual HTTP/PG/files; no fake auth service. Device integration verifies API-to-UI semantics and startup ≤3 seconds/read-search ≤2 seconds on a declared fixed dataset/device/network; record actual timings and outliers, not fabricated compliance.

Introduce Makefile `verify-local-core` plus restart verification and the integration_test target in this milestone. Before running, start the local services/fixtures and select an Android emulator or supported iOS simulator/device. Android can use adb reverse to preserve loopback API addressing; iOS simulator can access host loopback, while physical devices need explicitly configured trusted LAN/local TLS access. No global release cleartext exception.

```sh
make -C backend migrate
make -C backend seed-dev
make -C backend local-up
make -C backend verify-local-core
cd mobile
flutter pub get
flutter analyze
flutter test
adb reverse tcp:8080 tcp:8080
flutter test integration_test/local_core_test.dart --dart-define=API_BASE_URL=http://127.0.0.1:8080 --dart-define=RENDEZ_DEV_AUTH=true
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8080 --dart-define=RENDEZ_DEV_AUTH=true
```

The adb command is Android-only; omit it for iOS simulator. The integration command assumes exactly one selected supported test device; supply `-d` with that device ID if several are connected. RENDEZ_DEV_AUTH is permitted only in a non-release Flutter build and is not backend authority. Package download/build occurs **before** network isolation. Re-run the built app/real backend journey with external network blocked but local loopback/Compose traffic enabled. Measure traffic or test with cold external caches; airplane mode alone may also remove the local device connection and is not the intended setup.

**Acceptance/commit boundary:** actual User→Admin→Guest path, reject-preserves-approved branch, source privacy and restart persistence pass offline. No mock fields are authoritative. Likely failures: remote fonts/images, wrong emulator host, stale full-Place navigation, null-to-zero conversions, bearer leakage to image host, role/session cache leak, fake success and unsupported controls. Deliver dependent integration commits, complete only after device gate. No M7/M8 work starts to compensate for a failed local gate.

## 15. M7 federation outline

Start only after M6. Cover production FR-01/02, approved §13.9 and provider-specific security obligations without redesigning favorites/contributions/RBAC.

First run a small registered-device spike for Google and Apple on the actual supported Flutter Android/iOS versions. Compare the simplest correct supported native/server verification or system-browser/code flow. Prove provider audience/issuer/signature/expiry, nonce/replay binding, redirect behavior where used, cancellation and app resume. Architecture §19's browser callback/handoff design is a candidate, not mandatory machinery before this evidence. Never replace proof validation with decoding claims or accepting client user IDs.

Add auth_identities with unique verified (issuer,subject) bound to existing users. Provider authentication → find/create Rendez user → issue the existing opaque session. Email is optional profile data, never canonical key or automatic merge rule. Existing protected API contracts and user IDs remain stable. Test fixtures do not automatically become production Admins or transfer ownership; controlled bootstrap identifies an authenticated internal user UUID.

Add auth_attempts, callback/handoff proof, PKCE, provider credential storage/encryption and session identity reference only to the extent the proven flow/provider obligations need them. Explicit authenticated account linking cannot merge accounts by email. Reauthentication/revocation requirements must be implemented before exposing their sensitive production operations. No second Rendez JWT/refresh system.

Acceptance includes both real-device provider journeys and local signed-fixture tests for wrong issuer/audience/nonce, replay, identity races and cross-account linking. Production artifact still excludes /dev/login regardless of config. Genuine dependencies: registrations/signing-key ownership, permitted callback/app-link domains, devices and provider terms. This outline deliberately does not specify all OAuth DTOs or choose libraries beyond approved stack direction.

## 16. M8 OCR outline

Start after stable M5/M6 manual review; federation is not required for an isolated OCR benchmark. Evaluate consented/de-identified actual Vietnamese menus, service tariffs and receipts. Measure field correctness/completeness, units, receipt totals, latency, failure behavior, cost and private-data terms. Select one implementation/provider after evidence and approval; no automatic preference becomes a purchase commitment.

Introduce a narrow extraction boundary only now, accepting private evidence and returning untrusted proposed fields/diagnostics. It never changes a current-price selection or final decision. Proposed OCR fields are separate from submitted facts and the final reviewed snapshot. Valid partial/empty output goes to manual review with nulls. Service outage is retryable processing failure, not rejected content. Typed proposed facts are preferable; bounded sanitized raw provider response is an appropriate JSONB use here.

Start with one in-process worker and the smallest durable PostgreSQL job record required to recover accepted work. No in-memory-only queue after acknowledging submission. Persist queued/running/failed/completed outcome and safe diagnostic/attempt identity as actually needed. On restart, unfinished work remains visible and is explicitly retried or handed to manual review. A transaction checks contribution has no final decision before storing a result; late results cannot overwrite Admin work. If manual fallback and provider completion overlap even with one worker, an attempt identity/state check is already needed; defer leases/heartbeats, not stale-result safety.

Add multi-worker leasing/heartbeats/fencing only when overlapping execution/recovery across workers/processes actually requires them. Provider calls remain at-least-once; do not claim exactly-once billing. A bounded request deadline is required immediately; a sophisticated multi-attempt scheduler is not. Start with explicit retry/manual handoff if sufficient. No Redis/broker or multi-provider routing.

Keep existing approval/receipt/privacy invariants unchanged. Test with deterministic local provider responses and real DB, then the approved benchmark. No unapproved private user evidence in external CI. Complete FR-14/15 and OCR portion FR-19/22 here; distinguish invalid submission, processing, retryable outage, incomplete extraction, manual review, approval and rejection in the UI.

## 17. M9 hardening/deferred work

This is a menu of triggered slices, not one mandatory giant milestone. Some become production launch gates and cannot wait until after the corresponding exposure.

| Candidate | Concrete trigger | Smallest initial result |
|---|---|---|
| Wrong/stale/closed-place reports | Product chooses to expose report action | Typed report + owner submission + Admin resolution; never automatic price mutation. Until then omit fake report success. |
| Account deletion/retention | Before production account/receipt collection requiring the promised notice/process | Approved privacy policy, durable deletion state, immediate session revocation and operator-assisted completion before sophisticated orchestration. |
| Backups/restore | First deployment retaining non-disposable evidence | Documented matching DB/files backup and actual restore drill, responsible operator/RPO/RTO; no DB-only recovery claim. |
| Public menu source images | Real source-image display/FR-05 acceptance required | Explicit safe representation, privacy review and authorized delivery; originals remain private. No blanket original-public flag. |
| Public redacted receipts | Product explicitly wants public receipt images | Separate burned-in redacted/re-encoded derivative, approval/revocation and access checks. Structured approval alone never grants image access. |
| Native place links | Stable public domain/app association becomes practical | Safe /p/{id} fallback/app link; current availability, escaped text, no tracking/social subsystem. Native text sharing already M6. |
| Production observability | Operator cannot diagnose measured failures with safe logs/health/SQL | Targeted metrics/alerts for actual bottleneck or capacity; no monitoring platform by default. |
| Object storage | Ephemeral disks, independent replicas/hosts, or single-host capacity/recovery fails | Private object storage migration with hash verification and unchanged asset IDs/access checks. Do before such deployment. |
| pg_trgm/projection | Fixed-data search misses target and EXPLAIN identifies substring scan as cause | Rebuildable normalized search text plus measured index; do not misdeclare unaccent immutable. |
| PostGIS | Measured geographic query target cannot be met by bounded scan | Indexed geographic predicates with unchanged straight-line semantics; not interactive routing. |
| More OCR retry/coordination | Real restart overlap, additional workers or operational retry workload | Only the needed persisted attempt/lease/retry extension, with conflict tests. |
| Saved Admin review drafts/versions | Review loss/length or collaboration becomes a demonstrated burden | Immutable review snapshots and explicit revision reference; no silent edit of accepted evidence. |

Production privacy notice, provider obligations, TLS and recovery are not optional merely because M0–M6 are local. The local-first gate deliberately uses controlled fixtures and private originals; production readiness is a separate acceptance gate.

## 18. Deferred architecture mechanisms

Complexity is not automatically waste. Retain a mechanism when removing it would break a current invariant; otherwise name the actual trigger.

| Mechanism | Why deferred from M0–M6 | Invariant preserved now | Trigger to introduce |
|---|---|---|---|
| auth_identities / auth_attempts | No external identities/round-trip proofs | Internal user IDs and live opaque sessions | M7 verified identity and flow spike |
| Provider refresh credentials/keyring | No provider credentials stored | Digest-only Rendez tokens, no plaintext secrets | Provider revocation/refresh obligation proven in M7 |
| PKCE/browser callback/handoff | No provider redirect in local core | Dev entry cannot exist in production artifact | Chosen provider/mobile flow requires exact bindings |
| Recent Admin provider reauthentication | No provider to reauthenticate with locally | Live Admin/session rechecked in sensitive transaction | Before production sensitive Admin/link/deletion exposure in M7+ |
| creation_hash | Place create can return explicit duplicate conflict | Client stable ID, no automatic retry with new identity | Repeated creates need semantic replay beyond GET reconciliation |
| Request/payload hashes everywhere | Most writes are desired-state or revision-guarded | Owner/UUID recovery, typed comparison; decision-only hash | A specific ambiguous non-idempotent command cannot be reconciled simply |
| Global admin_actions | No general audit query/product exists | Immutable review attribution, observation sources and last catalog/selection actor/time/reason | Need complete operator/catalog change history or broader security audit |
| Multiple audit/event layers | One final decision/observation facts enough locally | Final review and approved history not overwritten | Separate consumers/legal retention need additional audit facts |
| Cyclic/composite FK graph | No versions/publications graph | Ordinary FKs + one acyclic same-item selection composite FK + locked mapping checks | Multiple independent writers/publication/version relationships require more DB enforcement |
| Deferred cross-table constraint trigger | One controlled approval operation | Locked state validation, final-decision uniqueness, all-or-none SQL and real DB rollback tests | Independent write paths make application-only cross-table validation insufficient |
| Per-table immutable DB-role privilege engineering | One application writer, no maintenance pipeline yet | No normal update/delete SQL for source/approved facts, constrained transactions/tests | Production operators/importers/multiple writers warrant defense-in-depth grants |
| Upload reservation states | Single-process synchronous file finalization | Validate/private random path, DB insert after file durability | Frequent ambiguous uploads need registry recovery rather than conservative orphan handling |
| Upload leases/heartbeats/fencing | No distributed uploader or concurrent cleaner | Unique upload ID/hash, no overwrite, no attachment cleanup race | Background cleanup/retry ownership races actually introduced |
| Separate publications table | One final approved snapshot per contribution | Decision outcome distinct from withdrawal fields; public eligibility checked | Several independent publications/access grants/versions per source |
| structured_versions | No persisted preapproval editing yet | Immutable intake and atomic final reviewed snapshot | Saved review drafts, collaboration or multiple OCR candidate versions |
| automatic_checks table | Only fixed local image/metadata/basic-value checks | Typed validation facts/version and explicit not_run extraction | Multiple versioned checks need their own durable results |
| Replacement chains/superseded state | Independent immutable resubmission sufficient | Old submission preserved; revisions/date guard prevent silent overwrite | Product needs explicit lineage/latest-only queue policy |
| OCR jobs/runs/provider package | No background OCR before M8 | Manual review is visible, no pretend processing | M8 extraction integration |
| OCR leases | No competing worker ownership | M8 must first persist unfinished work and check state | Multiple/overlapping process execution or recovery |
| OCR heartbeats | No long-lived leased worker yet | Finite provider deadline/cancellation when introduced | Real execution outlives claim and ownership renewal is needed |
| OCR fencing tokens | No OCR locally | Admin decision remains authoritative; later stale-result check mandatory | Overlap/reclaim makes state-only check inadequate |
| Multi-attempt retry scheduler | No external failure to schedule locally | No outage classified as rejected; explicit M8 retry/manual fallback | Repeated transient failures require durable automated retries |
| Multi-worker coordination | One local process; no background work | Short locked DB transactions serialize real writes | Measured throughput or deployment introduces additional workers |
| Restore-time deletion ledger | No real account erasure/backups in controlled local fixtures | No claim of production erasure/recovery | Before restoring retained data after actual deletions |
| Advanced backup coordination | No distributed writers/storage | Local volume persistence only, not backup claim | First retained deployment needs matching DB/files; advanced scheme only on measured downtime/RPO need |
| Search projections | Small one-city direct SQL sufficient until measured | Literal normalized relevance and correct pre-page filtering | EXPLAIN demonstrates text bottleneck |
| pg_trgm | No measured text index requirement | Native PostgreSQL normalization/filtering | Representative search misses target due to scan |
| PostGIS | Simple straight-line calculation sufficient | Null origins/finite coordinates/pre-page distance | Geographic query performance needs spatial index |
| Public-safe derivative pipeline | No public binary evidence delivery locally | All originals private, public structured facts reviewed | Public menu-image or redacted receipt capability accepted for delivery |
| Object storage/presigned/CDN | Persistent single host is sufficient | Authenticated private delivery and durable local files | Ephemeral/multi-host/capacity requirement; never expose private original bucket |
| Rate-limit infrastructure | No public untrusted traffic in local core | Body/pixel/page/query/timeout/concurrency bounds now | Before public exposure add simple process/proxy limits; distributed infrastructure only for actual distributed abuse |
| Redis/broker/search service | PostgreSQL covers current work | Durable data/transactions and local-only gate | No planned introduction; revisit only demonstrated PostgreSQL failure of a real need |

No deferred mechanism is permission to weaken ownership, source immutability, image validation or public eligibility. The essential same-item FK, final-decision uniqueness, private file checks and approval transaction remain in M0–M6 even though they require careful code.

## 19. Database evolution map

| Milestone | New schema | Existing schema changed | Explicitly absent |
|---|---|---|---|
| M0 | Goose metadata/bootstrap only | None | All domain tables |
| M1 | users, sessions | None | identities/attempts/passwords/refresh family |
| M2 | categories, pricing_units, places; unaccent | None | prices/galleries/reports/social |
| M3 | price_items, price_observations, current_prices | None | contributions/versions/publications/OCR |
| M4 | favorites | None | social collections |
| M5 | assets, contributions, contribution_assets, moderation_decisions, receipt_lines | places.origin; observation source kind/decision FK | OCR jobs/runs, global audit, separate publication/version systems |
| M6 | None | Only contract fixes justified by tests | Future schema scaffolding |
| M7 | Verified identities; attempts only if selected flow needs them | Sessions identity reference/user provisioning as required | Domain user-ID replacement |
| M8 | Minimal durable extraction/proposal records justified by chosen integration | Typed processing status/proposals separated from final review | Broker/lease/heartbeat graph upfront |
| M9 | Only triggered workflow's schema | Forward migrations preserving historical facts | Giant final-schema migration |

Each core migration is additive and introduces that milestone only. Existing legacy migration files never become the active Goose input. New core DB isolation avoids destructive conversion assumptions. Once a core migration is shared/applied, change it with a forward migration; do not rewrite history. Rollback destructive Down steps only on disposable test DBs. Test empty-to-current plus previous-milestone-to-current evolution, preserving earlier price observations/sessions. No release reset or Automatic GORM migration.

## 20. API evolution map

All paths except health/dev login are under /v1. Endpoint details/errors are in each owning milestone; no scaffold handler returns not-implemented for future capabilities.

| Milestone | Added capability/routes |
|---|---|
| M0 | GET health/live, health/ready |
| M1 | POST /dev/login (separately gated); GET /me; DELETE /auth/session |
| M2 | GET /catalog, /places, /places/{id}; Admin place list/detail/create/patch/delete |
| M3 | Admin price-observations create/current selection; public prices/history; listed-unit-price list filter |
| M4 | GET /me/favorites; PUT/DELETE /me/favorites/{place_id} |
| M5 | Upload create/recovery/private bytes; contributions create/own list/detail; Admin queue/detail/decision/withdraw; public receipts and receipt-based filter |
| M6 | No new backend endpoints; integrate existing contracts, native text sharing |
| M7 | Only proven provider entry/verification/link/reauth routes; protected business routes unchanged |
| M8 | Only required retry/manual-handoff/status/proposal additions; approval remains existing authority |
| M9 | Reports/deletion/public assets/share fallback only when the corresponding slice is selected |

OpenAPI begins at M1 and grows before implementing each milestone's handlers. Include representative errors/nulls/multipart at their first use. No full future API spec, HTTP DTO code generation or endpoint per table. One consistent /v1 error contract supersedes the legacy unconnected Gin response shapes.

## 21. Frontend integration sequence

1. **Restore a runnable baseline:** fix incorrect imports; preserve ordinary navigation, themes and Riverpod. Defer unreachable social/map UI without creating backend work.
2. **Transport and identity:** base URL, safe errors, secure opaque session, /me, dev fixture gate and logout. Replace AuthNotifier's mock initial account before attaching personal data.
3. **Read discovery:** catalog→list/search/detail by ID. Replace MockData, artificial repetition/refresh, fixed distance and mandatory min/max/verified. Implement nullable image/price/origin paths before success-only polish.
4. **Price semantics:** map MenuItem to generic priced item/unit/basis/source; map RealBill to separate reviewed receipt header/lines/spending. Update CurrencyFormatter and all cards/detail consistently.
5. **Favorites:** replace seeded BookmarksNotifier/global set and MockData joins; retain heart feedback/Undo with desired-state serialization and owner reset.
6. **Contribution intake/history:** picker/local preview→private upload→stable-ID submission→server history. Submitted metadata remains visible and immutable; do not show OCR progress before M8.
7. **Admin in same app:** server role gate, place/manual-price management and source review/final decision. No mock Admin action currently exists to reuse; build the missing small operational capability, not a web application.
8. **Failure/offline audit:** unavailable place, no prices, no receipts, forbidden/private images, DB/network timeout, ambiguous write, Admin revision conflict, logout/account switch and cold fonts/images. Add native text sharing and remove fake report/directions/invitation success.

The detailed file map is §14. Do not implement a Flutter domain/repository/service stack solely because these are eight integration steps. A shared API client and feature Riverpod state are enough until actual reuse demands another boundary.

## 22. Local end-to-end acceptance scenario

Use fixed synthetic/consented fixtures: ordinary User A, Admin B, a published place with current item price 40,000 VND/item, a published service with 150,000 VND/room-hour, a no-price/no-coordinate place, local menu images, and a receipt total 330,000 VND with two guests. Use fixed source dates, never startup-relative dates that create false freshness. Extra owner C is test-only for privacy checks. These categories/city fixtures do not select the launch catalog.

Prepare all builds/dependencies/fonts/files, then deny external egress while retaining local API/DB networking. Start from a cold application cache so external assets cannot mask a dependency.

1. Start core PostgreSQL and backend; migrate/load fixtures. Confirm live/ready.
2. Guest opens Flutter, browses and searches Vietnamese text. No-price venue remains discoverable; its estimate is unavailable. Missing origin means distance unavailable.
3. Select a known coordinate origin; verify approximate straight-line distance and nearest ordering. No map or routing call.
4. Favorite as Guest → sign-in continuation → development login as User A → real /me → persisted favorite. Repeat desired save without duplicate; remove/Undo restores it.
5. Pick a valid local menu image. Upload and submit against the published place with dated source. Record durable contribution ID; owner history shows awaiting manual review.
6. Force a lost response/retry with the same ID. One submission exists. Public current price remains 40,000, not the user's proposed amount.
7. Guest and owner C cannot fetch A's original or private contribution/reason. A can see own source. No static file path is public.
8. Switch to development Admin B; prior owner state is cleared. Open real Admin queue/detail/private source.
9. Enter reviewed 45,000 VND/item from the menu, choose explicit current mapping, confirm approval. Real decision/observation/selection commit together.
10. Switch to User/Guest and reload detail by ID. Current price is 45,000 with actual source date/review date; 40,000 remains history. No universal verification or freshness claim.
11. User submits another conflicting menu price. Pending submission leaves 45,000 visible. Admin rejects with a reason. Owner sees reason; Guest still sees 45,000 and never rejected source data.
12. Propose a new place with valid evidence/name/address. It stays private draft; Admin completes category/one-city details and approves linked contribution to publish. A rejected-only draft stays draft until manual hide/delete.
13. Submit/approve the receipt with total 330,000/two guests. Public shows a dated 165,000 VND/person example, not a future guarantee; menu selections remain unchanged. Approve another partial receipt without guest count: per-person remains unavailable.
14. Confirm original receipt remains private after approval, and public breakdown omits private receipt text/identity. Image area is explicitly unavailable, not a stock proof image.
15. Hide a saved place. Guest detail becomes generic unavailable; favorite remains safe removable placeholder. Pending/rejection never caused hiding.
16. Inject DB failure during approval. No partial decision/observation/selection/draft publication survives. Two Admin approvals race: one result and conflict/reload, not last-write-wins.
17. Restart API/container without deleting volumes. Still-valid nonrevoked session, favorites, contributions, decisions, current/history and image bytes persist. Restart PostgreSQL and recheck persistence. Do not treat restart as a backup test.
18. Logout and call protected API with old bearer: denied. Unauthenticated public reads still work. Verify normal production artifact has no /dev/login even with manipulated environment.
19. Native share opens OS sheet with public place name/address only. No friends/chat/provider login or remote image-preview fetch needed.
20. Record observed startup/read/search timings, device/OS, dataset counts/images, configuration and failure outcomes. Confirm no Google/Apple/OCR/map/object-storage/remote-font/Unsplash/SaaS runtime dependency.

Pass requires both real backend integration tests and the built Flutter journey. A curl-only success or a mock provider/widget test does not establish M6 completion.

## 23. Risks of the simplified plan

| Deliberate ceiling | Consequence | Guard now / upgrade trigger |
|---|---|---|
| One host, synchronous private upload | Rare unreferenced file on crash; no horizontal storage | Durable rename, DB lookup after ambiguous commit, no public root; conservative offline orphan cleanup when needed; object storage before ephemeral/multi-host deployment |
| App-enforced source immutability and cross-table checks | Privileged direct SQL could bypass application rules | No normal mutation SQL, narrow FK/unique checks, locked transactions and tests; add scoped DB grants/guards before independent writers/production maintenance require them |
| No complete catalog/admin event log | Only latest catalog/selection actor/reason retained; final approval history is complete | Do not call this a full audit trail; add targeted append-only change facts when operational audit history becomes required |
| Review edits live only in form | App termination loses unsaved Admin work | Submitted/approved evidence remains safe; add saved immutable review versions when actual review burden warrants it |
| Independent resubmissions | Similar pending records may coexist | Immutable IDs/source-date/current-revision checks; add explicit replacement lineage only for approved queue semantics |
| No public source images locally | Structured transparency works but image-display FR-05 remains incomplete | Honest unavailable image; explicit approved safe-menu representation before claiming full source-image acceptance |
| No freshness or score policy | Cannot classify selected evidence fresh or implement BR-08 transparency ranking | Show observation dates, history and insufficient evidence; obtain policy separately, never invent thresholds/weights |
| Manual moderation only | Admin labor; OCR FRs incomplete until M8 | Visible queue and small scope; benchmark OCR after usable core, not fake processing |
| Development identity only | Local core cannot be publicly released as genuine authentication | Compile-time dev exclusion, fixed fixture keys, real session/RBAC; M7 provider validation before launch |
| Basic SQL search | Small-city scan and offset page shifts | Correct normalization/order, dedup/reset; measured pg_trgm/PostGIS triggers only |
| No production erasure/recovery pipeline | Local test persistence is not production privacy/backup readiness | Controlled fixtures; approved notice/deletion/DB+files restore before retaining real production data |
| Plugin/toolchain and existing imports | Flutter may not build until baseline repair; device networking varies | M6 analyzer/device checks, compatible pinned dependencies/debug-only transport settings; no UI redesign |

Human decisions genuinely outstanding: launch city/category/unit seed content; production hosting/operator/recovery commitments; Google/Apple registration/domain/key ownership; approved private-evidence notice/retention/deletion terms; OCR benchmark acceptance, budget and data-processing terms. Score/freshness formula/thresholds remain intentionally deferred product work and are not blockers to local factual implementation. If the university requires full SRS acceptance at an earlier demonstration, explicitly resolve the recorded OCR/image/ranking gaps rather than silently changing claims.

## 24. Final implementation order and commit strategy

Implement M0 → M1 → M2 → M3 → M4 → M5 → M6. Do not pull federation or OCR forward. M4's backend can technically follow M2, but the serial order keeps review simple for two developers. A teammate may integrate a completed contract while the next backend slice proceeds; do not prebuild endpoints/tables for parallelism.

| Commit boundary | Reviewable outcome |
|---|---|
| M0 | Checkpoint legacy work; isolated core runner/Goose/pgx/chi/health/config/tests, obsolete active scaffold removed safely |
| M1 | Real opaque sessions, gated fixtures/login, /me/logout, first OpenAPI and live RBAC tests |
| M2 | Reference catalog/places/Admin operations/public discovery/distance and real SQL tests |
| M3 | Generic manual observations/current selection/history and exact unit-based filters |
| M4 | Desired-state owner favorites and unavailable handling |
| M5a | Validated private files, immutable submissions/new drafts and own/Admin reads |
| M5b | Atomic manual decisions/receipt examples/withdrawal, public eligibility and contested-write tests |
| M6a | Runnable Flutter baseline, transport/session, real discovery/prices/favorites |
| M6b | Actual contributions/history/Admin review, native sharing, honest failure states |
| M6 gate | Offline full journey/restart evidence and corrected contract/tests; no third-party work before pass |
| M7 | Mobile-provider spike first, then only proven federation session entry/link/revocation requirements |
| M8 | Benchmark/approval first, then one extraction integration assisting existing review |
| M9 | One justified trigger per small workflow/operations commit |

Every milestone commit includes its schema evolution, queries, only-current OpenAPI additions, focused tests, command target and README usage. Regenerate sqlc once after relevant SQL changes and review the generated diff. Run the milestone tests and required earlier invariants; broaden testing only for a changed boundary or unresolved failure. Avoid giant “all tables”, “all handlers” or “all tests” layer commits.

A new implementation agent told “Implement M2 only” should read §§2/4/7/10, verify M0/M1 completion and their commands, implement precisely M2's schema/routes/queries/tests, then stop at its commit boundary. It must not silently implement prices/providers/reports or rewrite earlier documents. If prerequisites are missing, report that concrete dependency and complete only separately authorized prerequisite work.

Final YAGNI check: every local table supports a current acceptance path; no workers/providers/storage abstractions exist before their trigger; one session system, one public-price selection, one final decision and one concrete filesystem are sufficient. Retained complexity—live authorization, ownership, image validation, immutable facts, the same-item FK and atomic publication—is required for correctness and cannot be traded away for fewer files.
