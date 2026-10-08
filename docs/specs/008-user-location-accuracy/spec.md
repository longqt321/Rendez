# User location accuracy

## Observed problem and evidence

A laptop web user at Da Nang University of Science and Technology reports the location action centers the map more than 15km away. The screenshot alone cannot establish the browser-returned coordinates or accuracy. OSM provides raster tiles; user coordinates come from Geolocator and the browser geolocation service. The original map centers initially on catalog venue bounds and uses venue pins; it did not render a distinct current-user dot.

The installed geolocator SDK already defaults to `LocationAccuracy.best`; geolocator_web translates it into `enableHighAccuracy: true`. Asking for high accuracy alone therefore does not fix this report. Both the map and venue distance estimator consumed returned coordinates without checking `Position.accuracy`. In addition, the web `requestPermission` implementation performs a separate unconfigured location lookup; permission acquisition now occurs within the single configured current-position request instead.

## Behavior

- Explicit user action only; no background location tracking.
- Web requests high accuracy, zero cached-position age and a 15-second timeout. Browser handles permission for that request. Native paths retain service/permission checks.
- Common validation rejects non-finite/out-of-range coordinates, missing/invalid reported accuracy and accuracy over 500 metres. The 500m limit is an app policy for these two consumers, not a geolocation standard or guarantee of physical correctness.
- Rejected fixes never move the camera, render a user dot or generate a venue-distance estimate. Show a functional error with reported uncertainty and retry.
- Accepted map fixes show a distinct current-user dot and an accuracy circle in metres. Tooltip describes the reported uncertainty. Venue pins retain their original identities and prices.
- Successful recentering clears map-local applied bounds and venue selection and enables area search; shared discovery filters are preserved.
- A fresh failed request clears a previous user dot. Browsing and retry remain available, and errors replace queued snackbars promptly.

## Limits

The app cannot independently verify physical location or correct an incorrectly confident provider fix. This change never hardcodes the user's university or substitutes a guessed coordinate. If a laptop still produces wrong or coarse fixes, compare with a GPS-equipped device. Native-device acceptance remains separate.

## References and checks

- https://developer.mozilla.org/en-US/docs/Web/API/Geolocation/getCurrentPosition
- https://developer.mozilla.org/en-US/docs/Web/API/GeolocationCoordinates/accuracy
- https://pub.dev/packages/geolocator
- Installed `geolocator_web` and `geolocator_platform_interface` implementations.
- `make check-mobile`: analyzer and all 36 tests pass (four integration-only tests skipped outside integration mode). Regression cases include 15km accuracy, invalid accuracy/coordinates, unchanged camera after rejection and a 20m retry with correct user dot/accuracy circle.
- Web build and browser evidence are recorded in `docs/design/qa/location-accuracy.md`.
