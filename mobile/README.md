# Rendez mobile

Flutter/Riverpod prototype. Run commands from the repository root:

```sh
make mobile-deps
make mobile
make check-mobile
```

Use `flutter run -d chrome` from this directory for the web preview. Web uses a mobile-width viewport. Android and iOS retain their native build configuration.

`lib/features` contains feature screens and widgets; `lib/core` holds shared models, providers, mock data and design constants. All app imports use `package:rendez/...`. Tests live in `test`.

Authentication, bookmarks, contributions and chat currently use in-memory fixtures. The map is illustrative. The app has no business API client or durable storage yet. Backend integration is separate work described in `../docs/backend-implementation-plan.md`.
