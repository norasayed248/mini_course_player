# Rationale

This document covers the three things the assessment intentionally left
open, plus a short write-up of the trickiest part of the implementation
(resume playback) and an AI-use disclosure.

## 1. State management approach

I used **Cubit** (from `flutter_bloc`) for the course list screen, and
plain `StatefulWidget` + `setState` for the video detail screen.

**Why Cubit for the list screen:** the screen has a clear, small set of
states (loading / loaded / error) plus data derived per course (a
progress fraction and a completed flag). That's exactly the shape Cubit
is built for — it holds all of that state in a class separate from the
widget tree, which meant I could write direct unit tests against it
(`test/course_list_cubit_test.dart`) without spinning up any widget at
all.

**Why NOT Cubit for the detail screen:** `VideoPlayerController` is a
real platform resource with a lifecycle (`initialize()` → `dispose()`)
that has to be created and torn down in lockstep with the widget itself.
Wrapping that in a Cubit would add indirection without a real benefit —
the controller's lifecycle is already exactly the widget's lifecycle, so
`StatefulWidget` is the more direct, correct tool here.

**Rule of thumb I used:** Cubit for state that's shaped by data/business
logic and needs to be testable in isolation; `StatefulWidget` for state
that's tied to a platform resource's lifecycle.

## 2. What "progress" means and how it's tracked

Progress is defined as: **seconds watched ÷ total video duration**,
stored per course.

- While a video plays, a `Timer.periodic` (every 3 seconds) persists the
  current playback position (in whole seconds) to `shared_preferences`,
  keyed by course id. A final save also happens on screen `dispose()` as
  a safety net for quick exits between ticks.
- On reopening a course, the saved position is read once and the
  controller is seeked to it before playback starts — this is the resume
  behavior.
- Once a course crosses a **98% watched threshold**, it's treated as
  finished: the saved *position* resets to 0 (so re-watching starts from
  the top, not the last frame), but a **separate, sticky `isCompleted`
  flag** is set to `true` and stays `true` regardless of the position
  reset. This flag is what the list screen actually reads to show
  "Completed 🎉" instead of a percentage — deriving "completed" from the
  position alone doesn't work, since the position is intentionally reset
  to 0 right when a course finishes.
- Progress values are clamped to `[0.0, 1.0]` to guard against bad
  durations (e.g. 0) or a saved position slightly overshooting the real
  duration.

**Trade-off:** the 3-second save interval balances resume accuracy
against write volume — finer intervals cost more with no real benefit to
the player experience.

## 3. Behavior on video failure / offline

`CourseDetailScreen` wraps `VideoPlayerController.initialize()` in a
`try/catch` combined with a **15-second timeout**. If initialization
throws, or takes longer than 15 seconds, the screen shows a "Failed to
load video" message with a **Retry** button that re-attempts
initialization from scratch.

I did not add a separate connectivity pre-check (e.g. via
`connectivity_plus`). A lack of internet naturally surfaces through the
same initialization failure/timeout path, so a dedicated check would add
a dependency without changing the user-facing outcome. If I had more
time, I'd add a connectivity check so the "offline" state could be shown
immediately rather than waiting out the full timeout.

## What I'd do differently with more time

- Debounce progress writes further (skip saving if the position hasn't
  meaningfully changed, e.g. while paused).
- Add a `connectivity_plus` pre-check for immediate offline feedback.
- Cache thumbnails locally so the list screen doesn't refetch images on
  every rebuild.
- Add unit tests specifically for the `isCompleted` sticky-flag behavior
  in `ProgressService` and its propagation through `CourseListCubit`
  (partially written, not yet finalized in this submission).
- Add an integration test that drives a full "watch partway → leave →
  reopen → verify resumed position" flow.

## AI-use disclosure

I used Claude to help scaffold the project structure, debug a video
playback issue (tracked down to a broken video source, not a code bug),
and migrate the course list screen's state management from `setState` to
Cubit. I reviewed and tested each change myself before committing — in
particular I verified the resume behavior and the "Completed" state by
running the app on a physical Android device, and ran `flutter test`
after each change to confirm nothing regressed. The sticky `isCompleted`
flag design (separate from the resettable position) was a fix I asked
for after noticing the "Completed" tab/state logic broke once a course
finished, which I verified by testing on-device before accepting it.