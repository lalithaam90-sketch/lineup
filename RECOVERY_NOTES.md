# Lineup — recovered project (2026-10-17)

Your old laptop's `C:\Users\aarav\Documents\LineUP` project is gone, but I still had a
working copy of your code sitting in this chat session's own workspace from when I
read/edited it earlier. This zip reconstructs the project from that.

## What's in here (and fully intact)
- `lib/` — the entire app: all screens, services, models, theme, and widgets
- `pubspec.yaml` — includes `http`, `firebase_core`, `cloud_firestore`, `firebase_auth`
  already added

## What's rebuilt, not recovered as-is
Four small widget files were never read into this session, so I couldn't recover their
original source — only how they were *called* from `home_screen.dart` / `waba_screen.dart`.
I rebuilt them from those call signatures so the app compiles and looks the same:
- `lib/widgets/lineup_logo.dart`
- `lib/widgets/stat_card.dart`
- `lib/widgets/quick_action_card.dart`
- `lib/widgets/menu_action_card.dart`

If the originals looked meaningfully different, let me know and we can restyle them.

## What's missing entirely (easy to regenerate)
- The native `android/`, `ios/`, `web/`, `windows/`, `linux/`, `macos/` folders, plus
  `.metadata`, `analysis_options.yaml`, `.gitignore` — none of these were ever staged into
  this session, so they're not recoverable, but they're 100% boilerplate.
- Your `.git` history — gone for good (this wasn't ever in this session).

## How to get this building again
1. Unzip this into a new empty folder, e.g. `C:\Users\<you>\Documents\LineUP`
2. Open a terminal in that folder and run:
   ```
   flutter create --platforms=android,ios,web,windows .
   ```
   This regenerates the native folders + `.metadata`/`analysis_options.yaml` **without**
   touching your existing `lib/` or `pubspec.yaml` (flutter create merges into an existing
   project).
3. `flutter pub get`
4. Immediately run `git init && git add -A && git commit -m "recovered"` and push it to a
   **private GitHub repo** — so this never happens again. (Do this before anything else.)
5. Then pick back up where we left off: Firebase was never fully wired in (no
   `lib/firebase_options.dart` was ever generated), so run `flutterfire configure
   --project=lineup` once you're set up, and I'll wire `Firebase.initializeApp()` into
   `main.dart` and migrate `AppState` off `SharedPreferences` onto Firestore.

## Also recovered, in case useful
Your earlier Next.js/Firebase web backend (`Whatsapp Application` / "aardtech" project) is
also still sitting in my workspace from an older session. That's now superseded by this
Flutter rebuild, but say the word if you want that zipped up too as a safety net.
