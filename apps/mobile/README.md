# SnapGrub Mobile

Flutter source for the SnapGrub iOS/Android app.

This repository was scaffolded on a machine without the Flutter SDK, so native platform folders are generated through:

```sh
bash ../../scripts/bootstrap-mobile-platforms.sh
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run --flavor dev --dart-define=SNAPGRUB_ENV=dev --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
```

Only public Supabase anon configuration may be passed to the app.
