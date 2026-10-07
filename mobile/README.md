# Rendez mobile

Run `make demo` from the repository root, then `make mobile-deps` and `make mobile`. For web:

```sh
cd mobile
flutter run -d web-server --web-hostname=127.0.0.1 --web-port=7357
```

Live navigation: Đã lưu, Khám phá, Đóng góp and Cá nhân. All six local modules call real API/database data. Register a User, explore/filter places, inspect menus, select quantities/party size, calculate distance with GPS or manual coordinates, save favorites and upload 1–5 JPEG/PNG menu/bill photos. Personal contribution history shows review status and reasons.

Admin: `admin@rendez.local` / `RendezDemo123!`, then Quản trị in Cá nhân. Create/edit/hide places, inspect original images and OCR text/draft, add/remove/correct menu rows, save drafts and approve/reject. Admin uploads through the same Đóng góp screen, with draft/hidden places available. Bill originals stay private; only approved totals/party size/date become public examples.

Web/desktop defaults to `http://127.0.0.1:8080`; Android emulator to `http://10.0.2.2:8080`. Override using `--dart-define=API_BASE_URL=http://<host>:8080`. Android debug allows local HTTP. Physical devices need reachable LAN API and platform transport configuration. Device camera/GPS/photo permission acceptance still requires native testing; web/widget tests do not prove it.

`make check-mobile` runs analyzer and widget tests; `make integration-ui` runs actual HTTP/Docker PostgreSQL/Tesseract and Admin review UI tests. `make build-web` compiles the web app. Sessions remain in memory, so reload requires login; persistent user data stays in DB.

Active scope: [local completion spec](../docs/specs/000-local-completion/spec.md). Chat/social/map prototypes remain outside live navigation.
