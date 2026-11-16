# Data & Storage Schema — Zetzy

Zetzy is **offline-first**: all settings, active game saves, match history, and pending score uploads work locally without an internet connection, and seamlessly synchronize with **Supabase (PostgreSQL + Storage + Realtime)** when signed in.

---

## 1. Local Storage

### 1.1 `SharedPreferences` (`SettingsRepository`)
Persisted as primitive keys in [`lib/data/local/settings_repository.dart`](file:///Users/umardani/Documents/workspace/zetzy/lib/data/local/settings_repository.dart) and mirrored into `profiles.account_data.settings` JSON when authenticated:

| Key | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `zetzy_theme` | `String` | `'oled_midnight'` | `ZetzyThemeMode.id` |
| `zetzy_abyssal_alter_ego` | `bool` | `false` | Toggles monochrome dark-cyan Abyssal Alter Ego |
| `zetzy_locale` | `String` | `'en'` | `'en'` or `'id'` |
| `zetzy_sfx` | `bool` | `true` | Sound effects enabled |
| `zetzy_bgm` | `bool` | `true` | Legacy/master BGM flag |
| `zetzy_bgm_mode` | `String` | `'auto'` | `'off'`, `'auto'`, `'manual'` |
| `zetzy_bgm_track` | `String` | `'1.mp3'` | Selected manual BGM filename |
| `zetzy_bgm_favorite_track` | `String` | `'5.mp3'` | 3× weighted favorite BGM in `auto` mode |
| `zetzy_haptics` | `bool` | `true` | Haptic feedback toggle |
| `zetzy_haptic_intensity` | `String` | `'medium'` | `'light'`, `'medium'`, `'strong'` |
| `zetzy_wakelock` | `bool` | `true` | Keep screen awake in-game |
| `zetzy_snake_ctrl` | `String` | `'swipe'` | `'swipe'`, `'dpad'`, `'splitTap'` |
| `zetzy_snake_grid` | `bool` | `true` | Show grid lines in Snake arena |
| `zetzy_snake_assist_overlay` | `bool` | `true` | Hazard/assist overlay |
| `zetzy_chess_pieces` | `String` | `'cburnett-v2'` | `'cburnett'`, `'cburnett-v2'`, `'tatiana'` |
| `zetzy_chess_auto_queen` | `bool` | `true` | Auto-promote pawns to Queen |
| `zetzy_chess_legal_moves` | `bool` | `true` | Show legal target dots/rings |
| `zetzy_chess_coordinates` | `bool` | `true` | Show `a–h` / `1–8` board labels |
| `zetzy_chess_move_confirm` | `String` | `'fastOnly'` | `'off'`, `'fastOnly'`, `'always'` |
| `zetzy_chess_auto_flip_pass_play` | `bool` | `false` | Auto-rotate board in Pass & Play |
| `zetzy_sudoku_auto_finish` | `bool` | `true` | Enable Auto-Finish button |
| `zetzy_sudoku_auto_finish_threshold` | `int` | `5` | Trigger threshold (`5` or `7` empty cells) |
| `zetzy_sudoku_highlight_same` | `bool` | `true` | Highlight matching digits on board |
| `zetzy_sudoku_auto_clear_notes` | `bool` | `true` | Auto-remove conflicting notes on fill |
| `zetzy_sudoku_streak_stats` | `bool` | `true` | Show Streak & Accuracy HUD |
| `zetzy_sudoku_smart_notes` | `bool` | `true` | Show Smart Notes candidate helper |
| `zetzy_minesweeper_quick_chord` | `bool` | `true` | Tap revealed number to chord neighbors |
| `zetzy_minesweeper_swap_tap_flag` | `bool` | `false` | 1-Tap Swap (`Dig` ⇄ `Flag`) |
| `zetzy_practice_rewind_on_loss` | `bool` | `true` | Show Rewind & Continue on Practice loss |
| `zetzy_practice_rewind_steps` | `int` | `3` | Rewind step count (`1–3`) |
| `zetzy_guest_elo` | `int` | `1200` | Offline/guest Chess ELO |
| `zetzy_guest_unlocked` | `String` (JSON) | `{all: 5}` | Per-game unlocked tier map for guest mode |

### 1.2 Drift SQLite (`ZetzyDatabase`) & Web Fallback (`LocalStorageService`)
Defined in [`lib/data/local/zetzy_database.dart`](file:///Users/umardani/Documents/workspace/zetzy/lib/data/local/zetzy_database.dart) (`schemaVersion = 1`). On Web, `LocalStorageService` automatically uses JSON lists/maps in `SharedPreferences`.

1. **`AutoSaveSlots`** (Primary Key: `gameType`)
   - `gameType` (`text`), `difficulty` (`integer`), `elapsedMs` (`integer`), `stateJson` (`text`), `updatedAt` (`dateTime`).
   - Maintains 4 independent resume slots (one per game).
2. **`OfflineScoreQueue`** (Primary Key: `id`)
   - `id`, `userId`, `gameType`, `difficulty`, `isWon`, `score`, `durationMs`, `platform`, `metadataJson`, `playedAt`.
   - Queued when offline or guest; flushed automatically to Supabase `game_records` upon reconnect/sign-in.
3. **`LocalGameRecords`** (Primary Key: `id`)
   - `id`, `userId`, `username`, `gameType`, `difficulty`, `isWon`, `score`, `durationMs`, `platform`, `metadataJson`, `playedAt`.
   - Powers offline Statistics and Guest/Offline **My Best**.

---

## 2. Cloud Database — Supabase (PostgreSQL)

Full SQL setup & RLS policies live in [`docs/supabase-setup.md`](file:///Users/umardani/Documents/workspace/zetzy/docs/supabase-setup.md) and [`lib/core/constants/supabase_schema.dart`](file:///Users/umardani/Documents/workspace/zetzy/lib/core/constants/supabase_schema.dart).

### 2.1 `public.profiles`
| Column | Type | Notes |
| :--- | :--- | :--- |
| `id` | `uuid` (PK, FK `auth.users`) | User UUID |
| `username` | `text` (UNIQUE) | `3–20` chars (`^[a-zA-Z0-9_]+$`) |
| `role` | `text` (`'player'` \| `'admin'`) | Default `'player'`; editable via Supabase Table Editor |
| `recovery_hash` | `text` | SHA-256 hash of user's recovery phrase |
| `avatar_url` | `text` | Public URL in `avatars` bucket (`256×256` PNG) |
| `chess_elo` | `integer` | Default `1200` |
| `unlocked_levels` | `jsonb` | `{"sudoku":5,"chess":5,"minesweeper":5,"snake":5}` |
| `account_data` | `jsonb` | Cross-device snapshot: `{ "settings": {...}, "stats": {...} }` |
| `updated_at` | `timestamptz` | Auto-updated timestamp |

### 2.2 `public.game_records`
| Column | Type | Notes |
| :--- | :--- | :--- |
| `id` | `text` / `uuid` (PK) | Match record ID |
| `user_id` | `uuid` (FK `profiles.id`) | Owner |
| `game_type` | `text` | `'sudoku' \| 'chess' \| 'minesweeper' \| 'snake'` |
| `difficulty` | `integer` | `1..7` |
| `is_won` | `boolean` | Win flag |
| `score` | `integer` | Match score (Snake/Chess/XP) |
| `duration_ms` | `integer` | Anti-cheat constraint: `>= 3000` |
| `platform` | `text` | `'android' \| 'ios' \| 'web' \| 'windows' \| 'macos' \| 'linux'` |
| `metadata` | `jsonb` | e.g. `{"mode": "vsAi"}`, `3bv`, etc. |
| `played_at` | `timestamptz` | Completion timestamp |

### 2.3 Online Chess Tables
- **`public.chess_rooms`**: `code` (PK, 6-char), `host_id`, `guest_id`, `status` (`waiting | playing | finished`), `created_at`. Paired with Supabase Realtime Broadcast channel `chess_room:<code>`.
- **`public.chess_matchmaking_queue`**: `user_id` (PK), `username`, `chess_elo`, `time_control_sec`, `status`, `room_code`, `updated_at`.

### 2.4 `public.feedbacks`
| Column | Type | Notes |
| :--- | :--- | :--- |
| `id` | `uuid` (PK) | Feedback UUID |
| `user_id` | `uuid` (FK `profiles.id`) | Author (RLS: visible only to owner + `role = 'admin'`) |
| `username` | `text` | Cached display username |
| `app_version` | `text` | e.g. `0.0.7` (tracks version reported from) |
| `message` | `text` | Editable by owner only within **6 hours** of `created_at`; deletable anytime |
| `status` | `text` | `'pending' \| 'approved' \| 'rejected'` (max `5` pending per user enforced by RLS/app) |
| `admin_reply` | `text` | 1× reply written when Admin approves/rejects |
| `reviewed_by` | `uuid` | Admin UUID |
| `reviewed_at` | `timestamptz` | Auto-expires & deletes after **3 days** (`reviewed_at + interval '3 days'`) |
| `created_at` / `updated_at` | `timestamptz` | Timestamps |

---

## 3. Cross-Device Cloud Sync Strategy

1. **Settings & Stats (`profiles.account_data`)**:
   - On sign-in / app restore (`AuthNotifier`), remote `account_data.settings` updates `SettingsNotifier`, and `account_data.stats` merges into `statsSummaryProvider` so XP, total played, wins, and profile preferences follow the user across devices.
2. **Personal Best (`LeaderboardScreen` — "My Best" tab)**:
   - Rather than duplicating full match arrays into `profiles.account_data`, signed-in users fetch their own rows directly from `public.game_records` (`SupabaseService.fetchMyBestRecords(userId: ...)` with pagination + pull-to-refresh) and deduplicate/merge with any local offline records by `id`.
