# Rendez — Complete UI/UX Design Specification

**Version:** 1.0 · **Date:** 2026-10-08 · **Target:** Flutter Android / iOS / responsive web · **Language:** Vietnamese (`vi-VN`)  
**Visual reference:** `rendez-visual-reference.png` (concept image, NOT pixel-perfect ground truth).  
**Precedence:** Current repository `docs/specs/000-local-completion/spec.md` is authoritative for functional scope and API; this document specifies presentation and proposes new Explore/Map design where marked **NEW**.

## 0. Scope and non-negotiable boundaries

Current app is Flutter + Riverpod and Go + PostgreSQL. Existing local modules: authentication, public place catalog/menu/search/filter, favorites, distance and item-based cost estimation, photo contributions + history, admin place management, OCR drafts and decisions. Login is mandatory; no guest skip. Tokens stay in memory and the app returns to login when restarted. The current local MVP does **not** offer interactive map, chat or recommendations; map below is **NEW, requires implementation and real map service**, not a claim of existing functionality. Review/rating/social follow, gamification, maps routing and bookings are **out of scope** unless separately specified. Do not display invented ratings, real-time crowd data, verified prices, route travel times or available bookings.

### 0.1 Complete navigable surface inventory

| ID | Screen / overlay | Route/surface | Existing / proposed | Access |
|---|---|---|---|---|
| A01 | Login | `/login` | Existing | Public |
| A02 | Register | `/register` | Existing | Public |
| A03 | Session expired | Full-screen auth redirect + snack | Existing | Public |
| E01 | Explore feed | `/explore` | Existing redesigned | User |
| E02 | Search | `/search` | Existing redesigned | User |
| E03 | Filter | Modal bottom sheet / desktop dialog | Existing redesigned | User |
| E04 | Search no results | Inline full-height state | Existing | User |
| M01 | Interactive map | `/map` | **NEW** | User |
| M02 | Map selected-place preview | Bottom sheet / desktop side pane | **NEW** | User |
| M03 | Location permission/help | Contextual sheet | Proposed | User |
| P01 | Place detail | `/places/:id` | Existing redesigned | User |
| P02 | Full menu | `/places/:id/menu` | Existing redesigned | User |
| P03 | Image viewer | Full-screen dialog | Existing redesigned | User |
| P04 | Cost estimate | `/places/:id/estimate` or detail sheet | Existing redesigned | User |
| F01 | Saved places | `/saved` | Existing redesigned | User |
| C01 | Contribution hub | `/contribute` | Existing redesigned | User |
| C02 | Choose place / propose new | `/contribute/place` | Existing | User |
| C03 | Upload / contribution form | `/contribute/new` | Existing redesigned | User |
| C04 | Review & submit | `/contribute/review` | Proposed presentation | User |
| C05 | Submission result | `/contribute/result` | Proposed presentation | User |
| C06 | My contribution history | `/contributions/mine` | Existing | User |
| C07 | Contribution detail / rejection reason | `/contributions/:id` | Existing | Owner / admin |
| U01 | Profile | `/profile` | Existing redesigned | User |
| U02 | Settings / sign out | `/settings` | Proposed presentation | User |
| D01 | Admin dashboard / queues | `/admin` | Existing redesigned | Admin |
| D02 | Admin place list | `/admin/places` | Existing | Admin |
| D03 | Admin place editor (create/edit) | `/admin/places/new` or `/:id/edit` | Existing | Admin |
| D04 | Admin review queue | `/admin/contributions` | Existing | Admin |
| D05 | Admin review & OCR editor | `/admin/contributions/:id` | Existing redesigned | Admin |
| D06 | Reject reason dialog | Dialog on D05 | Existing | Admin |
| X01 | Global loading / network error | Shared component states | Existing | All |
| X02 | Deletion/unsaved changes confirmation | Modal dialog | Required | Relevant |
| X03 | Access denied / not found | Full-page state | Required | Relevant |

**Not included:** Password-reset email flow, third-party login, separate admin website, map turn-by-turn directions, messaging, reviews/ratings, ordering, payment, notification feed, collections, social posts. These cannot be inferred from the visual reference.

## 1. Design language and exact tokens

### 1.1 Layout units and breakpoints

Flutter logical pixels (`dp` equivalence; on Flutter web CSS pixel coordinate conventions may differ with device scale). **Do not treat screenshots' image pixels as layout units.** Safe areas always respected.

| Token | Exact value |
|---|---|
| `space.0/1/2/3/4/5/6/8/10/12` | `0/4/8/12/16/20/24/32/40/48 dp` |
| `radius.xs/sm/md/lg/xl/round` | `6/10/14/20/28/999 dp` |
| `stroke.default` | `1 dp` |
| `screen.mobile.gutter` | `16 dp` |
| `screen.tablet.gutter` | `24 dp` |
| `screen.desktop.gutter` | `32 dp` |
| `width.mobile` | `<600 dp` |
| `width.tablet` | `600–1023 dp` |
| `width.desktop` | `>=1024 dp` |
| `width.content.max` | `1280 dp` centered |
| `width.reading.max` | `760 dp` |
| `width.admin.form.max` | `860 dp` |
| `size.touch.min` | `48×48 dp` app policy |
| `size.icon.standard` | `24×24 dp` |
| `size.icon.small` | `20×20 dp` |
| `size.input` | `52 dp` height |
| `size.button.primary` | `52 dp` height |
| `size.chip` | `36 dp` height |
| `size.nav.bottom` | `68 dp` excluding system safe-area |
| `size.nav.desktop.sidebar` | `224 dp` width |
| `size.appbar` | `56 dp` |

Mobile preview design target `390×844 dp`; additionally test `320×640`, `360×800`, `412×915`. Tablet `768×1024`. Desktop `1440×900` and `1024×768`. At 320 dp, grids and forms should wrap or scroll without horizontal clipping.

### 1.2 Colors

| Token | Light | Dark | Usage |
|---|---|---|---|
| `bg.canvas` | `#FAF9F6` | `#141917` | Screen |
| `bg.surface` | `#FFFFFF` | `#1D2420` | Cards/sheets |
| `bg.subtle` | `#F1F3F0` | `#2B332E` | Chips, subtle areas |
| `fg.primary` | `#202521` | `#F6F7F4` | Main copy |
| `fg.secondary` | `#647168` | `#AFBAB2` | Metadata |
| `border.default` | `#E2E8E2` | `#3C4840` | Dividers |
| `brand.primary` | `#205B48` | `#78C7A4` | CTA, active nav |
| `brand.onPrimary` | `#FFFFFF` | `#11241B` | Text on CTA |
| `accent.coral` | `#E46B45` | `#F18C69` | Contribution highlight only |
| `semantic.error` | `#BC3D3D` | `#FF8E8E` | Validation |
| `semantic.warning` | `#9A660F` | `#F2C46C` | Pending |
| `semantic.success` | `#24764D` | `#89D7A4` | Approved |

Theme tokens must be checked against WCAG 2.2 AA; do not assume every pair qualifies. Prefer semantic colors and sufficient text contrast over decorative brand treatment. Photos retain true color in either theme.

### 1.3 Type

Use `Inter` for Latin and Vietnamese glyph support, fallback `Roboto`/system. Font scaling must be enabled. Do not truncate critical labels, prices or error explanations merely for visual balance.

| Style | Size / line-height / weight |
|---|---|
| `display` | 30 / 38 / 700 |
| `headline` | 24 / 32 / 700 |
| `title` | 20 / 28 / 650 |
| `section` | 17 / 24 / 650 |
| `body` | 14 / 21 / 400 |
| `bodyStrong` | 14 / 21 / 600 |
| `metadata` | 12 / 18 / 400 |
| `label` | 13 / 18 / 600 |
| `button` | 14 / 20 / 650 |

### 1.4 Interaction rules

- Motion: microstate `120–180ms`, sheet/dialog `220–280ms`; honor reduced-motion accessibility setting. Do not animate/map-fly on every small tap.
- Focus: 2 dp visible focus ring; mobile taps at least 48 dp; keyboard focus order follows visual order.
- Standard scroll: content under collapsible controls only where specified; preserve scroll offset when navigating back.
- One primary action per viewport region; destructive actions never share visual primary treatment.
- Labels: Vietnamese, direct and factual. No filler marketing text. Skeleton placeholder is a visual shape, not dummy sentences. If sample filler prose is required in mockups, use `Lorem ipsum` and never expose it in live UI.
- Currency: `35.000 đ`, dates: `08/10/2026`, distance `1,2 km` (explicitly **đường chim bay / ước tính**), local time `HH:mm`. Do not present estimated distance as navigation distance.
- Images: cached cover 4:5 on feed; landscape 16:9 in details; crop `cover`, meaningful image fallback neutral illustration; do not use fake thumbnails in production.
- UI must never infer menu prices from bill photos. A missing number is `Chưa có giá`, not `0 đ`.

## 2. Adaptive shell and navigation

### Mobile (less than 600 dp)

- App surface fills width; system status bar controlled by OS. Bottom navigation fixed 68 dp + safe area, five items: **Khám phá**, **Bản đồ** (NEW), **Đóng góp**, **Đã lưu**, **Cá nhân**. Each nav action has 24 dp icon, 11–12 dp label, active brand color; contribution is emphasized with coral filled 44 dp circle but remains accessible and not floating above forms.
- Auth screens hide bottom navigation. Detail pages show 56 dp top bar and no main nav while pushed; back returns to prior tab plus scroll/query/filters/map state. Keep navigation tab state in shared Riverpod state.
- Input-focused pages adjust for keyboard; CTA not hidden under keyboard or safe area.

### Tablet 600–1023 dp

- Navigation rail `80 dp`, content remainder. Explore 3 columns; forms max 600 dp; admin edit and OCR stacked if remaining width < 680 dp.

### Desktop 1024+ dp

- Side navigation 224 dp. Explore 4 columns inside max 1280 dp content. Search/filter sticky at top. **Map**: map + 360 dp results panel (panel width fixed; map fills rest). Admin review: original image pane 45%, editable OCR pane 55%, total max width 1440 dp. Profile/settings forms max 760 dp. All nav items have hover/keyboard states and semantic tooltips.

## 3. Shared components (source of truth)

| ID | Component | Geometry and content | States and behavior |
|---|---|---|---|
| CMP01 | Primary button | Full-width mobile, 52h, radius14, 16 px horizontal inset; icon20 optional | idle, hover, focus, pressed, loading spinner20, disabled |
| CMP02 | Secondary button | Same geometry, surface + 1dp border | idle/hover/focus/disabled |
| CMP03 | Text field | 52h min, label above 12sp, radius12, left/right padding14 | empty, filled, focused, invalid (error text 12sp), disabled |
| CMP04 | Search field | 48h, search icon20, clear icon20, radius24 | typing, clear, submitting, no result |
| CMP05 | Filter chip | h36, horizontal padding12, radius18, text13 | off/on/loading/disabled; count badge if multiple filters |
| CMP06 | Place tile | Mobile masonry `calc((width - 40dp)/2)`, image 4:5, radius14; title 14/20 strong; 2 metadata rows 12/18 | loading image, image missing, favorite async, press detail |
| CMP07 | Place horizontal row | thumb 96×96, text flexible, row min112, divider1 | map results / saved / search list |
| CMP08 | Map marker | point icon ~38×44; highlighted 44×50, accessible label | default/selected/clustering; no fabricated count |
| CMP09 | Bottom sheet | radius top24, drag handle36×4 with top12; peek 168dp, expanded ~80% height | drag, swipe dismiss, keyboard-safe |
| CMP10 | Section heading | 17/24 semibold; content gap12 | optional factual action text |
| CMP11 | Price row | name flexible + price right, min48h; qty control ± and count where allowed | unavailable-price disables estimation |
| CMP12 | Status tag | min28h, padding10, radius999 | pending/approved/rejected with text + color |
| CMP13 | Image upload tile | 104×104 mobile, radius12, add icon24 | empty, selected, uploading, invalid, retry/remove |
| CMP14 | Snackbar | min-height48, bottom above nav, text14, optional Undo/Retry | info, success, error; assertive errors announced |
| CMP15 | Empty state | icon48, heading17, 1–2-line message14, action52 | no content / no results / unavailable |
| CMP16 | Dialog | mobile width viewport−32 (max440), desktop max480, padding24 | confirmation, blocking failure, destructive |
| CMP17 | Menu image | 16:9 thumbnail + zoom action; fullscreen uses contain | approved only, loading, image unavailable |
| CMP18 | Numeric stepper | controls 44×44 visually, 48dp tap targets, center 32 | 0–99 items, 1–100 guests |

## 4. Per-screen production specifications

### A01 — Login

- Canvas neutral. Desktop center max-width 420 dp white panel; mobile 16dp padding with vertically centered form, top safe area + 56dp. Branding `Rendez` 30/38 at top; subtitle optional only if factual, otherwise omit.
- Form: email field 52h, gap16, password field 52h with reveal toggle 48 tap; fields labelled. Primary `Đăng nhập` full-width 52h, margin24 top. Secondary `Tạo tài khoản` text action gap16; no guest skip and no social login.
- Validation: required, email format, wrong credentials -> generic inline error; loading disables double submit; successful login replaces stack with E01; session token memory-only.

### A02 — Register

- Same auth shell as A01. Fields order: display name, email, password, confirm password only if API/frontend validates locally; no invented profile demographic fields. Form gap16, help/error under field. Primary `Tạo tài khoản`; secondary `Đã có tài khoản? Đăng nhập`.
- Errors: email exists, weak/invalid password per backend, network, mismatched confirmation. On success follow existing auth flow (if backend returns session, enter Explore; otherwise present login with registration success message). Do not invent auto-login capability.

### A03 — Expired session

- Immediately clear protected navigation stack; redirect A01. Show `Phiên đăng nhập đã kết thúc. Vui lòng đăng nhập lại.` as snack/banner on A01. Do not reveal prior private contribution/favorite contents.

### E01 — Explore

- Top region: `Rendez` wordmark left (24/32), optional location label only with valid, granted location (never fabricated); search row height48, top/bottom gaps12; horizontal category chip row height36, spacing8, horizontal scroll.
- Feed uses actual public places (published, not deleted) and confirmed image references. Mobile two masonry columns with 8dp column gap and 12dp row spacing; card widths `floor((viewport−40)/2)`. Card image aspect 4:5; metadata bottom padding8; show name max2 lines, type and approximate price indicator only if sourced, `Chưa có giá` otherwise. Do not show user reviews/stars (unsupported).
- Top toolbar can filter, optionally sort as backend supports. On scroll, collapse brand area but keep compact search; restore when scrolling upward. `favorite` tap sends idempotent API, only then reflects change; failure reverts state with retry snack.
- Mobile bottom nav, desktop sidebar. Empty dataset -> CMP15 with `Chưa có địa điểm`; API error -> retry; no dummy place cards.

### E02 — Search

- Search field autofocus when opened; left back 48dp; clear 48dp. Below field show actual results as list (not fake suggestions), searchable by name/address/type/dish/vibe as supported, filter chip opens E03. Search is debounced around 250ms on client for local list; pressing enter triggers immediate search.
- Search results list rows CMP07 full width mobile, 2 columns on desktop as needed. Highlight query matches only if literal match; empty query restores all; no-results E04. Returning preserves typed query.

### E03 — Filter overlay

- Mobile bottom sheet min-height content, max 90% safe screen; desktop centered dialog width 520dp. Header `Bộ lọc`, clear (`Xóa bộ lọc`) action only if active, close 48tap. Sections: City (from `/v1/lookups`), type (from lookup), price minimum/maximum numeric inputs (currency), each gap20. No fake distance slider unless coordinates and functionality exist; distance filter requires explicit separate scope.
- Sticky footer: secondary `Đặt lại` and primary `Xem kết quả`, 52h each on desktop; on mobile two in row if >=360dp else stacked. Applying updates Explore/Search and Map shared filter state atomically; closing without apply leaves previous state.

### E04 — No search results

- CMP15 centered within available height; heading `Không tìm thấy địa điểm`; supporting `Thử thay đổi từ khóa hoặc bộ lọc.`; primary/secondary `Xóa bộ lọc` only when active. Do not claim no businesses exist in the real world.

### M01 — Map **NEW**

- Full-bleed interactive map under overlay search. Mobile search overlay top safe area + 12, x16, h48; optional filter chip carousel underneath; center map displays actual published places with valid coordinates only. Bottom navigation overlays map lower edge with safe inset. Location recenter FAB 48×48 above bottom sheet + 16, not over markers. No default fake center named user location. If location unavailable, choose map region from existing public place bounds or user-selected city; no permission-on-launch requirement.
- Tap marker -> select place, visually emphasize marker, open M02. Tap map background -> collapse peek. Pan/zoom -> update visible-place listing and optionally show `Tìm trong khu vực này` explicit action to avoid repeated network calls. Clustering thresholds map-SDK-specific; accessibility place labels provided. Offline/map tile error -> visible error with retry / fallback Explore.
- Map provider, credentials, rate limits and tile usage must be selected and documented separately. Do not implement screenshots as maps or estimate travel-time; this is an enhancement over current MVP.

### M02 — Map place preview **NEW**

- Mobile bottom sheet at 168dp peek height (above nav), expanded max80% available; header image 88×88, name title17, address/type metadata12, sourced price or missing state. Action row `Xem chi tiết` and `Đã lưu/Lưu`; `Chỉ đường` may use installed external navigation deep link if explicitly implemented, not in-app routing.
- Desktop right-side result pane width360dp; selecting marker scrolls corresponding place into view. Reopening same marker does not duplicate sheet stack.

### M03 — Location permission / guidance

- Trigger only from `Vị trí của tôi` or distance action. In-app contextual explanation; OS permission prompt only after action. Denied: `Không thể truy cập vị trí` + `Chọn thành phố` / `Thử lại`; permanently denied: link to OS app settings. Missing coords: `Chưa có tọa độ cho địa điểm này`, omit estimated distance entirely.

### P01 — Place detail

- 56h top appbar with back, bookmark action 48 tap. Cover photo 16:9 width full; carousel only images approved for public use. Below cover: name 24/32 bold, category 12/18 and address 14/21, optional admin-confirmed indicator with explicit meaning (not generic verified badge). Vertical spacing 20–24.
- Overview: opening-hours if known, `Chưa có thông tin giờ mở cửa` otherwise; cost metadata explicitly marked sample/reference. Tabs/sections in order `Tổng quan`, `Menu`, `Ảnh`, `Chi phí` (tabs can anchor-scroll and retain section state). `Menu` opens P02, photos P03, estimate P04. Approved example bills may show date, total and party count but NEVER original image. Never show ratings/reviews unless model/API later supports them.
- Sticky action footer on mobile with `Tính chi phí` if eligible, and secondary `Lưu`; safe area respected. Desktop hero constrained max1280, two-column body 2:1.

### P02 — Menu

- 56h header, place title secondary. Scroll categories if backend provides them; otherwise flat list. Menu row h min56, item name flexible, price right-aligned, optional evidence update date; photo image section explicitly dated. No arbitrary prices derived from OCR that is still pending.
- Missing prices show `Chưa có giá` and disabled add-to-estimate; if no menu data -> CMP15 and `Đóng góp menu` CTA to C03. Thumbnail on tap opens P03.

### P03 — Full-screen image viewer

- Background near-black, safe-area Close 48; image aspect `contain`, pinch zoom native, page swiping for gallery, counter `2/5` only when multiple. Approval/public permission governs fetch; on 404 show error and return affordance. No raw private receipts here.

### P04 — Cost estimate

- Show exact explicit selection, not generic average. Item list rows name, known unit price, quantity stepper 0–99. Bottom summary fixed above keyboard: `Tổng`, `Số người` stepper 1–100, `Mỗi người`; display `Chọn món để tính chi phí` until at least one positive quantity. `0 đ` only if actual selected item(s) have zero sourced unit price.
- Recalculate locally on each change; use integer VND, never floating summations; do not include transport/service fees. Example approved bills are marked `Ví dụ được đóng góp` and kept separate from this calculation.

### F01 — Saved

- Title `Đã lưu` 24/32; no invented collections. List CMP07 with image 96×96, place name, type/address, price if any, heart/bookmark on right. Pull-to-refresh; fetching owner-scoped DB, refresh on account switch, no optimistic favorite success.
- Empty state `Bạn chưa lưu địa điểm nào`, CTA `Khám phá địa điểm`. Hidden/deleted places excluded per API policy. Search saved only if local count warrants it; otherwise no extra control.

### C01 — Contribution hub

- Title `Đóng góp`, short factual instruction. Two 56h selection rows/card CTAs `Ảnh menu` and `Hóa đơn`, each with icon and one-line explanation. `Đóng góp của tôi` history entry to C06. A 3-step indicator is acceptable only after contribution type is chosen.

### C02 — Choose place / new place

- Search existing place using API, row h64–80; selecting sets place id. Secondary `Đề xuất địa điểm mới` reveals mandatory name, address, city, type fields; does not publish it. Admin may see draft/hidden places if role. No coordinate input shown to ordinary users.

### C03 — Upload & details

- Appbar56 with back, title `Thêm hình ảnh`. Upload tile CMP13 104×104, actual images thumbnails; min1 max5 JPG/PNG, each under10MiB, pixels 100×100 min and <=20M. Capture date input (required) with date-picker; no future date. Place summary editable via C02; select type `Ảnh menu` vs `Hóa đơn`.
- Show selected file count `3/5` and per-file remove action (48 tap). Reject invalid format/size immediately with exact error. Primary CTA `Tiếp tục` enabled only for valid form. OCR happens after submission on backend, never claim draft OCR values as verified prices.

### C04 — Submission review

- Preview chosen place, date, contribution type, image gallery. A short factual privacy note: `Ảnh chỉ được công khai theo chính sách duyệt; hóa đơn gốc không công khai.` Action primary `Gửi đóng góp`, secondary `Chỉnh sửa`. On submit disable button and display progress indicator; can exceed routine HTTP latency, do not promise exact OCR finish time. Server failure leaves user data in form and exposes retry. No fake success on timeout.

### C05 — Result

- On successful API `201`, show status `Đã gửi — Chờ duyệt`, confirmation graphic48, CTA `Xem đóng góp` / `Về Khám phá`. OCR error can still lead to pending admin, present factual `Ảnh đã được gửi. Cần kiểm tra thủ công.` only where indicated by response.

### C06 — Contribution history

- Header `Đóng góp của tôi`, vertically stacked contribution cards h auto min100; thumbnail64 if authorized, place, type, date, status CMP12. Status labels exactly `Chờ duyệt`, `Đã duyệt`, `Bị từ chối`. Sort newest first. Empty state `Bạn chưa gửi đóng góp nào` + CTA.

### C07 — Contribution detail

- Only owner/Admin sees originals. Header, place, upload/capture dates, status. Private images in scroll/gallery; for rejected show plain reason panel, no invalid editing flow after final decision. For `pending_admin` show processing states and `Đang chờ kiểm duyệt` rather than fake ETA. Unauthorized 404.

### U01 — Profile

- Header `Cá nhân`; show display name and email retrieved from session, no invented follower statistics/avatar upload. Entry rows 52–60h: `Đã lưu`, `Đóng góp của tôi`, `Cài đặt`; `Quản trị` visible only for Admin. Logout action located in Settings, not duplicate CTA everywhere.

### U02 — Settings

- Title `Cài đặt`. Theme choice `Theo hệ thống / Sáng / Tối` only if implemented; otherwise avoid inert UI. `Đăng xuất` button opens confirmation dialog, API revokes session and clears stack. Version info from app build metadata optional. No placeholder Privacy/Support buttons without actual destinations.

### D01 — Admin dashboard

- Entered through profile Admin entry, retains same Flutter app. Header `Quản trị`, two primary destination cards `Địa điểm`, `Đóng góp chờ duyệt`; queue count only if server data loaded. No speculative graphs/analytics. Desktop left admin sidebar; mobile admin local nav/back to profile.

### D02 — Admin place list

- Search bar48; rows min72 show name, city, category, visibility status `Công khai / Bản nháp / Đã ẩn`, edit pencil 48tap and overflow actions. Toolbar primary `Thêm địa điểm`; desktop table may display columns name/city/type/status/actions. Confirm hide/delete; preserve soft-delete contract and blocked delete if pending contributions.

### D03 — Admin place editor

- Desktop form max860dp in 2 columns where space allows, mobile one column. Inputs: name, address, city, type, description, opening hours, latitude/longitude **admin-only**, confirmation status, publication/visibility. Mandatory fields aligned with backend validation, numeric coordinate bounds validated. CTA `Lưu`, secondary `Hủy`. Dirty-state confirmation before leaving. Do not invent photo moderation inside place editor.

### D04 — Admin contributions queue

- Header + segmented status `Chờ duyệt / Đã duyệt / Bị từ chối`; default `Chờ duyệt`. Each row: submission type, place, capture date, submit date, contributor, status, tap for D05. Queue empty state. Filter statuses backed by real API; no unimplemented SLA countdown.

### D05 — Admin review and OCR

- Highest priority complex view. Wide >=1024: image gallery left 45%, OCR draft form right 55%, both independently scroll; top summary place/type/date/submitter/status. Mobile: selected image 16:9 above tabs `Ảnh / Dữ liệu OCR`, editing data scrolls under fixed actions.
- Menu-photo mode: raw OCR output in collapsible read-only panel; editable repeating rows `Tên món` and `Giá` (numeric integer VND), optional group, add/remove controls. Bill mode: `Tổng tiền` and `Số khách` (integers >=0 and >=1 respectively), no invented menu lines. `Chạy lại OCR` explicit action, `Lưu bản nháp` secondary, `Duyệt` primary, `Từ chối` destructive. Fixed footer buttons height52; on small width stack appropriately. OCR technical failure must retain manual editing and previous saved draft. Server 409 => show `Đóng góp này đã được xử lý. Tải lại dữ liệu.` without replay decision.
- Review actions require server success before replacing status; approval publicizes only permitted fields. Raw bill image never appears on public place detail.

### D06 — Rejection dialog

- Dialog max440, heading `Từ chối đóng góp`, required reason multi-line min120h max400 chars (adjust to backend limit), secondary `Hủy`, destructive `Xác nhận từ chối`. Empty reason disables submit; pending shows spinner; 409 handling same as D05.

### X01 — Loading and network states

- Loaders: list uses 6–8 neutral skeleton tile shapes; menu skeleton 3 rows, header skeleton. Critical action shows spinner inside disabled CTA; avoid endless full-screen spinners.
- Failed fetch retains stale data only if clearly marked and appropriate; error `Không tải được dữ liệu` with `Thử lại`; no silent mock fallback. For write failures, preserve input and do not assume commit status. Timeouts with uncertain result require refreshed server state before resubmit where duplicate action unsafe.

### X02 — Destructive / unsaved dialog

- Max440 width, 24dp padding; clear subject and consequence. Buttons `Hủy` and exact destructive verb e.g. `Xóa địa điểm`. Dirty editor exit `Bạn có thay đổi chưa lưu` => `Tiếp tục chỉnh sửa` / `Rời trang`; do not accidentally mutate.

### X03 — Access denied / not found

- Unauthorized owner resource returns not-found UI, no private details; Admin access denied returns profile with `Bạn không có quyền truy cập`. Missing place -> `Không tìm thấy địa điểm` plus `Về Khám phá`.

## 5. Required app states matrix

Each screen must be tested in these applicable states: **initial/loading**, **content**, **empty**, **API error**, **offline**, **permission denied**, **invalid input**, **write pending**, **write success**, **write conflict 409**, **keyboard open**, **large text 200%**, **dark mode**, **320dp small viewport**, **desktop**. Do not invent a new full screen for a component-local state; use consistent inline/banner/dialog variant.

## 6. Proposed shared state and API boundary

```text
DiscoveryState {
  query: String
  cityId: String?
  categoryId: String?
  minPriceVnd: int?
  maxPriceVnd: int?
  selectedPlaceId: String?
  activeMode: explore | map
  mapViewport: MapViewport?
}
```

- `mapViewport` exists only if M01 implemented. Preserve query and filters across mode transitions; never silently copy selected marker into a search text query.
- Current API endpoints use `/v1` direct JSON and error `{error:{code,message,retryable}}`; frontend should respect returned field names rather than invent them from UI tokens.
- Source metadata `price_updated_at`, approved images, `place.status` must be rendered only when returned and authorized.
- Contribution images private to uploader/Admin; approved menu photos public; approved bill aggregate fields public. Frontend must not cache bill image in public route widgets.

## 7. Layout templates / page anatomy

### Mobile Explore — 390×844 dp (safe areas not counted as fixed chrome)

```text
[ OS SAFE STATUS ]
[ 16 ] Rendez                       [optional location]
[ 16 ][ Search input h48                       ][16]
[ 16 ][ Chip h36 ][ Chip ][ Chip →           ]
[ 16 ][ Image 4:5 ][ Image 4:5 ][16]
       [ Name 2 lines max ] [ Name ... ]
       [ Category · Price ] [ Category ... ]
       [ Image ...  ][ Image ... ]
[ BOTTOM NAV: 68dp + safe area ]
```

### Mobile Map — 390×844 dp

```text
[ OS SAFE STATUS ]
[ Search box floating top16 h48 ]
[ Filter chips floating top72 ]
[                    MAP                     ]
[ Places markers from valid coordinates      ]
[ Location FAB ]
[ Selected place preview peek168 / expanded80% ]
[ BOTTOM NAV: 68dp + safe area ]
```

### Mobile Place detail

```text
[ toolbar h56: back | title context | save ]
[ landscape gallery width×9/16 ]
[ title / type / address / optional confirmation ]
[ opening information / update date ]
[ sections: overview, menu, approved images, cost ]
[ sticky CTA / bottom safe area ]
```

### Desktop 1440×900

```text
[ fixed nav 224 ] [ content up to 1216 ]
                  [ toolbar 72 ]
Explore:          [ responsive four-column feed ]
Map:              [ results sidebar 360 ][ map remainder ]
Admin review:     [ images 45% ][ OCR editor 55% ]
```

## 8. External visual references and permitted reuse

- Pinterest: image-driven masonry discovery: https://www.pinterest.com/
- Google Maps: markers, selected location and spatial navigation: https://www.google.com/maps
- Airbnb: listing/details decision flow: https://www.airbnb.com/
- Mobbin: real shipped screen research (may require account): https://mobbin.com/
- Material Design 3: https://m3.material.io/
- Apple HIG: https://developer.apple.com/design/human-interface-guidelines/
- WCAG 2.2: https://www.w3.org/TR/WCAG22/

The included `rendez-visual-reference.png` is **AI-generated moodboard** showing six representative scenes, not a ground-truth UI capture, not a Figma component source, and not an inventory of every screen. If it depicts stars, reviews, a reputation score, or social panels inconsistent with this spec, **ignore those decorations**. The written behavior/information contract overrides the image. Use original licensed/owned images in actual application.

## 9. Frontend implementation acceptance criteria

1. All A/E/P/F/C/U/D/X screens or surfaces in §0.1 have explicit routes / launch actions and back paths; M screens gated behind approved NEW feature scope.
2. No dead button, placeholder navigation, lorem ipsum in live product, generated fake prices, fabricated reviews or polished loading that masks errors.
3. UI supports 320×640 mobile without overflow and readable 200% text; keyboard does not cover submit or error.
4. Search/filter and selected place persist across Explore ↔ Map and back where Map is implemented.
5. Public gallery never shows raw invoice images; pending contributions remain private.
6. Favorites reflect server success only, persist across re-login, and clear on account switch.
7. Costs only from selected menu item prices × quantities; if no selected items, summary says no items selected.
8. Admin OCR editor supports missing OCR result, saving manual draft, approved/rejected terminal states and 409 conflict.
9. Screenshot visual review performed at mobile narrow/typical/tablet/desktop, light/dark and high text scale. Every visible action actually clicked / keyboard-activated during test.
10. Compare screenshots against this spec (content order, geometry, spacing, visible states); images are supplementary moodboard, not authority for unsupported features.

## 10. Open technical decisions requiring implementation (not design guesses)

- Map provider, geographic coverage and keys; whether map is within project assessment scope; location-permission behavior validated on physical devices.
- Precise API shape for place imagery, menu grouping and admin editor fields—derive from existing Go backend models at implementation time.
- Whether registration returns active session or requires login.
- Which theme switch settings are actually persisted or should remain system-only.
- Numeric validators' maximum input constraints from backend; never impose arbitrary limits incompatible with server contract.

**Ship rule:** The local six-module MVP should not be held hostage by map implementation. Use the current six modules for technical completion; add map after real SDK integration, permission tests and data-coordinate validation.
