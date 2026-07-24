# Mini Course Player

A small Flutter app with two screens: a course list (with per-course
progress and completion status) and a course detail screen that plays a
video and resumes from where you left off, even after fully closing the
app.

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

Pick any target when prompted (Android device/emulator, iOS simulator,
Chrome, etc.). The app needs an internet connection, since course
thumbnails and videos are streamed from remote URLs.

## Running tests

```bash
flutter test
```

This runs:
- `test/progress_service_test.dart` — unit tests for the resume/progress
  logic (`ProgressService`)
- `test/course_list_cubit_test.dart` — unit tests for the course list's
  state management (`CourseListCubit`)
- `test/course_list_screen_test.dart` — widget test for the course list
  screen

## Project structure

```
lib/
models/course.dart Course data model
services/course_service.dart Loads courses from assets/courses.json
services/progress_service.dart Persists & reads resume position and
completion status (shared_preferences)
cubit/course_list_cubit.dart State management for the course list screen
cubit/course_list_state.dart Immutable state for CourseListCubit
screens/course_list_screen.dart Course list UI (Cubit-driven)
screens/course_detail_screen.dart Video playback + resume UI (StatefulWidget)
main.dart App entry point
assets/courses.json Mock course catalogue
test/ Unit + widget tests
```

## Key dependencies

- `video_player` — video playback
- `shared_preferences` — persisting resume position and completion status
- `flutter_bloc` — Cubit-based state management for the course list screen

## Notes

- **State management:** Cubit (`flutter_bloc`) for the course list screen;
  plain `StatefulWidget` for the video detail screen, since
  `VideoPlayerController` is a platform resource whose lifecycle should
  stay tied directly to the widget. See `RATIONALE.md` for the full
  reasoning.
- **Resume playback:** position is saved every 3 seconds and on screen
  exit, keyed by course id, via `shared_preferences`. Once a course is
  watched to ~98% completion, it's marked as **Completed** using a
  separate, sticky flag (`isCompleted`) that persists even after the
  resume position itself resets to 0. See `RATIONALE.md` for details.
- **Edge case handled:** a failed or slow video load (15-second timeout)
  shows a retry button instead of a stuck spinner or crash.