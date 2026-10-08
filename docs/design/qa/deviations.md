# Acceptance boundaries

- The existing workspace requires login at startup and returns there on session expiry. This behavior was preserved; guest-first discovery in the design contract is not enabled because it conflicts with those pre-existing changes.
- Web screenshots and widget tests do not certify Android/iOS GPS, camera, native sharing, physical-device gestures or permissions. Device checks remain required.
- Existing demo catalog has two coordinate-backed venues and one without coordinates. Browser replay verifies aggregation and expansion of the two actual markers. Larger dense catalogs and coincident-coordinate spiderfy still need acceptance evidence.
- The base OSM raster tiles remain in their provider's light cartographic style in dark mode. App controls, preview and navigation use dark tokens.
- Feed images retain source geometry when available; current local catalog has no cover photos. Variable source-photo ratios therefore require a real approved-photo catalog to visually accept.
- The original browser permission-error timing gap is addressed by the location accuracy patch. `location-accuracy.md` and `location-denied-web.png` record immediate denial feedback in Chrome; native permission behavior still needs device checks.
- Feed and map have light/dark screenshots at all four required widths. The large-text render is checked by widget tests; screenshots for every nested dialog and exhaustive control inventory are not yet certified.
- Existing account, contribution, price evidence and Admin behavior is retained and covered by tests/integration. This change does not claim a new visual certification for every Admin or contribution dialog.
- Before production, confirm tile-provider capacity and license. Provider outages show retry feedback without disabling discovery navigation.
