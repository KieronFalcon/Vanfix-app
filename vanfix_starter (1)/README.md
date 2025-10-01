# VanFix Estimator - Starter Flutter Project

This is a starter Flutter project for the **VanFix Estimator** app — captures photos/video of van damage, selects damage location and severity, and produces a simple instant repair estimate.

## What’s included
- `pubspec.yaml`
- `lib/main.dart` (compact single-file demo)
- `.github/workflows/android-build.yml` - example GitHub Actions workflow to build an Android APK
- `README.md` (this file)

## How to build an Android APK locally

1. Install Flutter (https://flutter.dev/docs/get-started/install).
2. Clone or unzip this project.
3. From the project root run:
   ```bash
   flutter pub get
   flutter build apk --release
   ```
   The generated APK will be in `build/app/outputs/flutter-apk/app-release.apk`.

### Android permissions
Make sure to add required permissions in `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
```

### iOS
To run on iOS, open `ios/Runner.xcworkspace` in Xcode, add the `Info.plist` camera/photo usage keys, and build from Xcode.

## CI: GitHub Actions example
An example workflow `.github/workflows/android-build.yml` is included. It uses the `subosito/flutter-action` to set up Flutter and build an APK. You can connect this repo to GitHub and the workflow will produce an APK artifact.

## Next steps I can help with
- Produce an Android APK for you (you can run the commands above locally, or I can add a Git repo + GitHub Actions that builds and uploads the APK as an artifact).
- Replace the hit-zone UI with an interactive SVG for accurate location marking.
- Integrate a backend for parts pricing and regional labour rates.
- Add TFL or VAT region adjustments, PDF export, or damage-detection ML.

If you'd like, I can also set up a GitHub repo with the workflow so you can get a downloadable APK automatically — tell me if you want that and which GitHub username/org to use (or I can provide the exact git commands to run locally).
