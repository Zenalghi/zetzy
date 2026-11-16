# Development Roadmap — Zetzy

This roadmap tracks Zetzy's progression from initial MVP through completed production enhancements and future backlog items.

---

## Phase 1 — Core Foundation & MVP ✅
- [x] Project scaffolding with Flutter, Riverpod 3, and `ZetzyPalette` theme engine.
- [x] Offline-first persistence layer (`Drift` SQLite on native + `SharedPreferences` JSON fallback on Web).
- [x] 4 independent auto-save slots (`AutoSaveSlots`) and offline score sync queue (`OfflineScoreQueue`).
- [x] Core pure-Dart / Isolate game engines & UI for **Sudoku**, **Chess** (`bishop`), **Minesweeper**, and **Snake**.
- [x] 7-tier difficulty progression (`Chill` → `Are U a God?`) + unrated **Practice Mode**.
- [x] Responsive navigation shell (`BottomNavigationBar` on mobile, `NavigationRail` on tablet/desktop).

## Phase 2 — Gameplay Depth & Polish ✅
- [x] **Sudoku**: Level 7 verified 17-clue isomorphism generator, Notes-only Undo, Smart Notes, digit lock, Auto-Finish (`5` or `7` empty cells), Streak/Accuracy HUD.
- [x] **Minesweeper**: Safe first tap, real-time 3BV calculation, Lv. 1–2 Defuse Shield (`🛡️`), Chording, 1-Tap Swap (`Dig ⇄ Flag`), zoom/pan `InteractiveViewer`.
- [x] **Chess**: 3 SVG piece sets (`cburnett`, `cburnett-v2` default, `tatiana`), Pass & Play + auto-flip, Touch Move Confirmation (`off / fastOnly / always`), PGN list, Post-game move scrubber.
- [x] **Snake**: 2-step input queue, 3 touch modes (`Swipe`, `D-Pad`, `Split Tap`), Golden Apple / Scissors / Poison / Brick Walls, Lv. 6–7 Starvation Bar.
- [x] **Practice Rewind & Post-Game Review**: `1–3` step Rewind on Loss + *View Board / View Result* inspection across all games.
- [x] **Audio & Haptics**: Runtime `AssetManifest` SFX variation discovery, 9 BGM tracks (`Off / Auto 3× favorite / Manual`), native Android `Vibrator` intensity (`Light / Medium / Strong`).

## Phase 3 — Cloud, Multiplayer & Community ✅
- [x] **Supabase Integration**: Username-only Auth, SHA-256 recovery phrase password reset RPC, `256×256` PNG avatar compression & Storage upload.
- [x] **Leaderboards**: Paginated Global (`20` + `Load More 10`), Chess ELO rankings, and cross-device **My Best** cloud + local merge.
- [x] **Cross-Device Account Sync**: `profiles.account_data` JSONB syncing all Profile settings and Statistics XP/totals across devices.
- [x] **Online Chess**: 6-character Friend Rooms (Supabase Realtime Broadcast) + Rated `Find Match` ELO queue with expanding search window & anti-abort fairness (`< 4` half-moves).
- [x] **Feedback & Admin Moderation**: Dedicated `FeedbackScreen` with 5-pending cap, 6-hour edit lock, delete anytime, `Admin` role inbox (`Load More 20`), 1× reply/decision, and 3-day auto-expiry.

## Phase 4 — Onboarding, Aesthetics & CI/CD ✅
- [x] **6 Visual Themes**: Added *Abyssal Cyan* (with double-tap monochrome **Alter Ego**) and *Warm Parchment*.
- [x] **Bilingual `l10n`**: Full English (`en`) and Bahasa Indonesia (`id`) ARB coverage (`app_en.arb`, `app_id.arb`).
- [x] **Visual Guide & Interactive Tutorial**: Slideable illustrated rules + full-screen in-game pause-to-explain interactive tutorials for all 4 games.
- [x] **Dynamic Launcher Icon Easter Egg**: Android & iOS dynamic launcher icon (`flutter_dynamic_icon_plus`: `23:00–05:30` → `abyssal_cyan0`, daytime → active theme), static `warm_parchment` icon for Web & Desktop.
- [x] **CI/CD & Deployment**: GitHub Actions tag-validated builds for Android, Web (GitHub Pages), Windows, Linux, and GHCR Docker container (`docs/docker.md`).

## Phase 5 — Upcoming Backlog & Future Enhancements 🚀
- [ ] **Daily Challenge Mode**: Seeded daily Sudoku & Minesweeper boards with shared daily leaderboard.
- [ ] **In-App Achievement / Trophy System**: Unlockable milestones beyond rank tiers (e.g. Zero-Mistake Sudoku, Sub-30s Minesweeper, 5-Win Chess Streak).
- [ ] **Tournament / Custom Time-Control Lobby**: Configurable Blitz/Rapid presets (`3+2`, `5+0`, `10+0`) in Chess Friend Rooms.
- [ ] **Automated Integration Tests**: End-to-end `integration_test` flows on Android/iOS emulators and Web headless Chrome.
- [ ] **Store Release Prep**: Signed Android App Bundle (`.aab`) Play Store metadata and iOS App Store provisioning/screenshots.
