# Rendez — Design System v2.0

**Direction:** Pinterest-inspired discovery + real interactive map. **Platform:** Flutter mobile first, Flutter Web and desktop adaptive. **Status:** approved specification for implementation; not yet runtime-verified.

## 1. Non-negotiable principles

1. **Every element earns its space.** An element must support discovery, orientation, trust, input, decision, feedback or accessibility. Delete anything with no task value.
2. **Data over decoration.** Never invent places, prices, pictures, reviews, ratings, open-now state or distance.
3. **Visual feed and functional map.** Feed emphasizes verified imagery and scan-friendly metadata; map emphasizes geographic position and selection.
4. **Progressive disclosure.** Surface venue name, category, area and price state immediately; place evidence details and cost calculation in Place Detail.
5. **Shared meaning, distinct presentations.** Feed and map filters operate over the same place catalog. Neither silently resets the other.
6. **Native usability.** Respect text scaling, touch targets, focus/keyboard, dark mode and OS permissions.
7. **Do not build ornamental UX.** No hero slogans, arbitrary counters, emoji headings, decorative chips, auto-rotating carousels or motion without user value.

## 2. Information architecture

Five primary destinations in order:

| Route identity | Label | Purpose | Icon concept |
|---|---|---|---|
| `explore` | Khám phá | Image-first browsing and text/category/price search | grid/search |
| `map` | Bản đồ | Geo-pins and area search | map |
| `saved` | Đã lưu | Owner-scoped saved places | bookmark |
| `contribute` | Đóng góp | Submit menu/bill evidence | add-photo |
| `profile` | Cá nhân | Account, preferences, Admin entry | user |

- Compact width: fixed bottom navigation with five labeled destinations. No duplicate feed/map segmented control above it.
- Wide width: navigation rail left. Preserve current destination when resizing.
- Details, source-image viewer, authentication-related actions and Admin editor are pushed/modal nested views, not extra bottom-nav tabs.
- Preserve feed scroll offset, map camera/selected pin and unfinished contribution data on tab switches.
- For protected actions, authenticate then return to the exact intended action or destination.

## 3. Visual tokens

Tokens are **design targets**, not claims of existing constants. Implement as reusable theme tokens, not ad hoc literals repeated across widgets. Before replacing current Material 3 tokens, validate contrast in both themes.

### 3.1 Color

| Role | Light | Dark | Use |
|---|---|---|---|
| Primary | `#6D28D9` | `#C4B5FD` | selected navigation, primary CTA, selected pins |
| On primary | `#FFFFFF` | `#24113F` | button/icon foreground |
| App background | `#FAF9F7` | `#15141A` | content canvas |
| Surface | `#FFFFFF` | `#24212B` | cards, bottom sheets |
| Primary text | `#1C1917` | `#F5F4F7` | content/title |
| Secondary text | `#625F66` | `#C5C1CD` | address, dates, supporting metadata |
| Border | `#E7E4E8` | `#413B49` | input/card separators |
| Success semantic | `#166534` | `#86EFAC` | confirmed successful actions only |
| Warning semantic | `#92400E` | `#FCD34D` | action required or incomplete source state |
| Error semantic | `#B91C1C` | `#FCA5A5` | failures/validation |

Purple is an accent, not a mandatory full-card background. Card backgrounds should remain primarily neutral. Price is emphasized with weight/placement, **not** a special badge implying verification.

### 3.2 Type

- Font family: **Plus Jakarta Sans**, already used in Rendez; system fallback permitted when unavailable.
- Display page title: 24sp, 700, line height ~1.25.
- Section title: 18sp, 700, line height ~1.3.
- Card name: 15–16sp, 700, line height ~1.3, max 2 lines.
- Primary price: 16–18sp, 700; preserve full currency formatting.
- Standard body: 14sp, 400–500, line height ~1.45.
- Supporting metadata: 12–13sp, 400–500; must remain legible at contrast and large text.
- Use sentence case Vietnamese. No all-caps slogans. Do not ellipsize prices, decision labels or errors.

### 3.3 Geometry

- Spacing scale: 4 / 8 / 12 / 16 / 20 / 24 / 32dp.
- Horizontal compact screen margin: 16dp; desktop feed container margin: 24dp.
- Feed column gap: 12dp; row gap: 16dp.
- Cards: 16dp radius, subtle 1dp border, no prominent permanent elevation.
- Sheets: upper radius 20–24dp; floating buttons 14–16dp radius.
- Buttons: touch region at least 48×48dp; important filled button height 48–52dp.
- Image card aspect ratios: flexible among ~3:4, 4:5 and 1:1 based on true source geometry. Do **not** assign random heights.
- Image overlay action (save): visually 36–40dp but effective hit area at least 48dp, sufficiently separated from outer card tap.

### 3.4 Responsive layout

| Content width | Feed | Map | Navigation |
|---|---|---|---|
| `< 360dp` | 1 column | Full available map viewport | bottom bar |
| `360–599dp` | 2 columns | Map + overlay controls + bottom preview | bottom bar |
| `600–839dp` | 2–3 columns based on min card width | Map + larger preview | bottom bar or rail according to tested content width |
| `≥ 840dp` | 3–4 columns, center content within 1200dp | Map and optional fixed selected-place side panel | rail |

Do not blindly apply the current Flutter Web **1100px root width limit to the map canvas**. On wide web, use the available map area after the rail; limit only content blocks/cards where needed. Any change to the global builder must preserve existing non-map screen layouts. Test 320, 390, 768 and 1280px.

## 4. Components

### 4.1 SearchBar

- Search place name, address and menu dish by existing API semantics.
- Search action must have accessible label; provide visible clear action only when nonempty.
- Do not add a redundant title/tagline above search.
- A functional field label such as **“Tìm địa điểm hoặc món ăn”** is not a decorative placeholder; preferably expose it as a real label/semantic hint. Avoid unnecessary filler in the field itself.

### 4.2 Filter controls

- Required: city, category, price band; text search shared across feed/map.
- Each selected filter is visible and removable. **“Bỏ bộ lọc”** clears only search/filter fields, not map camera or login.
- Do not introduce **“Đang mở”**, **“Giảm giá”**, **“Dưới 2 km”** or **“Đã xác minh”** until supported and precisely defined in the backend.
- Price filtering is explicitly on **đơn giá**; missing-price places do not magically get a numerical range.

### 4.3 PlaceCard — photo

Anatomy: real source photo → category → name → short address/area → **known menu starting price or “Chưa có bảng giá”**; saving control in image corner. Visual height may vary with actual image ratio, but metadata is stable. Distance appears only after user location was actually obtained and valid venue coordinates exist. No user stars, review counts or generic “verified” decoration.

### 4.4 PlaceCard — no-photo

Use a neutral block/icon appropriate to the category; show name/area and price data prominently. **Never replace an unknown venue photo with stock photography.** Do not fabricate a descriptive paragraph just to fill the card.

### 4.5 Map pin

- Only for `published` and valid latitude/longitude.
- Normal: minimal location marker with an accessible name; selected: brand-purple accent and distinct outline, not color alone.
- At close zoom, optionally show a compact *documented menu price* label such as `Từ 35.000đ`, if the API genuinely supports that value. Otherwise icon pin without price; never infer a price from a historical bill.
- Dense markers group into a numeric cluster. A cluster tap zooms/fits members; it does not open a random venue.
- Marker collision handling and overlap are required. Cluster/pin touch target ≥48dp, even if drawn smaller.

### 4.6 MapPreviewSheet

At compact width: anchored bottom sheet above primary nav, initially compact (roughly content-driven, typically 170–240dp). At wide width: side preview panel or constrained bottom card. Content: optional true image, venue name, address, category, known price or missing-price state; actions **“Chi tiết”** and **“Lưu”**. Sheet dismissal must preserve camera and filters. Do not obscure map attribution.

### 4.7 Price and evidence

- Format VND consistently. Known zero is **0đ**, not “chưa có giá.”
- Show source observation/capture date separately from approval date when supplied; never swap them.
- An approved bill is a **historical example** with total and guest count if known; it is not a general budget.
- The cost estimator uses selected menu item quantities and party size; no speculative default basket.
- Empty price state: **“Chưa có bảng giá”**; if useful, provide **“Gửi menu”**.

### 4.8 State feedback

- Loading: actual skeleton/progress, not invented content.
- Empty: factual one-line state + one recovery action only if available.
- Error: concise description + “Thử lại” when retryable. Never expose raw stack trace/HTTP exception text.
- Success: exact action result, e.g., **“Đã lưu địa điểm”** only after server confirmation.
- Partial: map tile service error must not suppress a still-functional place list. Bad pin coordinates must not hide a place from Feed.

## 5. Copywriting contract — highest priority

### 5.1 Prohibited

- Promotional hero blocks, slogans and generic motivational text.
- Phrases that praise the app or dramatize user actions: “Trải nghiệm tuyệt vời”, “Khám phá thế giới ẩm thực”, “Hành trình vị giác”, “Đừng bỏ lỡ”, “Cùng Rendez...”.
- Decorative section descriptions such as “Nơi những điều thú vị bắt đầu”.
- AI-like overexplaining: multi-sentence apologies for small operational errors, repetitive assurances, self-congratulatory success feedback.
- Fake statistics or metadata intended to make a card seem alive: review counts, invented prices, fictitious opening hours, curated popularity.
- Placeholder prose with plausible facts.

### 5.2 Mandatory placeholder policy

**When content exists only to visually fill a mock, sample, screenshot, skeleton-design demonstration, or unconnected text field, use exactly `Lorem ipsum` or conventional Lorem ipsum sentences. Never invent natural Vietnamese text and present it as sample venue data.**

- `Mock description`: `Lorem ipsum dolor sit amet.`
- `Mock title`: `Lorem ipsum`
- `Mock multiline`: `Lorem ipsum dolor sit amet, consectetur adipiscing elit.`
- Prefer an empty/neutral placeholder over fabricated data where a mock price, location, date, receipt or image would mislead.
- Production fields with genuine business purpose use visible **labels** and authentic values; they are **not** placeholder prose. Do not replace informative labels such as “Email”, “Mật khẩu”, “Tên địa điểm” or required error/help text with Lorem ipsum.
- A genuinely empty production state uses a factual state label (e.g. “Chưa có địa điểm”), **not** Lorem ipsum.
- Image loading uses a neutral skeleton; an image unavailable state uses a neutral icon. Lorem ipsum is only for **mock text**, not a fake source image.

### 5.3 Approved functional text examples

| Situation | Copy |
|---|---|
| Search action | Tìm địa điểm hoặc món ăn |
| Reload map after pan | Tìm trong khu vực này |
| Map location permission trigger | Vị trí của tôi |
| Unknown menu price | Chưa có bảng giá |
| No search results | Không tìm thấy địa điểm |
| No matches in visible map | Không có địa điểm trong khu vực này |
| Need auth to save | Đăng nhập để lưu |
| Failed fetch | Không tải được địa điểm. |
| Real submission received | Đã gửi đóng góp |
| Add evidence | Gửi menu hoặc hóa đơn |

Every piece of visible user-facing copy must be registered or derived from real data. No agent may add nonfunctional text merely because a screen “looks empty”.

### 5.4 Copy acceptance test

For every literal Text/tooltip/semantic label, reviewer asks: (1) What action, state, data or accessibility need does it serve? (2) Is it a real fact or permitted mock Lorem ipsum? (3) Could it be deleted without hurting use? If yes to (3), delete it. Do not globally replace Flutter/Material localization strings, third-party legal attribution or real user-supplied content.

## 6. Motion and interaction

- Ordinary route transitions use platform standards; avoid surprise slide shows.
- Selecting a pin animates focus/preview once, without repeatedly changing camera while the user interacts.
- Explicit “Tìm trong khu vực này” applies current viewport and suppresses the button until viewport changes again.
- Cards do not bounce in ways that obscure content; saving feedback must follow server result.
- Reduced-motion preference removes nonessential transitions.
- Display keyboard focus ring, semantic labels and tap affordance for interactive elements.

## 7. Technical handoff constraints

- Reuse existing Flutter/Riverpod and current price/favorites/contribution models. Add only the state needed for two destinations and a map.
- Candidate: `flutter_map` with licensed tiles and a compatible clustering library; confirm Flutter Web, Android and iOS behavior and licensing before choosing.
- Do not add a backend geospatial service for the existing small data set unless profiling shows the need. Keep the source of truth the real Go API.
- City/keyword/category/price filters are shared; map camera, bounds and selected marker are **map-local**.
- Never synthesize marker coordinates. Non-geocoded published places stay in Explore.
- Keep Admin interface task-dense and editorial; do not force a Pinterest grid into operational review.
- No dependencies or features for social feed, location tracking in background, advertising, realtime chat or recommendation.

## 8. Design review and evidence

Accept screens only with screenshots from the running application (both theme modes, 320/390/768/1280 widths where relevant), interaction replay and an exception list. Compare screenshots to the component specification; do not infer visual quality from widget trees. All navigation, pins, filters, sheets, dialogs, save controls and recovery buttons must be clicked in tests. Native GPS/camera/sharing require separate device checks; headless browser simulations are not equivalent to device acceptance.
