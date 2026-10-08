# Design v2 runtime evidence

Captured 2026-10-08, Asia/Ho_Chi_Minh. Flutter Web release build, Chrome headless, viewport height 844px, local Go API/PostgreSQL. Screenshots are actual renders, not design mockups.

## Verified checks

- Root `make check-mobile`: analyzer clean; 34 tests pass, four live tests intentionally skipped outside integration mode.
- Root `make check-backend`: Go tests, development-tag tests and both vet runs pass.
- Root `make integration-ui`: real HTTP/Postgres journey including Flutter passes. Existing development data and volumes retained.
- Root `make build-web`: release build succeeds.
- `discovery_v2_test.dart`: shared search survives switching Feed/Map; a published place without coordinates remains in discovery; explicit zoom enables area search and applying bounds hides it.
- Discovery v2 also tests the five destinations, map and selected preview at 320dp and 1.5x text. Existing usability tests cover 320dp at 1.5x text, authentication/expiry, contribution preservation, account boundaries, prices and recovery.

## Browser replay

Signed in with an existing local audit account. Feed captured at 320, 390, 768 and 1280px. Selected Map, zoomed, applied “Tìm trong khu vực này”, selected the actual Rendez Demo Kitchen marker, opened its live detail, returned, changed theme to dark, switched Feed/Map and resized to 768/1280. Camera and selection survive navigation/resizing. Provider tiles visibly render; marker positions correspond to API coordinates. The third API place lacks coordinates and stays in the feed only.

## Screenshot inventory

- `320-feed-light.png`, `390-feed-light.png`, `768-feed-light.png`, `1280-feed-light.png`: responsive feed.
- `390-feed-dark.png`: dark discovery.
- `390-map-default.png`, `390-map-zoom.png`, `390-map-area.png`: tiles and area workflow.
- `390-map-selected.png`, `390-map-detail.png`: marker identity, preview and detail.
- `390-map-dark.png`: selected preview in dark mode.
- `768-map-panel.png`, `1280-map-panel.png`: retained selection after resize, full-width map after rail.
- `390-map-save-toggle.png`, `390-map-save-restored.png`: favorites change with successful HTTP 204 responses; QA restores the venue to its original unsaved state afterward.
- `390-map-cluster.png`, `390-map-cluster-expanded.png`: two actual coordinate-backed venues aggregate and split after clicking the numeric cluster.
- `*-map-light-final.png`, `*-map-dark-final.png`, `*-feed-dark-final.png`: final-build snapshots at 320/390/768/1280px; light feed snapshots use the original names.
- `390-map-attribution-save.png`: final provider attribution remains visible while a server-confirmed save snackbar is displayed.
- `390-map-location-denied.png`: browser geolocation permission set to denied; map remains interactive. This capture does not certify native permission handling or immediate error-message delivery.

Final `*-map-*-final.png` captures are the acceptance reference. Earlier map captures record previous iterations. Runtime review found a snackbar could obscure bottom attribution; the final implementation moves attribution into a separate row above the canvas. The 320dp/1.5x test checks attribution stays above preview actions.

Images reviewed for price visibility, neutral/no-photo states, pin selection, attribution visibility and navigation collisions. See deviations for incomplete coverage.
