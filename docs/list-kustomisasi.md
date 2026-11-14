Berikut adalah **75 pertanyaan pilihan ganda** komprehensif yang mencakup seluruh aspek teknis, mekanik tiap game, sistem autentikasi, database Supabase, hingga UI/UX.

Untuk menjawabnya dengan cepat, Anda cukup menuliskan **Nomor dan Hurufnya saja** (Contoh: `1A, 2C, 3B...` atau jika ada modifikasi khusus: `15A (tapi maksimal 5 kali)`).

---

### Kategori 1: Identitas Aplikasi & Arsitektur Dasar (1 - 10)

1. **Orientasi layar aplikasi:**
* A. Full Portrait (Tegak) untuk semua game.
* B. Portrait untuk menu/Sudoku/Chess, tapi bisa Landscape untuk Minesweeper & Snake.
* C. Bebas berputar (Auto-rotate) di semua layar.


2. **Target Platform Utama:**
* A. Android saja.
* B. Android & iOS.
* C. Android, serta siap di-compile ke Desktop (Windows/Linux) dan Web.


3. **Gaya Visual (Art Style) UI secara keseluruhan:**
* A. Modern Minimalist (Clean, flat design, mirip Lichess / NYT Games).
* B. Retro Pixel Art / Arcade 8-bit.
* C. Neon / Cyberpunk Futuristic.
* D. Neumorphism / Glassmorphism (Elegan dengan efek kedalaman).


4. **Pengaturan Tema Warna (Theme):**
* A. Hanya Dark Mode (OLED friendly, hemat baterai).
* B. Hanya Light Mode.
* C. Bisa pilih Dark Mode, Light Mode, atau ikut sistem HP.
* D. Multi-tema (Bisa ganti skin warna papan, misal tema Kayu, Hijau Klasik, Nord, atau Dracula).


5. **Bahasa Pengantar di dalam Aplikasi:**
* A. Bahasa Inggris saja.
* B. Bahasa Indonesia saja.
* C. Bilingual (Bisa ganti Indonesia / Inggris di pengaturan).


6. **Navigasi Halaman Utama (Home Screen):**
* A. Bento Grid (4 kartu besar untuk 4 game di tengah layar, langsung klik main).
* B. Bottom Navigation Bar (Tab Home, Leaderboard, Statistik, Profil).
* C. Carousel / Swipe kiri-kanan untuk memilih game.


7. **State Management Flutter yang ingin digunakan di PRD:**
* A. Riverpod (Modern, aman dari sisi *compile-time*, sangat direkomendasikan).
* B. BLoC / Cubit (Terstruktur ketat, standar *enterprise*).
* C. Provider / GetX (Simpel dan cepat ditulis).


8. **Database Lokal (Offline Storage) di HP:**
* A. Hive / Isar (NoSQL cepat untuk simpan state papan & antrean skor).
* B. SQLite / Drift (Relasional lokal, mirip struktur Supabase).
* C. SharedPreferences saja (Simpan sebagai JSON string).


9. **Konektivitas saat Pertama Kali Buka Aplikasi:**
* A. Wajib Login/Register dulu baru bisa masuk ke menu game.
* B. Bisa langsung main (Mode Tamu/Offline), login hanya diperlukan jika ingin *sync* skor ke Cloud/Leaderboard.


10. **Fitur Resume Game (Melanjutkan game yang tertunda):**
* A. Hanya 1 *save slot* aktif untuk keseluruhan aplikasi (Jika mulai main Catur, progres Sudoku yang belum selesai akan tertimpa).
* B. 1 *save slot* aktif **per jenis game** (Sudoku, Chess, Minesweeper, dan Snake masing-masing punya tombol "Continue" sendiri).
* C. Bisa menyimpan banyak sesi sekaligus (Multi-slot).



---

### Kategori 2: Autentikasi, Akun & Keamanan (11 - 18)

11. **Aturan Format Username saat Registrasi:**
* A. Bebas karakter apa saja termasuk spasi.
* B. Hanya huruf kecil, angka, dan *underscore* (`a-z, 0-9, _`), panjang 3–16 karakter, tanpa spasi.
* C. Huruf besar/kecil bebas, minimal 4 karakter.


12. **Aturan Panjang Password:**
* A. Minimal 6 karakter bebas (Standar minimum Supabase).
* B. Minimal 8 karakter dengan kombinasi huruf dan angka.
* C. Bebas/pendek (Misal PIN 4-6 digit saja agar praktis).


13. **Mekanisme Ganti Password (Tanpa 2FA/Email):**
* A. Langsung ketik *Password Baru* saja di menu pengaturan lalu klik Simpan.
* B. Wajib mengetik *Password Lama* + *Password Baru* + *Konfirmasi Password Baru* (Mencegah orang iseng mengganti password saat HP Anda dipinjam).


14. **Fitur Ganti Username:**
* A. Username bersifat permanen (Tidak bisa diganti setelah dibuat).
* B. Username bebas diganti kapan saja di menu Profil.


15. **Foto Profil / Avatar Pengguna:**
* A. Tidak perlu avatar (Hanya teks inisial username).
* B. Pilih dari koleksi ikon/avatar bawaan aplikasi (Offline SVG, tidak perlu *upload* file).
* C. Bisa *upload* foto sendiri ke Supabase Storage.


16. **Penanganan jika User Lupa Password (Karena tanpa Email/OTP):**
* A. Benar-benar tidak ada pemulihan (User harus buat akun baru).
* B. Tambahkan fitur "Recovery Code / Secret Phrase" opsional saat daftar (Jika lupa password, masukkan kode rahasia ini via RPC function).


17. **Manajemen Sesi Login (Multi-Device):**
* A. Satu akun bebas login di banyak HP/perangkat sekaligus.
* B. Hanya 1 perangkat aktif (Login di perangkat baru otomatis me-logout perangkat lama).


18. **Fitur Hapus Akun / Reset Data:**
* A. Ada tombol "Reset Statistik" dan "Hapus Akun Permanen" di pengaturan.
* B. Tidak perlu ada fitur hapus akun di UI.



---

### Kategori 3: Level Kesulitan, Timer & Sistem Skor (19 - 27)

19. **Aksesibilitas 7 Tingkat Kesulitan (*Chill* s/d *Are U a God?*):**
* A. Semua 7 level langsung terbuka (Unlocked) sejak awal untuk semua game.
* B. Sistem Progresif (Harus menang level *PRO* minimal 1x untuk membuka *Nightmare*, dan menang *Nightmare* untuk membuka *Are U a God?*).


20. **Format Tampilan Timer di Layar:**
* A. `MM:SS` (Menit:Detik saja, misal `04:25`).
* B. `MM:SS.ms` (Menit:Detik.Milidetik di layar, misal `04:25.82` untuk kesan kompetitif).
* C. `MM:SS` saat bermain, namun hasil akhir saat menang menampilkan milidetik detail (`04:25.824`).


21. **Perilaku Timer saat Aplikasi Berpindah ke Background (Ada telepon / buka WA):**
* A. Otomatis *Pause* seketika, dan papan permainan di-blur sampai user menekan tombol "Resume".
* B. Otomatis *Pause*, dan langsung lanjut jalan saat aplikasi dibuka kembali.
* C. Timer tetap berjalan di background (Real-time).


22. **Skor & Timer untuk Game yang Kalah (Game Over):**
* A. Hanya game yang **Menang (Won)** yang disimpan ke database Supabase (Kecuali Snake karena Snake pasti berakhir mati/tabrakan).
* B. Semua riwayat baik Menang maupun Kalah tetap dikirim ke Supabase untuk menghitung persentase *Win Rate*.


23. **Sistem Leaderboard (Papan Peringkat):**
* A. Global Leaderboard (Melihat skor tertinggi dari semua user yang terdaftar di Supabase).
* B. Personal Best saja (Hanya membandingkan rekor diri sendiri di masa lalu).
* C. Keduanya (Ada tab *My Best* dan tab *Global Top 100* untuk tiap level kesulitan).


24. **Perhitungan Skor Gabungan (Global XP / Player Level):**
* A. Tidak perlu (Skor tiap game berdiri sendiri-sendiri).
* B. Buat sistem EXP/Level Akun (Menang di level *Chill* dapat +10 XP, menang di *Are U a God?* dapat +500 XP).


25. **Filter Riwayat & Statistik:**
* A. Tampilkan ringkasan simpel (Total Main, Total Menang, Waktu Tercepat per level).
* B. Lengkap dengan grafik perkembangan (Win streak, rata-rata waktu penyelesaian, total jam bermain per game).


26. **Penyimpanan Replay / Bukti Kemenangan di Database (`metadata` JSONB):**
* A. Hanya simpan angka skor dan waktu saja (Hemat database).
* B. Simpan detail permainan (Misal: notasi langkah PGN untuk Catur, jumlah *mistake* untuk Sudoku, dan nilai *3BV* untuk Minesweeper).


27. **Sinkronisasi Skor ke Supabase:**
* A. Otomatis di latar belakang setiap kali game selesai (Dengan sistem antrean jika sedang offline).
* B. Manual (Ada tombol "Sync Data to Cloud" di halaman profil).



---

### Kategori 4: Mekanik Game 1 — SUDOKU (28 - 37)

28. **Metode Input Angka Sudoku:**
* A. *Cell-First* (Klik kotak di papan dulu, lalu klik angka 1–9 di bawah).
* B. *Digit-First* (Klik dan kunci angka di bawah dulu, lalu tap banyak kotak di papan dengan cepat).
* C. Mendukung keduanya (Bisa di-toggle atau otomatis kunci angka jika tombol angka ditekan lama).


29. **Batas Kesalahan (Mistake Limit / Nyawa):**
* A. Klasik 3 Kesalahan = Game Over.
* B. Mengikuti tingkat kesulitan (Misal: *Chill* = Tanpa batas, *Normal* = 5 nyawa, *Nightmare* = 3 nyawa, *Are U a God?* = 1 nyawa / Sudden Death).
* C. Tanpa batas nyawa (Kesalahan tidak langsung dideteksi sampai papan penuh).


30. **Validasi Angka Saat Diisi:**
* A. Langsung dicek terhadap kunci jawaban (Jika salah isi angka, langsung berwarna merah).
* B. Hanya mendeteksi konflik baris/kolom/blok 3x3 (Baru ketahuan salah di akhir jika tidak sesuai kunci).
* C. Mengikuti level kesulitan (Level mudah langsung cek kunci, level *PRO* ke atas hanya cek konflik).


31. **Fitur Catatan Kecil (Pencil Marks / Notes):**
* A. Otomatis terhapus di baris/kolom/blok yang sama saat angka asli dimasukkan (*Auto-remove notes*).
* B. Sepenuhnya manual (User harus menghapus catatan sendiri).
* C. Otomatis di level bawah, tetapi manual di level *Nightmare* & *Are U a God?*.


32. **Fitur Bantuan Visual (Highlighting):**
* A. Saat memilih satu angka (misal angka 5), semua angka 5 lain di papan ikut menyala terang, serta baris & kolomnya diberi warna bayangan.
* B. Polos seperti kertas koran (Hanya kotak yang dipilih yang berubah warna).
* C. Bisa dinyalakan/dimatikan lewat menu Settings.


33. **Sembunyikan Tombol Angka yang Sudah Penuh (9x terpakai):**
* A. Ya, sembunyikan atau redupkan tombol angka di bawah jika angka tersebut sudah lengkap 9 biji di papan.
* B. Biarkan tetap tampil normal.


34. **Fitur Hint (Petunjuk):**
* A. Tidak ada fitur Hint sama sekali (Murni asah otak).
* B. Ada Hint, tetapi menambah penalti waktu (Misal: pakai 1 Hint = waktu timer ditambah +60 detik).
* C. Ada Hint gratis terbatas (Misal maksimal 3x per game).


35. **Fitur Undo / Redo:**
* A. Bebas Undo tanpa batas.
* B. Hanya bisa Undo catatan/notes, tidak bisa Undo kesalahan angka.


36. **Pembuatan Papan (Board Generation):**
* A. *Real-time Generator* di HP (Algoritma pembuat papan langsung bekerja secara acak setiap kali klik Play — butuh *Isolate/background thread* untuk level 7 agar UI tidak lag).
* B. Kombinasi *Pre-generated Seed* untuk level 7 (*Are U a God?*) yang diacak orientasinya agar instan tanpa *loading* lama, dan *Real-time* untuk level 1–6.


37. **Tipe Timer di Sudoku:**
* A. Murni Stopwatch (Hitung maju dari `00:00` untuk mencari rekor tercepat).
* B. Ada opsi Countdown (Misal di level *Are U a God?* harus selesai di bawah 20 menit atau dianggap kalah).



---

### Kategori 5: Mekanik Game 2 — CHESS / CATUR (38 - 47)

38. **Pilihan Mode Bermain Catur:**
* A. Hanya Lawan AI (Vs Komputer sesuai 7 tingkat kesulitan).
* B. Lawan AI + Mode *Pass & Play* (Main berdua gantian di 1 HP yang sama).
* C. Lawan AI + *Pass & Play* + Online Multiplayer via Supabase Realtime.


39. **Pemilihan Warna Bidak (Putih / Hitam):**
* A. Bebas pilih Putih, Hitam, atau Acak (Random) sebelum mulai.
* B. Selalu Putih di level mudah, dan dipaksa Hitam di level *Are U a God?*.


40. **Sistem Timer / Jam Catur (Chess Clock):**
* A. Bebas pilih kontrol waktu sebelum mulai: *Tanpa Waktu (Santai)*, *Bullet (1 menit)*, *Blitz (3 atau 5 menit)*, atau *Rapid (10 menit)* + Stopwatch durasi total.
* B. Waktu ditentukan kaku oleh tingkat kesulitan (Makin tinggi levelnya, waktu berpikir pemain makin sempit).
* C. Hanya Stopwatch biasa (Menghitung berapa lama total pertandingan berlangsung tanpa batas waktu habis).


41. **Metode Menggerakkan Bidak:**
* A. *Tap-to-Move* (Klik bidak, lalu klik kotak tujuan).
* B. *Drag-and-Drop* (Geser bidak ke kotak tujuan).
* C. Mendukung keduanya sekaligus.


42. **Bantuan Visual Langkah Legal (Legal Move Dots):**
* A. Selalu tampilkan titik kecil di kotak-kotak yang boleh dituju saat bidak disentuh.
* B. Tampilkan titik di level 1–5, tapi **sembunyikan** di level *Nightmare* dan *Are U a God?* agar lebih menantang.


43. **Fitur Undo (Tarik Langkah) saat Melawan AI:**
* A. Boleh Undo di level 1–4 (*Chill* s/d *High*), tetapi **dilarang Undo** di level 5–7 (*PRO*, *Nightmare*, *Are U a God?*).
* B. Dilarang Undo di semua level.
* C. Boleh Undo di semua level, tapi kemenangan dengan Undo tidak masuk ke Leaderboard/Rekor.


44. **Informasi di Layar Catur:**
* A. Tampilkan daftar bidak yang sudah dimakan (*Captured Pieces*) + selisih poin materi (Misal `+3`) + riwayat notasi langkah (PGN).
* B. Tampilan bersih (Hanya papan catur dan timer saja).


45. **Promosi Pion (Saat pion mencapai ujung papan):**
* A. Muncul pop-up pilihan (Queen, Rook, Bishop, Knight).
* B. Otomatis jadi Menteri/Ratu (*Auto-Queen*), kecuali diatur di Settings.


46. **Engine AI Catur di balik layar:**
* A. **Stockfish FFI** (Sangat kuat, level 7 benar-benar mustahil dikalahkan manusia biasa karena setara Grandmaster ELO 2800+, ukuran aplikasi bertambah ~15-20MB).
* B. Pure Dart Chess Engine / Minimax (Ukuran aplikasi sangat kecil, tapi level tertingginya hanya setara pemain klub menengah ~1600-1800 ELO).


47. **Metrik Skor Utama untuk Leaderboard Catur:**
* A. Kemenangan dengan jumlah langkah paling sedikit & waktu paling cepat di masing-masing level.
* B. Sistem Rating ELO Pribadi (Mengalahkan AI level tinggi menaikkan ELO pemain, kalah menurunkan ELO).



---

### Kategori 6: Mekanik Game 3 — MINESWEEPER (48 - 57)

48. **Kontrol Membuka Kotak vs Menaruh Bendera (Flag):**
* A. *Tap* = Buka kotak, *Long-Press* (Tahan sebentar) = Pasang Bendera.
* B. Ada tombol *Toggle Mode* di bawah layar (Mode Gali ⛏️ vs Mode Bendera 🚩) agar bisa bermain sangat cepat tanpa perlu *long-press*.
* C. Kombinasi keduanya (Mendukung *Long-Press* sekaligus punya tombol *Toggle*).


49. **Fitur *Chording* (Standar Pro Minesweeper):**
*(Penjelasan: Jika angka '2' sudah dikelilingi 2 bendera, meng-klik angka '2' tersebut akan otomatis membuka semua kotak tertutup di sekitarnya).*
* A. Wajib ada (Sangat penting untuk mengejar rekor waktu cepat).
* B. Tidak perlu, buka satu-satu saja.


50. **Navigasi Papan Ukuran Besar (Level *PRO* s/d *Are U a God?*):**
* A. Papan bisa di-*Zoom in / Zoom out* (Pinch to zoom) dan digeser (*Panning*) menggunakan 2 jari (`InteractiveViewer`).
* B. Ukuran kotak diperkecil otomatis agar seluruh grid muat di satu layar tanpa perlu digeser.


51. **Keamanan Klik Pertama (First-Click Guarantee):**
* A. Klik pertama dijamin selalu membuka **area kosong (Angka 0 / Flood-fill)** sehingga langsung membuka ruang yang lega untuk mulai berpikir.
* B. Klik pertama hanya dijamin bukan ranjau (Bisa saja langsung muncul angka di satu kotak itu saja).


52. **Generator Papan Bebas Tebakan (No-Guessing Mode vs Random):**
* A. Standar Acak (Setelah klik pertama aman, sisa ranjau disebar murni acak — kadang di akhir permainan user terpaksa menebak 50:50).
* B. Usahakan logika deduksi murni di level rendah, dan murni acak yang kejam di level *Nightmare* & *Are U a God?*.


53. **Fitur Tanda Tanya (`?`):**
* A. Tidak perlu (Cukup: Tertutup -> Bendera -> Tertutup).
* B. Perlu (Tertutup -> Bendera -> Tanda Tanya -> Tertutup).


54. **Penanganan Saat Menginjak Ranjau (Kalah):**
* A. Langsung Game Over dan perlihatkan semua posisi ranjau yang tersisa.
* B. Berikan opsi "Perisai / Defuse" (Khusus level *Chill* & *Mudah* punya 1x kesempatan selamat dari ledakan).


55. **Kondisi Menang Otomatis:**
* A. Menang segera setelah semua kotak **bukan ranjau** berhasil dibuka (Meskipun pemain tidak menaruh semua bendera).
* B. Harus membuka semua kotak aman DAN menancapkan semua bendera dengan tepat.


56. **Tampilan Penghitung di Atas Papan Minesweeper:**
* A. Sisa Ranjau (Total Ranjau dikurangi Bendera terpasang) + Stopwatch Timer.
* B. Tambahan indikator metrik kecepatan klik / *3BV* di akhir permainan.


57. **Tipe Timer di Minesweeper:**
* A. Murni Stopwatch (Hitung maju dari `00:00` saat kotak pertama diklik).
* B. Ada mode *Time Bomb* (Hitung mundur di level tertentu).



---

### Kategori 7: Mekanik Game 4 — SNAKE (58 - 67)

58. **Metode Kontrol Pergerakan Ular di Layar Sentuh:**
* A. *Swipe Gesture* di mana saja pada layar.
* B. Tombol arah Virtual D-Pad (Atas, Bawah, Kiri, Kanan) di bagian bawah layar.
* C. Bisa dipilih di pengaturan (Swipe, D-Pad, atau Tap sisi kiri/kanan layar untuk belok 90 derajat).


59. **Aturan Tembok Pinggir (Boundary Rules) berdasarkan 7 Level:**
* A. Level 1 (*Chill*) bisa tembus tembok pinggir (Muncul di sisi seberang), sedangkan Level 2–7 tembok pinggir mematikan.
* B. Semua level tembok pinggir mematikan, bedanya hanya di kecepatan dan balok rintangan di tengah papan.
* C. Tembok pinggir всегда tembus, rintangan mematikan hanya ada di tengah papan.


60. **Desain Rintangan (Obstacles/Maze) untuk 7 Tingkat Kesulitan:**
* A. Setiap level kesulitan (1–7) memiliki pola tembok labirin statis yang berbeda-beda (Makin tinggi level, labirin makin sempit).
* B. Di level *Nightmare* dan *Are U a God?*, balok rintangan bisa muncul/berpindah tempat secara dinamis setiap kali ular memakan 5 makanan!


61. **Kecepatan Ular (Speed Progression):**
* A. Kecepatan konstan sesuai level kesulitan yang dipilih dari awal sampai akhir.
* B. Kecepatan awal sesuai level yang dipilih, TAPI makin panjang ularnya, gerakannya makin cepat sedikit demi sedikit.


62. **Jenis Makanan / Umpan:**
* A. Hanya 1 jenis makanan standar (+1 panjang, +10 poin).
* B. Makanan standar + **Bonus Food** yang muncul sesekali dengan timer hitung mundur (Poin besar jika berhasil dimakan sebelum hilang).
* C. Ditambah item *Power-up / Debuff* (Misal: Gunting untuk memotong ekor, atau Racun yang membalik kontrol di level *Are U a God?*).


63. **Fungsi Timer di Game Snake:**
* A. Stopwatch durasi bertahan hidup (*Survival Time* — dicatat mendampingi skor poin).
* B. Timer hitung mundur untuk memakan umpan di level *Are U a God?* (*Starvation Mechanic*: jika dalam 10 detik tidak makan apel, ular kelaparan dan mati).
* C. Kombinasi: Level 1–6 menggunakan Stopwatch biasa, khusus Level 6–7 ada *Starvation Bar* + Stopwatch total waktu.


64. **Ukuran Grid Papan Snake:**
* A. Tetap (Misal 20x20 kotak untuk semua level).
* B. Menyesuaikan level (Misal level rendah grid lebih kecil/besar).


65. **Kondisi Menang Sempurna (Beat the Game) di Snake:**
* A. Jika badan ular memenuhi 100% seluruh kotak kosong di layar, tercatat sebagai kemenangan (`is_won = true`).
* B. Snake dianggap selalu tercatat dan di-ranking berdasarkan **Skor Tertinggi (High Score)** meskipun akhirnya menabrak.


66. **Gaya Visual Ular:**
* A. Kotak-kotak terpisah bergaya klasik Nokia.
* B. Tersambung mulus dengan sudut membulat (*Rounded smooth segments*) dan mata di bagian kepala yang menghadap arah jalan.


67. **Pencegahan Bunuh Diri Instan (Input Buffering):**
*(Jika ular sedang jalan ke Kanan, lalu pemain sangat cepat menekan Atas lalu Kiri sebelum 1 frame selesai, tanpa input queue ular akan langsung berbalik menabrak lehernya sendiri).*
* A. Wajib implementasikan *Input Queue* (Maksimal menyimpan 2 antrean belokan per *tick* agar kontrol terasa sangat responsif di level cepat).
* B. Standar biasa saja.



---

### Kategori 8: Polish, Audio & Pengalaman Pengguna (68 - 75)

68. **Efek Suara (Sound Effects / SFX):**
* A. Hanya efek suara klik/langkah pendek tanpa musik latar (Agar user bisa sambil mendengarkan Spotify/YouTube di HP).
* B. Efek suara + Musik latar (BGM) *chiptune/lo-fi* yang bisa di-*mute* terpisah di pengaturan.
* C. Tanpa suara sama sekali (Hanya getaran/Haptic).


69. **Getaran (Haptic Feedback):**
* A. Aktif untuk aksi penting (Pasang bendera Minesweeper, makan apel di Snake, skak di Catur, salah isi angka di Sudoku) dengan toggle On/Off.
* B. Tidak perlu fitur getar.


70. **LayarTetap Menyala (Keep Screen Awake / Wakelock):**
* A. Ya, selama berada di dalam papan permainan (terutama saat mikir lama di Catur atau Sudoku), layar HP tidak boleh meredup/terkunci otomatis.
* B. Ikuti pengaturan layar HP bawaan saja.


71. **Animasi Kemenangan:**
* A. Tampilkan efek *Confetti* / partikel singkat + kartu ringkasan skor (Waktu, Rekor Baru/Tidak, Tombol *Play Again*).
* B. Pop-up dialog teks sederhana saja.


72. **Keamanan Anti-Cheat Dasar untuk Skor Database:**
* A. Tambahkan validasi logis di Supabase Database/RLS (Misal: tolak *insert* skor Sudoku level *Are U a God?* jika durasinya di bawah 10 detik karena mustahil secara fisik).
* B. Tidak perlu validasi ketat karena aplikasi ini untuk penggunaan pribadi / komunitas terbatas.


73. **Fitur Share Skor:**
* A. Ada tombol untuk *generate* gambar kartu skor keren (Mirip Wordle/Strava) untuk dibagikan ke WhatsApp/sosmed.
* B. Tidak perlu fitur share.


74. **Penamaan Label 7 Tingkat Kesulitan di UI:**
* A. Persis seperti yang Anda tulis: `1. Chill`, `2. Mudah`, `3. Inter / Normal`, `4. High`, `5. PRO`, `6. Nightmare`, `7. Are U a God?`.
* B. diseragamkan ke Bahasa Inggris semua: `1. Chill`, `2. Easy`, `3. Normal`, `4. High`, `5. PRO`, `6. Nightmare`, `7. Are U a God?`.


75. **Prioritas Pengerjaan (MVP Phasing di dalam PRD):**
* A. Langsung rancang arsitektur *All-at-once* (Keempat game dibangun beriringan).
* B. Buat tahapan *milestone* di PRD (Tahap 1: Core Auth Supabase + Shell UI -> Tahap 2: Snake & Minesweeper -> Tahap 3: Sudoku -> Tahap 4: Chess Stockfish -> Tahap 5: Leaderboard & Polish).



---