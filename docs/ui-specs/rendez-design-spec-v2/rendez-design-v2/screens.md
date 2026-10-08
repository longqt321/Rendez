# Rendez — Screen & Interaction Specification v2.0

**Scope:** Product UI contract for Pinterest-inspired feed and interactive map, followed by existing core user journeys. **Date:** 2026-10-08. **Language:** Vietnamese user UI; implementation notes in English when unambiguous.

> This document defines target behavior, not completed features. The map is not currently part of the live app. All displayed prices, location points, images and evidence must come from real, permitted app data. **Do not add ornamental or promotional text. Mock-only text is Lorem ipsum.**

## 0. Screen map, navigation, and shared state

### 0.1 Primary destinations

| Index | Destination | Default entry | Protected? | State retained |
|---|---|---|---|---|
| 0 | Khám phá | Initial landing | No | feed scroll, search, filters |
| 1 | Bản đồ | From bottom nav/rail | No | camera, selected place, bounds and map-ready state |
| 2 | Đã lưu | Bottom nav/rail | Yes for data; guest sees sign-in entry | list position |
| 3 | Đóng góp | Bottom nav/rail / place detail | Yes to submit | unfinished valid form and images |
| 4 | Cá nhân | Bottom nav/rail | Guest/authenticated variants | form state when appropriate |

The existing order in the repository is different; this is a deliberate requested IA change. Mobile labels must remain visible. Admin is accessible from account only after server-authorized Admin authentication.

### 0.2 Shared discovery state

Single source of truth for:

- `searchQuery`: name/address/dish search, same meaning as existing backend search.
- `selectedCity`: all cities or one supported city, from existing lookup/API. No fake locations.
- `selectedCategory`: all or one published category.
- `selectedPriceBand`: published **menu unit-price** filter, not historic bill total.
- `publishedResults`: last successfully fetched authoritative server results and loading/error state.
- `savedIds`: authenticated, owner-scoped state; current account only.

Map-local:

- Camera center/zoom, viewport bounds, user-current-position permission state, selected place ID, pending-area-refresh indicator.
- A map-viewport query must **not** silently narrow Explore when switching tabs.
- If users explicitly select a map action such as “Xem danh sách khu vực này” in a later iteration, the app must clearly show that area constraint and offer a way to remove it. Not required for v2.

### 0.3 Data invariant

**Feed results** are server-published places meeting shared search/filters. **Map candidates** are the same results restricted to records with valid coordinates; **visible pins** are further restricted to active map viewport as appropriate. A published place missing coordinates remains in Feed and detail. A hidden/draft/deleted place must never appear publicly in either mode. Changing filters updates both modes using a consistent result version; no stale pin should lead to a deleted/hidden record in public detail.

### 0.4 Common states

Every route defines loading, data, empty, error and recovery states. Failure of a fresh request may keep previously valid data if visibly identified as stale and never misrepresented as current. Fetch errors must show human-readable Vietnamese, not raw backend exceptions. “Retry” must actually retry. Authentication/error states must not leak another account's saved places or uploaded images.

---

## S01 — Explore / Pinterest Feed

**Goal:** browse real nearby/city-filtered food and drink places quickly, compare documented prices and open detail. **Reference:** Pinterest uneven-height image cards; functional content density from Rendez's current MVP.

### S01.1 Layout (compact)

```text
┌────────────────────────────────┐
│ [Tìm địa điểm hoặc món ăn]  [×]│
│ [Thành phố ▾] [Loại hình ▾]    │
│ [Đơn giá ▾]   [Bỏ bộ lọc]*    │
│  N địa điểm*                   │
│ ┌─────────────┐ ┌────────────┐│
│ │ real photo  │ │ photo /    ││
│ │         ♡   │ │ neutral    ││
│ ├─────────────┤ │ placeholder││
│ │ Cafe        │ ├────────────┤│
│ │ Place name  │ │ Name       ││
│ │ Area        │ │ Area       ││
│ │ From price  │ │ No menu    ││
│ └─────────────┘ └────────────┘│
│ ... masonry results            │
├────────────────────────────────┤
│ Khám phá | Bản đồ | Đã lưu ... │
└────────────────────────────────┘
```

The schematic uses role names to illustrate layout, **not UI text to insert**. Actual venue names/data come from API, otherwise mock prose uses Lorem ipsum only. `N địa điểm` is displayed only when actually counted, not for decorative density.

### S01.2 Component order

1. Search field anchored top of scrolling content or sticky only if it doesn't crowd screens.
2. One compact filter region; wrap or horizontal-scroll filter chips without cutting labels on 320dp.
3. Result count, if useful and true; one clear-filters action only while filters are active.
4. Masonry cards; two columns for normal mobile widths, one column below 360dp.
5. Persistent primary navigation outside scroll content.

**No large introductory title, seasonal hero, banner, editorial copy or promotional subheading.**

### S01.3 Place card specification

- Real approved image (if any) with aspect ratio preserved within allowed layout geometry; fallback neutral icon block when missing.
- Visible: category, `name` (max 2 lines), shortened `address`/area (max 2), authentic “Từ {price}” only if a valid menu minimum is available, otherwise **“Chưa có bảng giá”**.
- `Save` icon is separately tappable and accessible. Tap image/card excluding save opens detail. Tapping save as a guest opens account flow and resumes the save; network failures must not pretend it succeeded.
- Optional distance only if actual user position was acquired and valid venue coordinates exist. Label **“Khoảng {x} km”**, never travel distance/time.
- No fabricated 5-star score, like count, popularity, hours, photo, neighborhood pin or offer.

### S01.4 Behavior

- Typing search updates results with modest debouncing; pending request results must not overwrite newer queries.
- Changing a shared filter updates Feed and Map and is reflected in selected controls on both routes.
- `Bỏ bộ lọc` clears active shared filters/query; do not reset scroll to unrelated content unless list identity changed appropriately.
- Pull-to-refresh makes a real API request; results reflect current publication state.
- Infinite scrolling/pagination not required for the small local catalog; add only after measurable need.
- “Gần bạn” sorting/label may appear only if user location exists and ordering is actually by computed straight-line distance; **do not** assume location permission on launch. Without location, retain existing backend/default order and city filter.

### S01.5 State matrix

| State | What is shown | Action |
|---|---|---|
| loading | neutral image/text skeletons with no fake price or names | wait |
| normal | real cards | open/save/filter |
| missing photo | neutral category icon tile | normal card actions |
| missing menu | “Chưa có bảng giá” | open place or contribute |
| empty after filters | “Không tìm thấy địa điểm” | “Bỏ bộ lọc” |
| city has no published places | “Chưa có địa điểm ở khu vực này” | change city |
| network failure | “Không tải được địa điểm.” | “Thử lại” |

### S01.6 Acceptance IDs

- `FEED-01`: Visually useful first viewport: search/filter plus real result content, no hero prose.
- `FEED-02`: Cards display correct source-backed name, category and price state; don't invent ratings or photos.
- `FEED-03`: Save icon and card navigation work independently.
- `FEED-04`: Shared query/filters remain selected after switching to Map and back.
- `FEED-05`: 320dp+large text has no overflow; one column where necessary.

---

## S02 — Interactive Map

**Goal:** explore published venues by actual spatial position and inspect places with minimal interruption.

### S02.1 Layout (compact)

```text
┌────────────────────────────────┐
│ [Search               ] [Filter]│
│ [City] [Category] [Price band] │
│                                │
│       INTERACTIVE MAP          │
│       ○ cluster(8)    ● pin    │
│                ◎ selected pin  │
│                         [◎]    │
│     [Tìm trong khu vực này]*   │
│ ┌────────────────────────────┐ │
│ │ Selected place preview*    │ │
│ │ name · area · price state  │ │
│ │ [Chi tiết] [Lưu]           │ │
│ └────────────────────────────┘ │
├────────────────────────────────┤
│ Khám phá | Bản đồ | Đã lưu ... │
└────────────────────────────────┘
```

No visible debug coordinates, no mock gray rectangle pretending to be a functional map, no arbitrary coordinates for pins. Attribution remains visible even while a place sheet is open.

### S02.2 Core pieces

- Genuine tile/map canvas occupying the available content space, with pan, pinch zoom, mouse wheel zoom and keyboard alternatives where feasible.
- Top floating search/filter control consistent with Feed, without covering most of the map.
- Real pin layer derived from published places with valid geographic coordinates.
- Cluster layer for dense locations; numeric clusters may show actual member count only.
- Current-location control (clearly named) requesting permission **only on explicit action**.
- “Tìm trong khu vực này” CTA appears when map camera has moved meaningfully and current viewport is not applied to results.
- Place-preview bottom sheet/panel appears only on selected place and stays above main nav.
- Visible map provider/license attribution. The UI cannot obscure attribution with filter chips, previews or floating buttons.

### S02.3 Initial camera selection

1. Reopen within the current session: restore last user map camera (even when switching tab).
2. First open with published valid-coordinate results: fit their bounds with reasonable padding/zoom limits; if a selected city is active, fit the valid pins in that city.
3. With no valid pins: show a usable base map at a configured, verified region default if available; otherwise use a city-selection state, **not guessed per-place pins**.
4. Current position is **not** requested automatically. On explicit `Vị trí của tôi`, ask permission, pan to actual result if allowed. If denied, leave map browse usable and show a small actionable permission message.
5. If the provider cannot load tiles, show a map error/retry; retain a path back to Explore and do not invent a painted substitute.

### S02.4 Marker behavior

- Single pin tap: set `selectedPlaceId`, highlight only that pin and show preview of the *same* place ID.
- Tapping selected pin again: keep or dismiss preview consistently; do not open details unexpectedly.
- Cluster tap: zoom/focus cluster members; no random selection.
- Tapping map blank area: dismiss preview but keep camera and filters.
- Tap preview `Chi tiết`: open existing Place Detail, re-fetch live record.
- Tap preview `Lưu`: use authenticated favorites API; guest sign-in flow resumes the intended action.
- After filters change, if selected place is excluded, clear selection and sheet; preserve camera.
- No location/coordinate valid → place does not render as marker but does remain discoverable in Feed.

### S02.5 Manual area search behavior

A deliberate, predictable workflow:

1. User pans/zooms; pins/candidates can be recomputed from locally loaded, already filtered data when safe, but **do not claim a server area search was executed**.
2. A `mapBoundsDirty` state causes “Tìm trong khu vực này” to appear if the user moved away from the last applied viewport.
3. User taps CTA; derive bounds from the map controller; filter only the known published result set to visible bounds (plus declared search/filter). On small catalog, this is client-side and sufficient; if later required, implement real bounding-box API.
4. Update visible pins and the genuine result count if displayed, clear dirty state and hide CTA.
5. New pan/zoom re-enables CTA. Avoid API requests on every rendered camera frame.

**Rule:** Do not promise exhaustive coverage of all restaurants in the geographical area. The map only shows places present in Rendez data. A factual empty state is **“Không có địa điểm trong khu vực này”**, not “Ở đây không có quán ăn”.

### S02.6 Place preview content

- Source-backed place name, category, address/area, actual minimum menu price or “Chưa có bảng giá”.
- Approved place imagery if available; neutral icon if unavailable.
- Optional user-relative distance (actual position + valid venue coords) labeled as an estimate, never routing/travel time.
- Actions `Chi tiết` and `Lưu` only. Do not introduce “Chỉ đường” before a verified external-map/deep-link strategy is implemented and tested.
- Preview scroll does not accidentally pan the map. Moving the sheet cannot cover all navigation or attribution.

### S02.7 State matrix

| State | Result | Recovery |
|---|---|---|
| map loading | neutral progress indicator, no fake map image | wait |
| map loaded + pins | tappable markers / clusters | inspect |
| no published coordinates | map empty of venue pins, factual state | go to Feed/change city |
| missing permission | usable map, no location dot or “nearby” claim | `Vị trí của tôi` retry/device settings |
| tile/provider error | explicit map error, other navigation accessible | `Thử lại` / Feed |
| venue fetch error after pin | preview cannot open stale detail as if fresh | retry detail |
| filters produce no pins | “Không có địa điểm trong khu vực này” | remove filters/move map |

### S02.8 Wide-screen adaptation

Map fills its available portion after nav rail. If a place is selected, prefer a constrained side card/panel (e.g., 320–380dp wide) to obscuring the lower map. Keep fit-bounds padding aware of the side panel, and preserve mouse/keyboard interaction.

### S02.9 Acceptance IDs

- `MAP-01`: Actual tiles render; pan/zoom works on web/mobile; attribution visible.
- `MAP-02`: Pin positions match API coordinates; missing coordinates never fabricated.
- `MAP-03`: Selected pin matches preview and re-fetched detail ID.
- `MAP-04`: Clusters correctly aggregate actual valid markers and split on zoom.
- `MAP-05`: Filters match Feed; map-bound selection does not invisibly alter Feed.
- `MAP-06`: Location is optional; denied permission does not block map.
- `MAP-07`: Search-area CTA works after actual camera movement and dismisses appropriately.
- `MAP-08`: No preview/bottom nav/attribution collision at 320 and 390dp or in dark mode.

---

## S03 — Place Detail

**Goal:** judge a venue using documented price information, estimate a selected meal, examine sources and contribute updates.

### S03.1 Layout order

1. Standard app bar/back with factual venue name and save/share actions.
2. Optional approved photo gallery/cover. If none, use no-image state; do not promote generic imagery.
3. Venue name, category, address, opening-hour field **only if known**.
4. Single meaningful distance component: optional user permission, estimate displayed only when computed.
5. Menu with item name/category/actual price, source observation and review dates when provided.
6. Price calculator: +/- item quantity, group size, computed total and per-person estimate. No preset selection.
7. Approved menu source images, zoomable, with accessible close.
8. Approved historical receipt examples in a separate clearly named section.
9. `Gửi menu hoặc hóa đơn` action with venue preselected.

### S03.2 Price rules

- Known menu prices remain item-level truth. Source observation date is not replaced by Admin review date.
- Selected quantities 0–99; people 1–100; zero selected items ≠ zero-priced selected items.
- Formula: `sum(unit_price × selected_quantity)` and `total / party_size`, with current backend/model currency rounding convention.
- Historical receipts do not determine current per-item price or venue minimum price.
- Honest caveat, when displayed and useful: “Giá tham khảo; có thể thay đổi.” Do not repeat same caveat under every item.
- Missing price: “Chưa có bảng giá” plus useful contribution action; no anonymous made-up range.

### S03.3 Acceptance IDs

- `DETAIL-01`: Entered via either Feed or Map, same record and consistent price information.
- `DETAIL-02`: Source photos and observed/review dates remain distinct.
- `DETAIL-03`: Calculate only selected items; correct with zero-priced items.
- `DETAIL-04`: Save/share/contribute buttons invoke real functions and show actual outcome.
- `DETAIL-05`: Long names, narrow widths and dark theme do not obscure essential values.

---

## S04 — Saved

- Signed-in users: show server-owned saved places using the same factual card language. Unsaving persists through API, with existing Undo semantics when a real reversal is available.
- Guest users: one factual gated state and **“Đăng nhập để xem đã lưu”**, not a marketing benefit list.
- Empty signed-in state: **“Chưa lưu địa điểm nào”** and optional **“Khám phá”** action.
- Deleted/hidden venues do not leak via public saved rendering; follow backend permissions.
- Account switch/logout clears visible private user state.

`SAVED-01`: proper owner scope; `SAVED-02`: undo and save synchronization across Feed/Map/detail; `SAVED-03`: no fictitious items or upsell text.

---

## S05 — Contribution + History

### Main contribution

- Keep existing functioning multi-step flow; no Pinterest-like styling on dense input form.
- Start from place detail or destination: preselect place if known. Otherwise choose existing venue or submit a new draft venue.
- Clearly labeled *real* fields: venue identity, evidence type (`Ảnh menu` / `Hóa đơn`), capture date, photos.
- Support only verified MIME/quantity limits from current specification: 1–5 actual JPG/PNG files, each under 10MiB, valid capture date.
- Preview chosen real images and permit removal; no invented “sample bill” image. Preserve form and selected files across tab changes and recoverable upload failures.
- Submitting uses the real API; show **“Đã gửi đóng góp”** only when confirmed. OCR result remains a draft until Admin review.

### History

- Show type, submission date, status, and rejection reason where applicable; private source images only to owner/Admin.
- Status language: `Chờ duyệt`, `Đã duyệt`, `Từ chối`; genuine backend distinctions only.
- OCR failed/pending is not incorrectly labeled `Từ chối`. Retry and read source action when allowed.
- No content extolling community contribution, no made-up contribution counts.

`CONTRIB-01`: actual image/metadata; `CONTRIB-02`: draft survives failures/navigation; `CONTRIB-03`: correct status and privacy; `CONTRIB-04`: Admin approval is not simulated in user UI.

---

## S06 — Authentication / Profile

- Profile is utilitarian: sign in/register when guest; account identity, logout and theme setting when authenticated; Admin entry only if role confirmed by API.
- No inspirational headers or meaningless stats. Do not display account token or implementation details.
- Input fields use visible semantic labels (`Email`, `Mật khẩu`, `Tên hiển thị`), not marketing guidance. Password visibility toggle and validations remain.
- After authentication, resume destination or protected save/contribution action. A declined/cancelled flow returns safely without fake success.
- Session revocation/401 clears account-specific UI state and gives a compact sign-in recovery.

`ACCOUNT-01`: register/login/logout work; `ACCOUNT-02`: protected-action continuation; `ACCOUNT-03`: dark/large text/keyboard; `ACCOUNT-04`: no ornamental copy.

---

## S07 — Admin Venue and Evidence Review

Keep a **workbench** rather than a social/photo feed:

- Queue: actionable pending contributions, separate processed history. Counts are shown only when backed by API.
- Venue editor: labeled fields, draft/published/hidden states, soft-delete confirmation and real server validation.
- Review: image source adjacent to OCR draft on wide screens and stacked on compact screens. Edit name/price/category or historical bill total/guest count according to evidence type.
- Support save draft, OCR retry, approve and reject (with reason) under actual backend transactions. Handle 409 concurrent reviews by showing server-confirmed outcome, not client assumptions.
- Original bill images remain private; approved menu images can be public under current rules.
- Error copy states exact functional problem; no praise/marketing text.

`ADMIN-01`: actual source/OCR comparison; `ADMIN-02`: no accidental public bill image; `ADMIN-03`: valid review lifecycle including conflict; `ADMIN-04`: 320dp readable and desktop workspace efficient.

---

## S08 — Responsive and global accessibility specification

- All widths: 320, 360, 390, 430, 768, 1280px; test portrait and desktop resizing.
- At 1.5× text: no horizontal overflow, clipped price, unreadable action, cut-off Vietnamese label or inaccessible bottom-sheet action.
- All actual interactive surfaces should target ≥48×48dp and have accessibility semantics. Pin/cluster accessible labels include actual place identity or actual cluster count.
- Navigation stays reachable while keyboard is open; content and sheets respect safe areas.
- Dark theme passes readable text/action contrast, especially selected pins, overlays and image viewer close affordance.
- Mouse hover/focus and keyboard support for web as practical; avoid interactions requiring only drag or long press.
- Respect user reduced-motion preference for nonessential animation.

---

## 9. Implementation order and no-scope-creep boundary

### Phase 1 — Shared discovery foundation

- Adapt five-destination navigation. Preserve all existing tested features.
- Centralize shared search/city/category/unit-price state and align Feed with current API.
- Tighten Feed cards and copy according to this spec. Do not rewrite backend or add recommendation.

### Phase 2 — Real map

- Confirm map renderer and licensed tile provider; implement genuine map rendering, markers from valid venue coords, clusters and selected-preview workflow.
- Implement explicit camera/viewport behavior, city/permission fallback, shared filters and map-local viewport.
- Verify mobile/web with real HTTP data; avoid fake pins or decorative map snapshots.

### Phase 3 — Consistency and regression

- Apply visual tokens to Place Detail, Saved, Contribution, Account and Admin without breaking business rules.
- Run existing Go/Flutter/integration checks; add UI tests for map/feed navigation and state sharing.
- Screenshot and interact with all controls, record discrepancies, fix, screenshot again.

### Out of scope

- Personalized feed ranking, social chat, post comments, social engagement, imported Google Places listings, automatic geocoding of missing addresses, turn-by-turn navigation, map-based crowd-sourced ratings, open-now badge, sponsored venues, and speculative backend architecture.

---

## 10. Acceptance matrix and required QA evidence

| ID | Scenario | Method | Passing evidence |
|---|---|---|---|
| `QA-01` | Feed at 320, 390, 768, 1280 | running app screenshot | no overflow; visible functional data; no decorative text |
| `QA-02` | Open/close switch Feed ↔ Map multiple times | automated UI navigation | query/filter stay; scroll and camera stay |
| `QA-03` | Pan, zoom and tap a real pin | actual rendered map | exact venue ID and preview; appropriate clustering |
| `QA-04` | Map area CTA after camera move | automated/manual map interaction | real viewport applied; no ghost state |
| `QA-05` | No location permission | permission denial simulation + device check | map usable; no false nearby claim |
| `QA-06` | Missing venue coordinates, photo, menu | API-backed fixtures | no fake pins/photos/prices; Feed remains accessible |
| `QA-07` | Favorite from Feed, Map, Detail | real authenticated backend | consistent server-confirmed state |
| `QA-08` | Submit menu/bill → Admin review → public result | actual HTTP/Postgres/OCR | correct source privacy and price semantics |
| `QA-09` | All exposed controls | interaction inventory | each button/chip/filter/menu/sheet/dialog exercised |
| `QA-10` | Strict microcopy audit | string inventory + screenshot review | every text functional; mock-only text Lorem ipsum; no slogans |
| `QA-11` | Light/dark, 1.5× text, keyboard | screenshot + accessibility inspection | legible labels/actions and no clipping |
| `QA-12` | Android/iOS physical device features | separate device acceptance | no claim of device certification from web tests |

### Recommended evidence directory

```text
docs/design/
  references.md
  design-system.md
  screens.md
  qa/
    320-feed-light.png
    390-feed-dark.png
    390-map-default.png
    390-map-selected.png
    768-map.png
    1280-map-panel.png
    interactions.md
    deviations.md
```

Names are a required output convention for future actual captures; **this specification does not claim screenshots currently exist**.

### Agent review loop

1. Open **the actual running app** using real API data; take screenshot.
2. Compare rendered layout and all text to this specification and references.
3. Click every visible UI control, including edge/error states. Record any controls impossible to automate.
4. Correct layout, copy and behavior. Capture updated screenshot.
5. Repeat until all P0 defects are gone: nonfunctional controls; fake data; false geography/price; visual overflow; source privacy leak; missing error recovery; blocked primary flow.
6. Deliver evidence: paths to actual screenshots, tests run, pass/fail and explicit untested platform limitations.

Passing `flutter analyze` or `flutter test` alone **does not** satisfy visual acceptance. Evidence of rendered UI is mandatory.

---

## 11. Copy audit checklist

Apply to *every added or changed user-visible literal*, including dialogs, snackbar, tooltip and accessibility labels:

- [ ] Exact business/task/accessibility purpose identified.
- [ ] All facts come from actual app data or explicitly labeled example state.
- [ ] Pure filler/mock text is **Lorem ipsum**, not plausible invented Vietnamese prose.
- [ ] No marketing slogans, motivational intros, fake reviews, fake status or gratuitous reassurance.
- [ ] Labels/action text remain meaningful; **do not use Lorem ipsum for real functional labels or messages**.
- [ ] If content provides no user value, delete it instead of rewriting it.
- [ ] No new unsupported UI features are implied by text.
