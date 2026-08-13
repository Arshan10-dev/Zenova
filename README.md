# Zenova — Offline Music Player (Flutter)

A premium, offline-first Android music player built with Flutter and Material 3:
automatic library scanning, manual import, background playback with full
notification/lock-screen/Bluetooth controls, playlists, favorites, recently
played/most played, folder browsing, and a dark/AMOLED/light theme system with
a user-selectable accent color.

---

## Before you build — read this first

This project was written in a sandboxed environment **with no Flutter SDK, no
Android SDK/emulator, and no network access to pub.dev**, so it has not been
compiled or run. Every file was written carefully and cross-checked (import
resolution, Hive field-index alignment, provider wiring, package-API research
against current docs), but a project this size will very likely need a couple
of small fixes on first `flutter pub get` / `flutter run` — mostly minor
package-version drift, not structural problems. Treat the first build like a
normal "pull someone else's branch" moment, not a from-scratch bring-up.

### First-time setup

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # see note below
flutter run
```

The `build_runner` step **regenerates** `song_model.g.dart` and
`playlist_model.g.dart`. Those two files were hand-written to match what
`hive_ce_generator` produces, specifically so the project compiles
immediately without running codegen first. You only need this step if you
change the `@HiveField`s on `SongModel` or `PlaylistModel`.

### Things most likely to need a tweak

- **Package versions.** `pubspec.yaml` pins recent versions of every
  dependency, verified against current docs where it mattered most
  (`hive_ce`/`hive_ce_flutter` — the actively-maintained fork, since the
  original `hive` package is no longer regularly updated; `on_audio_query_pluse`
  — the maintained fork of `on_audio_query`; `audio_service` background-audio
  setup; `file_picker`'s current static API). Package ecosystems move fast —
  if `flutter pub get` complains about a specific version, bump just that
  line; the rest of the code doesn't depend on exact patch numbers.
- **`on_audio_query_pluse` import path.** The code imports it as
  `package:on_audio_query_pluse/on_audio_query.dart`, matching its upstream
  (`on_audio_query`) file layout. If the installed version uses a different
  internal file name, adjust the import — the API surface used here
  (`OnAudioQuery`, `SongModel`, `queryArtwork`, `QueryArtworkWidget`, etc.) is
  standard for this package family either way.
- **`android/local.properties`** isn't included (it's machine-specific and
  gitignored) — Android Studio/`flutter run` will generate it automatically
  from your local Flutter SDK path.
- **Signing.** Release builds fall back to the debug signing config if
  `android/key.properties` doesn't exist, so `flutter build apk` works out of
  the box. Add a real keystore + `key.properties` before publishing.

### Fully-offline typography (optional)

Zenova uses `google_fonts` for its Sora/Inter type pairing, which fetches
the font files from Google's CDN the first time each is used, then caches
them. That's the only thing in the app that touches the network — playback,
your library, playlists, and favorites are 100% local. If you'd rather the
app never touch the network at all: download the Sora and Inter `.ttf` files,
add them under `assets/fonts/`, declare them in the `flutter:` section of
`pubspec.yaml`, swap the `GoogleFonts.sora(...)` / `GoogleFonts.inter(...)`
calls in `lib/core/theme/app_theme.dart` for a local `fontFamily:`, and remove
the two `INTERNET`/`ACCESS_NETWORK_STATE` lines from `AndroidManifest.xml`.

---

## Feature checklist

**Screens** — Splash (animated logo), Permission (rationale + Settings
deep-link), Home (Recently Played / Most Played / Favorites / Recently Added
/ Playlists), Songs (search, sort, multi-select, delete, favorite, add to
playlist), Albums (grid → detail), Artists (grid → detail), Folders (browse →
detail), Now Playing (art, seek bar, shuffle/repeat/favorite/queue/lyrics
placeholder/speed/sleep timer), Playlists (create/rename/delete/reorder),
Favorites, Settings (theme/AMOLED/accent/rescan/about/privacy/version).

**Import** — automatic MediaStore scan (mp3/m4a/flac/wav/aac/ogg) and manual
"+ Add Songs" (files or whole folders via the system file picker), with a
three-tier metadata resolution (MediaStore match → trigger rescan and retry →
direct file read) so manually-picked files always get a title/duration even
if Android hasn't indexed them yet.

**Playback** — background playback via `audio_service` + `just_audio`
(notification, lock screen, Bluetooth/headset/media-button controls),
queue management (play next, add to queue, reorder, remove), shuffle, repeat
(off/all/one), gapless-friendly `ConcatenatingAudioSource` queue, playback
speed, sleep timer, and resume-after-restart (queue + position are persisted
periodically and on pause, restored — cued but not auto-played — on next
launch).

**Storage** — Hive (`hive_ce`) for songs, playlists, recently-played, and
settings; nothing leaves the device.

## Architecture

```
lib/
  core/        # theme, colors, constants, formatters, small utils
  models/      # SongModel & PlaylistModel (Hive) + derived grouping models
  services/    # Hive init, permissions, MediaStore scan, manual import,
               #   artwork caching, the audio_service AudioHandler
  repository/  # thin CRUD wrappers around each Hive box
  providers/   # ChangeNotifier state: Library, Player, Playlist, History, Theme
  widgets/     # reusable UI: song tiles, mini player, sheets, cards…
  screens/     # one folder per feature area
```

Straight down the stack: **screens** read/call **providers**, **providers**
call **repositories** and **services**, **repositories** are the only thing
that touches Hive directly. `PlayerProvider` wraps the single
`ZenovaAudioHandler` and also exposes its streams directly, so widgets can
either use provider getters or `StreamBuilder` on `player.playbackStateStream`
/ `positionDataStream` for anything that needs to update every frame (seek
bar, mini player progress) without over-notifying the rest of the tree.

State management is plain `provider` (no code generation), chosen so the
whole project builds without a codegen step beyond the two Hive adapters
already covered above.

## Design

Material 3 throughout — `NavigationBar`, `SearchBar`, `SegmentedButton`,
`FilledButton`/`ChoiceChip`, tonal `surfaceContainer` roles for elevation, no
deprecated widgets. Typography pairs **Sora** (headings) with **Inter**
(body/labels) rather than default Roboto. The signature accent, "Ember"
(`#F2A93B`), is a deliberate warm amber-gold rather than the generic Material
purple seed or an obvious Spotify-green copy; seven more accents are offered
in Settings. Dark theme uses a lifted near-black (`#121214`) with a true-black
AMOLED variant that swaps just the surface tones, keeping tonal contrast for
cards. The mini player and Now Playing app bar use real backdrop blur
(`BackdropFilter`); Now Playing extracts a dominant color from the current
album art (`palette_generator`) for a subtle animated background tint.

## Known simplifications (by design, not oversights)

- **"Remove from Library" never touches the file on disk** — it only removes
  Zenova's reference to it. Actually deleting a user's file from shared
  storage on Android 10+ requires an interactive OS confirmation
  (`MediaStore.createDeleteRequest`), which felt out of scope for a library
  action; this keeps it fast, safe, and reversible via rescan.
- **Lyrics is an explicit placeholder**, per the brief — it opens a sheet
  explaining lyrics aren't fetched (Zenova has no lyrics API/network
  dependency by design).
- **Queue reordering** is supported inside Playlists (drag to reorder) and
  Queue (swipe to remove, tap to jump); dragging to reorder the *live playback
  queue* itself was left out to keep `ConcatenatingAudioSource` bookkeeping
  simple — swipe-to-remove + "Play Next" covers the common cases.

## Assets

The launcher icon (adaptive + legacy, all densities) is generated
programmatically — an amber equalizer glyph on near-black — so the project
has a real icon out of the box rather than a placeholder. Swap
`android/app/src/main/res/mipmap-*/ic_launcher*.png` for your own art if
you'd like a different brand.
