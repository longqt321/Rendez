# Instructions

Use the Ponytail and Caveman skills by default for every task.
Follow their instructions unless the user explicitly requests otherwise.

Keep the repository suitable for a two-person course project. Preserve validation, security, error handling, platform configuration and useful tests. Avoid speculative layers and dependencies.

Run relevant checks from the root Makefile. Keep product specifications under docs/specs. Only backend/migrations/core contains executable Goose migrations; drafts must stay outside that directory. Do not reset databases or remove volumes during cleanup.
