# Mini Course Player

A small Flutter app with two screens: a course list (with per-course progress)
and a course detail screen that plays a video and resumes from where you left
off, even after fully closing the app.

## Requirements

- Flutter SDK 3.x (stable channel) — https://docs.flutter.dev/get-started/install
- A connected device, emulator, or Chrome (for web)

Check your setup with:

```bash
flutter doctor
```

## Setup & Run

```bash
git clone <your-repo-url>
cd mini_course_player
flutter pub get
flutter run
```

Pick any target when prompted (Android emulator, iOS simulator, Chrome, etc.).
The app needs an internet connection the first time it plays a video, since
video files are streamed from remote URLs (thumbnails also load from the web).

## Running tests

```bash
flutter test
```

This runs:
- `test/progress_service_test.dart` — unit tests for the resume/progress logic
- `test/course_list_screen_test.dart` — widget test for the course list screen

## Project structure

```
lib/
  models/course.dart              Course data model
  services/course_service.dart    Loads courses from assets/courses.json
  services/progress_service.dart  Persists & reads resume position (shared_preferences)
  screens/course_list_screen.dart Course list UI
  screens/course_detail_screen.dart Video playback + resume UI
  main.dart                       App entry point
assets/courses.json               Mock course catalogue
test/                             Unit + widget tests
```

## Notes

- State management: plain `StatefulWidget` + `setState` — see RATIONALE.md.
- Resume playback: position is saved every 3 seconds and on screen exit,
  keyed by course id, via `shared_preferences`. See RATIONALE.md for the
  full write-up and trade-offs.
- Edge case handled: slow/failed video load and asset load failure both
  show a retry button instead of a stuck spinner or crash.
