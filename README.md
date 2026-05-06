# eventsandtimetables

Campus Events is a Flutter app for managing campus events, class timetables, user accounts, notifications, and admin workflows. It uses Supabase for authentication and backend services, and includes provider-based state management for theme and notification updates.

## Features

- Landing, login, signup, and password recovery flows
- Events and class timetable screens
- Add and update flows for events and classes
- Notifications and notification management
- User profile, settings, and theme switching
- Admin tools for user and notification management

## Tech Stack

- Flutter
- Provider
- Supabase Flutter
- Material 3 theming

## Getting Started

### Prerequisites

- Flutter SDK installed
- A configured device, emulator, or browser target

### Run the app

```bash
flutter pub get
flutter run
```

### Optional checks

```bash
flutter analyze
flutter test
```

## Project Structure

- `lib/main.dart` initializes Supabase, registers routes, and sets up app-wide providers.
- `lib/pages/` contains the primary screens and admin flows.
- `lib/widgets/` contains reusable UI and notification-related providers.
- `lib/assets/` stores local assets and constants.

## Notes

- The app starts on the landing route and routes through the screens defined in `lib/main.dart`.
- Supabase configuration is initialized in code, so avoid committing any private secrets outside the existing app configuration.
