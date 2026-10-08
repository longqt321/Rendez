# MVP runtime audit — 7–8 October 2026

Scope: the six local modules in [the active specification](specs/000-local-completion/spec.md), plus approved external place sharing. The Flutter Web app ran in Chrome against the normal Docker Go API, PostgreSQL and Vietnamese/English Tesseract. This audit used real HTTP, images and persisted records, not the legacy mock dataset.

## Changes

- Guest save opens authentication and resumes saving. Saved and Contribution sign-in entry points return to the requested tab.
- Save feedback follows the API result. Undo restores a specific prior state, respects account ownership and does not stack outdated actions. Concurrent save requests for the same place are guarded.
- A revoked/expired session clears authentication and account-scoped state after a real 401, including private-image fetches. Contribution details provide direct sign-in recovery. Authorization remains in the backend. Access and availability errors use Vietnamese.
- Menu items expose separate observation and Admin review dates from their source contribution. Seed items with no source date show an unavailable date. Review time is not substituted for observation time; display dates use the local timezone. A historical-source integration check protects this distinction.
- Removed promotional headers, unsupported generic verification badges and decorative account counts. Discovery brings search, filters and prices into the first viewport. Missing venue photos use a neutral placeholder rather than invented photography.
- The discovery filter says “Đơn giá”; historical receipt examples label image capture dates explicitly. Read-only menu and bill amounts use the shared VND formatter.
- Structured prices precede source images. Approved menu images remain available under “Ảnh menu nguồn,” with zoom and an accessible, contrasting close control.
- Detail navigation fetches current server data. Completed reviews display the server result, including a competing review outcome, rather than unsaved local edits.
- Contributor details use readable results rather than disabled Admin fields. History distinguishes image type, submission date, status and rejection reason. Source capture date and Admin decision date remain separate in details.
- Admin forms have spacing between inputs. Receipt instructions describe receipt content; unknown guest counts stay unknown in read-only evidence and remain blank in Admin review until explicitly entered.
- Contribution drafts survive transitions between bottom navigation and desktop rail. Upload failures retain inputs/images and give visible feedback. Picker errors do not expose platform exceptions.
- Flutter's bundled Vietnamese localization covers calendar dialogs. Native sharing uses `share_plus`; unavailable sharing falls back to copying place name/address. No receipt image, account information, invented price or inaccessible localhost link is shared. A clipboard confirmation follows the actual write.

Existing Riverpod providers, navigation, API boundary, migrations, upload validation, ownership rules and moderation transactions were retained. No social feature, map, freshness threshold or ranking formula was added. Development volumes were not reset or removed.

## References inspected

- [Airbnb mobile screenshots in the Denovers reference collection](https://www.denovers.com/blog/app-homepages-inspirational-collection): inspected the actual two-phone image. Search and filters precede listings; listing details stay compact; save controls sit on listing imagery. Rendez retains its compact grid and honest image placeholders.
- [Pinterest café reference](https://www.pinterest.com/pin/knokke--591519732308404791/): opened the pin and inspected its full image. Address and opening information are grouped with the place. Rendez preserves that grouping and keeps the map deferred.
- [Google's Places UI Kit article](https://mapsplatform.google.com/resources/blog/introducing-places-ui-kit-a-low-code-way-to-display-googles-places-content-on-your-map-of-choice/): read the official information hierarchy description. This was text research, not a claim of inspecting a running Google Maps flow.

Mobbin's public landing page was opened. No authenticated Mobbin screen library was inspected or claimed as a visual reference. The accessible Airbnb screenshots served as the equivalent mobile reference. Search-first listings were compared with the existing promotional header; structured prices with progressive source-image disclosure were compared with image-first details. The implemented changes follow the observed user tasks and approved price semantics.

“Liệu thiết kế ứng dụng như thế này thì người dùng có muốn sử dụng ứng dụng này hay không?” The practical benefits are earlier price visibility, clear save/submit actions, readable evidence states and recovery without lost inputs. This is a task-based design review, not evidence of user adoption.

## Screen and interaction inventory

| Surface and entry | Principal task | Controls actually activated | States inspected |
| --- | --- | --- | --- |
| Discovery, launch/Explore | Find a place | Search, clear search, city selector, both categories, every price range, reset filters, place cards, save | Live results, no matches, missing photos, long names/addresses, 320/390/430px, desktop, dark |
| Place detail, card/Saved | Read prices and estimate selected costs | Back, refresh, retry, save, item increment/decrement, party increment/decrement, location request, share, contribution entry, source expansion | API failure/recovery, missing coordinates, denied location, browser-simulated location, unknown price dates, observed/reviewed dates, historical receipt example |
| Saved, navigation | Revisit saved places | Guest sign-in, saved card, unsave, Undo, navigation back | Owner-scoped saved state, guest state, save persistence across login, state cleanup on logout/revocation |
| Authentication, Profile/protected action | Sign in/register | Login, register switch, display name/email/password inputs, password visibility, logout, theme choices | Required-input validation, wrong credentials, real registration/login, return to intended action, revoked-session recovery |
| Contribution, tab/detail | Submit evidence | Existing/new-place selection, name/address, city/category, menu/bill type, date, image chooser, camera-source chooser, remove image, submit, history refresh | No-image validation, real file preview/upload, processing, pending/approved/rejected history, offline failure with retained image, successful retry |
| Calendar, contribution date | Select observation/capture date | Open, previous/next month, year selection, calendar day, manual date entry, OK/cancel | Vietnamese dialog, historical date, accepted input |
| Owner contribution detail, history row | Inspect evidence/status | History row, source image, image retry, direct sign-in recovery, back | Private source, approval, rejection reason, unavailable bill total/guest count, capture/decision dates |
| Admin, Profile button | Review queue/manage venues | Refresh, pending/history selector, review rows, create/edit rows, back | Empty queue, pending items, processed history, draft/published/hidden venues |
| Place editor, Admin | Manage publication | Every field, city/category/state dropdowns, save, delete, cancel/confirm dialog | Real create/edit/hide/soft-delete on a disposable marked sample |
| Admin review, queue row | Check source and decide | Source image, OCR expansion, OCR retry, edit name/price/group, add/remove row, draft save, approve, reject, reason | Real OCR, persisted correction, reason-required rejection, approved menu publication, approved bill example, owner-visible rejection |
| Source-image dialog, menu/review | Read original evidence | Open, zoom, close | Light/dark viewing and close contrast |

Camera-source selection in headless web was exercised with an actual file through the picker adapter. It is not proof of a physical camera capture. Location success used a browser-simulated position; denial was separately tested. Native sharing completion was not exercised on a physical device; web fallback was verified by reading the actual clipboard contents.

## Screenshot review

[Selected captured screenshots](qa/mvp-2026-10-07/) are retained with this report. They are actual app output. Review iterations corrected:

1. Promotional headers occupying the discovery/authentication viewport.
2. Source images obscuring structured prices.
3. Touching Admin input borders and contributor views resembling disabled editor forms.
4. Stale save snackbars and inconsistent Undo behavior.
5. Form data lost when responsive navigation changed.
6. Low-contrast close controls over white images in dark mode.
7. History rows lacking evidence type/submission dates and receipt instructions referring to a menu.

Screenshots were checked for wrapping, hierarchy, empty/error feedback, supported values and phone density. Narrow-screen tests also use 1.5x text and long Vietnamese names. The missing-date state is intentional. No unapproved freshness threshold was inferred.

## Verification

- `make demo`: Docker API/OCR/DB running, migrations through version 5 applied forward; seed preserves existing records.
- `make check`: Go normal/dev tests and vet pass; Flutter analyzer clean; 30 Flutter tests pass. Four live tests are skipped in this offline command by design.
- `make integration-ui`: all backend PostgreSQL/OCR integration tests and four Flutter real-HTTP tests pass. Tests cover ownership, private images, approval races (including server-confirmed results after a competing review), rejection validation, invalid uploads, OCR failure, favorites persistence/idempotence and revoked-session cleanup.
- `make build-web`: passes. The missing adaptive icon-font warning was resolved by bundling Flutter's standard Cupertino font.
- Final browser reruns: discovery/search/filter, authentication/save/Saved/Undo, real menu submission/OCR/draft/approval/history; receipt rejection and approval; failure/retry; native-share fallback; session revocation. UI screenshots follow final changes.
- `git diff --check`: clean.
- `graphify update .`: AST graph refreshed without an API call. SQL extraction still reports missing `tree_sitter_sql`; migration verification comes from real PostgreSQL tests, not the graph.

Marked demo contributions and test accounts remain in the development database to support demonstration. A separately created CRUD-test venue was soft-deleted through the app. Images are clearly marked test evidence; sample prices are not represented as independently collected real-world prices.

## Remaining limits

Physical Android/iOS camera, GPS permissions, native share sheets and device builds still need device acceptance. The documented local session remains memory-only. There is no deployed universal/deep link; sharing uses the real place name/address. No product freshness threshold or transparency formula was invented. These checks do not establish user adoption.
