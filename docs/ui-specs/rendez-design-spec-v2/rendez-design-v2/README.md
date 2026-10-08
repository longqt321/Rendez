# Rendez UI Specification v2.0

**Direction:** Pinterest-inspired discovery feed + actual interactive map.

Read in this order:

1. [references.md](references.md) — verified public design references, research boundary, design pattern extraction and technical provider constraints.
2. [design-system.md](design-system.md) — tokens, components, responsive and accessibility rules, **strict copywriting contract**.
3. [screens.md](screens.md) — exact layout/interaction contracts, error states, acceptance IDs and visual-testing protocol.

## Implementation instructions

Treat these files as the UI acceptance contract for [longqt321/Rendez](https://github.com/longqt321/Rendez). Keep the existing price-evidence, moderation, privacy and account semantics. Map is new work: implement an actual coordinate-backed map, not a decorative placeholder. Research-first references do not excuse skipping screenshots of the running implementation.

**Highest-priority content rule:** no marketing/filler/AI-sounding prose; all mock-only text uses `Lorem ipsum`; real UI labels/errors/empty states remain functional and accurate. Delete unnecessary Text widgets rather than filling space.

## Scope / status

Design specification only. No repository changes, runtime screenshots or app integration are asserted by these documents. All screenshots listed in `screens.md` are future acceptance artifacts.
