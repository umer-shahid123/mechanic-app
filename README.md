# mechanic_app

A new Flutter project.

## Getting Started

### 🔐 Social Login Configuration (Google/Apple)

If you see **Error Code 10** during Google Login, follow these steps:
1. Go to Google Cloud Console.
2. Select your project.
3. Navigate to **APIs & Services > Credentials**.
4. Create an **OAuth 2.0 Client ID** for Android.
5. Add your **Package Name** (`com.example.mechanic_app`).
6. Add your **SHA-1 Fingerprint** (Run `./gradlew signingReport` in the `android` folder to get it).
7. Ensure the **Web Client ID** in `login_screen.dart` matches your project's Web Client ID.

### 📍 Google Maps Integration
The app now supports **Live Mechanic Tracking** using the `google_maps_flutter` package.
- Ensure your API Key in `AndroidManifest.xml` has **Maps SDK for Android** enabled.

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
