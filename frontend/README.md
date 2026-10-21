# Taskly AI

Frontend-only Flutter monorepo for a premium AI-powered service marketplace.

## Structure

- `apps/user_app` - customer experience
- `apps/tasker_app` - service provider experience
- `packages/shared_theme` - brand tokens, typography, dark Material 3 theme
- `packages/shared_models` - local demo models and mock content
- `packages/ai_mock` - simulated AI concierge responses
- `packages/shared_ui` - reusable primitive widgets
- `packages/shared_components` - marketplace-specific components

## Run

Install Flutter, then from an app directory:

```bash
flutter pub get
flutter run
```

This project intentionally contains no backend, database, payments, cloud functions, or real authentication.
