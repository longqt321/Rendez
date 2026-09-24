# Rendez Product and Engineering Reconciliation

## Scope and review basis

This document reconciles the approved v1 SRS in `docs/SRS_PBL6.pdf` with the existing Flutter prototype under `mobile/`. It evaluates the product behavior rather than treating either artifact as automatically correct. Business rules, security constraints, data integrity, and required MVP capabilities take precedence over the SRS's suggested screen organization.

The review covered all 44 SRS pages, including diagrams, and all 31 application Dart files, the Flutter test file, dependencies, navigation, and relevant platform configuration. Generated widget-preview scaffolding was identified separately from product functionality. The existing `backend/` directory was outside this frontend reconciliation; statements about missing integration refer to the Flutter application.

This is a source-based assessment, not a runtime acceptance report. No build or test was run during the review, and no source files were changed as part of the analysis.

The classifications used below are:

- **SATISFIED:** the inspected frontend responsibility is present.
- **PARTIALLY SATISFIED:** meaningful UI or local behavior exists, but the requirement is incomplete.
- **MISSING:** the required frontend capability or integration is absent.
- **IMPLEMENTED DIFFERENTLY:** the prototype expresses a materially different behavior.
- **SRS SHOULD BE RECONSIDERED:** the specification needs clarification or revision before its acceptance criteria are reliable.

For backend-only obligations, **MISSING** means missing frontend integration or verification evidence, not a conclusion that the Go backend violates the requirement.

## 1. Executive summary

The prototype's visual direction and compact navigation should be preserved. Its data semantics, trust model, and scope must be reconciled before it can represent the MVP.

The strongest coherent product direction is:

> Discover places, understand their documented prices, estimate a visit, save useful places, and contribute evidence that Admin reviews before publication.

The current prototype supports that direction visually, particularly through discovery cards, integrated filters, receipt breakdowns, and contribution history. It also suggests a broader social application—with chat, invitations, presence, and RSVP—which would substantially increase the workload for two developers.

The largest gaps are not screen organization. They are:

- Real authentication and account ownership.
- Durable, API-backed data.
- Clear meanings for menu prices, receipt totals, and per-person estimates.
- Actual image submission and OCR.
- Automatic checks followed by Admin review.
- Separate publication, moderation, and freshness states.
- Honest loading, failure, missing-data, and unavailable-place behavior.

There is also an immediate engineering issue: a read-only path check found **23 unresolved relative imports across six frontend files**. For example, [`ExploreScreen` imports](../mobile/lib/features/explore/explore_screen.dart) resolve to `mobile/core/`, while the files are under `mobile/lib/core/`. The affected files also include:

- `mobile/lib/features/auth/auth_profile_screen.dart`
- `mobile/lib/features/bookmarks/bookmarks_screen.dart`
- `mobile/lib/features/contribute/contribute_screen.dart`
- `mobile/lib/features/place_detail/place_detail_screen.dart`
- `mobile/lib/features/place_detail/widgets/plan_invite_sheet.dart`

The overall recommendation is to keep the compact discovery and place-detail experience, then add real authentication, evidence-backed prices, and the missing Admin workflow. Inexpensive filter shortcuts can remain; chat and maps introduce substantial new scope and should not displace mandatory MVP work.

## 2. Current frontend architecture

The application is a presentation-focused Flutter prototype with Riverpod state and embedded fixtures.

| Area | Actual implementation | Assessment |
|---|---|---|
| Application entry | `mobile/lib/main.dart`: `main()`, `RendezApp`, `ProviderScope`, Material 3, light/dark themes | A reasonable starting structure. Web rendering is constrained to a 450-pixel mobile-style viewport. |
| Primary navigation | `mobile/lib/features/navigation/main_scaffold.dart`: `MainScaffold` | Three tabs—Map, Explore, Profile—but only two retained screens. Map and Explore switch modes within `ExploreScreen`. |
| Secondary navigation | `Navigator.push`, `MaterialPageRoute`, modal sheets and dialogs | Simple and appropriate in principle for this MVP. There is no central route authorization or authenticated-action continuation. |
| Application state | `mobile/lib/core/providers/app_providers.dart`: `StateProvider`, `StateNotifierProvider`, derived `Provider` | Synchronous, application-wide, in-memory state. No request lifecycle or persistence. |
| Discovery | `filteredPlacesProvider` filters `MockData.places` | Local substring search and predicates; no search service, pagination, or transparency ranking. |
| Authentication | `AuthNotifier`, `AuthState` | Starts logged in as the mock user. `login()` ignores credentials. `logout()` only changes auth state. |
| Favorites | `BookmarksNotifier` | A seeded `Set<String>` shared across the application; no account scoping or persistence. |
| Contributions | `ContributionsNotifier` | Prepends local `UserContribution` summaries. No upload, extraction, moderation, or publication operation. |
| Places and prices | `mobile/lib/core/models/place.dart`: `Place`, `MenuItem`; `mobile/lib/core/models/bill_item.dart`: `RealBill`, `BillItem` | Display-oriented models. They cannot adequately represent the SRS publication and evidence lifecycle. |
| Personal data | `mobile/lib/core/models/user.dart`: `UserProfile`, `UserContribution` | No role on the user; no contributor ownership, source image, place ID, or extracted items on a contribution. |
| Social features | `mobile/lib/core/providers/chat_providers.dart`, `mobile/lib/core/models/chat_models.dart` | Local messages, fixed friends/conversations, invitations and RSVP state. No real communication. |
| Services/repositories | None in application source | No business API client, repository layer, JSON mapping, session storage, upload service, OCR integration, or location integration. |
| Design | `AppColors`, `AppTheme`, `MasonryPlaceCard` | Shared palette, typography, and themes. Many screens still hard-code light backgrounds and text colors. |
| Tests | `mobile/test/widget_test.dart` | Covers formatting, mock providers, selected widgets, chat, and themes. It does not establish SRS compliance. |

The direct dependencies are appropriately small: Flutter, Riverpod, staggered grid layout, Google Fonts, `intl`, and cached network images. `http` and `sqflite` appear transitively in the lockfile; that does not mean the app has an API layer or persists business data.

The prototype currently assumes:

- All place data can be loaded synchronously.
- Prices, coordinates, and distances always exist.
- One global identity owns all personal state.
- A single `isVerified` boolean can explain trust.
- A contribution can be represented by a name, address, date, total, and status.
- A place object passed into a route remains usable without revalidation.

Those assumptions require more attention than replacing Riverpod or introducing a large architectural framework.

## 3. Current user journeys

These describe the behavior encoded in the source, subject to the build blockers above.

| Journey | Implemented behavior | Where it stops |
|---|---|---|
| Discover a place | Opens Explore; displays cards; supports region, keyword, vibe, budget, and some quick-filter predicates | Five fixtures are repeated 50 times in the grid. Pull-to-refresh only waits 500 ms. |
| Search/filter | Search matches name, category, address, and vibes using lowercase substring matching | No explicit place-type selector. Facilities and “Check-in đẹp” do not affect results. |
| Change region | City sheet offers Đà Nẵng & Hội An, Hồ Chí Minh, and Hà Nội | All fixtures belong to Đà Nẵng & Hội An; the other options produce empty results. |
| Open place details | Gallery, address, opening hours, price range, receipt/menu tabs, favorite action | No fresh API lookup, publication-state check, real menu photograph, or price-update timestamp. |
| Inspect a receipt | Item breakdown, total, guest count, per-person calculation, zoomable source-image URL | Fixtures supply the evidence; the card always stamps itself `VERIFIED`. |
| Inspect menu | `MenuTabView` displays item names, categories, and prices | No menu source image, update date, item/service unit, or approval state. |
| Save a place | Heart/bookmark changes the shared set; Profile opens saved places; removal supports Undo | Works without authentication checks at mutation points; not durable or account-specific. |
| Sign in/out | Profile initially shows a mock account; logout reveals the login form; any credentials restore the same account | No registration, validation, real session, role, expiry, or session invalidation. |
| Contribute | Select a fixture place or type a proposed name/address; toggle a stock image; edit items; adjust guest count; submit | Saves only a local summary. No actual image, bill date, items, guest count, or draft place is persisted. |
| Check contribution history | Sheet displays pending/approved/rejected badges and an optional rejection reason | Seeded/local records only; no processing updates, ownership enforcement, detail view, or empty-state explanation. |
| Report stale/wrong prices | Select a reason, optionally type a comment, press Submit | Only dismisses the sheet and displays a success snackbar. Nothing is recorded. |
| View map/get directions | Decorative map with selectable pins; directions button displays a snackbar | Pins use index-based screen coordinates. No geographic map, location acquisition, routing, or external navigation. |
| Invite/chat | Select an existing mock conversation and a preset time; send a plan; send text; accept/decline | All changes remain local. No friend discovery or conversation creation. |
| Admin work | No journey exists | No Admin identity, management screens, review queue, OCR correction, or publication controls. |

## 4. SRS to frontend traceability matrix

The SRS defines a `UI-xx` naming convention but does not assign UI requirement IDs. Those requirements are referenced by section.

### 4.1 Functional requirements

| Requirement | Classification | Implementation evidence | Decision and rationale |
|---|---|---|---|
| **FR-01 — Registration, M** | **MISSING** | `AuthProfileScreen` labels its app bar “Đăng Nhập / Đăng Ký” but implements only login. | **CHANGE PROTOTYPE:** provide actual registration; a combined account screen remains acceptable. |
| **FR-02 — Authentication and role-based session, M** | **PARTIALLY SATISFIED** | `AuthNotifier.login()` always selects `MockData.mockUser`; no role/session. | **CHANGE PROTOTYPE:** retain the account entry point, replace simulated identity with authenticated state. |
| **FR-03 — Logout/session invalidation, S** | **PARTIALLY SATISFIED** | `logout()` clears only `AuthState`. | **CHANGE PROTOTYPE:** invalidate the session according to the agreed mechanism and clear personal state. |
| **FR-04 — Place list/detail, M** | **PARTIALLY SATISFIED** | `ExploreScreen`, `MasonryPlaceCard`, `PlaceDetailScreen`; detail omits explicit category and meaningful publication states. | **MERGE BOTH APPROACHES:** keep the layout, add complete published-place information and unavailable states. |
| **FR-05 — Menu images, items/services, unit prices, update time, M** | **PARTIALLY SATISFIED** | `MenuTabView` has item prices; `BillBreakdownCard` has receipt imagery/date, which is not the menu update time. | **MERGE BOTH APPROACHES:** retain both presentations; add approved menu evidence, units, and timestamps. |
| **FR-06 — Keyword search, M** | **PARTIALLY SATISFIED** | `filteredPlacesProvider` implements useful local matching. | **KEEP PROTOTYPE** interaction; complete backend-backed results and request states. |
| **FR-07 — Type/price filters, M** | **PARTIALLY SATISFIED** | Budget filtering exists; explicit type filtering does not; facilities are inert. | **MERGE BOTH APPROACHES:** keep chips/sheet, add supported categories and precise price semantics. |
| **FR-08 — Distance from current/selected origin, M** | **PARTIALLY SATISFIED** | Cards show fixed `Place.distanceKm`; no origin input/calculation. | **CHANGE PROTOTYPE:** calculate from a real origin and label the distance method. |
| **FR-09 — Estimated cost, M** | **PARTIALLY SATISFIED** | `RealBill.costPerPerson` calculates receipt total/guests; place range is independently seeded. | **MERGE BOTH APPROACHES:** retain receipt arithmetic, distinguish it from a general visit estimate. |
| **FR-10 — Authenticated favorite mutations, M** | **PARTIALLY SATISFIED** | `BookmarksNotifier.toggle()` updates a shared set without auth. | **MERGE BOTH APPROACHES:** retain immediate save feedback, enforce ownership and durable writes. |
| **FR-11 — View all saved places, M** | **PARTIALLY SATISFIED** | `BookmarksScreen` joins saved IDs against `MockData.places`. | **KEEP PROTOTYPE** list and Undo UX; complete account-backed retrieval and unavailable-place handling. |
| **FR-12 — Admin place management, M** | **MISSING** | No Admin screens or role model. | **CHANGE PROTOTYPE:** add the required operational capability; public contribution is not a substitute. |
| **FR-13 — Admin image upload/validation, M** | **MISSING** | No file selection/upload implementation. | **CHANGE PROTOTYPE:** actual image handling and validation are required. |
| **FR-14 — OCR extraction into unconfirmed data, M** | **MISSING** | OCR appears in contribution copy only. | **CHANGE PROTOTYPE:** represent actual extraction results and processing failures. |
| **FR-15 — Admin OCR correction, M** | **MISSING** | Contributor text fields are not an Admin review interface. | **CHANGE PROTOTYPE:** Admin needs source-image comparison and correction. |
| **FR-16 — Admin-confirmed publication, M** | **MISSING** | No publication operation; `isVerified` is fixture data. | **CHANGE PROTOTYPE:** publication must follow an authorized decision. |
| **FR-17 — Bill/menu contribution with required metadata, M** | **PARTIALLY SATISFIED** | `ContributeScreen` provides a bill-oriented form but no real image, menu branch, or capture date. | **MERGE BOTH APPROACHES:** retain contextual submission, support both evidence types and required metadata. |
| **FR-18 — New draft place linked to contribution, M** | **IMPLEMENTED DIFFERENTLY** | “Thêm quán mới” only changes local strings. | **CHANGE PROTOTYPE:** create a linked draft through the backend; do not imply a place was created from a label change. |
| **FR-19 — Automatic checks before manual review, M** | **MISSING** | No format/OCR/price checks or automatic-review result. | **CHANGE PROTOTYPE:** add the required gate without allowing automatic publication. |
| **FR-20 — Automatic rejection and reason, S** | **MISSING** | No automatic rejection path. | **CHANGE PROTOTYPE:** show actionable rejection reasons; distinguish invalid evidence from service outages. |
| **FR-21 — Admin contribution queue/approval/rejection, M** | **MISSING** | No Admin queue. | **CHANGE PROTOTYPE:** this is essential to the community-data model. |
| **FR-22 — Admin correction before approval, M** | **MISSING** | No Admin editing workflow. | **CHANGE PROTOTYPE:** contributors’ suggested corrections must remain reviewable. |
| **FR-23 — Contributor status tracking, S** | **PARTIALLY SATISFIED** | `ContributionHistorySheet`, `ContributionStatus`, optional `rejectionReason`. | **KEEP PROTOTYPE** presentation; connect it to durable, owner-scoped processing records. |

### 4.2 Business and data rules

| Requirement | Classification | Evidence and decision |
|---|---|---|
| **BR-01 — Only Admin changes official places** | **PARTIALLY SATISFIED** | Contributors currently do not update the public fixture list, but there is no official-data/role mechanism. **CHANGE PROTOTYPE:** preserve this separation explicitly. |
| **BR-02 — Only display permitted places** | **PARTIALLY SATISFIED** | All fixtures are displayed according to discovery filters; no publication/hidden-state filter exists. **CHANGE PROTOTYPE:** consume only publishable public records. |
| **BR-03 — Places may lack prices, with explanation** | **PARTIALLY SATISFIED** | Empty bill/menu branches exist, but `minPrice` and `maxPrice` remain mandatory. **CHANGE PROTOTYPE:** represent unknown prices without inventing numbers. |
| **BR-04 — Admin confirms official prices regardless of source** | **MISSING** | No per-menu/price confirmation or source linkage. **CHANGE PROTOTYPE:** use the same publication rule for Admin-entered and community evidence. |
| **BR-05 — OCR is provisional** | **MISSING** | No OCR result lifecycle. **CHANGE PROTOTYPE:** keep extraction separate from approved data. |
| **BR-06 — Definition of verified place** | **SRS SHOULD BE RECONSIDERED** | The SRS leaves verification conditions undefined; the UI translates `Place.isVerified` into “Bill thật” and “Hóa đơn đã kiểm duyệt.” **MERGE BOTH APPROACHES:** define precisely what was checked and label it accordingly. |
| **BR-07 — Prices are dated references** | **PARTIALLY SATISFIED** | Approximation symbols and receipt dates exist, but menu update dates and clear qualification do not. **CHANGE PROTOTYPE:** attach source dates and reference-price wording. |
| **BR-08 — Prioritize price transparency in ranking** | **MISSING** | `filteredPlacesProvider` preserves fixture order. **MERGE BOTH APPROACHES:** define a simple transparency preference within relevant results. |
| **BR-09 — Authentication for personal features** | **MISSING** | Favorites and contribution entry/submission do not check auth. **CHANGE PROTOTYPE:** require authentication at protected actions and enforce it server-side. |
| **BR-10 — v2/v3 excluded from MVP acceptance** | **IMPLEMENTED DIFFERENTLY** | Map and social features are prominent while required workflows are missing. **CHANGE PROTOTYPE:** defer substantial extra capabilities; retain inexpensive presentation improvements. |
| **BR-11 — Both moderation layers before publication** | **MISSING** | Pending summaries exist, but neither layer operates. **CHANGE PROTOTYPE:** preserve both decisions in the lifecycle. |
| **BR-12 — Community draft publication requires approved contribution** | **MISSING** | No draft place record or contribution linkage. **CHANGE PROTOTYPE:** approval must link evidence and place publication consistently. |
| **BR-13 — Rejection reasons private to contributor** | **PARTIALLY SATISFIED** | Reason appears in personal history, but records have no owner and state is global. **CHANGE PROTOTYPE:** owner-scoped retrieval, with authorized Admin access for moderation. |
| **BR-14 — Manual cleanup of abandoned drafts** | **MISSING** | No draft inventory or Admin cleanup. **CHANGE PROTOTYPE:** enable controlled manual cleanup; automatic deletion is unnecessary for this MVP. |

### 4.3 Security requirements

| Requirement | Classification | Evidence and decision |
|---|---|---|
| **SEC-01 — Authenticate protected operations** | **MISSING** | Only Profile observes auth state; protected mutations are not gated. **CHANGE PROTOTYPE.** |
| **SEC-02 — Secure password hashes** | **MISSING — integration/evidence** | No frontend registration/authentication integration establishes this. Backend hashing needs separate verification; do not move password storage into Flutter. |
| **SEC-03 — Backend Admin authorization** | **MISSING — integration/evidence** | No Admin role or API flow in the frontend. **CHANGE PROTOTYPE:** support authorized Admin access, backed by server enforcement. |
| **SEC-04 — HTTPS business/auth traffic** | **MISSING — integration/evidence** | Image URLs use HTTPS, but no business API transport exists. **CHANGE PROTOTYPE:** configure the deployed API connection accordingly. |
| **SEC-05 — No credential logging** | **SATISFIED, frontend source only** | No credential logging found in application code. **KEEP PROTOTYPE** practice when real requests are introduced. Backend logging is unassessed. |
| **SEC-06 — Resource authorization** | **MISSING** | Favorites and contributions are global rather than owner-scoped. **CHANGE PROTOTYPE:** identity-specific data and authorized APIs. |
| **SEC-07 — Validate client input** | **PARTIALLY SATISFIED** | Some local constraints exist, but login is unchecked and malformed contribution amounts become zero. **CHANGE PROTOTYPE:** meaningful validation plus authoritative backend validation. |
| **SEC-08 — Validate uploaded image type/size** | **MISSING** | No actual uploaded file exists. **CHANGE PROTOTYPE:** validate actual file content and limits. |
| **SEC-09 — Logout invalidates current session** | **PARTIALLY SATISFIED** | A local logged-out flag exists; personal state remains. **CHANGE PROTOTYPE:** complete session and state invalidation. |
| **SEC-10 — No hard-coded service secrets** | **SATISFIED, frontend source only** | No real API/service secrets were found. The prefilled password is a demo fixture, not evidence of a leaked production credential. **KEEP** secret separation; remove demo credentials from real login UX. |
| **SEC-11 — Consistent authorization mechanism** | **MISSING — integration/evidence** | No common API/session mechanism. **CHANGE PROTOTYPE:** one coherent authentication boundary. |

### 4.4 Nonfunctional requirements

| Requirement | Classification | Evidence and decision |
|---|---|---|
| **NFR-01 — Main UI ≤3 seconds** | **PARTIALLY SATISFIED** | Local content renders synchronously; network images/fonts remain dependencies. No timing evidence. Preserve the compact UI; verify against the specified environment. |
| **NFR-02 — Read APIs ≤2 seconds** | **MISSING — integration/evidence** | No business API requests to evaluate. Retain as an acceptance target. |
| **NFR-03 — Search/filter ≤2 seconds** | **PARTIALLY SATISFIED** | Local filtering exists, but five fixtures do not validate backend/end-to-end performance. |
| **NFR-04 — Processing state after 500 ms** | **PARTIALLY SATISFIED** | Image placeholders and simulated refresh feedback exist; no business-request state handling. **CHANGE PROTOTYPE.** |
| **NFR-05 — Responsive OCR processing UI** | **MISSING** | No OCR operation or processing state. **CHANGE PROTOTYPE.** |
| **NFR-06 — Timeout instead of indefinite wait** | **MISSING** | No business-request timeout/error policy. **CHANGE PROTOTYPE.** |
| **NFR-07 — Upload progress/result** | **MISSING** | Photo toggle is not upload feedback. **CHANGE PROTOTYPE.** |
| **NFR-08 — Reference prices, not guarantees** | **PARTIALLY SATISFIED** | `~` exists, but “receipt-based” and per-person claims are not supported by the underlying range. **CHANGE PROTOTYPE** semantics and copy. |
| **NFR-09 — Honest distance description** | **IMPLEMENTED DIFFERENTLY** | Fixed kilometers are displayed without origin or method; “nearest” is a radius filter. **CHANGE PROTOTYPE.** |
| **NFR-10 — No fabricated missing values** | **MISSING** | Required numeric fields prevent normal unknown states. **CHANGE PROTOTYPE** models and presentation. |
| **NFR-11 — Graceful permission refusal** | **MISSING** | No permission-dependent feature is implemented. **CHANGE PROTOTYPE:** support refusal and manual alternatives where relevant. |
| **NFR-12 — Dependency failures do not crash** | **PARTIALLY SATISFIED** | Some image error widgets exist; API/OCR/location failures are unhandled. **CHANGE PROTOTYPE.** |
| **NFR-13, NFR-15 — Unconfirmed OCR is never official** | **MISSING** | No enforceable extraction/publication distinction. **CHANGE PROTOTYPE.** |
| **NFR-14 — UI reflects published API/database data** | **MISSING** | Public content comes from fixtures. **CHANGE PROTOTYPE** data source. |
| **NFR-16 — Understandable discovery-to-price journey** | **PARTIALLY SATISFIED** | The interaction structure is promising; price meaning is inconsistent and no usability validation was performed. **KEEP PROTOTYPE** structure, correct semantics. |
| **NFR-17 — Useful error messages** | **PARTIALLY SATISFIED** | Useful no-results/favorites messages exist; business failures have no UI. **MERGE BOTH APPROACHES.** |
| **NFR-18 — Preserve successfully saved data** | **MISSING** | Business state is memory-only. **CHANGE PROTOTYPE:** durable saves and recoverable reads. |
| **NFR-19 — Failed writes leave consistent data** | **MISSING — integration/evidence** | No real writes or atomic approval operation. Preserve this backend invariant and reflect failure honestly. |
| **NFR-20 — Functional modularity** | **PARTIALLY SATISFIED** | Feature folders and reusable widgets exist; screens directly depend on fixtures/global state. **MERGE BOTH APPROACHES:** retain modules, introduce modest data boundaries. |
| **NFR-21 — Separate environment configuration** | **MISSING for business integration** | No business API environment configuration. **CHANGE PROTOTYPE** when connecting services. |
| **NFR-22 — Independently testable core capabilities** | **PARTIALLY SATISFIED** | Provider/widget tests exist, but mostly validate prototype behavior. Extend coverage to actual product rules. |
| **NFR-23 — Identifiable business/API errors** | **MISSING** | No error contracts or mappings. **CHANGE PROTOTYPE.** |
| **NFR-24 — Android 10+/iOS 15+** | **PARTIALLY SATISFIED** | Native projects exist; iOS target is 15.0; Android uses Flutter’s SDK defaults. Runtime compatibility remains unverified. |
| **NFR-25 — Consistent data presentation** | **PARTIALLY SATISFIED** | Shared currency formatting helps, but verification and price meanings differ between components. **CHANGE PROTOTYPE** semantics while keeping shared formatting. |

### 4.5 Unnumbered requirements and UI decisions

| SRS reference | Classification | Reconciliation |
|---|---|---|
| **§1.4 — Price transparency as core value** | **PARTIALLY SATISFIED** | Strong receipt-oriented presentation, insufficient evidence metadata. **MERGE BOTH APPROACHES.** |
| **§2.3 — Contributor is an ordinary authenticated User** | **SATISFIED at role-design level** | No separate contributor account type is introduced. **KEEP PROTOTYPE** concept; add authentication. |
| **§2.5.2 / §3.3 — Backend-mediated business data/OCR/location** | **MISSING** | No integration. Preserve server authority; a decorative map is not a service integration. |
| **§3.1.1 — Separate named user screens** | **IMPLEMENTED DIFFERENTLY** | Search/filter/cost are embedded in discovery/detail. **CHANGE SRS:** specify accessible capabilities, not mandatory separate routes. |
| **§3.1.2 / §3.2.2 — Admin UI and mobile device** | **MISSING** | No Admin surface. **CHANGE PROTOTYPE**, unless the team formally revises the supported Admin platform. |
| **§3.1.3 / §6.2 — Vietnamese and currency formatting** | **PARTIALLY SATISFIED** | Most copy is Vietnamese and full amounts use Vietnamese formatting; some trust labels are English and units are ambiguous. Preserve the language direction, standardize terminology. |
| **§3.1.3 — Confirm dangerous Admin actions** | **MISSING** | Admin actions are absent. Add confirmation when that capability exists. |
| **§2.6 — User/Admin manuals** | **MISSING in inspected frontend deliverables** | Root README remains the Flutter starter text. Manuals should describe the agreed product behavior. |
| **§6.1 — Relationships, timestamps, integrity** | **PARTIALLY SATISFIED** | Models express basic nesting, but lack evidence ownership, durable relationships, approval metadata, and price history. **CHANGE PROTOTYPE** contracts. |
| **§6.3 — Backup/restore** | **MISSING verification evidence; backend responsibility** | Cannot be established from Flutter. Keep outside UI compliance claims. |
| **§4.1.2 diagrams — Recovery and editing submitted contributions** | **SRS SHOULD BE RECONSIDERED** | Diagram-only capabilities lack corresponding FRs and detailed behavior. Explicitly include or defer them. |

## 5. Important conflicts

### Screen organization versus user capability — KEEP PROTOTYPE; CHANGE SRS wording

The SRS lists separate search, filter, menu, cost, and distance screens. `SearchHeader`, `AdvancedFilterSheet`, and `PlaceDetailScreen` make those tasks available in context.

That is a sound mobile interaction pattern. Separate screens would increase navigation and maintenance without strengthening business rules. Acceptance should verify that users can complete each task, not count routes.

### Receipt evidence versus the menu-first specification — MERGE BOTH APPROACHES

`BillBreakdownCard` makes price evidence concrete: what was ordered, when, for how many people, and at what total.

Preserve it. A receipt documents one purchase; it cannot establish a complete current menu. The product still needs real menu/service-price images, approved structured prices, source dates, and missing-menu behavior under **FR-05**.

Receipt presentation itself is not wholly outside the SRS: its place-information diagram explicitly includes original menu/receipt images.

### Place verification versus receipt verification — MERGE BOTH APPROACHES, with a stricter definition

The same boolean drives:

- “Bill thật” on `MasonryPlaceCard`.
- “Hóa đơn đã kiểm duyệt” on `PlaceDetailScreen`.
- A separate, unconditional `VERIFIED` stamp inside `BillBreakdownCard`.

These are different claims. A published place may have only an Admin-entered menu. An approved receipt may be old. A newer contribution may still be pending.

The SRS also needs revision because **BR-06** does not define verification criteria. The UI should state the specific checked fact—such as “Giá đã được kiểm tra”—without implying a guarantee of current prices or business quality.

### Price range versus per-person spending — CHANGE PROTOTYPE

`CurrencyFormatter.formatRange()` always appends `/người`. The same `minPrice/maxPrice` values are used for card summaries, budget filtering, invitations, and “Khoảng chi phí theo hóa đơn.”

No calculation connects those ranges to receipts.

For example, Kyoto Ramen's fixture has a **330,000₫ bill for two people**, producing **165,000₫ per person**, while its displayed range ends at **150,000₫ per person**.

This undermines the core product promise. Distinguish:

- Listed item/service prices.
- Total of a particular receipt.
- Per-person spend for that receipt.
- A broader visit estimate, only if its method and evidence are defined.

### Contributor correction versus Admin authority — MERGE BOTH APPROACHES

Letting contributors correct obvious extraction mistakes can improve data quality and reduce Admin effort. It does not violate the SRS if corrections remain proposed data.

However, the current form invites users to edit a fully populated table before any actual extraction. That is misleading and makes contribution unnecessarily demanding.

The essential invariant is **FR-16 / BR-04 / BR-11**: contributor edits never publish official prices. Admin sees the original evidence and retains final authority.

### Automatic rejection versus OCR reliability — CHANGE SRS clarification; CHANGE PROTOTYPE behavior

**FR-19/20** require automatic checks, while **UC-10** permits manual entry when OCR fails.

A malformed image and a temporary OCR-service outage are not the same outcome. Treating both as rejected content would punish users for infrastructure failures.

Define three outcomes:

- Invalid submission: reject with a user-understandable reason.
- Temporary processing failure: retain as retryable processing failure.
- Valid evidence with incomplete extraction: follow an explicitly agreed manual-review policy.

Both required moderation layers must remain. A machine check must never publish data.

### Admin mobile interface versus unspecified web application — CHANGE SRS clarification

Section **2.1** mentions a web application, but **§3.2.2** and the software-interface diagram place Admin operations on mobile.

A generated Flutter web target does not resolve this inconsistency. The team should commit to one required Admin surface. The recommended default is a compact role-protected Admin area in the existing Flutter app because that matches the detailed SRS and avoids maintaining two separate UIs. A small web Admin tool is also defensible if explicitly agreed.

### Social application versus price-discovery MVP — CHANGE PROTOTYPE

Chat, presence, friendship, invitations, and RSVP require more than screen wiring: identities, access rules, delivery, persistence, conversation membership, and lifecycle handling.

The current social code is substantial but remains entirely local. Finishing it would compete directly with mandatory moderation and price transparency. Defer it from MVP acceptance and primary navigation.

## 6. Prototype strengths worth preserving

| Strength | Concrete evidence | Why retain it |
|---|---|---|
| Compact discovery | `SearchHeader`, `FilterChipsBar`, `AdvancedFilterSheet` | Users can refine results without repeatedly leaving the list. |
| Recognizable visual identity | `AppColors`, `AppTheme`, `MasonryPlaceCard` | The product has a coherent direction that does not need to become an administrative-looking catalog. |
| Price visibility on cards | `MasonryPlaceCard` | Helps users compare before opening every place, provided the label has a defined meaning. |
| Evidence-rich receipt display | `BillBreakdownCard`, `_openBillPhotoDialog()` | Supports the price-transparency proposition directly. |
| Integrated detail tabs | `PlaceDetailScreen`, `MenuTabView` | Keeps related evidence in one place. |
| Immediate favorite feedback | `BouncingHeartButton`, `BookmarksScreen` | Clear, reversible interaction; preserve Undo. |
| Contribution entry from no-results | `ExploreScreen._buildEmptyState()` | Connects a discovery failure to a useful community action. |
| Personal contribution status | `ContributionHistorySheet` | Makes moderation understandable and reduces uncertainty after submission. |
| Shared state updates | Riverpod providers | A reasonable mechanism for keeping cards, details, and saved lists consistent. |
| Existing empty-state copy and semantics | Discovery/favorites messages and selected button labels | Useful foundations for accessibility and recovery, though coverage is incomplete. |

### Prototype features absent from the MVP SRS

| Prototype feature | Classification | Decision and rationale |
|---|---|---|
| Masonry cards, pastel tags, heart animation | **Harmless UX enhancement** | **KEEP PROTOTYPE:** no meaningful backend expansion. |
| Favorite Undo | **Harmless UX enhancement** | **KEEP PROTOTYPE:** reduces accidental removal. |
| Light/dark/system theme choice | **Harmless UX enhancement** | **KEEP PROTOTYPE** intent; finish consistent styling only within available scope. |
| Chips that expose existing category/price criteria | **Harmless UX enhancement** | **CHANGE SRS:** clarify that a shortcut presentation is not a separate v2 capability. |
| New vibe/amenity criteria | **Useful MVP improvement**, if supported by maintained data | Keep only a small, defined set. Unsupported labels add false precision and Admin work. |
| Price/menu/closure reporting | **Useful MVP improvement** | **MERGE BOTH APPROACHES:** route reports to review; never mutate official data automatically. |
| Receipt guest count and per-person example | **Useful MVP improvement** | **KEEP PROTOTYPE:** directly supports **FR-09**. It is not a group debt-settlement tool. |
| Contributor corrections to extracted items | **Useful MVP improvement**, optional | **MERGE BOTH APPROACHES:** suggestions can assist review but must not become a prerequisite for simple submission. |
| Multi-city selector | **Useful MVP improvement**, conditional | Show supported coverage honestly; do not imply populated national coverage. |
| In-app geographic map | **Scope creep** | Defer; explicitly v2 in the SRS. |
| Chat, online status, invitations, RSVP | **Scope creep** | Defer; their backend and security obligations are disproportionate for the MVP. |
| Ratings/review counts without a real source | **Contradicts product model as currently presented** | Remove from MVP data presentation unless a legitimate source and scope are agreed. |
| Verified stamps without record-level verification | **Contradicts product model** | Replace decorative trust claims with actual approval metadata. |
| Arbitrary map pins presented as locations | **Contradicts product model** | Do not expose as geographic information in an accepted MVP. |

There is no implemented contributor-reward system or interactive group-splitting tool; neither should be inferred from counts or receipt arithmetic.

## 7. Prototype weaknesses

The most consequential weaknesses are behavioral and structural.

- **Authentication is disconnected from protected actions.** `AuthNotifier` starts authenticated, accepts any credentials, and leaves bookmarks, contributions, and chat intact after logout. UI hiding on Profile does not enforce **SEC-01/06** or **BR-09**.
- **Submission reports success without preserving evidence.** The submit callback in `ContributeScreen` drops item names/prices, guest count, and photo selection. `date` becomes submission time, not the required bill capture time.
- **Validation silently changes bad input into data.** `_totalAmount` treats unparsable prices as zero; negative amounts are not excluded. Missing imagery does not prevent submission.
- **“New place” has no identity.** Selection uses names, and proposed places remain strings. Real businesses can share names; contributions need an unambiguous existing-place link or an explicit new-place proposal.
- **Discovery controls overpromise.** Facilities are stored but never read by `filteredPlacesProvider`; `checkin` has no predicate. “Gần nhất” filters within 1.5 km rather than sorting nearest first.
- **Reset is incomplete.** “Xóa toàn bộ bộ lọc” clears query, vibe, and quick filter but leaves budget/facilities. The search field has no controller synchronized to provider resets, so displayed text and active query can diverge.
- **List length is fabricated.** `ExploreScreen` repeats results 50 times rather than implementing pagination.
- **Missing data cannot be represented properly.** Required prices and distances encourage invented fallback values. A menu's absence is described as “Đang cập nhật…” even though no update is running.
- **Freshness is absent.** `MenuItem` has no source/update timestamp. Fixture receipt dates are regenerated relative to startup, so the demo continually looks recent.
- **Receipt selection is underdefined.** `Place.latestBill` returns `bills.first` without establishing chronological order. The detail tab advertises the bill count but renders only that one bill.
- **Unavailable records are not handled.** `PlaceDetailScreen` receives a full object instead of resolving current availability. `RendezPlanBubble._openPlaceDetail()` falls back to the first unrelated place if its ID is missing.
- **False-success actions exist.** Price reporting and directions display confirmation-like messages without doing the stated work.
- **Dark mode is incomplete.** Theme-aware cards coexist with hard-coded light screens, sheets, and search text.
- **Platform readiness is unproven.** The main Android manifest has no explicit Internet permission, while debug/profile manifests do. The release merged manifest needs checking. Camera/location integration and iOS usage descriptions are absent.
- **Tests encode prototype assumptions.** They explicitly expect initial login and test the local mock behavior. Their presence does not validate ownership, moderation, publication, stale data, or failure recovery.
- **The repository currently has frontend build blockers.** The unresolved relative imports must be corrected before the prototype can be treated as a runnable baseline.

## 8. SRS assumptions that should be revised

These are specification corrections, not permission to drop mandatory capabilities.

| SRS issue | Recommended revision | Why |
|---|---|---|
| **§3.1.1 treats capabilities as separate screens** | Allow integrated screens, tabs, and sheets | Preserves the prototype’s efficient UX without losing functionality. |
| **§2.2 defers “quick filters” while FR-07 requires filters** | Separate shortcut UI from additional filtering criteria | A chip for an existing criterion is not a major new feature. |
| **BR-06 leaves “verified” undefined** | Define verification at place/evidence/menu level and its limits | Prevents a badge from claiming more than Admin reviewed. |
| **FR-09 leaves cost estimation undefined** | Specify the estimate basis, units, minimum evidence, and unknown state | Prevents menu-item prices being relabeled as per-person spending. |
| **FR-08 / NFR-09 leave distance method unresolved** | Select straight-line or route distance, origin behavior, and labels | Makes mobile UX and backend responsibility testable. |
| **BR-08 leaves ranking unspecified** | Prefer better price evidence among otherwise relevant matches | Avoids an elaborate ranking system or irrelevant results outranking relevant ones. |
| **FR-19/20 versus UC-10 OCR fallback** | Distinguish invalid content, incomplete extraction, and temporary failures | Makes the two-layer process coherent and recoverable. |
| **BR-12 is written broadly around “draft places”** | Scope the approved-contribution condition to community-created drafts | Admin-created seed data should still follow the SRS's direct validation/confirmation path. |
| **§2.1 versus §3.2.2 Admin platform** | Name the required Admin surface explicitly | Avoids accidentally committing to separate mobile and web Admin applications. |
| **Diagram-only password recovery** | Explicitly include it with a mechanism or defer it | Recovery is currently untraceable, and §3.4 does not require email/SMS infrastructure. |
| **Diagram-only editing of submitted contributions** | Define whether users can edit, withdraw, or resubmit—and when | Editing pending evidence affects review consistency; it is not merely another form. |
| **Mixed M/S dependencies** | Resolve essential rejection feedback, file validation, logout, and status tracking coherently | Some “Should” capabilities support flows and invariants described as required elsewhere. |
| **No stale-data policy** | Define evidence date versus approval date, stale presentation, and correction handling | Approval does not keep a price current indefinitely. |
| **§6.1 omits explicit contribution/moderation storage groups** | Add contributions, source evidence, extraction results, decisions, and ownership | These are essential to the expanded community-data requirements. |
| **Public original receipt images** | Define what may be public and what must be obscured | Receipts may contain personal details unrelated to price transparency. |
| **Broad external-service prohibition** | Clarify whether public image delivery and font assets are allowed directly | Business/OCR credentials should remain server-controlled; the current wording is broader than necessary. |
| **Unbounded seed-data ambition** | Define initial geography and representative venue/service categories | A two-person team needs a credible, reviewable dataset rather than implied national coverage. |

The document also needs editorial cleanup: the referenced context diagram in Appendix B is not there—Appendix B contains TBDs—and the search/filter decomposition diagram is duplicated.

## 9. Missing MVP functionality

The essential missing capabilities are:

1. **Real account lifecycle:** registration, login, session restoration/expiry, protected actions, and logout.
2. **Published place retrieval:** complete details, unavailable/hidden handling, distinct records, and real refresh.
3. **Approved menu evidence:** actual images, structured item/service prices, units, and evidence/update dates.
4. **Required search/filter semantics:** category and well-defined price filtering, relevant results, and transparency preference.
5. **Actual location-based distance:** current or selected origin, calculation, correct label, and unavailable behavior.
6. **Defensible cost estimates:** a documented basis and honest insufficient-data state.
7. **Account-backed favorites:** durable save/remove/list behavior with ownership and failure recovery.
8. **Complete contribution intake:** actual bill/menu image, place association, required bill metadata, and new draft-place proposals.
9. **Automatic validation/OCR:** results, pending processing, rejection reasons, timeouts, and retryable failures.
10. **Admin operations:** place/menu/price management, OCR correction, contribution review, approval/rejection, and controlled cleanup.
11. **Publication integrity:** only confirmed evidence becomes public; pending updates do not overwrite existing approved prices.
12. **End-to-end state handling:** loading, upload feedback, empty results, missing data, API errors, permission refusal, and failed writes.

The existing history sheet makes **FR-23** relatively well represented visually, but it still needs real records. Similarly, logout and automatic-rejection explanations remain incomplete even though the SRS marks them “Should.”

## 10. Recommended final MVP product behavior

### Discovery and authentication

Allow guests to browse, search, filter, and inspect published price information. Require login when saving, contributing, or accessing personal history. After successful login, return users to the action they were attempting.

Keep the visual discovery grid, integrated search, and filter sheet. Show unique results with honest coverage. Retain shortcuts only when they map to defined, supported criteria.

### Place detail and price transparency

Keep one detail destination containing basic place information, menu/prices, receipt evidence, and estimates.

The screen should distinguish:

| Information | Meaning |
|---|---|
| Menu/service price | A listed price from an identified, approved source |
| Receipt total | What a particular documented purchase cost |
| Receipt spend per person | That receipt’s total divided by a known positive guest count |
| Visit estimate | A separately defined estimate with an explicit basis |
| Evidence date | When the menu/receipt information was observed |
| Review date | When Admin checked it |

Do not describe a partial item list as the “entire menu” unless completeness is established.

For the simplest defensible **FR-09** interpretation, show a dated per-person example from an approved receipt when guest count is known. Show menu prices independently. Where neither supports a meaningful visit estimate, display “Chưa đủ dữ liệu để ước tính.”

This interpretation should be confirmed against the project's acceptance expectations.

### Distance

The recommended v1 behavior is a clearly labeled approximate straight-line distance from a known current or selected origin. It satisfies the underlying discovery need without requiring an interactive map or routing engine.

When origin or destination coordinates are unavailable, retain normal browsing and explain why distance is unavailable. A city filter must not masquerade as a precise origin.

### Contributions and OCR

A user selects an existing place or proposes a new one, chooses bill versus menu, supplies an actual image, and provides required metadata. Guest count is optional supplementary information for bills; it is not relevant to menu submissions.

OCR output remains proposed data. Contributor corrections can be optional. Automatic checks run before manual review. Only Admin approval publishes official changes.

A new contribution for an existing place must leave its current approved information visible while the update is reviewed.

### Separate data states

| Object | Recommended distinction |
|---|---|
| Place | Draft, published, hidden |
| Contribution | Processing, awaiting Admin, approved, rejected; distinguish retryable processing failure |
| Extracted data | Unconfirmed versus Admin-confirmed |
| Price evidence | Source date, approval metadata, and freshness |
| Personal history | Owner-visible status and rejection explanation |

“Rejected” primarily describes a submission. “Stale” describes age or reliability concerns. Neither should be overloaded into a single place verification boolean.

A rejected contribution must not unpublish an already valid place. A community-created draft with only rejected contributions remains nonpublic until Admin decides whether to retain or clean it up.

### Admin

Admin reviews the source image, submitted context, extraction, and proposed corrections together. Approval publishes a consistent result. Rejection requires a reason visible to the contributor and authorized Admins.

Admin-entered seed data and approved community data should have equivalent public trust treatment, as required by **§1.4 / §2.5.3 / BR-04**.

### Freshness and failure behavior

Show source dates consistently. Old approved information may remain visible as historical/reference data with an appropriate warning; it must not silently become “current” when the app reloads.

A price report requests review. It does not immediately alter public prices.

Show success only after a real operation succeeds. Preserve entered information after recoverable failures. Distinguish “no matches,” “no menu supplied,” “still processing,” and “could not load.”

## 11. Recommended frontend changes

These are target changes, not an implementation sequence.

| Frontend area | Decision | Rationale |
|---|---|---|
| `MainScaffold` | **CHANGE PROTOTYPE:** remove the placeholder map as an MVP destination; Explore, Saved, Profile is a coherent option. | Makes navigation reflect completed core tasks. |
| `SearchHeader` | **MERGE BOTH APPROACHES:** retain inline search, region selection, and contribution access; defer chat access. | Preserves compact discovery while reducing scope. |
| `FilterChipsBar`, `AdvancedFilterSheet` | **MERGE BOTH APPROACHES:** retain the controls, expose required category/price criteria, remove unsupported choices. | Gives each visible option an actual contract. |
| `filteredPlacesProvider` | **CHANGE PROTOTYPE:** separate query state from fetched results and request status. | Enables honest loading, retry, ordering, and pagination without replacing Riverpod. |
| `MasonryPlaceCard` | **KEEP PROTOTYPE** layout; correct price units and verification labels. | Preserves a strong discovery component while protecting trust. |
| `PlaceDetailScreen` | **MERGE BOTH APPROACHES:** keep integrated tabs; add category, evidence dates, missing/unavailable states, and context-aware contribution. | Satisfies the SRS without fragmenting the journey. |
| `MenuTabView` | **CHANGE PROTOTYPE:** support source images, units, dates, partial coverage, and explicit empty states. | Menu transparency is a core requirement. |
| `BillBreakdownCard` | **KEEP PROTOTYPE** presentation; derive trust badges from approved evidence and clarify historical costs. | Retains the prototype's most distinctive useful component. |
| `ContributeScreen` | **MERGE BOTH APPROACHES:** real evidence selection, bill/menu distinction, bill date, stable place identity, optional corrections. | Removes fictional submission behavior while retaining its approachable structure. |
| `ContributionHistorySheet` | **KEEP PROTOTYPE** status presentation; add owner-scoped records, processing failures, details, and empty state. | Makes the contribution lifecycle understandable. |
| `AuthProfileScreen`, auth providers | **CHANGE PROTOTYPE:** real account states, registration, expiration, authenticated-action continuation, and personal-state cleanup. | Required for security and consistent user journeys. |
| `BookmarksNotifier`, `BookmarksScreen` | **MERGE BOTH APPROACHES:** preserve feedback/Undo; make save state durable and account-specific. | Keeps good UX without sacrificing ownership. |
| `PriceReportSheet` | **MERGE BOTH APPROACHES:** record an actual place/evidence-linked report or omit the action until supported. | A success snackbar must correspond to a persisted report. |
| Models | **CHANGE PROTOTYPE:** distinguish publication, evidence, ownership, dates, units, and nullable values. | The current display models cannot express mandatory rules safely. |
| Data access | **CHANGE PROTOTYPE:** introduce a small API/repository boundary. | Removes direct fixture dependence without imposing production-scale architecture. |
| Admin capability | **CHANGE PROTOTYPE:** provide the agreed protected operational surface. | Required for the product to maintain trustworthy data. |
| Chat/map modules | **CHANGE PROTOTYPE:** defer from MVP-facing behavior. | Prevents unfinished extras from consuming core development capacity. |
| Theme/platform/test foundations | **CHANGE PROTOTYPE:** resolve imports, inconsistent theme use, platform integration gaps, and mock-only assumptions. | Makes the agreed product reviewable and testable on real devices. |

Keeping Riverpod, feature folders, ordinary Flutter navigation, and reusable widgets is reasonable. This project does not need a framework migration or a large multi-layer architecture to achieve the required separation.

## 12. Questions requiring human product decisions

| Decision | Recommended default | Why it needs agreement |
|---|---|---|
| **What exactly satisfies FR-09?** | Dated receipt-based spending examples, with menu prices shown separately and no invented estimate | Determines required evidence, budget-filter semantics, and acceptance tests. |
| **Which Admin surface is required?** | Role-protected Flutter Admin area | The SRS contradicts itself about web versus mobile. |
| **What does “verified” promise?** | Identified data/evidence was checked by Admin; no guarantee of current price or venue quality | Affects public trust language and review criteria. |
| **How should incomplete OCR be handled?** | Reject invalid files; retry outages; permit manual review of valid but incompletely extracted evidence if formally accepted | Resolves the automatic-gate/manual-fallback conflict. |
| **Must contributors correct OCR before submission?** | No; corrections optional | Mandatory item editing increases friction and abandons the simple evidence-contribution model. |
| **What initial area and venue types are covered?** | One explicitly supported area with a curated dataset | Determines realistic data collection and review workload. |
| **What makes data stale?** | Always display source dates; agree on any additional age threshold | No threshold is specified, and menu/receipt age is domain-dependent. |
| **What receipt content is public?** | Only evidence approved for public display, with unrelated personal information obscured | Original receipts can contain more than menu prices. |
| **What distance method is accepted?** | Approximate straight-line distance; routing/map UI deferred | Determines whether a map service is necessary for v1. |
| **Are social features and ratings deferred?** | Yes, including chat, presence, invitations, RSVP, and unsupported ratings | They materially change scope and the product model. |
| **Are recovery and editing submitted contributions in v1?** | Explicitly defer unless required by the evaluator; provide a defined correction/resubmission policy | They appear in diagrams but lack actionable requirements. |
| **Which “Should” features are acceptance commitments?** | Include logout, rejection reasons, image validation, and contribution status in the coherent MVP | They support mandatory workflows despite inconsistent priority labels. |

## Continuation context

Another agent continuing from this document should preserve these conclusions unless a human product decision resolves one of the questions above. The next activity should not assume that visual conformity to the SRS is the goal. The central reconciliation is to preserve the prototype's strong discovery and price-evidence interactions while making authentication, data ownership, evidence provenance, moderation, publication, freshness, and failure states conform to the mandatory product rules.

This document deliberately does not contain an implementation plan.

## 13. Approved product decisions

The following decisions are the baseline for subsequent architecture work.

### 13.1 Product and UX

- Preserve the prototype's compact discovery UX.
- SRS capabilities do not require separate screens when an integrated screen, tab, or sheet provides the capability clearly.
- Preserve integrated search/filter, place details, receipt breakdown, favorites feedback/Undo, contribution entry, and contribution history where practical.
- Defer chat, friends, presence, invitations, RSVP, ratings/reviews, and the interactive map from MVP.
- External place sharing remains in MVP through the platform-native share mechanism and, if practical, a shareable/deep link. This must not require a social subsystem.

### 13.2 Cost semantics

Distinguish these concepts explicitly:

- Menu/service item price.
- Receipt total.
- Receipt spend per person.
- General visit-cost estimate.

For MVP, satisfy the useful intent of **FR-09** primarily through dated, receipt-based spending examples when approved evidence and a valid guest count exist.

Do not present a receipt example as a guaranteed or universal prediction of future visit cost.

If evidence is insufficient, display an honest unavailable state rather than inventing an estimate.

### 13.3 Trust, verification and transparency

Do not use one generic `isVerified` concept.

Keep these concerns separate:

- Place publication state.
- Contribution moderation state.
- Evidence review state.
- Source/observation date.
- Approval/review metadata.
- Freshness.
- Derived transparency ranking signal.

The product may use a derived Transparency Score to help rank places with better price transparency.

The Transparency Score is not itself an authorization, publication, or verification state.

A low or unavailable score must not imply that a venue is untrustworthy. New venues or venues with insufficient Rendez evidence must be represented as having insufficient evidence rather than being treated as inherently low quality or unsafe.

Search relevance remains fundamental. Transparency is a ranking signal among otherwise relevant results.

Do not define the Transparency Score formula in this phase.

### 13.4 Evidence freshness

Use progressive freshness / soft expiry.

Evidence is never deleted merely because it becomes old.

The product must be capable of distinguishing conceptually:

- Fresh evidence.
- Aging evidence.
- Stale evidence.
- Historical evidence.

Old evidence may remain available as provenance/history while no longer being treated as current price information.

Store and distinguish:

- `observed_at`: when the price, menu, or receipt was actually observed.
- `reviewed_at`: when Admin reviewed it.

Admin review does not reset the observation date.

Do not define hard freshness thresholds yet. The future policy must be changeable without database redesign.

### 13.5 Evidence presentation and privacy

Structured price/menu data is the primary user-facing representation.

Approved menu images may be exposed as supporting source evidence.

Receipt images are private by default and primarily support OCR and Admin moderation.

A receipt image may become public only through an explicit approved public-safe/redacted representation.

The data model must not assume that every evidence asset is public.

### 13.6 Contribution and OCR lifecycle

Contributor OCR correction is optional assistance and is not required for submission.

Distinguish at least these conceptual outcomes:

- Invalid submission.
- Processing.
- Retryable processing/service failure.
- Valid evidence with incomplete extraction.
- Awaiting Admin review.
- Approved.
- Rejected.

Valid evidence with incomplete OCR may proceed to manual Admin review.

A temporary OCR/service outage must not cause the contribution to be classified as rejected.

A newer pending contribution must not overwrite or hide already approved public data.

Submitted contributions are immutable evidence records.

If correction is required after submission, use resubmission/new contribution/version semantics rather than silently mutating evidence that an Admin may already be reviewing.

### 13.7 Admin surface

Use the existing Flutter application for both User and Admin functionality.

Admin UI is role-protected, but backend authorization remains authoritative.

Do not create a separate Admin web application for MVP unless this decision is explicitly revisited.

### 13.8 Location

For MVP, use approximate straight-line geographic distance from a known current or explicitly selected origin.

Interactive routing and map UI are deferred.

Do not introduce a third-party routing service solely to calculate v1 distance if coordinates are already available.

### 13.9 Authentication

Rendez owns its own internal user identity.

Federated login identities are authentication mechanisms linked to a Rendez user and must not become the domain user identifier.

Current MVP direction:

- Google sign-in.
- Apple sign-in.
- No local password authentication for MVP.
- Facebook login deferred unless later justified.

The backend must verify provider authentication and establish its own Rendez authenticated session.

Do not use email address as the canonical federated identity key.

Account linking must be explicit and authenticated; do not automatically merge accounts solely because two providers report the same email.

### 13.10 MVP coverage

Limit MVP coverage to one supported city and a deliberately small set of venue categories.

The exact supported venue categories remain a product/data-collection decision and must not be hard-coded into the architecture prematurely.

The domain model must support priced goods and services, not only food items.

Examples may include:

- A food/drink item priced per item.
- Karaoke priced per room/hour.
- Billiards priced per table/hour.
- Tickets priced per person.
- Other priced services.

### 13.11 Database modeling direction

PostgreSQL remains the primary database.

Use a hybrid model:

- Normalized relational tables/columns for stable business-critical facts, identities, relationships, constraints, transaction boundaries, fields used for filtering/sorting, and domain invariants.
- PostgreSQL JSONB for genuinely heterogeneous, category-specific, optional, or external/provider-specific attributes.

Do not switch to a document database merely to avoid schema evolution.

Do not store the entire Place, PriceItem, Contribution, or moderation lifecycle as opaque JSON documents.

A practical rule is:

- If the backend must frequently constrain, join, filter, sort, aggregate, or enforce integrity on a field, prefer a typed relational field.
- If the value is optional, category-specific, provider-specific, or structurally unstable, JSONB may be appropriate.

Raw OCR/provider responses are good JSONB candidates.

### 13.12 Requirements marked Should

Implement the Should-level capabilities that are necessary to make mandatory workflows coherent, including at minimum:

- Logout.
- Uploaded-image validation.
- Meaningful rejection reasons.
- Contribution status tracking.

Do not interpret this decision as requiring every Should feature in the SRS.

## 14. Explicitly deferred decisions

Do not make these decisions implicitly in later architecture work:

- Exact Transparency Score formula.
- Transparency Score weights.
- Exact freshness thresholds.
- Exact stale-data decay function.
- Final initial venue-category list.
- Advanced recommendation algorithms.
- Interactive routing.
- Social/chat architecture.

The backend should preserve sufficient factual data to support future versions of these policies without requiring a fundamental schema redesign.
