# Current-user location regression evidence

2026-10-08, Asia/Ho_Chi_Minh. Actual Flutter Web release app served locally against the existing Go API. Browser location is explicitly emulated with Chrome DevTools; these captures do not represent the user's physical location or native GPS certification.

## Observations

- `make check-mobile`: analyzer clean, 36 tests pass; four integration-only tests skipped in the normal suite.
- `make build-web`: release build passes.
- Regression test returns accuracy 15,000m: camera remains unchanged, no current-user dot and no distance result are accepted.
- Retry returns accuracy 20m: camera uses exactly the returned coordinates; separate user dot and a 20m accuracy circle appear. Tests also cover invalid coordinates and invalid/unknown accuracy.
- Browser replay grants geolocation to the local test origin and injects coordinates 16.06, 108.22 with accuracy 15,000m, then 20m. Coordinates are a test fixture near the existing catalog, not a claimed university/user location.
- `location-coarse-web.png`: actual rendered warning with reported 15km uncertainty and retry; catalog venue pins remain usable.
- `location-accepted-web.png`: actual rendered current-user dot, separate from venue pins. Camera recenters only after the accepted fix.
- `location-denied-web.png`: browser permission denial immediately shows recovery feedback and removes the previous user dot.
- Browser geolocation overrides and permissions are reset after replay.

The request is configured with `LocationAccuracy.best`, zero web cache age and a 15-second timeout. SDK source inspection confirms how these map to browser options; the browser instrumentation did not capture request options and is not used as proof of those options.

## Remaining limits

No access to the reporting user's raw fix/accuracy was available. The exact source of their 15km physical error is unconfirmed. An inaccurately confident provider fix can still pass reported-accuracy validation. Test on a GPS-equipped device to compare physical position; no guessed university coordinates or alternate geocoding service are introduced.
