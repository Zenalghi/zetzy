Fitur **Ikon Platform di Leaderboard** sangat bisa dibuat dan justru menjadi nilai plus yang keren karena aplikasi Anda mendukung multi-platform (Android, Web, Windows, Linux). Setiap kali permainan selesai, aplikasi akan otomatis mendeteksi OS/Platform tempat game tersebut dimainkan dan menyimpannya ke dalam baris skor di database Supabase, bukan hanya di profil user. Dengan begitu, jika Anda main Snake lewat HP Android lalu besoknya main Minesweeper lewat PC Linux/Windows, ikon di Leaderboard akan akurat mengikuti perangkat yang dipakai saat mencetak rekor tersebut.

Berikut adalah **Master Product Requirements Document (PRD)** lengkap yang telah dikompilasi dari seluruh 75 jawaban dan kustomisasi Anda, diikuti dengan **Daftar Lengkap Asset (PNG/SVG/WAV)** yang perlu Anda unduh.

---

# MASTER PRODUCT REQUIREMENTS DOCUMENT (PRD)

**Project Name:** Zetzy
**Target Platforms:** Android, Web, Desktop (Windows & Linux)
**Framework & Stack:** Flutter (Riverpod) + Drift (SQLite Local) + Supabase (Cloud Backend & Realtime)

---

## 1. Arsitektur UI/UX, Tema & Cross-Platform Adaptability

### 1.1 Gaya Visual & Tema (Answers: 1C, 2C, 3AD, 4D, 5C, 6B)

* **Visual Style:** **Tactile Modern Minimalist** — memadukan kebersihan desain datar ala Lichess/NYT Games (`3A`) dengan sentuhan kedalaman *Neumorphism/Glassmorphism* halus (`3D`) pada tombol, kartu, dan efek *blur overlay* saat game di-pause.
* **Multi-Theme Engine (`4D`):** Mendukung pergantian *skin* secara instan:
1. *OLED Midnight* (Hitam pekat `#0D0D0D`, hemat baterai).
2. *Classic Wood & Slate* (Nuansa papan kayu hangat).
3. *Nordic Frost* (Palet biru-abu dingin).
4. *Dracula Neon* (Kontras tinggi ungu/sian).


* **Bilingual (`5C`):** Mendukung Bahasa Indonesia dan Bahasa Inggris secara penuh (`flutter_localizations`).
* **Responsive Orientation (`1C`):** Mendukung *Auto-Rotate* (Portrait & Landscape) dengan tata letak adaptif (`LayoutBuilder`):
* **Portrait (Mobile):** Papan di tengah, *timer/stats* di atas, tombol kontrol/keypad di bawah.
* **Landscape / Desktop / Web:** Papan di sisi kiri/tengah (proporsional), panel kontrol, riwayat langkah catur, dan *timer* berada di *Sidebar* kanan.


* **Navigasi Utama (`6B`):** Menggunakan *Bottom Navigation Bar* (di Mobile) atau *Navigation Rail* (di Desktop/Web) dengan 4 Tab: **Home (Play)**, **Leaderboard**, **Statistics**, dan **Profile/Settings**.

### 1.2 Jawaban Khusus: Kontrol Minesweeper & Snake di Desktop/Web (Answers: 50A, 58C)

* **Minesweeper Zoom & Pan di Desktop/Web (`50A`):**
* **Mobile:** *Pinch-to-zoom* (2 jari) dan *drag* untuk menggeser papan besar.
* **Desktop & Web:** Menggunakan `Listener` pada `InteractiveViewer` untuk mendeteksi **Mouse Scroll Wheel** (Zoom In/Out), **Klik Kanan + Drag** atau **Middle-Click + Drag** atau **Tahan Spasi + Drag** untuk menggeser papan (*panning*). Klik Kiri untuk membuka kotak, dan Klik Kanan langsung menancapkan Bendera (`🚩`).


* **Kontrol Snake di Desktop/Web (`58C`):**
* **Mobile:** Bisa pilih di Settings antara *Swipe Gesture*, *Virtual D-Pad*, atau *Split-Screen Tap* (Tap kiri/kanan layar untuk belok 90°).
* **Desktop & Web:** Otomatis mengaktifkan `FocusNode` keyboard untuk mendeteksi tombol **WASD** dan **Arrow Keys (Panah)** tanpa perlu menekan tombol di layar.



---

## 2. Sistem Penyimpanan Lokal & Autentikasi Supabase

### 2.1 Offline-First & Local Database (Answers: 7A, 8B, 9B, 10B)

* **State Management:** `flutter_riverpod` dengan arsitektur *Feature-First*.
* **Local SQLite (`Drift` - `8B`):**
* Menyimpan **4 Slot Auto-Save terpisah** (`10B`)—masing-masing 1 slot aktif untuk Sudoku, Chess, Minesweeper, dan Snake.
* Menyimpan `offline_score_queue` untuk menampung skor saat bermain tanpa internet (`9B`, `27A`), yang otomatis di-*push* ke Supabase saat koneksi kembali menyala.



### 2.2 Autentikasi Tanpa Email & Keamanan Sesi (Answers: 11B–18A)

* **Dummy Email Wrapper (`11B`, `12B`):**
* Format Username: Huruf kecil, angka, dan underscore (`^[a-z0-9_]{3,16}$`).
* Format Password: Minimal 8 karakter, kombinasi huruf dan angka.
* Di balik layar, username `zain_99` diubah menjadi `zain_99@arcade.local` ke Supabase Auth.


* **Ganti Username & Avatar (`14B`, `15C`):**
* Username tampilan di tabel `public.profiles` dapat diubah kapan saja.
* User dapat mengunggah foto profil ke **Supabase Storage** bucket `avatars` (otomatis dikompres ke ukuran 256x256 px WebP/PNG di sisi Flutter sebelum diunggah).


* **Ganti Password Aman (`13B`):** Wajib memasukkan *Password Lama* (diverifikasi ulang via `signInWithPassword`), lalu *Password Baru* + *Konfirmasi*.
* **Optional Recovery Phrase (`16B`):**
* Pada halaman Pengaturan Keamanan, terdapat *toggle* **"Aktifkan Kode Pemulihan (Recovery Code)"**.
* Jika diaktifkan, sistem men-generate kode rahasia (atau user membuat *Secret Passphrase* sendiri) yang disimpan dalam bentuk **Hash (`bcrypt` / `pgcrypto`)** di tabel `profiles`. Jika lupa password, user cukup memasukkan `Username` + `Recovery Phrase` untuk mereset password via Supabase RPC (`SECURITY DEFINER`) tanpa email sama sekali. Jika tidak diaktifkan, kolom bernilai `NULL` dan fitur lupa password tidak bisa dipakai.


* **Single Active Session (`17B`):** Saat login di perangkat baru, aplikasi memanggil `supabase.auth.signOut(scope: SignOutScope.others)` sehingga perangkat lama otomatis ter-logout.
* **Reset & Delete (`18A`):** Tersedia tombol *"Reset Semua Statistik"* dan *"Hapus Akun Permanen"* di menu Settings.

---

## 3. Sistem 7 Tingkat Kesulitan, Timer & Platform Leaderboard

### 3.1 Label & Progresi Level (Answers: 19B, 29B, 74B)

* **7 Tingkatan Resmi (`74B`):**
`1. Chill` | `2. Easy` | `3. Normal` | `4. High` | `5. PRO` | `6. Nightmare` | `7. Are U a God?`
* **Progressive Unlock (`19B`):** Level 1–5 terbuka sejak awal. Menang di Level 5 (*PRO*) 1x akan membuka Level 6 (*Nightmare*). Menang di Level 6 1x akan membuka Level 7 (*Are U a God?*).
* **Practice Mode (`29B`):** Di setiap tingkat kesulitan yang sudah terbuka, terdapat *toggle* **"Practice Mode"**. Dalam mode ini, pemain bebas berlatih (nyawa tak terbatas di Sudoku), namun skor dan waktu hanya ditampilkan di layar akhir dan **tidak dikirim ke database/leaderboard**.

### 3.2 Aturan Timer & Deteksi Platform di Leaderboard (Answers: 20B–27A, 72A)

* **Real-time Millisecond Timer (`20B`):** Format tampilan aktif `MM:SS.ms` (contoh: `02:14.85`) menggunakan font *Monospace*.
* **Anti-Cheat Pause Blur (`21A`):** Begitu aplikasi masuk ke *background* (atau kehilangan fokus jendela di Desktop/Web), timer langsung berhenti seketika dan papan permainan tertutup *Glassmorphism Blur* sampai tombol "Resume" ditekan.
* **Deteksi Platform untuk Ikon Leaderboard:**
* Di Flutter, buat *helper* pendeteksi platform sebelum mengirim skor:
* Jika `kIsWeb` -> `'web'` 🌐
* Jika `Platform.isAndroid` -> `'android'` 🤖
* Jika `Platform.isWindows` -> `'windows'` 🪟
* Jika `Platform.isLinux` -> `'linux'` 🐧




* **Skema Database Supabase Lengkap (Dengan Platform & Anti-Cheat `72A`):**

```sql
-- 1. Tabel Profil Pengguna
CREATE TABLE public.profiles (
  id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  username TEXT UNIQUE NOT NULL CHECK (username ~ '^[a-z0-9_]{3,16}$'),
  avatar_url TEXT,
  chess_elo INT NOT NULL DEFAULT 1000, -- Untuk sistem ELO Catur (47B)
  recovery_hash TEXT DEFAULT NULL, -- NULL jika user tidak mengaktifkan fitur Recovery (16B)
  unlocked_levels JSONB NOT NULL DEFAULT '{"sudoku": 5, "chess": 5, "minesweeper": 5, "snake": 5}'::jsonb,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Tabel Riwayat Skor & Leaderboard (Menyimpan Platform saat main)
CREATE TABLE public.game_records (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  game_type TEXT NOT NULL CHECK (game_type IN ('sudoku', 'chess', 'minesweeper', 'snake')),
  difficulty INT NOT NULL CHECK (difficulty BETWEEN 1 AND 7),
  is_won BOOLEAN NOT NULL, -- Disimpan baik menang maupun kalah untuk Win Rate (22B, 65A)
  score INT NOT NULL DEFAULT 0, -- Poin Snake / ELO Delta Chess / 3BV Minesweeper
  duration_ms INT NOT NULL CHECK (duration_ms >= 3000), -- Anti-cheat dasar (72A): minimal 3 detik
  platform TEXT NOT NULL CHECK (platform IN ('android', 'web', 'windows', 'linux', 'ios', 'macos')),
  played_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index untuk query Global Top 100 & Personal Best (23C)
CREATE INDEX idx_leaderboard ON public.game_records (game_type, difficulty, is_won, score DESC, duration_ms ASC);

```

---

## 4. Spesifikasi Mekanik Keempat Game

### 4.1 Game 1: SUDOKU (Answers: 28C–37A)

* **Input & Bantuan Visual:** Mendukung *Cell-First* maupun *Digit-First* (tekan/kunci angka di bawah untuk *rapid tap* - `28C`). Angka yang sama menyala otomatis (`32A`), tombol angka yang sudah terpakai 9x otomatis meredup (`33A`), dan pengisian angka otomatis menghapus *pencil notes* di baris/kolom/blok terkait (`31A`).
* **Sistem Nyawa & Mode Practice (`29B`):**
* *Mode Ranked:* Level 1 (*Chill*) = Tanpa batas nyawa; Level 2–3 = 5 Nyawa; Level 4–5 = 3 Nyawa; Level 6 (*Nightmare*) = 2 Nyawa; Level 7 (*Are U a God?*) = **1 Nyawa (Sudden Death)**.
* *Mode Practice:* Nyawa tak terbatas di semua level, skor tidak masuk DB.


* **Validasi Kesalahan (`30C`):** Level 1–4 langsung mengecek kunci jawaban (merah jika salah). Level 5–7 hanya mendeteksi konflik baris/kolom/kotak 3x3 (tidak memberi tahu apakah sesuai kunci jawaban sampai papan penuh).
* **Hint & Undo (`34C`, `35B`):** Maksimal 3x Hint gratis per game. Tombol Undo hanya bisa membatalkan catatan (*notes*), tidak bisa membatalkan kesalahan nyawa.
* **Generator (`36B`):** Level 1–6 dibuat secara *real-time* di *Background Isolate*, sedangkan Level 7 (*Are U a God?* - 17 petunjuk) mengambil dari kumpulan *Master Seed* yang ditransformasi/dirotasi secara matematis agar terbuka secara instan tanpa *loading*.

### 4.2 Game 2: CHESS / CATUR (Answers: 38C–47B)

* **3 Mode Permainan (`38C`):**
1. **Vs AI (Stockfish FFI - `46A`):** Menggunakan engine Stockfish C++ untuk Android/Desktop, dan `stockfish.js` (WebAssembly) saat dijalankan di Browser Web.
2. **Pass & Play:** Main berdua gantian di 1 perangkat.
3. **Online Multiplayer:** Menggunakan **Supabase Realtime Broadcast/Presence** (Bisa buat *Room Code* untuk menantang teman secara *real-time*).


* **Kontrol & Aturan (`39A`–`45B`):** Bebas pilih warna bidak (`39A`), pilih kontrol waktu *Untimed / Bullet / Blitz / Rapid* (`40A`), metode klik *Tap-to-Move* (`41A`) dengan titik langkah legal selalu aktif (`42A`), dan *Auto-Queen* saat promosi pion dengan opsi ganti di Settings (`45B`).
* **Aturan Undo (`43A`):** Boleh *Undo* langkah saat melawan AI di Level 1–4, namun **terkunci/dilarang** di Level 5, 6, dan 7.
* **Informasi Layar & Sistem ELO (`44A`, `47B`):** Menampilkan bidak yang dimakan, selisih poin materi (`+3`), dan barisan notasi PGN. Leaderboard Catur diurutkan berdasarkan **Rating ELO pemain** (mengalahkan AI level tinggi atau pemain online akan menaikkan ELO).

### 4.3 Game 3: MINESWEEPER (Answers: 48C–57A)

* **Kontrol Cepat & Chording (`48C`, `49A`):** Mendukung *Long-press* dan tombol *Toggle* (Gali ⛏️ / Bendera 🚩 / Tanda Tanya ❓ `53B`), serta fitur **Chording** (klik angka yang benderanya sudah lengkap untuk membuka seluruh kotak di sekelilingnya sekaligus).
* **Generator & First-Click (`51B`, `52B`):** Klik pertama dijamin bukan ranjau. Level 1–4 menggunakan generator ramah logika deduksi, sedangkan Level 5–7 murni acak ekstrem.
* **Fitur Perisai / Defuse (`54B`):** Khusus di Level 1 (*Chill*) dan Level 2 (*Easy*), pemain mendapat **1x Perisai Defuse** (kesempatan selamat saat tidak sengaja mengklik ranjau pertama kali). Di Level 3–7, menginjak ranjau langsung meledak (Game Over).
* **Kondisi Menang & Statistik (`55A`, `56AB`):** Otomatis menang begitu seluruh kotak aman terbuka. Header menampilkan sisa ranjau & stopwatch, dan layar hasil menampilkan metrik **3BV (Bechtel's Board Benchmark Value)** & *3BV/s*.

### 4.4 Game 4: SNAKE (Answers: 58C–67A)

* **Ukuran Grid & Aturan Tembok (`59AC`, `64B`):**
* Ukuran grid menyesuaikan level (misal 15x15 di level bawah, hingga 25x25 di level tinggi).
* Di Level 1 (*Chill*), tembok pinggir bisa ditembus (*wrap-around*). Di Level 2–7, tembok pinggir mematikan, ditambah rintangan di tengah papan.


* **Rintangan Dinamis & Kecepatan Progresif (`60B`, `61B`):**
* Makin panjang tubuh ular, kecepatannya bertambah secara bertahap (`61B`).
* Khusus di Level 6 (*Nightmare*) dan Level 7 (*Are U a God?*), balok rintangan di dalam arena akan **berpindah posisi secara dinamis** setiap kali ular memakan 5 umpan (dengan indikator bayangan peringatan 2 detik sebelum balok muncul).


* **Item Spesial & Starvation Timer (`62C`, `63C`):**
* Selain apel biasa (+10 poin), muncul *Bonus Food* berwaktu, *Gunting* (memotong 3 segmen ekor agar lebih lega), dan *Racun/Debuff* (membalik kontrol sesaat di level atas).
* Di Level 1–5 menggunakan Stopwatch *Survival Time* biasa. Di Level 6–7 aktif **Starvation Bar** (bar kelaparan hitung mundur yang ter-reset setiap kali makan apel; jika habis, ular mati kelaparan).


* **Visual, Input Queue & Kondisi Menang (`65A`, `66B`, `67A`):**
* Tubuh ular digambar menyambung mulus (*rounded smooth segments*) dengan mata menghadap arah gerak (`66B`) serta dilengkapi **2-Step Input Buffer Queue** (`67A`) agar belokan cepat tidak membuat ular menabrak lehernya sendiri.
* Jika ular berhasil memenuhi 100% ruang grid, tercatat `is_won = true` (Beat the Game!). Jika menabrak sebelum penuh, tercatat `is_won = false`, namun **skor dan durasinya tetap masuk ke Leaderboard Snake** (`65A`).



---

## 5. Daftar Lengkap Asset (PNG / SVG / WAV / Font) yang Perlu Anda Unduh

Agar Anda mudah menyiapkannya di dalam folder `assets/` proyek Flutter, berikut adalah daftar rincian file yang perlu Anda unduh (disarankan dari situs gratis berlisensi *CC0 / Public Domain* seperti **Kenney.nl**, **Lichess Open Source**, **Lucide Icons**, dan **Freesound.org**):

### A. Asset Gambar & Ikon (`assets/images/` & `assets/icons/`)

*(Catatan: Untuk bidak catur dan ikon platform, format `.svg` sangat disarankan, tapi Anda juga bisa menggunakan `.png` resolusi minimal 256x256 px transparan).*

1. **Ikon Platform untuk Leaderboard (6 File SVG/PNG):**
* `ic_platform_android.svg` (Logo Robot Android)
* `ic_platform_web.svg` (Ikon Globe / Browser)
* `ic_platform_windows.svg` (Logo Jendela Windows)
* `ic_platform_linux.svg` (Logo Pinguin Tux Linux)
* `ic_platform_ios.svg` & `ic_platform_macos.svg` (Logo Apple - jaga-jaga untuk ekspansi)


2. **Bidak Catur — 12 File (Unduh dari GitHub Lichess `cburnett` set):**
* Putih: `wP.svg` (Pawn), `wN.svg` (Knight), `wB.svg` (Bishop), `wR.svg` (Rook), `wQ.svg` (Queen), `wK.svg` (King).
* Hitam: `bP.svg`, `bN.svg`, `bB.svg`, `bR.svg`, `bQ.svg`, `bK.svg`.


3. **Asset Minesweeper — 6 File PNG/SVG:**
* `mine_normal.png` (Ranjau laut berduri hitam)
* `mine_exploded.png` (Ranjau dengan latar merah menyala)
* `mine_defused.png` (Ranjau dengan tanda silang hijau / perisai untuk fitur Defuse Level 1–2)
* `flag.png` (Bendera merah `🚩`)
* `question_mark.png` (Tanda tanya `❓`)
* `shield_icon.png` (Ikon perisai aktif di pojok layar)


4. **Asset Snake — 5 File PNG/SVG:**
**(Badan dan kepala ular lebih bagus digambar langsung dengan kode `CustomPainter` agar pergerakannya mulus, jadi Anda hanya butuh sprite item):*
* `food_apple.png` (Apel merah standar)
* `food_golden.png` (Apel/Koin emas berkilau untuk Bonus Food)
* `item_scissors.png` (Ikon gunting pemotong ekor)
* `item_poison.png` (Botol racun ungu / tengkorak untuk debuff)
* `wall_brick.png` (Tekstur kotak tembok rintangan)


5. **Badge 7 Tingkat Kesulitan — 7 File PNG/SVG (Opsional agar menu keren):**
* `badge_1_chill.png` (Ikon es/daun santai) s/d `badge_7_god.png` (Ikon petir/mahkota emas menyala).



### B. Asset Suara & Musik (`assets/audio/`)

*(Gunakan format `.wav` atau `.ogg` pendek ukuran < 100 KB untuk SFX agar *zero-latency* saat diklik, dan `.mp3` atau `.ogg` *looping* untuk musik latar BGM).*

| Nama File | Kegunaan di Dalam Game | Rekomendasi Karakter Suara |
| --- | --- | --- |
| **`sfx_ui_click.wav`** | Klik tombol menu & navigasi | Suara *pop* atau *tick* lembut |
| **`sfx_sudoku_tap.wav`** | Mengisi angka / *pencil mark* di Sudoku | Suara ketukan pensil/kayu halus |
| **`sfx_error_buzz.wav`** | Salah isi angka Sudoku / langkah ilegal | Suara *thud* rendah (tidak memekakkan telinga) |
| **`sfx_chess_move.wav`** | Menggerakkan bidak catur ke kotak kosong | Suara gesekan/ketukan bidak kayu di papan |
| **`sfx_chess_capture.wav`** | Memakan bidak lawan di catur | Suara hentakan kayu yang lebih tegas |
| **`sfx_chess_check.wav`** | Peringatan Skak (*Check*) | Suara lonceng/denting pendek |
| **`sfx_mine_dig.wav`** | Membuka kotak aman di Minesweeper | Suara pasir/ketukan ringan |
| **`sfx_mine_flag.wav`** | Menancapkan / mencabut bendera | Suara kain berkibar / *snap* singkat |
| **`sfx_mine_shield.wav`** | Perisai Defuse pecah menyelamatkan pemain | Suara kaca/energi perisai pecah |
| **`sfx_mine_explode.wav`** | Menginjak ranjau / menabrak tembok Snake | Suara ledakan *arcade* 8-bit/modern |
| **`sfx_snake_eat.wav`** | Ular memakan apel standar | Suara *crunch* atau *blip* naik nada |
| **`sfx_snake_powerup.wav`** | Ular memakan Bonus Food / Gunting | Suara koin / *power-up* ceria |
| **`sfx_game_win.wav`** | Menang permainan (Muncul bersama Confetti) | *Fanfare* kemenangan singkat (2–3 detik) |
| **`bgm_chill_loop.mp3`** | Musik latar menu & bermain (`68B`) | *Lo-Fi Chill Beats* / *Ambient Synth* tanpa vokal |

### C. Asset Font (`assets/fonts/`)

1. **`JetBrainsMono-Bold.ttf` & `JetBrainsMono-Regular.ttf`:** Wajib untuk semua komponen Timer (`MM:SS.ms`), angka papan Sudoku, dan angka indikator Minesweeper.
2. **`PlusJakartaSans-Regular.ttf` & `PlusJakartaSans-Bold.ttf`:** Untuk seluruh teks UI, Leaderboard, dan tombol.

---

## 6. Roadmap Pengerjaan Bertahap (Milestone Phasing - Answer: 75B)

Berikut adalah pembaruan *Checklist* proyek Anda yang sudah disesuaikan dengan tahapan *Milestone* dari PRD di atas: