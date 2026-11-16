# MASTER PRODUCT REQUIREMENTS DOCUMENT (PRD)

**Project Name:** Zetzy
**Current Version:** Follow `pubspec.yaml` (`0.0.7+1`, ditampilkan di Profil sebagai `Zetzy v0.0.7`)
**Target Platforms:** Android, iOS, Web, Desktop (Windows, macOS, & Linux)
**Framework & Stack:** Flutter (Riverpod) + Drift (SQLite Local) + Supabase (Cloud Backend, Auth, Storage, RPC & Realtime)

Dokumen ini merupakan kompilasi **75 keputusan dasar** (dari [list-kustomisasi.md](file:///Users/umardani/Documents/workspace/zetzy/docs/list-kustomisasi.md)) yang telah diperbarui agar selaras penuh dengan **fitur gameplay lanjutan, efek visual, pengaturan mid-game, sistem matchmaking/anti-cheat, Panduan Visual & Tutorial Interaktif, Feedback & Role Admin, Easter Egg Icon Dinamis Android/iOS, serta daftar lengkap asset & SFX `.mp3`** dalam implementasi **Zetzy** saat ini.

> Lihat pula dokumentasi pendamping di `docs/`: [GDD.md](file:///Users/umardani/Documents/workspace/zetzy/docs/GDD.md), [ARCHITECTURE.md](file:///Users/umardani/Documents/workspace/zetzy/docs/ARCHITECTURE.md), [DATA_SCHEMA.md](file:///Users/umardani/Documents/workspace/zetzy/docs/DATA_SCHEMA.md), [ASSETS.md](file:///Users/umardani/Documents/workspace/zetzy/docs/ASSETS.md), dan [ROADMAP.md](file:///Users/umardani/Documents/workspace/zetzy/docs/ROADMAP.md).

---

## 1. Arsitektur UI/UX, Tema, Efek Visual & Pengaturan

### 1.1 Gaya Visual, Tema & Navigasi (Answers: 1C, 2C, 3AD, 4D, 5C, 6B)

* **Visual Style:** **Tactile Modern Minimalist** — memadukan kebersihan desain datar ala Lichess/NYT Games (`3A`) dengan sentuhan kedalaman *Neumorphism/Glassmorphism* halus (`3D`) pada kartu (`TactileCard`), tombol keypad, dan *blur overlay* anti-cheat saat game dijeda.
* **Multi-Theme Engine (`4D`):** Pergantian tema instan (bahkan saat match sedang berjalan) dengan **6 visual skin** (4 gelap, 2 terang):
  1. **OLED Midnight** (Hitam pekat `#0D0D0D`, hemat baterai).
  2. **Classic Wood & Slate** (Nuansa papan kayu hangat).
  3. **Nordic Frost** (Palet biru-abu dingin terang).
  4. **Dracula Neon** (Kontras tinggi ungu/sian).
  5. **Abyssal Cyan** (Campuran hitam pekat `#060A0B` + petrol cyan `#00393D` dengan aksen `#1ECAD6`, serta **Easter Egg Alter Ego** monokrom dark cyan `#001C1C` – `#D9EEEE` saat diketuk ulang).
  6. **Warm Parchment** (Nuansa kertas krem & tinta espresso terang beraksen amber hangat & forest teal).
* **Bilingual (`5C`):** Mendukung **Bahasa Indonesia** dan **Bahasa Inggris** secara penuh (`flutter_localizations` + `AppLocalizations` ARB).
* **Responsive Orientation (`1C`):** Mendukung *Auto-Rotate* (Portrait & Landscape) via `LayoutBuilder`:
  * **Portrait (Mobile):** Papan di tengah, *status HUD* di atas, kontrol/keypad di bawah.
  * **Landscape / Desktop / Web:** Papan di kiri/tengah secara proporsional; kontrol, statistik ringkas, notasi PGN catur, dan tombol aksi berada di *Sidebar* kanan.
* **Navigasi Utama (`6B`):** *Bottom Navigation Bar* (Mobile) atau *Navigation Rail* (Desktop/Web) dengan 4 Tab: **Home (Play)**, **Leaderboard**, **Statistics**, dan **Profile**.

### 1.2 Pengaturan Terstruktur, Quick Settings Mid-Game & Versi Aplikasi

* **Kartu Pengaturan Per-Game di Profile:** Menu Profil mengelompokkan opsi secara rapi ke dalam kartu khusus per game (**Sudoku**, **Chess**, **Minesweeper**, **Snake**), kartu **Practice Mode**, kartu **Preferensi Umum, Audio & Getaran**, serta **Cloud & Danger Zone**.
* **Getaran (Haptic Feedback) Terkontrol (`69A`):** Selain toggle On/Off, pengguna dapat mengatur **Kekuatan Getaran** (`Light` / `Medium` / `Strong` — default: **Medium**) langsung di Profil maupun Quick Settings mid-game. Di Android menggunakan *MethodChannel* native (`Vibrator` + `VibrationEffect` dengan durasi 12–145 ms & amplitudo 80–255) agar getaran terasa mantap dan jelas di motor getar HP, serta *fallback* adaptif untuk iOS/Web.
* **Mid-Game Quick Settings (`InGameSettingsSheet`):** Tombol gear ⚙️ di AppBar keempat game membuka *bottom sheet* khusus yang **hanya memuat pengaturan aman diubah di tengah permainan** (helper visual, opsi sentuh, tema, SFX, getaran & kekuatannya, layar menyala), sambil mem-pause timer secara aman dan menyembunyikan opsi berisiko seperti *Practice Mode* atau *Reset Statistik*.
* **Versi Aplikasi & Sinkronisasi CI/CD:** Versi aplikasi bersih tanpa build number (mis. `Zetzy v0.0.2`) ditampilkan secara halus di bagian paling bawah tab **Profile** menggunakan `package_info_plus` langsung dari `pubspec.yaml`. Workflow `.github/workflows/build-deploy.yml` memvalidasi kesesuaian Git tag `v*` terhadap `pubspec.yaml` sebelum membangun rilis Android, Web (GitHub Pages), Windows, dan Linux.

### 1.3 Efek Kemenangan, Review Papan & Share Skor (Answers: 71A, 73A)

* **Confetti & Hero Badge Spotlight (`71A`):** Kemenangan menampilkan efek partikel **Confetti** selama 3 detik serta menyorot medali **Badge Tier** resolusi pixel-art tajam (`92 px`, `FilterQuality.none`) sebagai ikon utama dialog hasil.
* **Rank Badges Showcase (7 Tier) & Modal Perbesar (`Profile` & `Difficulty Selector`):** Tab **Profile** menampilkan kartu **Koleksi Badge** (7 tier *Chill* s/d *Are U a God?*) beserta badge tertinggi di header akun; mengetuk badge mana pun membuka modal perbesar **`160 px`** dengan navigasi antar-tier serta status penaklukan di ke-4 game. Sheet pemilih difficulty juga menampilkan *live preview* badge `56 px` dari tier yang dipilih.
* **Post-Game Board Review (*View Board / View Result*):** Setelah game selesai (menang atau kalah), pemain dapat menutup dialog ringkasan sementara untuk menginspeksi papan akhir dan membuka kembali dialog hasil lewat tombol *View Result* (tersemat di setiap game sesuai mekaniknya).
* **Share Score Card (`73A`):** Tombol bagikan merender kartu skor PNG berkualitas tinggi (`RepaintBoundary` → `share_plus` / clipboard fallback) lengkap dengan badge platform.

### 1.4 Kontrol Adaptif Desktop & Web (Answers: 50A, 58C)

* **Minesweeper (`50A`):**
  * **Mobile:** *Pinch-to-zoom* (2 jari) dan *drag* untuk menjelajahi papan besar.
  * **Desktop & Web:** `Mouse Scroll Wheel` (Zoom), *Middle-click + Drag* atau *Spasi + Drag* untuk *panning*, *Klik Kiri* untuk aksi utama, dan *Klik Kanan* untuk aksi sekunder/chording.
* **Snake (`58C`):**
  * **Mobile:** Pilihan di pengaturan: **Swipe Gesture**, **Virtual D-Pad**, atau **Split-Screen Tap** (tap sisi kiri/kanan layar untuk belok 90°).
  * **Desktop & Web:** Otomatis mendukung tombol **WASD** dan **Arrow Keys (Panah)** melalui `KeyboardListener`.

---

## 2. Sistem Penyimpanan Lokal, Rewind Practice & Autentikasi Supabase

### 2.1 Offline-First, Auto-Save & Practice Rewind (Answers: 7A–10B, 29B)

* **State Management:** `flutter_riverpod` dengan arsitektur *Feature-First*.
* **Local SQLite (`Drift` - `8B`):**
  * Menyimpan **4 Slot Auto-Save terpisah** (`10B`) — masing-masing 1 slot aktif per game (Sudoku, Chess, Minesweeper, Snake).
  * Menyimpan antrean skor offline (`offline_score_queue` - `9B`, `27A`) untuk dikirim otomatis saat koneksi kembali tersedia.
* **Practice Mode & Rewind on Loss (`29B`):**
  * Mengaktifkan *Practice Mode* membuka latihan bebas tanpa mengirim skor ke Leaderboard Cloud maupun merusak rasio kemenangan Ranked.
  * **In-Game Practice Undo:** Setiap game (Sudoku, Chess, Minesweeper, Snake) menyimpan riwayat snapshot langkah agar pemain bisa mundur saat berlatih.
  * **Practice Rewind on Loss:** Dapat diatur di Profil (*On/Off* dan jumlah langkah mundur **1 / 2 / 3 langkah**); memunculkan tombol *"Rewind N & Continue"* langsung di dialog kalah agar pemain bisa memperbaiki kesalahan tepat sebelum titik fatal.

### 2.2 Autentikasi Tanpa Email & Keamanan Sesi (Answers: 11B–18A)

* **Dummy Email Wrapper (`11B`, `12B`):**
  * Username: `^[a-z0-9_]{3,16}$` (huruf kecil, angka, *underscore*, 3–16 karakter).
  * Password: minimal 8 karakter dengan kombinasi huruf dan angka.
  * Username `zain_99` dipetakan internal ke `zain_99@arcade.local`.
* **Ganti Username & Avatar (`14B`, `15C`):** Username dapat diubah di `public.profiles`. Foto profil dikompresi otomatis ke **256×256 px** di klien lalu diunggah ke bucket `avatars` Supabase Storage.
* **Ganti Password Aman (`13B`):** Verifikasi ulang password lama via `signInWithPassword` sebelum update.
* **Optional Recovery Phrase (`16B`):** Toggle opsional untuk menyimpan hash SHA-256 frasa pemulihan ke kolom `recovery_hash` dan mereset password tanpa email melalui Supabase RPC `reset_password_with_recovery` (`SECURITY DEFINER`).
* **Single Active Session (`17B`):** Login di perangkat baru memanggil `signOut(scope: SignOutScope.others)`.
* **Reset & Delete (`18A`):** Opsi *"Reset Semua Statistik"* dan *"Hapus Akun Permanen"* (memanggil RPC `delete_own_account`).

---

## 3. Sistem 7 Tingkat Kesulitan, Timer, Statistik & Platform Leaderboard

### 3.1 Label, Progresi Level & Sistem XP (Answers: 19B, 24B, 25B, 74B)

* **7 Tingkatan Resmi (`74B`):**
  `1. Chill` (10 XP) | `2. Easy` (25 XP) | `3. Normal` (50 XP) | `4. High` (100 XP) | `5. PRO` (175 XP) | `6. Nightmare` (300 XP) | `7. Are U a God?` (500 XP)
* **Progressive Unlock (`19B`):** Level 1–5 terbuka dari awal per game; menang di Level 5 membuka Level 6 (*Nightmare*), dan menang di Level 6 membuka Level 7 (*Are U a God?*).
* **Tab Statistics (`24B`, `25B`):** Menghitung **Player Level** (setiap 250 XP), total main, win rate, *win streak*, rata-rata durasi, dan ringkasan per game.

### 3.2 Timer, Anti-Cheat, Leaderboard Pagination & Skema Supabase (Answers: 20B–27A, 72A)

* **Real-time Millisecond Timer (`20B`):** Format monospace `MM:SS.ms`.
* **Anti-Cheat Pause Blur (`21A`):** Otomatis menjeda timer dan menutup papan dengan *Glassmorphism Blur* (`AntiCheatPauseOverlay`) saat aplikasi berpindah ke *background* atau kehilangan fokus jendela.
* **Deteksi Platform Multi-OS:** Mencatat `'android'`, `'web'`, `'windows'`, `'linux'`, `'ios'`, atau `'macos'` pada setiap rekor permainan.
* **Leaderboard 3 Tab + Paginasi (`23C`, `47B`):** Tab **Global**, **My Best**, dan **Chess ELO**, memuat **20 data awal** lalu bertahap **+10 entri saat scroll** hingga maksimal **Top 100**.
* **Skema Database Inti (`supabase-setup.md`):**
  * `public.profiles`: profil, `avatar_url`, `chess_elo`, `recovery_hash`, `unlocked_levels` JSONB.
  * `public.game_records`: rekor permainan, `score`, `duration_ms`, `platform`, dan kolom `metadata JSONB` (`mistakes`, `moves`, `mode`, `3bv`, dll.), dilindungi RLS anti-cheat (menolak Sudoku Lv 7 `< 10 detik` dan mewajibkan Catur Ranked `>= 4` half-moves serta validasi server RPC).
  * `public.chess_match_queue` & RPC matchmaking/settlement Catur (`find_or_enqueue_chess_match`, `finish_ranked_chess_match`).

---

## 4. Spesifikasi Mekanik, Fitur Lanjutan & Efek Keempat Game

### 4.1 Game 1: SUDOKU (Answers: 28C–37A)

* **Input Interaktif & Bantuan Visual (`28C`, `31A`–`33A`):**
  * Mendukung *Cell-First* dan *Digit-First* (tekan lama angka keypad bawah untuk mengunci angka; ketuk ulang angka/sel terpilih untuk **deselect / batal pilih**; ketuk angka di keypad bawah saat belum ada sel dipilih untuk langsung **highlight seluruh angka sejenis** di papan).
  * Penyorotan baris/kolom/blok 3×3 sejalan, angka sama menyala, tombol angka yang telah terisi 9× otomatis meredup, dan opsi *Auto-Clear Peer Notes*.
* **Efek Animasi Completion Wave:** Saat sebuah penempatan melengkapi 1 baris, 1 kolom, atau 1 kotak 3×3 tanpa kesalahan, muncul **gelombang cahaya terarah** (propagasi step-by-step menyebar dari sel pemicu—menurun dari atas ke bawah jika sel selesai di baris atas, atau memancar ke dua arah jika sel selesai berada di tengah).
* **Auto-Finish Endgame (Tombol Petir ⚡):**
  * Dapat diaktifkan/dimatikan dan diatur ambangnya (**5** atau **7** kotak kosong tersisa) lewat Profile maupun Quick Settings mid-game.
  * Berlaku di **semua tingkat kesulitan**: begitu sisa kotak kosong `<=` ambang batas dan tidak ada angka yang salah/konflik, muncul tombol **`Auto-Finish (N)`** dengan ikon petir ⚡ di sebelah kiri untuk menyelesaikan sisa kotak secara instan beserta efek gelombang menyeluruh dan suara petir/penyelesaian.
* **Mistake-Free Streak & Accuracy HUD (Default: ON):**
  * Menampilkan badge **Streak** beruntun tanpa salah & persentase **Accuracy (%)** secara langsung di status bar papan serta metrik **Best Streak** dan **Accuracy** di dialog hasil (*toggleable* di Profile / Quick Settings).
* **Smart Candidate Notes (Default: OFF — Khusus Practice & Beginner Lv 1–2):**
  * Jika diaktifkan di **Mode Practice** atau level **Chill/Easy (Lv 1–2)**, kandidat angka 1–9 yang valid otomatis terisi di awal papan, ditambah tombol cepat **Smart Notes** (tetap bisa di-Undo). Pada Ranked Lv 3–7 fitur ini terkunci nonaktif demi keadilan kompetisi.
* **Sistem Nyawa, Validasi & Hint (`29B`, `30C`, `34C`, `35B`, `36B`):**
  * *Ranked Lives:* Lv 1 = ∞; Lv 2–3 = 5 Nyawa; Lv 4–5 = 3 Nyawa; Lv 6 = 2 Nyawa; Lv 7 = **1 Nyawa (Sudden Death)**.
  * *Validasi:* Lv 1–4 cek kunci jawaban langsung; Lv 5–7 hanya cek konflik baris/kolom/blok 3×3.
  * *Hint & Undo:* Maksimal 3 Hint gratis; Undo Ranked hanya membatalkan *pencil notes*, sedangkan mode Practice mengizinkan Undo penuh (termasuk memulihkan *streak* & akurasi).
  * *Post-Game Review:* Mode **Show Answer / Hide Answer** menampilkan koreksi angka benar vs kesalahan yang dicoret merah di papan akhir.

### 4.2 Game 2: CHESS / CATUR (Answers: 38C–47B)

* **4 Mode Permainan (`38C`):**
  1. **Vs AI (Pure-Dart Search Engine):** Menggunakan algoritma **Alpha-Beta Pruning + Quiescence Search + Piece-Square Tables** di *Background Isolate* (`ChessAiEngine`, estimasi rating 700–2400 ELO dari Lv 1 hingga Lv 7 — menjaga ukuran app tetap ringkas dan mulus di semua platform termasuk Web tanpa ketergantungan native FFI).
  2. **Pass & Play:** Bermain berdua bergantian di 1 perangkat (unrated).
  3. **Find Match (Ranked ELO Matchmaking):** Pencarian lawan otomatis berbasis antrean dengan rentang ELO yang melebar bertahap (`400..3500`), penyelesaian rating server-verified (`finish_ranked_chess_match`), dan proteksi anti-cheat (abort unrated bila berhenti sebelum 4 half-moves).
  4. **Private Online (Room Code):** Buat atau gabung kode room 6 karakter via **Supabase Realtime Broadcast**.
* **Kontrol, Efek Sentuh & Tema Bidak (`39A`–`45B`):**
  * Pilih warna bidak (*White / Black / Random*), kontrol waktu (*Untimed*, *Bullet 1m*, *Blitz 3m*, *Blitz 5m*, *Rapid 10m*), opsi *Auto-Queen*, *Show Legal Move Hints*, dan *Show Board Coordinates*.
  * Pilihan 3 set bidak SVG (`cburnett`, `cburnett-v2`, `tatiana`).
  * **Accessible Board Flip Toggle:** Tombol 1-tap `Flip Board` tersemat langsung di AppBar permainan maupun panel kontrol; ditambah opsi **Auto-Flip in Pass & Play** (**Default: OFF**).
  * **Touch Move Confirmation (Default: `Off`):** Opsi **`Off`**, **`Bullet/Blitz` (`fastOnly`)**, dan **`Always`**. Saat aktif, langkah yang dipilih ditandai di papan dan menunggu konfirmasi lewat tap ulang kotak tujuan atau bilah konfirmasi **Confirm / Cancel** di bawah/samping papan untuk mencegah salah sentuh (*slip*).
* **Undo, Review & ELO (`43A`, `44A`, `47B`):**
  * Undo di Vs AI hanya diizinkan pada Level 1–4 (terkunci di Level 5–7).
  * **Post-Game Move Review Scrubber:** Setelah pertandingan selesai, pemain dapat menggeser riwayat langkah (awal, mundur 1 ply, maju 1 ply, akhir, atau ketuk langsung chip notasi SAN/PGN) lengkap dengan evaluasi bidak termakan & selisih materi.

### 4.3 Game 3: MINESWEEPER (Answers: 48C–57A)

* **Kontrol Cepat, Chording & Tap-vs-Flag Swap (`48C`, `49A`):**
  * Mendukung *Tap*, *Long-press*, *Quick Chord* (tap angka untuk membuka kotak sekitar saat jumlah bendera sesuai), serta segmen tool (`Dig ⛏️` / `Flag 🚩` / `Mark ❓`).
  * **Swap Tap & Flag / One-Handed Mode (Default: OFF):** Tombol toggle cepat 1-tap (`1-Tap: Dig` ⇄ `1-Tap: Flag`) tepat di atas segmen tool dan di pengaturan; menukar tap singkat untuk menaruh/mencabut bendera dan tekan-tahan untuk menggali agar nyaman dimainkan satu tangan.
* **Generator, Perisai Defuse & First-Click Safety (`51B`–`54B`):**
  * Klik pertama selalu aman dan membuka ruang kosong (*flood-fill*).
  * **Perisai Defuse Lv 1–2 (`54B`):** 1× kesempatan menyerap ledakan ranjau pertama tanpa kalah (`mine_defused.png` + suara perisai pecah).
* **Reveal All Mines & Post-Game Review (`54A`, `55A`, `56AB`):**
  * Baik saat **kalah maupun menang**, seluruh ranjau langsung dibuka di papan (membedakan ranjau meledak, ranjau tersingkap, *defused*, serta bendera salah), dan pemain tetap bisa meninjau/zoom-pan posisi kesalahan setelah dialog hasil ditutup (`View Board`).
  * Menampilkan metrik **3BV** dan **3BV/s**.

### 4.4 Game 4: SNAKE (Answers: 58C–67A)

* **Arena, Tembok & Rintangan Dinamis (`59AC`, `60B`, `61B`, `64B`):**
  * Ukuran grid proporsional terhadap level; Lv 1 (*Chill*) mendukung tembus tepi (*wrap-around*), sedangkan Lv 2–7 tembok pinggir mematikan + rintangan labirin progresif.
  * Kecepatan naik bertahap seiring panjang ular; di Lv 6–7, blok rintangan berpindah posisi setiap 5 apel dengan peringatan 2 detik (*Ghost Wall*).
* **Ghost Wall & Turn Guide Overlay (Default: ON):**
  * **Ghost Wall Countdown:** Rintangan dinamis menampilkan animasi kotak menyusut (*countdown shrink*) & garis tepi oranye selama 2 detik sebelum mengeras menjadi tembok.
  * **Ahead-of-Head Hazard Preview:** Memberi kilasan bar merah/kuning di sisi tembok atau sel rintangan/tubuh yang berjarak 1–2 langkah di jalur kepala ular saat kecepatan tinggi, plus titik jalur hantu ringan.
  * **Queued Swipe Direction Chevrons:** Menampilkan *chevron* arah kepala dan antrean belokan 2 langkah (**2-Step Input Buffer Queue** `67A`) langsung pada kanvas papan agar kontrol *swipe* cepat di Lv 6–7 akurat terbaca.
* **Item Spesial, Starvation Timer & Crash Inspector (`62C`, `63C`, `65A`):**
  * Item: Apel (+10), Golden Bonus (+50 & isi ulang Starvation), Gunting (potong 3 segmen ekor), Racun (membalik kontrol sesaat).
  * **Post-Game Crash Inspector:** Saat kalah, kotak titik tabrakan (`crashPoint`) ditandai silang merah eksplisit disertai alasan spesifik (*wall*, *obstacle*, *self*, *starvation*), dan skor tetap tercatat ke Leaderboard Snake (`65A`).

---

## 5. Daftar Lengkap Asset (PNG / SVG / WAV / Font)

Seluruh asset gambar, ikon platform, set bidak catur, dan font **sudah tersedia** di direktori `assets/` proyek ini; folder **`assets/audio/`** tinggal diisi file suara berikut.

### A. Asset Gambar & Ikon (Sudah Tersedia di `assets/`)

1. **App Launcher Icon:** `assets/images/ico.jpeg` (digunakan untuk Android, iOS, Web, Windows, macOS, dan ikon aplikasi).
2. **Ikon Platform Leaderboard (`assets/icons/platforms/` — 6 File SVG):**
   * `ic_platform_android.svg`, `ic_platform_web.svg`, `ic_platform_windows.svg`, `ic_platform_linux.svg`, `ic_platform_ios.svg`, `ic_platform_macos.svg`.
3. **Bidak Catur (`assets/icons/chess/` — 3 Tema Lengkap × 12 File SVG):**
   * Tersedia 3 set di folder `cburnett/`, `cburnett-v2/`, dan `tatiana/`:
     * Putih: `wP.svg`, `wN.svg`, `wB.svg`, `wR.svg`, `wQ.svg`, `wK.svg`.
     * Hitam: `bP.svg`, `bN.svg`, `bB.svg`, `bR.svg`, `bQ.svg`, `bK.svg`.
4. **Asset Minesweeper (`assets/images/minesweeper/` — 6 File PNG):**
   * `mine_normal.png`, `mine_exploded.png`, `mine_defused.png`, `flag.png`, `question_mark.png`, `shield_icon.png`.
5. **Asset Snake (`assets/images/snake/` — 5 File PNG):**
   * `food_apple.png`, `food_golden.png`, `item_scissors.png`, `item_poison.png`, `wall_brick.png`.
6. **Badge 7 Tingkat Kesulitan (`assets/images/badge/` — 7 File PNG):**
   * `1.png` (*Chill*) s/d `7.png` (*Are U a God?*).

### B. Asset Suara & Musik (`assets/audio/mp3/` & `assets/audio/mp3/bgm/`)

*(Saat ini sudah terpasang dalam format `.mp3` bernomor variasi di `assets/audio/mp3/` dan 9 trek musik latar di `assets/audio/mp3/bgm/`, serta terdaftar di `pubspec.yaml`. `AudioService` otomatis mendeteksi semua variasi yang tersedia (`1..N`) dan memutarnya secara acak tanpa pengulangan berurutan; BGM mendukung mode **`Off`**, **`Auto` (Default — weighted shuffle dengan trek favorit yang dapat dipilih pengguna, default `5.mp3`, berpeluang `3×` lebih sering)**, dan **`Manual` (loop trek pilihan 1–9)**).*

#### 1. Asset Suara Inti (13 Prefix SFX + 9 Trek BGM)

| Prefix File (`assets/audio/mp3/`) | Variasi Terpasang | Pemicu Fitur / Efek di Game |
| --- | --- | --- |
| **`sfx_ui_click`** | `1–2.mp3` | Klik tombol menu, navigasi tab, & opsi umum |
| **`sfx_sudoku_tap`** | `1–4.mp3` | Mengisi angka standar, *notes*, *Smart Notes*, & *Hint* Sudoku |
| **`sfx_error_buzz`** | `1–4.mp3` | Salah isi angka / konflik di Sudoku & efek racun *Poison* Snake |
| **`sfx_chess_move`** | `1–4.mp3` | Langkah bidak catur ke petak kosong |
| **`sfx_chess_capture`** | `1–4.mp3` | Memakan bidak lawan di Catur |
| **`sfx_chess_check`** | `1–4.mp3` | Peringatan Skak (*Check*) raja lawan |
| **`sfx_mine_dig`** | `1–4.mp3` | Membuka kotak / area aman (*flood-fill*) Minesweeper |
| **`sfx_mine_flag`** | `1–3.mp3` | Menancapkan, mengganti ke `?`, atau mencabut bendera |
| **`sfx_mine_shield`** | `1–3.mp3` | Perisai *Defuse* Lv 1–2 menyelamatkan pemain dari ranjau |
| **`sfx_mine_explode`** | `1–3.mp3` | Menginjak ranjau di Minesweeper (serta *fallback* kalah umum) |
| **`sfx_snake_eat`** | `1–3.mp3` | Ular memakan apel standar (`+10` poin) |
| **`sfx_snake_powerup`** | `1–3.mp3` | Ular memakan *Golden Bonus* atau *Gunting* pemotong ekor |
| **`sfx_game_win`** | `1–4.mp3` | Menang di game apa pun (bersamaan dengan animasi **Confetti**) |
| **`bgm/1.mp3` – `bgm/9.mp3`** | `9 trek` | Musik latar: Mode **Off / Auto (Default, custom fav trek 3× bobot, default `5.mp3`) / Manual** |

#### 2. Asset Suara Efek & Fitur Tambahan (7 Prefix Terpasang)

| Prefix File (`assets/audio/mp3/`) | Variasi Terpasang | Pemicu Fitur / Efek Baru | Fallback Otomatis |
| --- | --- | --- | --- |
| **`sfx_sudoku_line`** | `1–4.mp3` | Animasi **Completion Wave** saat 1 baris, kolom, atau kotak 3×3 Sudoku terpenuhi | `sfx_sudoku_tap` |
| **`sfx_sudoku_autofill`** | `1–3.mp3` | Tombol petir ⚡ **Auto-Finish Endgame** mengisi sisa ≤5/≤7 kotak Sudoku | `sfx_game_win` |
| **`sfx_mine_chord`** | `1–4.mp3` | Aksi cepat **Chording** (tap angka berbenderanya lengkap) di Minesweeper | `sfx_mine_dig` |
| **`sfx_undo_rewind`** | `1.mp3` | Aksi **Undo** (Notes Sudoku, Vs AI Catur) & **Practice Rewind** di ke-4 game | `sfx_ui_click` |
| **`sfx_match_found`** | `1–4.mp3` | Lawan ditemukan pada mode **Online Find Match** ELO Catur | `sfx_chess_check` |
| **`sfx_snake_warning`** | `1–4.mp3` | Peringatan **Ghost Wall Preview** (2 detik sebelum rintangan dinamis Snake Lv 6–7 muncul) | *(Opsional)* |
| **`sfx_game_lose`** | `1–4.mp3` | Kekalahan non-ledakan: habis nyawa Sudoku, skakmat/timeout/resign Catur, atau tabrak/kelaparan Snake | `sfx_mine_explode` |

### C. Asset Font (Sudah Tersedia di `assets/fonts/`)

1. **`JetBrainsMono` (`assets/fonts/JetBrainsMono-2.304/`):** Untuk komponen Timer (`MM:SS.ms`), angka papan & keypad Sudoku, indeks Minesweeper, skor, dan versi aplikasi di Profil.
2. **`PlusJakartaSans` (`assets/fonts/Plus_Jakarta_Sans/`):** Untuk seluruh teks UI, kartu profil, Leaderboard, dan tombol navigasi.

---

## 6. Roadmap & Status Implementasi (Answer: 75B)

* **Tahap 1 — Fondasi, Auth Supabase & Shell UI:** **Selesai** (Multi-theme, bilingual EN/ID, Drift offline-first + `offline_score_queue`, auth username `@arcade.local`, avatar 256×256, recovery phrase RPC, single-session, Profile per-game cards, Quick Settings mid-game, dan app version + CI/CD release).
* **Tahap 2 — Snake & Minesweeper:** **Selesai** (Input queue 2-step, starvation & rintangan dinamis, Ghost Wall & Turn Guide overlay, crash inspector, Minesweeper 3BV, perisai defuse Lv 1–2, chording, reveal-all on end, dan Tap-vs-Flag Swap).
* **Tahap 3 — Sudoku:** **Selesai** (Isolate generator Lv 1–6 + rotated master seed Lv 7, Cell/Digit-first + deselect/keypad highlight, completion wave animasi, Auto-Finish petir 5/7, Mistake-Free Streak & Accuracy HUD, Smart Candidate Notes khusus Practice/Lv 1–2, review solusi).
* **Tahap 4 — Chess:** **Selesai** (Alpha-Beta + Quiescence Isolate AI Lv 1–7, Pass & Play, Private Room Code Realtime, Online Find Match expanding ELO matchmaking + anti-cheat RPC, Flip Board toggle + Auto-Flip Pass & Play, Touch Move Confirmation Off/Bullet-Blitz/Always, Move Review Scrubber, 3 tema SVG bidak).
* **Tahap 5 — Polish, Pengisian Audio `.wav` & Rilis Multi-Platform:** **Aktif Berjalan** (Menunggu pengisian file `.wav`/`.mp3` pada `assets/audio/` + pencantuman `- assets/audio/` di `pubspec.yaml`, serta pengujian rilis berkala via GitHub Actions).
