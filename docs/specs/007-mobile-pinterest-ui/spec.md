# Mobile UI refinement

The all-screens design folder is a reference inventory and visual template, not a pixel-perfect implementation contract. This change targets native Flutter mobile presentation; Flutter web keeps its existing presentation. Existing Go APIs, validation, ownership, OCR and cost calculations remain authoritative.

Use Pinterest-inspired discovery: image-first masonry, rounded imagery, compact metadata, direct save actions, and clear search/category controls. Preserve missing-data labels rather than inventing photos or prices. Improve login, profile, saved places, contribution entry and detail presentation. Keep the already integrated map and its attribution/recovery behavior.

Acceptance: render and inspect every implemented mobile screen and important overlay, including user/admin flows. Verify 320dp and 200% text, light/dark, empty/error, keyboard and recovery. Archive actual Flutter render captures, identify fixture data where used, and distinguish render validation from native GPS/camera/device certification. Provide all final images and a review record. Commit verified checkpoints and push to GitHub.
