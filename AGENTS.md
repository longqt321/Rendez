# Instructions

Use the Ponytail and Caveman skills by default for every task.
Follow their instructions unless the user explicitly requests otherwise.

Use the TypeSafe skill at `.agents/skills/typesafe-ai/SKILL.md` when working on this project. Follow its guidance where relevant, and read the live TypeSafe docs before implementing an integration.

Keep the repository suitable for a two-person course project. Preserve validation, security, error handling, platform configuration and useful tests. Avoid speculative layers and dependencies.

Run relevant checks from the root Makefile. Keep product specifications under docs/specs. Only backend/migrations/core contains executable Goose migrations; drafts must stay outside that directory. Do not reset databases or remove volumes during cleanup.

## graphify

This project has a knowledge graph at graphify-out/ with god nodes, community structure, and cross-file relationships.

When the user types `/graphify`, use the installed graphify skill or instructions before doing anything else.

Rules:
- For codebase questions, first run `graphify query "<question>"` when graphify-out/graph.json exists. Use `graphify path "<A>" "<B>"` for relationships and `graphify explain "<concept>"` for focused concepts. These return a scoped subgraph, usually much smaller than GRAPH_REPORT.md or raw grep output.
- Dirty graphify-out/ files are expected after hooks or incremental updates; dirty graph files are not a reason to skip graphify. Only skip graphify if the task is about stale or incorrect graph output, or the user explicitly says not to use it.
- If graphify-out/wiki/index.md exists, use it for broad navigation instead of raw source browsing.
- Read graphify-out/GRAPH_REPORT.md only for broad architecture review or when query/path/explain do not surface enough context.
- After modifying code, run `graphify update .` to keep the graph current (AST-only, no API cost).

## UI acceptance

For every UI design decision, ask: "Liệu thiết kế ứng dụng như thế này thì người dùng có muốn sử dụng ứng dụng này hay không?" If the answer is no, redesign before considering the work complete. Explain the practical user benefit, preserve honest data and recovery actions, and check narrow screens, large text and dark mode. A design review is not proof of actual user adoption.

Assume users are not technical. Show benefits, results and clear next actions; keep algorithms, coordinates and implementation details out of user flows. Do not label an estimate as an actual travel route.
