# SimPlayer — TODO

> Last updated: 2026-08-16

---

## Priority Legend

| Symbol | Meaning |
|--------|---------|
| 🔴 P0 | Must-have — app is broken/unusable without it |
| 🟠 P1 | High — core music player expectation |
| 🟡 P2 | Medium — nice-to-have feature |
| 🟢 P3 | Low — polish / edge-case fix |

## Complexity Legend

| Symbol | Meaning | Estimated Effort |
|--------|---------|-----------------|
| ⬛ XL | Major architecture change | 2–4 days |
| 🟥 L | Significant new service/feature | 1–2 days |
| 🟧 M | Moderate — touches multiple files | 4–8 hours |
| 🟩 S | Small — isolated change | 1–3 hours |
| 🟦 XS | Trivial fix | < 1 hour |

---

## 🔴 P0 — Critical

### [ ] 1. Background Playback & Media Notification
- **Complexity:** ⬛ XL
- **Description:** `audio_service` package is in pubspec but never integrated. No `BaseAudioHandler` subclass exists. Playback stops when the app goes to background. No media notification controls (play/pause/skip) on lockscreen or notification shade.
- **What to do:**
  - Create `AudioPlayerHandler extends BaseAudioHandler` wrapping `just_audio`
  - Initialize via `AudioService.init()` in `main()`
  - Bridge existing `AudioService` methods to handler callbacks
  - Set `MediaItem` metadata + artwork for notification
  - Handle `audio_service` lifecycle (connect/disconnect)
- **Files affected:**
  - `lib/services/audio_service.dart` (major rewrite)
  - `lib/main.dart` (init)
  - `lib/providers/service_providers.dart`
  - `android/app/src/main/AndroidManifest.xml` (foreground service permission)

---

## 🟠 P1 — High Priority

### [x] 2. Headset/Bluetooth: Pause on Disconnect
- **Complexity:** 🟩 S
- **Description:** `pauseOnDisconnectProvider` toggle exists but no listener for audio becoming noisy / headset unplug. Standard Android/iOS behavior.
- **What to do:**
  - Listen to `AudioSession.instance` interruption events
  - On `AudioInterruptionType.unknown` with headset disconnect → pause
  - Respect the user's setting toggle
- **Files affected:**
  - `lib/services/audio_service.dart` (add listener in `init()`)

### [ ] 3. Headset/Bluetooth: Auto-Play on Connect
- **Complexity:** 🟧 M
- **Description:** `autoPlayOnConnectProvider` toggle exists but no Bluetooth/wired headset connection detection.
- **What to do:**
  - Listen to `AudioSession` for device connection events
  - On headset connect → resume playback if queue is non-empty
  - Respect the user's setting toggle
- **Files affected:**
  - `lib/services/audio_service.dart`

### [x] 4. Audio Ducking (Lower Volume for Notifications)
- **Complexity:** 🟩 S
- **Description:** `audioDuckingProvider` toggle exists. `AudioSession` is configured but interruption events are not handled.
- **What to do:**
  - Listen to `session.interruptionEventStream`
  - On `AudioInterruptionType.duck` → lower volume
  - On end → restore volume
  - On `AudioInterruptionType.pause` → pause playback
  - Respect the user's setting toggle
- **Files affected:**
  - `lib/services/audio_service.dart` (add in `init()`)

### [ ] 5. Sleep Timer
- **Complexity:** 🟥 L
- **Description:** Only a "finish current track" preference exists. No timer service, no countdown, no UI to start/stop/set duration.
- **What to do:**
  - Create `SleepTimerService` with countdown timer
  - Add provider: `sleepTimerProvider` (remaining time, active state)
  - Add UI: timer picker dialog accessible from Now Playing screen
  - On expiry: pause playback (optionally after current track finishes, per setting)
  - Show countdown indicator in mini player / now playing
- **Files affected:**
  - `lib/services/sleep_timer_service.dart` (new)
  - `lib/providers/service_providers.dart`
  - `lib/ui/screens/now_playing_screen.dart`
  - `lib/ui/widgets/mini_player.dart`

### [x] 6. Remember Last Playback Position
- **Complexity:** 🟩 S
- **Description:** `rememberLastPositionProvider` toggle exists. Queue restore loads the correct song but position is lost.
- **What to do:**
  - Save current position to `_queueBox` periodically (every 5s or on pause/stop)
  - On `_restoreQueue`, seek to saved position after loading song
  - Respect the toggle
- **Files affected:**
  - `lib/services/audio_service.dart` (`_saveQueue`, `_restoreQueue`)

### [ ] 7. Crossfade Between Tracks
- **Complexity:** 🟥 L
- **Description:** `crossfadeDurationProvider` is persisted but `AudioService` does a hard cut. Crossfade requires pre-loading the next track.
- **What to do:**
  - Add a second `AudioPlayer` instance for crossfade
  - Near end of current track (duration - crossfade seconds), start fading out current + fading in next
  - Swap players after transition
  - Respect the duration setting (0 = disabled)
- **Files affected:**
  - `lib/services/audio_service.dart` (significant changes)
  - `lib/main.dart` (pass setting on init)

### [ ] 8. Gapless Playback
- **Complexity:** 🟧 M
- **Description:** `gaplessPlaybackProvider` is stored but never used. Currently uses single-track loading.
- **What to do:**
  - When enabled, use `ConcatenatingAudioSource` from `just_audio` to pre-buffer the next track
  - When disabled, use current single-track behavior
  - Respect the toggle
- **Files affected:**
  - `lib/services/audio_service.dart`

---

## 🟡 P2 — Medium Priority

### [x] 9. Lockscreen Album Art
- **Complexity:** 🟦 XS (once #1 is done)
- **Description:** `showAlbumArtOnLockscreenProvider` toggle exists but has no effect since there's no media notification handler.
- **What to do:**
  - After implementing #1, conditionally set `MediaItem.artUri` based on toggle
- **Files affected:**
  - `lib/services/audio_service.dart`
- **Depends on:** #1

### [ ] 10. ReplayGain Volume Normalization
- **Complexity:** 🟥 L
- **Description:** `replayGainProvider` has modes (off/track/album) but no tags are read and no volume adjustment happens.
- **What to do:**
  - Extend `MetadataService` to parse ReplayGain tags (ID3 `TXXX:REPLAYGAIN_TRACK_GAIN`, Vorbis `REPLAYGAIN_TRACK_GAIN`, etc.)
  - Store gain values in `RichMetadata` model
  - Apply volume offset in `AudioService` when loading a track based on mode
- **Files affected:**
  - `lib/data/models/rich_metadata.dart`
  - `lib/services/metadata_service.dart`
  - `lib/services/audio_service.dart`

### [x] 11. Confirm Before Exit
- **Complexity:** 🟩 S
- **Description:** `confirmExitProvider` exists but no back-button or exit interceptor uses it.
- **What to do:**
  - Wrap root widget with `PopScope` (or `WillPopScope` on older Flutter)
  - Show confirmation dialog when `confirmExit` is true and user presses back on home screen
- **Files affected:**
  - `lib/ui/shell/main_shell.dart` or `lib/main.dart`

### [ ] 12. Profile Screen
- **Complexity:** 🟧 M
- **Description:** Route `'/profile'` is defined in `AppRoutes` but no `ProfileScreen` widget exists. Navigating to it would crash.
- **What to do:**
  - Create `ProfileScreen` (listening stats, favorites count, storage used, etc.)
  - OR remove the dead route if not planned
- **Files affected:**
  - `lib/ui/screens/profile_screen.dart` (new) or `lib/core/routes/app_routes.dart` (remove)

### [x] 13. Startup Resume Race Condition
- **Complexity:** 🟩 S
- **Description:** `_applyAudioSettings()` calls `audioService.play()` before `audioService.init()` queue restore may have completed.
- **What to do:**
  - Await `audioService.init()` fully (including `_restoreQueue`) before calling `_applyAudioSettings()`
  - Or add a `Completer` in AudioService that signals when restore is done
- **Files affected:**
  - `lib/main.dart` (`_initializeApp`)
  - `lib/services/audio_service.dart`

---

## 🟢 P3 — Low Priority / Polish

### [x] 14. Keep Shuffle Queue Setting Not Respected
- **Complexity:** 🟦 XS
- **Description:** `keepShuffleQueueProvider` is persisted, but `_restoreQueue` always restores the shuffled order regardless of this flag.
- **What to do:**
  - In `_restoreQueue`, check `keepShuffleQueue` — if false, restore `originalOrder` instead of shuffled `songIds`
- **Files affected:**
  - `lib/services/audio_service.dart` (`_restoreQueue`)

### [x] 15. Grid Column Count Not Wired
- **Complexity:** 🟦 XS
- **Description:** `gridColumnCountProvider` exists but may not be consumed by browse/library grid views.
- **What to do:**
  - Verify and wire `ref.watch(gridColumnCountProvider)` into `GridView.builder` crossAxisCount in browse/library screens
- **Files affected:**
  - `lib/ui/screens/browse_screen.dart`
  - `lib/ui/screens/library_screen.dart`

### [x] 16. Show Track Numbers Setting Not Wired
- **Complexity:** 🟦 XS
- **Description:** `showTrackNumbersProvider` exists but song tiles may not conditionally render track numbers.
- **What to do:**
  - In `SongTile`, conditionally show `song.trackNumber` based on setting
- **Files affected:**
  - `lib/ui/widgets/song_tile.dart`

### [x] 17. Min File Duration Re-filter
- **Complexity:** 🟩 S
- **Description:** Min duration filter only applies during scan. Changing the setting doesn't hide already-scanned short files.
- **What to do:**
  - Option A: Re-scan after setting change (simple)
  - Option B: Filter in `songsProvider` based on setting (real-time but changes library view)
- **Files affected:**
  - `lib/providers/song_providers.dart` or `lib/ui/screens/settings/library_settings_section.dart`

---

## Implementation Dependency Graph

```
#1  Background Playback ──────┐
                               ├──► #9  Lockscreen Album Art
#2  Pause on Disconnect ◄─────┤
#4  Audio Ducking ◄────────────┘ (all use AudioSession listeners)
#3  Auto-Play on Connect ◄─────── (AudioSession + Bluetooth)

#7  Crossfade ─────────────────┐
                               ├──► (choose one approach for audio pipeline)
#8  Gapless Playback ──────────┘

#5  Sleep Timer                    (independent)
#6  Remember Position              (independent)
#10 ReplayGain                     (independent)
#11 Confirm Exit                   (independent)
#13 Startup Race Condition         (independent, quick fix)
#14–17 Minor fixes                 (independent)
```

---

## Quick Wins (< 1 hour each)
- [x] #14 — Fix shuffle queue restore logic
- [x] #15 — Wire grid column count
- [x] #16 — Wire track number visibility
- [x] #9  — Lockscreen art (after #1)
