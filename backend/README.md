# Rendez backend M0

Requires Docker Compose and Go 1.26 or newer. This milestone has only process and database health checks. Run commands from the repository root:

```sh
make -C backend local-db
make -C backend migrate
make -C backend verify-m0
make -C backend run
```

In another terminal:

```sh
curl --fail http://127.0.0.1:8080/health/live
curl --fail http://127.0.0.1:8080/health/ready
```

Press Ctrl-C to stop the API. Then run `make -C backend local-down` to stop PostgreSQL **without deleting its volume**. `make -C backend test` runs unit tests; `make -C backend test-integration` creates and removes its own temporary test database inside the local PostgreSQL instance. It never resets `rendez_core`.

The Makefile uses disposable local credentials and a loopback-only database port. Export `DATABASE_URL` and optionally `HTTP_ADDR` to override. The API refuses startup before its Goose schema is installed. `-migrate` applies only `migrations/core` from the backend working directory. The old Gin/GORM/password/JWT project and its migration files are preserved as a separate, inactive nested module in `legacy/`; no legacy database is modified. The original untracked backend is also checkpointed in ignored `../scratch/rendez-backend-before-m0-20260923.tar.gz`.
