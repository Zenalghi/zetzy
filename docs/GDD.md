# Game Design Document (GDD) — Zetzy

**Zetzy** (`v0.0.7+1`) is a cross-platform tactile minimalist strategy and arcade suite combining **Sudoku**, **Chess**, **Minesweeper**, and **Snake** with shared progression, bilingual UI (`en` / `id`), visual guides, and interactive tutorials.

---

## 1. Core Progression, Tiers & Modes

### 1.1 Difficulty Tiers (`DifficultyLevel`)

| Level | Name | XP Reward (Win) | Unlock Condition |
| :---: | :--- | :---: | :--- |
| `1` | **Chill** | `+10 XP` | Unlocked by default |
| `2` | **Easy** | `+25 XP` | Unlocked by default |
| `3` | **Normal** | `+50 XP` | Unlocked by default |
| `4` | **High** | `+100 XP` | Unlocked by default |
| `5` | **PRO** | `+175 XP` | Unlocked by default |
| `6` | **Nightmare** | `+300 XP` | Win Level 5 (`PRO`) in that game |
| `7` | **Are U a God?** | `+500 XP` | Win Level 6 (`Nightmare`) in that game |

- Progression is tracked **per game** (`unlocked_levels` map keyed by `sudoku`, `chess`, `minesweeper`, `snake`).
- Rank badges (`assets/images/badge/1.png` – `7.png`) represent tier mastery and are showcased on **Profile** (with a `160 px` enlarged modal) and **WinResultDialog**.

### 1.2 Ranked vs. Practice Mode
- **Ranked Match**: Timers run continuously (pauses only on background/focus loss via `AntiCheatPauseOverlay` or Quick Settings). Wins award XP, unlock higher tiers, update Personal Best / Global Leaderboards (`duration_ms >= 3000` enforced by server RLS), and update Chess ELO (`vsAi` & `Find Match`).
- **Practice Mode (`isPractice = true`)**: Unrated (does not submit to Global Leaderboards, does not unlock tiers, and does not change Chess ELO). Enables **Practice Undo** (in Sudoku, Minesweeper, Chess) and **Practice Rewind on Loss (`1–3` steps)** via `WinResultDialog`.

### 1.3 Onboarding: Visual Guide & Pause-to-Explain Tutorial
Every Home game card includes a **Guide & Tutorial** button above **Play / Continue**:
1. **Slideable Visual Guide (`showGameGuideModal`)**: Multi-slide `PageView` with game-accurate illustrations and concise rules (`4` slides for Sudoku, Minesweeper, Snake; `5` slides for Chess including **Stalemate vs Checkmate**, **Castling**, **En Passant**, and **Promotion**).
2. **Interactive In-Game Tutorial (`GameInteractiveTutorialScreen`)**: Full-screen layout mirroring the active game board and controls. Each step opens **Paused (`⏸️`)** with a coach explanation, then switches to **Your Turn (`👆`)** and highlights the exact target cell/button with a pulsing accent glow (`_Blink`) until completed.

---

## 2. Game Specifications

### 2.1 Sudoku
- **Grid**: Standard `9×9` divided into `3×3` sub-boxes.
- **Generation**:
  - Levels `1–6`: Real-time Dart Isolate generator (`SudokuEngine`) removing clues according to difficulty while verifying unique solvability.
  - Level `7` (`Are U a God?`): Verified 17-clue master seeds transformed via mathematical isomorphisms (digit permutation, row/col band swaps, transposition).
- **Controls & Mechanics**:
  - **Select Cell → Tap `1–9` Keypad** (or long-press digit to lock digit-first input; keyboard `1–9`, arrows, `Backspace` supported).
  - **Notes Mode (`✏️`)**: Pencil candidates in cells without risking lives; includes **Smart Notes** auto-pruning on Beginner/Practice and dedicated notes-only Undo.
  - **Correct Cell Lock**: On Levels `1–4`, correctly placed digits lock automatically.
  - **Auto-Finish (`⚡`)**: Appears when remaining empty cells `<= sudokuAutoFinishThreshold` (`5` or `7`, configurable) to fill obvious remaining cells.
  - **Streak & Accuracy HUD**: Optional live streak and accuracy indicators.
- **Win / Loss**:
  - **Lives**: `3` hearts (`♥`). Conflicts/mistakes flash red and deduct `1` life (`0` lives = Loss).
  - **Win**: All `81` cells filled accurately. Ranked score/duration ranked primarily by fastest `duration_ms`.

### 2.2 Minesweeper
- **Grid**: Dynamic grid dimensions & mine counts scaled across Levels `1–7`.
- **Complexity Metric**: Calculates real-time **3BV** (*Bechtel's Board Benchmark Value*) for each generated board.
- **Controls & Mechanics**:
  - **Safe First Tap**: First dig is guaranteed safe and triggers flood-fill on `0`-mine regions.
  - **Input Modes**: Bottom `SegmentedButton` switches between **Dig (`⛏️`)**, **Flag (`🚩`)**, and **Mark (`?`)**, plus **1-Tap Swap** toggle (`minesweeperSwapTapFlag`) and desktop right-click / long-press flagging.
  - **Chording**: Tapping a revealed number surrounded by the exact matching number of flags opens all remaining unflagged neighbors (`minesweeperQuickChord`).
  - **Interactive Zoom/Pan**: `InteractiveViewer` (`0.65× – 3.2×`) for large boards.
  - **Defuse Shield (`🛡️`)**: Available on Beginner Levels `1–2` (`1×` automatic mine disarm on accidental mine tap).
- **Win / Loss**:
  - **Win**: All non-mine tiles revealed. Ranked primarily by fastest `duration_ms`.
  - **Loss**: Tapping an unshielded mine without shield remaining; post-game review reveals all mines and marks misplaced flags (`❌`).

### 2.3 Chess
- **Engine & AI**: Legal move generation & validation via `bishop`; Isolate-backed Alpha-Beta + Quiescence search AI scaled across Levels `1–7`.
- **Piece Sets**: 3 bundled SVG sets (`cburnett`, `cburnett-v2` default, `tatiana`).
- **4 Play Modes**:
  1. **Vs AI (Ranked)**: Affects ELO and unlocks tiers.
  2. **Pass & Play**: Local 2-player on one device (unrated; optional auto-flip board per turn).
  3. **Friend Room (Online)**: 6-character room code via Supabase Realtime Broadcast (`chess_rooms`).
  4. **Find Match (Rated ELO Matchmaking)**: Expanding ELO search window (`chess_matchmaking_queue`, clamping `400..3500`, forced nearest match after `45s`). Resigning before `4` half-moves aborts cleanly without rating penalty; resigning at `>= 4` half-moves counts as rated loss.
- **Controls & Special Rules**:
  - Tap piece → legal target dots (`p.accent`) & capture rings (`p.danger`).
  - Full support for **Castling**, **En Passant**, and **Pawn Promotion** (auto-Queen toggle or modal chooser).
  - **Touch Move Confirmation** (`off`, `fastOnly`, `always`), **Board Flip**, **PGN Move List**, and **Post-Game Move Scrubber** (`⏮ ◀ ▶ ⏭`).
- **Win / Loss / Draw**:
  - Checkmate, resignation, or timeout = Win/Loss.
  - Stalemate, 3-fold repetition, 50-move rule, or insufficient material = Draw.

### 2.4 Snake
- **Arena**: Grid-based arena with smooth interpolation and **2-Step Input Queue** (prevents accidental `180°` self-collisions on rapid turns).
- **3 Touch Control Modes** (plus Keyboard Arrow/WASD):
  1. **Swipe Gesture**: Directional swipes anywhere on the arena.
  2. **Virtual D-Pad**: On-screen directional pad.
  3. **Split-Screen Tap**: Left half turns counter-clockwise `90°`; right half turns clockwise `90°`.
- **Arena Items & Hazards**:
  - **Red Apple (`+10 pts`)**: Core food; grows tail and advances score.
  - **Golden Bonus (`+30 pts`)**: Timed high-value bonus item.
  - **Scissors (`✂️`)**: Trims snake tail shorter for breathing room.
  - **Poison (`☠️`)**: Hazard item; triggers penalty/danger.
  - **Brick Walls (`🧱`)**: Dynamic internal obstacles on higher tiers.
  - **Starvation Bar**: Active on Levels `6–7`; drains over time and refills when eating food.
- **Win / Loss**:
  - **Score & Duration**: Ranked on Snake leaderboards by highest `score` (tie-broken by `duration_ms`).
  - **Crash**: Hitting outer boundary, brick wall, or own body ends match (Practice Mode supports `1–3` step Rewind & Continue).

---

## 3. Themes, Audio & Easter Egg Systems

- **6 Visual Themes** (`ZetzyThemeMode`):
  - Dark: **OLED Midnight**, **Classic Wood & Slate**, **Dracula Neon**, **Abyssal Cyan** (double-tapping switches to monochrome dark-cyan **Alter Ego** palette).
  - Light: **Nordic Frost**, **Warm Parchment**.
- **BGM (`9` Tracks) & SFX**:
  - Modes: `Off`, `Auto` (weighted shuffle giving `3×` priority to user-selected favorite track, default Track `5`), and `Manual` (loop chosen track `1–9`).
- **Dynamic Launcher Icon Easter Egg (Android & iOS Only)**:
  - Between **`23:00 – 05:30`** local time, the mobile launcher icon silently changes to `abyssal_cyan0`.
  - Outside `23:00 – 05:30`, it mirrors the active theme skin (and Abyssal Alter Ego), defaulting to `warm_parchment` (`null` / `.DEFAULT`).
  - Web, macOS, Windows, and Linux use the static `warm_parchment.jpeg` icon.
