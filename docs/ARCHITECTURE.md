# Technical Architecture — Zetzy

**Zetzy** uses a clean feature-first layered Flutter architecture backed by **Riverpod 3**, **Drift (SQLite)** for native offline persistence, **SharedPreferences** for settings/web fallback, and **Supabase** for optional cloud synchronization and online multiplayer.

---

## 1. Directory Structure

```text
lib/
├── main.dart                     # App bootstrap, SharedPreferences/LocalStorage/Supabase init
├── app.dart                      # ZetzyApp (theme, locale, lifecycle observer, DynamicIconService)
├── core/
│   ├── constants/
│   │   ├── app_constants.dart    # GameType, DifficultyLevel, SnakeControlMode, BgmMode, ChessPieceSet, AssetPaths
│   │   └── supabase_schema.dart  # Embedded reference SQL & SupabaseConfig (--dart-define)
│   ├── routing/
│   │   └── app_router.dart       # Named routes + deferred loading for heavy game modules on Web
│   ├── services/
│   │   ├── audio_service.dart    # AssetManifest-driven SFX variation & weighted/manual BGM player
│   │   ├── avatar_picker_service.dart # Cross-platform gallery/camera picker
│   │   ├── dynamic_icon_service.dart  # Android/iOS launcher icon easter egg (23:00-05:30 + theme sync)
│   │   ├── haptic_service.dart   # Android MethodChannel Vibrator/VibrationEffect + fallback haptics
│   │   └── wakelock_service.dart # Keep screen awake during active gameplay
│   ├── theme/
│   │   └── zetzy_theme.dart      # ZetzyThemeMode (6 skins), Abyssal Alter Ego, ZetzyPalette, ThemeData
│   ├── utils/
│   │   ├── avatar_compressor.dart# 256x256 square crop & PNG compression
│   │   ├── platform_detector.dart# Current platform identifier & label helpers
│   │   ├── time_formatter.dart   # MM:SS.ms formatting
│   │   └── validation_rules.dart # Username, password, recovery phrase validation
│   └── widgets/
│       ├── anti_cheat_pause_overlay.dart
│       ├── difficulty_selector_sheet.dart
│       ├── game_lifecycle_guard.dart
│       ├── game_timer_badge.dart
│       ├── game_type_icon.dart
│       ├── in_game_settings_sheet.dart
│       ├── platform_badge.dart
│       ├── score_share_card.dart
│       ├── tactile_card.dart
│       ├── user_avatar.dart
│       └── win_result_dialog.dart
├── data/
│   ├── local/
│   │   ├── db_opener*.dart       # Conditional native SQLite vs Web stub DB opener
│   │   ├── local_storage_service.dart # Auto-save slots, local records, offline sync queue
│   │   ├── settings_repository.dart   # AppSettings JSON + SharedPreferences persistence
│   │   └── zetzy_database.dart   # Drift tables & ZetzyDatabase
│   ├── models/                   # AutoSaveSlot, FeedbackEntry, GameRecord, StatsSummary, UserProfile
│   └── remote/
│       └── supabase_service.dart # Auth, profile/account_data sync, leaderboards, matchmaking, feedback
├── features/
│   ├── feedback/                 # FeedbackScreen (player 5-pending limit, 6h edit, admin 20-item load more)
│   ├── games/
│   │   ├── chess/                # chess_matchmaking.dart, chess_controller.dart, chess_screen.dart
│   │   ├── minesweeper/          # minesweeper_engine.dart, minesweeper_controller.dart, minesweeper_screen.dart
│   │   ├── snake/                # snake_controller.dart, snake_screen.dart
│   │   └── sudoku/               # sudoku_engine.dart, sudoku_controller.dart, sudoku_screen.dart
│   ├── home/
│   │   ├── home_screen.dart      # 4-game Bento hub + resume slots + theme-synced Home icon
│   │   ├── game_guide_tutorial.dart        # Slideable visual guide modal (PageView)
│   │   └── game_interactive_tutorial.dart  # Full-screen pause-to-explain interactive tutorial
│   ├── leaderboard/              # Global, My Best (cloud + local merged), and Chess ELO tabs
│   ├── profile/                  # Auth, Avatar, Rank Badges, Theme 2x3 grid, Game Settings, Danger Zone
│   ├── shell/                    # MainShell (BottomNavigationBar on mobile / NavigationRail on >640px)
│   └── statistics/               # StatsSummary dashboard across all 4 games
├── l10n/                         # app_en.arb, app_id.arb & generated AppLocalizations
└── providers/
    └── app_providers.dart        # Central Riverpod providers & controllers
```

---

## 2. State Management (Riverpod 3)

All shared application state is orchestrated in [`lib/providers/app_providers.dart`](file:///Users/umardani/Documents/workspace/zetzy/lib/providers/app_providers.dart):

| Provider | Type | Responsibility |
| :--- | :--- | :--- |
| `settingsProvider` | `NotifierProvider<SettingsNotifier, AppSettings>` | Theme, Abyssal Alter Ego, locale, audio/BGM, haptics, per-game controls, guest fallback progression; triggers debounced `account_data.settings` cloud sync when signed in. |
| `authProvider` | `NotifierProvider<AuthNotifier, UserProfile>` | Restores Supabase session on startup, applies remote `account_data` (`settings` + `stats`), exposes sign-in/register/logout/avatar/role state. |
| `autoSaveSlotsProvider` | `NotifierProvider<AutoSaveSlotsNotifier, Map<GameType, AutoSaveSlot>>` | Manages the 4 independent pause/resume slots. |
| `localRecordsProvider` | `FutureProvider<List<GameRecord>>` | Local match history used for offline stats and guest/offline Personal Best. |
| `statsSummaryProvider` | `Provider<StatsSummary>` | Aggregates local records + cloud `account_data.stats` (`totalPlayed`, `wins`, `totalXp`, per-game counters & bests). |
| `scoreSyncControllerProvider` | `Provider<ScoreSyncController>` | Listens to `connectivity_plus`, records wins/games locally, queues offline scores, and flushes to Supabase `game_records` + `profiles`. |
| `pendingQueueCountProvider` | `FutureProvider<int>` | Exposes unsynced offline score count shown on Home/Stats. |

---

## 3. Navigation & Web Deferred Loading

[`AppRouter`](file:///Users/umardani/Documents/workspace/zetzy/lib/core/routing/app_router.dart) supports deep-linked routes (`/`, `/play`, `/leaderboard`, `/stats`, `/profile`, `/feedback`, `/sudoku`, `/chess`, `/minesweeper`, `/snake`) including optional query parameters (e.g. `level=3&practice=1`).

The 4 game screens are imported using Dart **`deferred as`** libraries (`sudoku_lib`, `chess_lib`, `minesweeper_lib`, `snake_lib`) wrapped in `_DeferredGameScreen` (`FutureBuilder` + loading indicator) so Web builds split heavy game chunks and keep initial load fast.

---

## 4. Performance, Isolates & Platform Services

- **Isolates**: Sudoku generation (`SudokuEngine`) and Chess AI Alpha-Beta + Quiescence search run off the main UI isolate so animations and timers remain smooth at 60+ FPS.
- **Anti-Cheat Lifecycle Guard (`GameLifecycleGuard` + `AntiCheatPauseOverlay`)**: Observes `WidgetsBindingObserver` (`inactive` / `paused` / `hidden`), immediately pauses active match timers, blurs the board, and manages `WakelockService`.
- **Audio (`AudioService`)**:
  - Parses `AssetManifest` at runtime to discover `assets/audio/mp3/sfx_*` variations and `assets/audio/mp3/bgm/1..9.mp3`.
  - Defers Web BGM autoplay until the first pointer/keyboard interaction (`notifyUserInteraction`) to comply with browser autoplay policies.
- **Dynamic Launcher Icon (`DynamicIconService`)**:
  - Runs **only** on Android & iOS (`flutter_dynamic_icon_plus`).
  - Evaluates local time (`23:00–05:30` → `abyssal_cyan0`; daytime → active theme icon) on app start, lifecycle transitions (`resumed`/`paused`), and theme updates, skipping redundant OS calls if already applied.
- **Native Android Haptics (`HapticService`)**: Invokes `Vibrator` / `VibrationEffect` via `MethodChannel` with intensity scaling (`light`, `medium`, `strong`), falling back cleanly to `HapticFeedback` on other platforms.
- **Localization (`l10n`)**: Configured via `l10n.yaml` (`app_en.arb` template + `app_id.arb`). All UI strings, visual guides, and interactive tutorials use `AppLocalizations` with zero hardcoded locale branches.
