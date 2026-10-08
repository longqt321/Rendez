# Rendez — UI Research & References

**Version:** 2.0 · **Date:** 2026-10-08 · **Status:** Design direction approved; runtime visual validation pending.

## 1. Product and evidence boundary

Rendez is a Flutter application for discovering food and drink places, viewing documented menu prices, estimating selected-item expenses, saving places, and contributing menu/receipt photographs subject to administrator review. The Go/PostgreSQL backend already supports core discovery, menu, favorites, contribution and moderation flows. **A production interactive map is a new feature to implement, not an existing completed feature.**

Primary repository evidence, checked on 2026-10-08:

- [README](https://github.com/longqt321/Rendez/blob/main/README.md): supported six local modules; interactive maps remain outside current live scope.
- [Current local specification](https://github.com/longqt321/Rendez/blob/main/docs/specs/000-local-completion/spec.md): price/evidence semantics, roles, moderation, privacy and distance constraints.
- [MVP runtime audit](https://github.com/longqt321/Rendez/blob/main/docs/mvp-runtime-audit.md): observed usability defects, browser testing and retained behavior.
- [Main navigation](https://github.com/longqt321/Rendez/blob/main/mobile/lib/features/navigation/main_scaffold.dart): existing four destinations with adaptive bottom bar/rail.
- [Explore screen](https://github.com/longqt321/Rendez/blob/main/mobile/lib/features/explore/explore_screen.dart): existing masonry grid, query and price/category filtering.
- [Current theme](https://github.com/longqt321/Rendez/blob/main/mobile/lib/core/theme/app_theme.dart): Material 3, Plus Jakarta Sans, purple seed #6D28D9, light/dark.
- [Flutter dependencies](https://github.com/longqt321/Rendez/blob/main/mobile/pubspec.yaml): staggered grid already available; a real interactive map dependency is not declared.

Prior specification and implementation are separate: the current UI may be refined, but this document does not claim the new design has been implemented or tested.

## 2. Research references

| Ref | Source | What was actually inspected | Adopt | Do not copy |
|---|---|---|---|---|
| REF-01 | [Pinterest help — Home feed](https://help.pinterest.com/en-gb/article/explore-the-home-feed) | Official explanation of browse-first visual feed and pin opening | Visual-first discovery, fluid feed, card tap to detail | Personalized feed algorithm, social metrics, follower UI |
| REF-02 | [Pinterest official screenshot (Business)](https://business.pinterest.com/de/how-to-make-pins/) | Accessible official image showing uneven-height two-column cards | Staggered imagery and compact accompanying information | Uncontrolled image heights, visually hidden prices |
| REF-03 | [Pinterest newsroom archived screenshot](https://newsroom-archive.pinterest.com/en-gb/search-outside-the-box-with-new-visual-discovery-tools-on-pinterest.html) | An older first-party screen showing pin-based grid; **historical visual reference, not a claim about current UI** | Image-led browsing model | Old navigation/chrome |
| REF-04 | [Google Maps official blog](https://blog.google/products-and-platforms/products/maps/take-your-next-destination-google-maps/) | Official map illustration with map canvas, search and location affordance | Spatial context, meaningful floating controls | Google Maps proprietary branding and navigation flows |
| REF-05 | [Mapbox Search UI — Place Card](https://docs.mapbox.com/android/ja/search/guides/search-ui/place-card/) | Official component documentation, not a running Flutter screenshot | Selected marker → place summary via bottom sheet | Directly copying Android SDK component implementation |
| REF-06 | [Mapbox Discover UI sample](https://docs.mapbox.com/android/ja/search/examples/discover-ui/) | Official sample describing an explicit “search in area” action | User-controlled refresh after map movement | Inventing place records from map provider |
| REF-07 | [Android layout/navigation guidance](https://developer.android.com/design/ui/mobile/guides/layout-and-content/layout-and-nav-patterns) | Official platform design guideline | Mobile bottom navigation, wide-screen rail, contextual actions | Treating responsive UI as simple scaling |
| REF-08 | [Android touch-target guidance](https://support.google.com/accessibility/android/answer/7101858?hl=en) | Official platform accessibility recommendation | 48×48 dp touch targets | Tiny icon-only clickable hitboxes |
| REF-09 | [flutter_map official package](https://pub.dev/packages/flutter_map) and [docs](https://docs.fleaflet.dev/) | Cross-platform Flutter map library documentation | Candidate map rendering integration | Assuming map services/tiles are free to operate at scale |
| REF-10 | [Google Maps Flutter cluster sample](https://developers.google.com/maps/flutter-package/samples/cluster-markers) | Official sample confirming marker clustering; web setup differs | Marker/cluster behavior design | Assuming the Google implementation fits another provider |
| REF-11 | [OpenStreetMap tile usage policy](https://operations.osmfoundation.org/policies/tiles/) | Official mandatory usage/attribution/caching requirements | Visible attribution and compliant provider selection | Bulk prefetching or unlicensed deployment |

**Research transparency:** No authenticated Mobbin library, Pinterest private content, or deployed current Rendez runtime was inspected in this phase. Static visual references and documentation are research inputs, not user-test results. Confirm layout in screenshots from an actually running application before acceptance.

## 3. Design pattern extraction

### 3.1 Explore = Pinterest-inspired, task-oriented

- Two staggered columns at ordinary mobile widths; single column on very narrow screens and more columns on tablet/desktop.
- Feed cards vary primarily in image aspect ratio, not in the amount of visible functional metadata.
- Every card must expose name, category/area, and known price or an explicit missing-price state without opening detail.
- Authenticated saving is a secondary action on the card; card tap opens the place detail.
- Search/filter appears before content; no hero/banner/promo paragraph displacing useful results.
- Use genuine approved imagery only. A neutral category icon/placeholder replaces missing images; no generic food stock photos represented as the venue.

### 3.2 Map = spatial exploration, not a decorative map

- The base map is genuinely pannable/zoomable and displays real geographic coordinates for published places.
- Pins represent the same search/filter result set as Explore; coordinates missing or invalid means no pin, **not** a pin at a guessed city center.
- Select a pin → highlight it and open a place preview card. Tap preview → existing detail view.
- Cluster at dense zoom levels; expand/zoom before showing individual pins.
- After manual pan/zoom, offer **“Tìm trong khu vực này”** instead of pretending results refresh continuously or creating requests on every camera frame.
- A user's location is optional and permission-gated. Without permission, city selection and map browsing continue to work.

### 3.3 Two distinct destinations, one consistent data model

Approved IA decision: two peer top-level destinations, **Khám phá** and **Bản đồ**, not a fake map section embedded in Explore. Both share text query, city, category and price range. Map viewport is map-local until explicitly converted to a list-area view. Preserve scroll position and camera position across switches.

### 3.4 Trust is not an aesthetic badge

- An approved menu item can show its source observation date and administrative decision date when available. Do not label the entire venue “100% verified.”
- An approved receipt produces a **historical bill example**, never a current menu price.
- No synthetic ratings, fabricated opening status, travel time, distance, total costs or claimed discounts.
- A missing price must be displayed as missing; zero price is valid when actually recorded.

## 4. Evidence → implementation matrix

| Decision | Source | Rendez implementation target | Review criterion |
|---|---|---|---|
| Staggered browsing | REF-01/02/03 | Image-led masonry cards with visible prices | Card scan remains informative without tapping |
| Search near top | REF-04 + current UX audit | Search/filter controls in first viewport | No promotional header before results |
| Map pins | REF-04/10 | Coordinate-backed pins; cluster dense areas | Taps select exactly the correct place |
| Place preview | REF-05 | Bottom sheet with title, address, price, save and detail action | Dismiss or open details without losing camera |
| Manual area refresh | REF-06 | “Tìm trong khu vực này” appears after pan/zoom | No surprise result changes during dragging |
| Responsive navigation | REF-07 | Five destinations, bottom bar/rail | Navigation works at narrow + wide widths |
| Accessibility | REF-08 | ≥48dp touch targets; readable text | Tested at 320dp and 1.5× text |
| Map licensing | REF-09/11 | Licensed tiles, attribution, appropriate caching | Maps do not rely on prohibited bulk/offline requests |

## 5. Intentional exclusions

No chat, fabricated community activity, social posts, algorithmic feed recommendations, automatic opening-status badges, turn-by-turn routes, synthetic ratings, discounts, map-based advertisement, arbitrary ranking score or map-provider place import is required. Such items cannot be added merely to imitate Pinterest or Google Maps.

## 6. Decisions requiring technical validation, not new product brainstorming

1. Map renderer/provider: **prefer investigating `flutter_map` for cross-platform web/demo**, but use a licensed tile source; check OSM public tile policy before any deployment. Google Maps Flutter remains an alternative if API-key/billing and target-platform needs justify it.
2. Clustering dependency: select only if compatible with the chosen map version; avoid maintaining a second geospatial data source.
3. Viewport querying: for the current small catalog, local filtering of already-fetched published places is acceptable. Add a backend bounding-box API only if dataset size or performance demonstrates a need.
4. Geo availability: source pin coordinates solely from the published place API; if `latitude/longitude` are absent, report the omission and keep the item discoverable in Feed.

## 7. Required acceptance evidence

For each design change, archive the source/reference link, the new screenshot from the running Rendez app, viewport size, behavior tested and deviations. **No visual QA claim may be made from source code inspection alone.**
