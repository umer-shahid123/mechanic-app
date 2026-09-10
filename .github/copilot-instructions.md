# Copilot instructions for Mechanic App

## Project overview
- This repository is a Flutter application for a mechanic-focused mobile app.
- Primary app entry point is `lib/main.dart`.
- Use clean, idiomatic Flutter/Dart patterns and keep changes scoped to the relevant feature area.
- Prefer Material 3 styling via the shared theme logic in `lib/theme/`.

## Key conventions
- Keep widget trees readable and modular; split reusable UI into `lib/widgets/` and feature screens into `lib/screens/`.
- Put domain/data concerns in `lib/models/` and `lib/services/`.
- Avoid broad refactors unless the task requires it.
- Preserve platform-specific setup for Android/iOS/Windows/macOS/Linux.

## Environment and runtime
- This app uses `flutter_dotenv` and expects a `.env` file at the project root.
- Keep Supabase environment variables in `.env` and never hardcode secrets.
- App initialization is configured in `lib/main.dart` with `Supabase.initialize(...)`.

## Dependencies and validation
- Use the existing project package versions from `pubspec.yaml` unless a task explicitly requires a dependency change.
- Validate changes with the smallest appropriate command, such as:
  - `flutter analyze`
  - `flutter test`
  - `dart format lib test`
- Prefer targeted checks over running the full suite when a single feature is being edited.

## Supabase guidance
- Treat Supabase as the backend/data layer and keep authentication and queries centralized in `lib/services/`.
- Do not expose secret keys in source code or commit generated credentials.
- When editing database-related code, respect the schema in `supabase_schema.sql` and avoid breaking RLS assumptions.

## Task expectations
- Provide direct, implementation-focused answers.
- When creating new files, prefer clear names and consistent Dart conventions.
- Keep comments minimal and only add them where they clarify non-obvious logic.
- If a task requires a design choice, explain the tradeoff briefly and recommend the safer/default approach.
