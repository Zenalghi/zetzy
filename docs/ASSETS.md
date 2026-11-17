# Assets & Audio Guide — Zetzy

All bundled assets are declared in [`pubspec.yaml`](file:///Users/umardani/Documents/workspace/zetzy/pubspec.yaml) and referenced through [`AssetPaths`](file:///Users/umardani/Documents/workspace/zetzy/lib/core/constants/app_constants.dart) or discovered dynamically at runtime via `AssetManifest`.

---

## 1. Visual Assets Inventory

### 1.1 App & Theme Icons (`assets/images/icons/`)
Used dynamically on Home & NavigationRail (`AssetPaths.themeAppIcon(...)`) and for launcher icons:

| File | Usage |
| :--- | :--- |
| `oled_midnight.jpeg` | Home/Rail icon & mobile launcher alias `.oled_midnight` |
| `classic_wood.jpeg` | Home/Rail icon & mobile launcher alias `.classic_wood` |
| `nordic_frost.jpeg` | Home/Rail icon & mobile launcher alias `.nordic_frost` |
| `dracula_neon.jpeg` | Home/Rail icon & mobile launcher alias `.dracula_neon` |
| `abyssal_cyan0.jpeg` | Home/Rail icon (normal), mobile alias `.abyssal_cyan0`, & **Night Easter Egg (`23:00–05:30`)** |
| `abyssal_cyan1.jpeg` | Home/Rail icon (Abyssal Alter Ego) & mobile alias `.abyssal_cyan1` |
| `warm_parchment.jpeg` | Home/Rail icon, **static launcher icon** (Web/macOS/Windows/Linux), & mobile `.DEFAULT` |
| `ico.jpeg` | Legacy fallback icon retained in `assets/images/icons/` |

#### Native Mobile Launcher Icon Assets (`flutter_dynamic_icon_plus`)
- **Android** (`android/app/src/main/res/mipmap-{mdpi,hdpi,xhdpi,xxhdpi,xxxhdpi}/`):
  - `ic_launcher.png` (default `warm_parchment`)
  - `ic_launcher_<variant>.png` (`48`, `72`, `96`, `144`, `192` px) for all 6 alternate `<activity-alias>` entries in [`AndroidManifest.xml`](file:///Users/umardani/Documents/workspace/zetzy/android/app/src/main/AndroidManifest.xml).
- **iOS** (`ios/Runner/Assets.xcassets/`):
  - `AppIcon.appiconset` (default `warm_parchment`)
  - `<variant>.appiconset` (`1024×1024` opaque PNGs) registered via `ASSETCATALOG_COMPILER_ALTERATE_APPICON_NAMES` in [`project.pbxproj`](file:///Users/umardani/Documents/workspace/zetzy/ios/Runner.xcodeproj/project.pbxproj).

### 1.2 Rank Badges (`assets/images/badge/`)
Pixel-art medals rendered with `FilterQuality.none` for crisp edges (`18px` chips, `56px` selector preview, `92px` WinResultDialog, `160px` Profile zoom modal):
- `1.png` (`Chill`) → `2.png` (`Easy`) → `3.png` (`Normal`) → `4.png` (`High`) → `5.png` (`PRO`) → `6.png` (`Nightmare`) → `7.png` (`Are U a God?`)

### 1.3 Minesweeper Sprites (`assets/images/minesweeper/`)
- `mine_normal.png`, `mine_exploded.png`, `mine_defused.png`, `flag.png`, `question_mark.png`, `shield_icon.png`

### 1.4 Snake Sprites (`assets/images/snake/`)
- `food_apple.png` (`+10 pts`), `food_golden.png` (`+30 pts`), `item_scissors.png` (tail trim), `item_poison.png` (hazard), `wall_brick.png` (obstacle)

### 1.5 Chess Piece SVG Sets (`assets/icons/chess/`)
Three selectable styles (`ChessPieceSet`):
- `cburnett/`
- `cburnett-v2/` *(default)*
- `tatiana/`

Each folder **must** contain all `12` piece SVGs named `{color}{piece}.svg` where `color` ∈ `{w, b}` and `piece` ∈ `{K, Q, R, B, N, P}` (e.g., `wK.svg`, `bP.svg`).

### 1.6 Platform Badges (`assets/icons/platforms/`)
- `ic_platform_android.svg`, `ic_platform_ios.svg`, `ic_platform_web.svg`, `ic_platform_windows.svg`, `ic_platform_macos.svg`, `ic_platform_linux.svg`

---

## 2. Audio Assets & Naming Rules (`assets/audio/mp3/`)

[`AudioService`](file:///Users/umardani/Documents/workspace/zetzy/lib/core/services/audio_service.dart) reads `AssetManifest` at runtime so variations are auto-discovered without hardcoding counts.

### 2.1 Background Music (`assets/audio/mp3/bgm/`)
- Files: `1.mp3` through `9.mp3` (`9` tracks).
- Naming rule: sequential integers `N.mp3`. Adding `10.mp3` automatically surfaces `Track 10` in Profile & Quick Settings.

### 2.2 Sound Effects (`assets/audio/mp3/`)
Naming rule: `<prefix><1..N>.mp3`. `AudioService` picks a random variation without repeating the previous index consecutively:

| Prefix | Files Present | Trigger |
| :--- | :--- | :--- |
| `sfx_ui_click` | `1{a–d}..4{a–d}.mp3` | Navigation & UI taps (4 hidden sound packs `1–4` cycled by re-tapping the active theme; random `a–d` within pack) |
| `sfx_sudoku_tap` | `1–6.mp3` | Digit placement / notes / hint (randomized without back-to-back repeats) |
| `sfx_sudoku_line` | `1–4.mp3` | Row / column / box completion |
| `sfx_sudoku_autofill` | `1–3.mp3` | Auto-Finish sequence |
| `sfx_error_buzz` | `1–4.mp3` | Invalid Sudoku input / Snake poison |
| `sfx_chess_move` | `1–4.mp3` | Legal piece move |
| `sfx_chess_capture` | `1–4.mp3` | Piece capture |
| `sfx_chess_check` | `1–4.mp3` | King in Check |
| `sfx_mine_dig` | `1–4.mp3` | Tile dig / flood-fill |
| `sfx_mine_flag` | `1–3.mp3` | Flag / `?` toggle |
| `sfx_mine_chord` | `1–4.mp3` | Number chord reveal |
| `sfx_mine_shield` | `1–3.mp3` | Defuse Shield save |
| `sfx_mine_explode` | `1–3.mp3` | Mine detonation |
| `sfx_snake_eat` | `1–3.mp3` | Red apple eaten |
| `sfx_snake_powerup` | `1–3.mp3` | Golden apple / Scissors |
| `sfx_snake_warning` | `1–4.mp3` | Low starvation timer warning |
| `sfx_game_win` | `1–4.mp3` | Match victory (+ Confetti) |
| `sfx_game_lose` | `1–4.mp3` | Match loss |
| `sfx_match_found` | `1–4.mp3` | Online Chess match found |
| `sfx_undo_rewind` | `1.mp3` | Practice Undo / Rewind |

---

## 3. Typography (`assets/fonts/`)

- **UI Font (`PlusJakartaSans`)**: `assets/fonts/Plus_Jakarta_Sans/` (`PlusJakartaSans-VariableFont_wght.ttf` + Italic).
- **Tabular Monospace (`JetBrainsMono`)**: `assets/fonts/JetBrainsMono-2.304/` for timers, Sudoku digits, Minesweeper counts, ELO, and scores so numbers never jitter when ticking.

---

## 4. Screen Ratios & Asset Guidelines

- **Responsive Breakpoint**: `MainShell` switches between `BottomNavigationBar` (`width <= 640px`) and `NavigationRail` (`width > 640px`). Game screens adapt between Portrait (HUD top, board center, controls bottom) and Landscape/Desktop (board left, controls & sidebar right).
- **Regenerating Static Launcher Icons**: After replacing `assets/images/icons/warm_parchment.jpeg`, run `dart run flutter_launcher_icons`.
