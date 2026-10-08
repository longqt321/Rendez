# Discovery design v2 implementation

Source contract: `docs/ui-specs/rendez-design-spec-v2/rendez-design-v2/`. Unmodified contract snapshots are archived here as `references.md`, `design-system.md`, and `screens.md` so the product specification remains under `docs/specs`.

The implementation adds five primary destinations in the requested order, shared city/name/address/dish/category/menu-unit-price filters, a responsive discovery feed, and a coordinate-backed map. Public venue data remains sourced from `/v1/places`; places without valid coordinates remain in discovery and never receive inferred pins. Map viewport filtering is local and does not constrain the feed.

The map supports raster tiles, clustering, venue preview, live detail, authenticated saving, explicit current-location permission, zoom controls and manual area search. The map uses available width after the navigation rail; other primary content remains constrained to 1100dp. Account startup and expiry changes already present in the workspace are preserved.

Colors, neutral card surfaces, card borders, search labels and server-confirmed save behavior follow v2. No synthetic ratings, distance, stock venue photos, inferred menu prices, AI integration or extra backend service is introduced.

## Tile provider

Renderer: flutter_map 8.3.2, BSD-3-Clause. Cluster plugin: flutter_map_marker_cluster 8.2.2, MIT. Both list Flutter Web, Android and iOS support; native behavior still requires device acceptance.

The local course demo defaults to `https://tile.openstreetmap.org/{z}/{x}/{y}.png`. Attribution is always visible and opens the OSM copyright page. Native requests identify `vn.rendez.app`; web uses browser identification and Referer. flutter_map's built-in cache is retained; no prefetch, offline download or cache-busting is added. `--dart-define=MAP_TILE_URL=...` supports an alternative compatible provider. A provider change must also update attribution and validate its license. OSM public tiles have usage restrictions and no availability guarantee; reassess the provider before production traffic.

Primary references: https://docs.fleaflet.dev/, https://pub.dev/packages/flutter_map_marker_cluster, https://operations.osmfoundation.org/policies/tiles/.

## Acceptance evidence

See `docs/design/qa/interactions.md` and `docs/design/qa/deviations.md`. Screenshots use actual local API data, including explicit existing demo records; no new mock data is inserted for visual capture. Native acceptance is not claimed.
