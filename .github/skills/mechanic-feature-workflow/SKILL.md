---
name: mechanic-feature-workflow
description: "Use when implementing or extending a mechanic-app Flutter feature, especially vehicle, service, profile, booking, or dashboard flows that involve Material 3 UI, Supabase data, authentication, loading states, or form validation."
argument-hint: "Describe the Flutter mechanic-app feature to implement"
user-invocable: true
---

# Mechanic App Feature Workflow

## Outcome

Deliver a focused Flutter feature that is consistent with the app, protects user-owned data, and is validated with the smallest useful checks.

## Quick Procedure

1. **Locate the owner.** Start from the requested screen, route, widget, model, or service. Read the nearest implementation, shared theme, and relevant call sites before editing. Keep the change within the owning feature area.
2. **Confirm the contract.** Inspect `supabase_schema.sql` and existing service conventions when data is involved. Identify the authenticated user, table columns, ownership key, required fields, and expected success or error result. Never put secrets in Dart source.
3. **Implement the smallest complete path.** Keep reusable widgets in `lib/widgets/`, screens in `lib/screens/`, and data concerns in `lib/models/` or `lib/services/`. Follow the shared Material 3 theme in `lib/theme/`. Include validation, loading, empty, success, and failure states where the flow needs them.
4. **Protect async UI.** Check `mounted` after awaited work before changing state or showing UI feedback. Avoid duplicate submissions and make navigation results explicit when a parent needs to refresh.
5. **Check data security.** For Supabase user data, scope reads, updates, and deletes to the authenticated owner. If schema or RLS changes are required, review policies against the actual access model and keep RLS enabled on exposed tables.
6. **Validate narrowly.** Run `dart format` on touched Dart files, then `flutter analyze`. Run the nearest relevant test or add a focused widget/unit test for important behavior. Exercise the changed flow with authenticated, unauthenticated, empty, success, and failure states when practical.

## Completion Criteria

- The feature is reachable from the existing navigation and does not break neighboring flows.
- Inputs and async operations provide clear validation and feedback.
- User-owned Supabase records cannot be addressed without an ownership check and matching RLS policy.
- No new analyzer errors, formatting drift, secret values, or unrelated refactors remain.
- Tests or manual checks cover the highest-risk behavior, and any environment limitation is reported.
