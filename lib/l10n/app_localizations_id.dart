// ignore_for_file: deprecated_member_use

// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppLocalizationsId extends AppLocalizations {
  AppLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get appTitle => 'Zetzy';

  @override
  String get navHome => 'Main';

  @override
  String get navLeaderboard => 'Peringkat';

  @override
  String get navStatistics => 'Statistik';

  @override
  String get navProfile => 'Profil';

  @override
  String get homeSubtitle => 'Arkade & Strategi Minimalis Taktil';

  @override
  String get continueGame => 'Lanjutkan';

  @override
  String get newGame => 'Mulai Baru';

  @override
  String get play => 'Main';

  @override
  String get practiceMode => 'Mode Latihan';

  @override
  String get practiceModeDesc =>
      'Bisa Undo & mundur 1–3 langkah saat kalah. Skor tidak masuk leaderboard.';

  @override
  String get practiceUndo => 'Undo';

  @override
  String practiceRewindContinue(int count) {
    return 'Mundur $count Langkah';
  }

  @override
  String get selectDifficulty => 'Pilih Tingkat Kesulitan';

  @override
  String lockedLevelHint(String prevLevel) {
    return 'Menang di $prevLevel 1x untuk membuka';
  }

  @override
  String get guestModeBanner => 'Bermain Offline (Mode Tamu)';

  @override
  String syncQueuePending(int count) {
    return '$count skor menunggu sinkronisasi cloud';
  }

  @override
  String get gameSudoku => 'Sudoku';

  @override
  String get gameSudokuDesc =>
      'Teka-teki angka 9×9 dengan catatan pintar & seed 17-clue';

  @override
  String get gameChess => 'Catur';

  @override
  String get gameChessDesc =>
      'Vs AI, Pass & Play, atau Ruang Online dengan rating ELO';

  @override
  String get gameMinesweeper => 'Minesweeper';

  @override
  String get gameMinesweeperDesc =>
      'Chording, Perisai Defuse & metrik kecepatan 3BV';

  @override
  String get gameSnake => 'Snake';

  @override
  String get gameSnakeDesc =>
      'Arkade mulus dengan labirin, power-up & mode kelaparan';

  @override
  String get diffChill => 'Chill';

  @override
  String get diffEasy => 'Easy';

  @override
  String get diffNormal => 'Normal';

  @override
  String get diffHigh => 'High';

  @override
  String get diffPro => 'PRO';

  @override
  String get diffNightmare => 'Nightmare';

  @override
  String get diffGod => 'Are U a God?';

  @override
  String get pausedTitle => 'Permainan Dijeda';

  @override
  String get pausedSubtitle => 'Blur anti-cheat aktif. Timer dihentikan.';

  @override
  String get resume => 'Lanjutkan';

  @override
  String get restart => 'Ulangi';

  @override
  String get quit => 'Keluar';

  @override
  String get victory => 'Menang!';

  @override
  String get gameOver => 'Permainan Berakhir';

  @override
  String get draw => 'Seri';

  @override
  String get newRecord => 'Rekor Pribadi Baru!';

  @override
  String get timeLabel => 'Waktu';

  @override
  String get scoreLabel => 'Skor';

  @override
  String get mistakesLabel => 'Kesalahan';

  @override
  String get playAgain => 'Main Lagi';

  @override
  String get shareScore => 'Bagikan Skor';

  @override
  String get backToHome => 'Kembali ke Menu';

  @override
  String get sudokuLives => 'Nyawa';

  @override
  String get sudokuUnlimited => 'Tak Terbatas';

  @override
  String get sudokuNotes => 'Catatan';

  @override
  String get sudokuErase => 'Hapus';

  @override
  String get sudokuHint => 'Petunjuk';

  @override
  String get sudokuUndoNotes => 'Undo Catatan';

  @override
  String get sudokuDigitLockHint => 'Tekan lama angka untuk kunci input cepat';

  @override
  String get sudokuConflictOnlyNote => 'Mode PRO+: Hanya deteksi konflik';

  @override
  String get sudokuConflictGuideTitle => 'Mode PRO+ Deteksi Konflik';

  @override
  String get sudokuConflictGuideBody =>
      '• Chill – High (Level 1–4): Angka langsung dicek ke kunci jawaban. Angka salah langsung mengurangi 1 nyawa, dan kotak benar terkunci.\n• PRO – God (Level 5–7): Kunci jawaban tidak dibocorkan sehingga Anda bebas mengisi dan mengganti angka tebakan.\n• Cara Nyawa Berkurang di PRO+: Mengisi angka kembar yang berkonflik di baris, kolom, atau blok 3×3 yang sama akan mengurangi 1 nyawa (PRO: 3, Nightmare: 2, God: 1 Sudden Death).\n• Menang / Kalah: Jika nyawa habis maka Game Over. Mengisi semua 81 kotak tanpa konflik berarti Menang.';

  @override
  String get chessModeVsAi => 'Lawan AI';

  @override
  String get chessModePassPlay => 'Pass & Play';

  @override
  String get chessModeFindMatch => 'Cari Lawan';

  @override
  String get chessModeOnline => 'Ruang Online';

  @override
  String get chessPlayAs => 'Main Sebagai';

  @override
  String get chessWhite => 'Putih';

  @override
  String get chessBlack => 'Hitam';

  @override
  String get chessRandom => 'Acak';

  @override
  String get chessTimeControl => 'Kontrol Waktu';

  @override
  String get chessUntimed => 'Tanpa Waktu';

  @override
  String get chessBullet => 'Bullet (1m)';

  @override
  String get chessBlitz3 => 'Blitz (3m)';

  @override
  String get chessBlitz5 => 'Blitz (5m)';

  @override
  String get chessRapid => 'Rapid (10m)';

  @override
  String get chessUndo => 'Undo';

  @override
  String get chessUndoLocked => 'Undo terkunci di PRO+';

  @override
  String get chessResign => 'Menyerah';

  @override
  String get chessFlipBoard => 'Putar';

  @override
  String get chessMoves => 'Langkah (PGN)';

  @override
  String get chessCaptured => 'Termakan';

  @override
  String get chessPromotion => 'Promosi Pion';

  @override
  String get chessAiThinking => 'AI sedang berpikir...';

  @override
  String get chessCheck => 'Skak!';

  @override
  String get chessCreateRoom => 'Buat Ruang';

  @override
  String get chessJoinRoom => 'Gabung Ruang';

  @override
  String get chessRoomCode => 'Kode Ruang';

  @override
  String get chessWaitingOpponent => 'Menunggu lawan...';

  @override
  String get chessOnlineRequiresAuth =>
      'Masuk ke akun Anda untuk bermain Multiplayer Online.';

  @override
  String get chessFindMatchStart => 'Cari Lawan';

  @override
  String get chessFindingMatchTitle => 'Mencari Lawan Ranked...';

  @override
  String chessSearchingEloRange(int minElo, int maxElo, int radius) {
    return 'Mencari ELO: $minElo – $maxElo (±$radius)';
  }

  @override
  String chessSearchingNearestElo(int minElo, int maxElo) {
    return 'Mencari ELO: $minElo – $maxElo (Terdekat / Bebas)';
  }

  @override
  String get chessExpandingRangeHint =>
      'Belum ada ELO setara? Rentang meluas otomatis hingga menemukan lawan terdekat.';

  @override
  String chessFindMatchStage(int stage, int total, int seconds) {
    return 'Tahap $stage/$total • ${seconds}d';
  }

  @override
  String get chessMatchTimedOnlyNote =>
      'Cari Lawan wajib memakai kontrol waktu (Tanpa Waktu dinonaktifkan agar bebas AFK).';

  @override
  String get chessAutoColorFair =>
      'Warna Putih/Hitam diacak secara adil saat lawan ditemukan.';

  @override
  String get chessOnlineUnratedNote =>
      'Ruang Teman bersifat Unrated (Santai) untuk mencegah kecurangan ELO/skor PRO+.';

  @override
  String get chessAbortedTooShortTitle => 'Laga Dibatalkan';

  @override
  String get chessAbortedTooShortNote =>
      'Berakhir sebelum 4 langkah-paruh — dihitung Unrated (0 perubahan ELO) demi Fair Play.';

  @override
  String get chessOpponentLabel => 'Lawan';

  @override
  String chessYourElo(int elo) {
    return 'ELO Anda: $elo';
  }

  @override
  String chessMatchFoundBanner(String username, int elo) {
    return 'Bertemu @$username (ELO $elo)';
  }

  @override
  String get chessTapForDetails => 'Ketuk untuk info ELO, skor & panduan main';

  @override
  String get chessModeGuideTitle => 'Aturan Pertandingan & Skor';

  @override
  String get chessPracticeDisabledNote =>
      'Mode Latihan aktif: ELO, Papan Skor, XP, dan pembukaan level dinonaktifkan untuk laga ini.';

  @override
  String chessTimeControlRule(String timeLabel) {
    return 'Kontrol Waktu ($timeLabel) hanya mengatur batas waktu tiap pemain. Bullet, Blitz, Rapid, dan Tanpa Waktu memberi ELO serta XP yang sama (durasi lebih cepat hanya unggul saat skor seri di Papan Skor).';
  }

  @override
  String get chessInfoSummaryVsAi => 'Ranked • ELO lawan AI & Papan Skor';

  @override
  String get chessInfoSummaryPassPlay => '2 Pemain Lokal • Tanpa ELO & Skor';

  @override
  String get chessInfoSummaryFindMatch =>
      'Ranked Acak 1v1 • Matchmaking ELO Dinamis';

  @override
  String get chessInfoSummaryOnline =>
      'Ruang Teman 1v1 • Unrated (Anti-Curang)';

  @override
  String get chessInfoSummaryPractice => 'Mode Latihan • Tanpa ELO & Skor';

  @override
  String chessInfoDetailVsAi(String level, String rating, String xp) {
    return '• Kekuatan Lawan: AI Level $level (Rating $rating).\n• ELO Catur & Papan Skor: Menang, seri, atau kalah mengubah ELO Catur Anda (rumus K=32). Selisih ELO dicatat sebagai skor, dan kemenangan masuk Papan Skor serta memberi +$xp XP.\n• Buka Level: Menang di PRO membuka Nightmare, dan menang di Nightmare membuka Are U a God?.';
  }

  @override
  String get chessInfoDetailPassPlay =>
      '• Cara Bermain: Anda dan teman bergantian melangkah Putih lalu Hitam pada satu perangkat yang sama.\n• Skor & ELO: Dihitung sebagai laga lokal santai (seperti Mode Latihan). Tidak mengubah ELO Catur, tidak masuk Papan Skor, dan tidak memberi XP maupun membuka level.';

  @override
  String get chessInfoDetailFindMatch =>
      '• Matchmaking Acak Adil: Mempertemukan Anda dengan pemain lain yang sedang antre di Kontrol Waktu berdurasi sama (Bullet, Blitz, atau Rapid).\n• Rentang ELO Meluas Otomatis: Mulai mencari lawan di sekitar ELO Anda (±50) lalu meluas bertahap (±120 → ±250 → ±500 → ±1000). Jika tetap belum ada lawan setelah 45 detik, sistem memilih pemain aktif terdekat (400–3500) meski selisihnya ratusan atau ribuan poin.\n• Perlindungan Anti-Curang: Warna diacak adil, blokir duel akun sendiri, menyerah sebelum 4 langkah-paruh dibatalkan (Aborted, 0 ELO), ELO dihitung memakai rating asli lawan (K=32), dan pembukaan level Nightmare/God tetap khusus mode Lawan AI.';

  @override
  String get chessInfoDetailOnline =>
      '• Konsep: Duel privat 1v1 via Supabase Realtime khusus bermain santai bersama teman.\n• Host & Gabung: Masuk ke akun dulu. Host memilih warna & Kontrol Waktu lalu membagikan Kode Ruang 6 karakter; teman memasukkan kode untuk bergabung.\n• Anti-Curang & Unrated: Ruang Privat selalu bersifat Unrated — tidak mengubah ELO Catur, tidak masuk Papan Skor PRO+, tidak memberi XP, dan tidak membuka level Nightmare/God agar tidak bisa dipakai win-trading.';

  @override
  String get chessCopyCode => 'Salin';

  @override
  String chessRoomCodeCopied(String code) {
    return 'Kode ruang disalin: $code';
  }

  @override
  String get mineRemaining => 'Ranjau';

  @override
  String get mineModeDig => 'Gali';

  @override
  String get mineModeFlag => 'Bendera';

  @override
  String get mineModeQuestion => 'Tanda (?)';

  @override
  String get mineShieldActive => 'Perisai Defuse Siap';

  @override
  String get mineShieldUsed => 'Perisai Terpakai!';

  @override
  String get mine3bv => '3BV';

  @override
  String get mine3bvSec => '3BV/s';

  @override
  String get mineDesktopHint =>
      'Scroll: Zoom • Klik Kanan: Bendera • Tengah/Spasi+Seret: Geser';

  @override
  String get snakeSpeed => 'Kecepatan';

  @override
  String get snakeLength => 'Panjang';

  @override
  String get snakeStarvation => 'Kelaparan';

  @override
  String get snakeDebuffReversed => 'KERACUNAN! Kontrol Terbalik';

  @override
  String get snakeObstacleWarning => 'Rintangan berpindah sebentar lagi!';

  @override
  String get snakeDesktopHint => 'Gunakan tombol WASD atau Panah';

  @override
  String get snakeTapLeft => 'Belok Kiri';

  @override
  String get snakeTapRight => 'Belok Kanan';

  @override
  String get leaderboardGlobal => 'Top 100 Global';

  @override
  String get leaderboardMyBest => 'Rekor Saya';

  @override
  String get leaderboardChessElo => 'ELO Catur';

  @override
  String get leaderboardEmpty => 'Belum ada rekor untuk filter ini.';

  @override
  String get leaderboardRank => 'Peringkat';

  @override
  String get leaderboardPlayer => 'Pemain';

  @override
  String get leaderboardPlatform => 'Perangkat';

  @override
  String leaderboardLoadMore(int count) {
    return 'Muat $count lagi';
  }

  @override
  String get leaderboardRefresh => 'Muat Ulang';

  @override
  String leaderboardShowingCount(int count) {
    return 'Menampilkan $count data • Muat ulang untuk skor terbaru';
  }

  @override
  String get statsTotalGames => 'Total Main';

  @override
  String get statsTotalWins => 'Menang';

  @override
  String get statsWinRate => 'Rasio Menang';

  @override
  String get statsBestStreak => 'Win Streak Terbaik';

  @override
  String get statsTotalTime => 'Total Jam Main';

  @override
  String get statsAvgTime => 'Rata-rata Durasi';

  @override
  String statsPlayerLevel(int level) {
    return 'Level $level';
  }

  @override
  String statsXp(int xp) {
    return '$xp XP';
  }

  @override
  String get statsChartTitle => 'Performa Terbaru & Tren Kemenangan';

  @override
  String get profileGuest => 'Pemain Tamu';

  @override
  String get profileSignIn => 'Masuk';

  @override
  String get profileRegister => 'Daftar Akun';

  @override
  String get profileSignOut => 'Keluar';

  @override
  String get profileUsername => 'Username';

  @override
  String get profilePassword => 'Password';

  @override
  String get profileConfirmPassword => 'Konfirmasi Password';

  @override
  String get profileOldPassword => 'Password Lama';

  @override
  String get profileNewPassword => 'Password Baru';

  @override
  String get profileForgotPassword => 'Lupa Password?';

  @override
  String get profileRecoveryPhrase => 'Kode Pemulihan / Passphrase';

  @override
  String get profileRecoveryToggle => 'Aktifkan Kode Pemulihan';

  @override
  String get profileRecoveryDesc =>
      'Memungkinkan reset password tanpa email lewat frasa rahasia ter-hash.';

  @override
  String get profileChangeUsername => 'Ganti Username';

  @override
  String get profileChangePassword => 'Ganti Password';

  @override
  String get profileConfigureAccount => 'Atur Akun';

  @override
  String get profileUploadAvatar => 'Unggah Foto Profil';

  @override
  String get profileAvatarUpdated => 'Foto profil berhasil diperbarui!';

  @override
  String get profileAvatarSignInRequired =>
      'Masuk atau daftar akun untuk mengunggah foto profil.';

  @override
  String get profileAvatarSourceGallery => 'Pilih dari Galeri / Foto';

  @override
  String get profileAvatarSourceCamera => 'Ambil Foto dengan Kamera';

  @override
  String get profileResetStats => 'Reset Semua Statistik';

  @override
  String get profileDeleteAccount => 'Hapus Akun Permanen';

  @override
  String get profileDangerZone => 'Manajemen Akun & Data';

  @override
  String get profileDangerZoneDesc =>
      'Tindakan di bawah ini menghapus progres statistik atau menghapus akun secara permanen dan tidak dapat dibatalkan.';

  @override
  String profileAppVersion(String version) {
    return 'Zetzy v$version';
  }

  @override
  String get settingsAppearance => 'Tampilan & Bahasa';

  @override
  String get settingsTheme => 'Skin Tema';

  @override
  String get settingsLanguage => 'Bahasa';

  @override
  String get settingsGameplay => 'Gameplay & Kontrol';

  @override
  String get settingsAudioSfx => 'Efek Suara (SFX)';

  @override
  String get settingsAudioBgm => 'Musik Latar (BGM)';

  @override
  String get settingsAudioPending => 'Paket file audio menyusul';

  @override
  String get settingsHaptics => 'Getaran (Haptic Feedback)';

  @override
  String get settingsWakelock => 'Layar Tetap Menyala saat Main';

  @override
  String get settingsSnakeControl => 'Kontrol Sentuh Snake';

  @override
  String get settingsSnakeSwipe => 'Usap (Swipe)';

  @override
  String get settingsSnakeDpad => 'D-Pad Virtual';

  @override
  String get settingsSnakeSplit => 'Tap Kiri/Kanan Layar';

  @override
  String get settingsChessPieces => 'Gaya Bidak Catur';

  @override
  String get settingsChessAutoQueen => 'Otomatis Jadi Menteri (Auto-Queen)';

  @override
  String get settingsPracticeRewind => 'Mundur saat Kalah (Mode Latihan)';

  @override
  String get settingsPracticeRewindDesc =>
      'Izinkan mundur 1–3 langkah tanpa mengulang dari awal saat kalah di Mode Latihan.';

  @override
  String get settingsPracticeRewindSteps => 'Jumlah Langkah Mundur (Practice)';

  @override
  String practiceRewindStepOption(int count) {
    return '$count Langkah';
  }

  @override
  String get settingsCloudStatus => 'Cloud & Sinkronisasi';

  @override
  String get settingsSupabaseConfigured => 'Sinkronisasi Cloud Terhubung';

  @override
  String get settingsSupabaseLocalOnly =>
      'Mode Offline (Sinkronisasi cloud tidak tersedia)';

  @override
  String get themeOledMidnight => 'OLED Midnight';

  @override
  String get themeClassicWood => 'Classic Wood & Slate';

  @override
  String get themeNordicFrost => 'Nordic Frost';

  @override
  String get themeDraculaNeon => 'Dracula Neon';

  @override
  String get themeAbyssalCyan => 'Abyssal Cyan';

  @override
  String get themeWarmParchment => 'Warm Parchment';

  @override
  String get cancel => 'Batal';

  @override
  String get save => 'Simpan';

  @override
  String get confirm => 'Konfirmasi';

  @override
  String get close => 'Tutup';

  @override
  String get copied => 'Disalin ke papan klip';

  @override
  String get requiredHint => '* Wajib diisi';

  @override
  String get optionalLabel => 'Opsional';

  @override
  String get invalidUsername =>
      '3–16 karakter: huruf kecil, angka, atau _ saja.';

  @override
  String get invalidPassword =>
      'Minimal 8 karakter dengan kombinasi huruf dan angka.';

  @override
  String get reviewBoard => 'Lihat Papan';

  @override
  String get viewResult => 'Lihat Hasil';

  @override
  String wrongFlagsCount(int count) {
    return '$count bendera salah';
  }

  @override
  String get minesRevealedHint =>
      'Semua ranjau & bendera terlihat. Cubit atau geser untuk periksa.';

  @override
  String get chessReviewTitle => 'Analisis Langkah';

  @override
  String chessMoveStep(int current, int total) {
    return 'Langkah $current/$total';
  }

  @override
  String get sudokuShowSolution => 'Lihat Jawaban';

  @override
  String get sudokuHideSolution => 'Sembunyikan Jawaban';

  @override
  String get sudokuMistakeReviewHint =>
      'Angka yang salah ditandai warna merah.';

  @override
  String get snakeDeathWall => 'Menabrak dinding arena.';

  @override
  String get snakeDeathObstacle => 'Menabrak blok rintangan.';

  @override
  String get snakeDeathSelf => 'Menabrak tubuh sendiri.';

  @override
  String get snakeDeathStarvation => 'Energi habis sebelum mencapai makanan.';

  @override
  String get snakeAllCleared => 'Arena berhasil diselesaikan!';

  @override
  String get settingsInGameTitle => 'Pengaturan Cepat';

  @override
  String get settingsInGameSubtitle => 'Aman diubah tanpa mengulang permainan';

  @override
  String get settingsSudokuAutoFinish => 'Selesai Otomatis';

  @override
  String get settingsSudokuAutoFinishDesc =>
      'Tampilkan tombol Selesai Otomatis saat hanya sedikit kotak tersisa.';

  @override
  String get settingsSudokuAutoFinishThreshold => 'Batas Sisa Kotak';

  @override
  String sudokuRemainingCellsOption(int count) {
    return '$count Kotak';
  }

  @override
  String sudokuAutoFinishAction(int count) {
    return 'Selesai Otomatis ($count)';
  }

  @override
  String get settingsSudokuHighlightSame => 'Sorot Angka yang Sama';

  @override
  String get settingsSudokuAutoClearNotes => 'Hapus Catatan Otomatis';

  @override
  String get settingsChessLegalMoves => 'Tampilkan Titik Langkah Legal';

  @override
  String get settingsChessCoordinates => 'Tampilkan Koordinat Papan';

  @override
  String get settingsMinesweeperQuickChord => 'Ketuk Angka untuk Chord';

  @override
  String get settingsMinesweeperQuickChordDesc =>
      'Buka kotak sekitar saat jumlah bendera sudah sesuai.';

  @override
  String get settingsSnakeGridLines => 'Tampilkan Garis Grid Arena';

  @override
  String get settingsPracticeSection => 'Mode Latihan';

  @override
  String get settingsSudokuStreakStats => 'Streak Bebas Salah & Akurasi';

  @override
  String get settingsSudokuStreakStatsDesc =>
      'Tampilkan streak beruntun & akurasi di papan dan ringkasan.';

  @override
  String get settingsSudokuSmartNotes => 'Catatan Kandidat Otomatis';

  @override
  String get settingsSudokuSmartNotesDesc =>
      'Isi kandidat valid otomatis di Mode Latihan atau Lv 1–2.';

  @override
  String get sudokuFillCandidates => 'Kandidat';

  @override
  String sudokuStreakBadge(int count) {
    return 'Streak $count';
  }

  @override
  String get sudokuBestStreakLabel => 'Streak Terbaik';

  @override
  String get sudokuAccuracyLabel => 'Akurasi';

  @override
  String get settingsMinesweeperSwapTapFlag => 'Tukar Tap & Bendera (1 Tangan)';

  @override
  String get settingsMinesweeperSwapTapFlagDesc =>
      'Ketuk singkat memasang bendera, tekan lama untuk menggali.';

  @override
  String get mineTapFlagActive => '1-Tap: Bendera';

  @override
  String get mineTapDigActive => '1-Tap: Gali';

  @override
  String get settingsChessMoveConfirm => 'Konfirmasi Langkah Sentuh';

  @override
  String get settingsChessConfirmOff => 'Mati';

  @override
  String get settingsChessConfirmFast => 'Bullet/Blitz';

  @override
  String get settingsChessConfirmAlways => 'Selalu';

  @override
  String get settingsChessAutoFlipPassPlay => 'Putar Otomatis Pass & Play';

  @override
  String chessConfirmMovePrompt(String move) {
    return 'Konfirmasi $move?';
  }

  @override
  String get settingsSnakeAssistOverlay => 'Bayangan Dinding & Arah Swipe';

  @override
  String get settingsSnakeAssistOverlayDesc =>
      'Tampilkan pratinjau rintangan & panah arah belokan.';

  @override
  String get settingsHapticIntensity => 'Kekuatan Getaran';

  @override
  String get hapticLight => 'Ringan';

  @override
  String get hapticMedium => 'Sedang';

  @override
  String get hapticStrong => 'Kuat';

  @override
  String get bgmModeOff => 'Mati';

  @override
  String get bgmModeAuto => 'Otomatis';

  @override
  String get bgmModeManual => 'Manual';

  @override
  String bgmAutoDesc(int number) {
    return 'Acak otomatis semua trek (★ Trek $number diputar lebih sering).';
  }

  @override
  String get bgmFavoriteTrackLabel => 'Trek Favorit (Prioritas 3× di Otomatis)';

  @override
  String bgmTrackLabel(int number) {
    return 'Trek $number';
  }

  @override
  String bgmNowPlaying(int number) {
    return 'Diputar: Trek $number';
  }

  @override
  String get bgmNextTrack => 'Trek Berikutnya';

  @override
  String get badgesTitle => 'Koleksi Badge';

  @override
  String get badgesSubtitle => 'Ketuk badge untuk perbesar & lihat detail';

  @override
  String badgesConqueredCount(int count, int total) {
    return '$count/$total Ditaklukkan';
  }

  @override
  String badgeWonCount(int count) {
    return '$count× Menang';
  }

  @override
  String get badgeStatusOpen => 'Terbuka';

  @override
  String get badgeStatusLocked => 'Terkunci';

  @override
  String get badgeAvailableAllGames => 'Terbuka sejak awal di semua 4 game';

  @override
  String get badgeUnlockedChallenge => 'Tier terbuka — Tantangan tingkat ahli';

  @override
  String get badgeSelectedPreview => 'Tier Dipilih';

  @override
  String get feedbackTitle => 'Feedback';

  @override
  String get feedbackAdminInboxTitle => 'Kotak Masuk Feedback';

  @override
  String get feedbackTabInbox => 'Kotak Masuk';

  @override
  String get feedbackTabMine => 'Feedback Saya';

  @override
  String get feedbackPrivacyNote =>
      'Feedback hanya dapat dilihat oleh Anda dan admin.';

  @override
  String get feedbackSignInRequired =>
      'Masuk ke akun Anda untuk mengirim feedback dan melihat balasan admin.';

  @override
  String feedbackPendingCount(int count, int max) {
    return 'Menunggu: $count/$max';
  }

  @override
  String get feedbackPlaceholder =>
      'Tulis laporan bug, saran fitur, atau masukan Anda...';

  @override
  String get feedbackSubmit => 'Kirim Feedback';

  @override
  String feedbackLimitReached(int max) {
    return 'Batas $max feedback menunggu tercapai. Tunggu tinjauan admin atau hapus yang lama.';
  }

  @override
  String get feedbackStatusPending => 'Menunggu';

  @override
  String get feedbackStatusApproved => 'Disetujui';

  @override
  String get feedbackStatusRejected => 'Ditolak';

  @override
  String get feedbackEditAction => 'Edit';

  @override
  String get feedbackEditDialogTitle => 'Edit Feedback';

  @override
  String feedbackEditWindow(String time) {
    return 'Bisa edit ($time)';
  }

  @override
  String get feedbackEditLocked => 'Edit terkunci (>6 jam)';

  @override
  String get feedbackDeleteAction => 'Hapus';

  @override
  String get feedbackDeleteConfirmTitle => 'Hapus Feedback?';

  @override
  String get feedbackDeleteConfirmBody =>
      'Feedback ini akan dihapus secara permanen.';

  @override
  String get feedbackAdminReplyLabel => 'Balasan Admin';

  @override
  String feedbackAutoDeleteNotice(String time) {
    return 'Terhapus dlm $time';
  }

  @override
  String get feedbackReviewActionApprove => 'Centang';

  @override
  String get feedbackReviewActionReject => 'Tolak';

  @override
  String get feedbackReviewDialogTitle => 'Tinjau & Balas (1× Saja)';

  @override
  String get feedbackReviewReplyHint =>
      'Pesan balasan opsional untuk pemain...';

  @override
  String get feedbackEmptyMine => 'Belum ada feedback yang dikirim.';

  @override
  String get feedbackEmptyInbox => 'Belum ada feedback dari pemain.';

  @override
  String get feedbackLoadMore => 'Muat Lagi (20)';

  @override
  String get profileFeedbackButton => 'Feedback';

  @override
  String get profileRoleAdminBadge => 'ADMIN';

  @override
  String get homeGuideTutorialButton => 'Panduan & Tutorial';

  @override
  String guideDialogTitle(String game) {
    return 'Panduan & Aturan $game';
  }

  @override
  String get guideDialogSubtitle =>
      'Geser slide untuk melihat ilustrasi & aturan';

  @override
  String get guidePrev => 'Sebelumnya';

  @override
  String get guideNext => 'Berikutnya';

  @override
  String get guideClose => 'Keluar Panduan';

  @override
  String get guideStartTutorial => 'Mulai Tutorial';

  @override
  String get guideSudokuS1Badge => '1. ATURAN DASAR';

  @override
  String get guideSudokuS1Title => 'Isi Angka 1–9 Tanpa Kembar';

  @override
  String get guideSudokuS1Desc =>
      'Papan Sudoku berukuran 9×9 yang terbagi menjadi 9 blok kotak 3×3. Tugasmu mengisi semua kotak kosong dengan angka 1 sampai 9.';

  @override
  String get guideSudokuS1Bullets =>
      'Setiap BARIS mendatar wajib berisi angka 1–9 tanpa ada yang kembar.\nSetiap KOLOM menurun wajib berisi angka 1–9 tanpa ada yang kembar.\nSetiap KOTAK 3×3 tebal wajib berisi angka 1–9 tanpa ada yang kembar.';

  @override
  String get guideSudokuS1VisualCaption => 'Kotak tengah hanya kurang angka 5!';

  @override
  String get guideSudokuS2Badge => '2. CARA BERMAIN';

  @override
  String get guideSudokuS2Title => 'Ketuk Kotak & Gunakan Sorotan Angka';

  @override
  String get guideSudokuS2Desc =>
      'Saat kamu mengetuk sebuah angka di papan atau keypad bawah, semua angka yang sama otomatis disorot agar mudah mencari posisi kosong.';

  @override
  String get guideSudokuS2Bullets =>
      'Pilih kotak kosong lalu ketuk angka 1–9 di bagian bawah layar.\nDi Level 1–4, jawaban yang benar otomatis terkunci aman.\nKetuk lagi kotak yang sama untuk mematikan sorotan.';

  @override
  String get guideSudokuS3Badge => '3. STRATEGI AMAN';

  @override
  String get guideSudokuS3Title => 'Gunakan Mode Notes (Catatan Pensil)';

  @override
  String get guideSudokuS3Desc =>
      'Belum yakin antara 2 angka? Jangan menebak! Aktifkan tombol Notes (✏️) untuk menulis angka kandidat kecil di dalam kotak.';

  @override
  String get guideSudokuS3Bullets =>
      'Mode Notes tidak akan mengurangi nyawa (♥) meskipun angkanya belum pasti.\nFitur Smart Notes otomatis menghapus catatan yang sudah tidak mungkin.\nGunakan tombol Erase untuk membersihkan kotak atau catatan.';

  @override
  String get guideSudokuS3VisualBadge => 'Notes ON (Aman)';

  @override
  String get guideSudokuS4Badge => '4. NYAWA & BANTUAN';

  @override
  String get guideSudokuS4Title => '3 Nyawa (♥), 3 Hint & ⚡ Auto-Finish';

  @override
  String get guideSudokuS4Desc =>
      'Kamu punya 3 nyawa dan maksimal 3 Hint per permainan. Saat sisa kotak kosong tinggal sedikit, tombol kilat Auto-Finish akan muncul!';

  @override
  String get guideSudokuS4Bullets =>
      'Salah isi angka akan memicu tanda merah & mengurangi 1 nyawa (♥).\nTombol ⚡ Auto-Finish otomatis menyelesaikan sisa papan saat hampir menang.\nDi Practice Mode, kamu bebas memakai Undo & Rewind saat kalah!';

  @override
  String get guideSudokuS4VisualBadge => 'Auto-Finish (Sisa ≤ 5 Kotak)';

  @override
  String get guideMineS1Badge => '1. ARTI ANGKA';

  @override
  String get guideMineS1Title => 'Angka = Jumlah Ranjau di Sekelilingnya';

  @override
  String get guideMineS1Desc =>
      'Setiap kotak yang terbuka dan berisi angka (1, 2, 3...) memberi tahu berapa banyak ranjau di 8 kotak tetangga yang menyentuhnya (termasuk miring/diagonal).';

  @override
  String get guideMineS1Bullets =>
      'Klik pertama dijamin 100% AMAN dan langsung membuka area bersih.\nAngka 1 berarti tepat ada 1 ranjau di antara kotak tertutup di sebelahnya.\nKotak kosong (0) otomatis membuka seluruh tetangganya yang aman.';

  @override
  String get guideMineS1VisualCaption =>
      'Angka \"1\" di tengah menyentuh tepat 1 ranjau di pojok kanan atas!';

  @override
  String get guideMineS2Badge => '2. GALI VS BENDERA';

  @override
  String get guideMineS2Title => 'Tancapkan Bendera (🚩) di Kotak Curiga';

  @override
  String get guideMineS2Desc =>
      'Jangan pernah menggali kotak yang kamu yakini berisi ranjau! Pasang Bendera (🚩) agar kotak tersebut terkunci dan tidak sengaja tergali.';

  @override
  String get guideMineS2Bullets =>
      'Tahan lama (Long-Press) pada kotak tertutup untuk pasang/cabut Bendera.\nAtau gunakan tombol 1-Tap Swap di bawah untuk berganti mode Gali ⇄ Bendera.\nMenang terjadi saat SEMUA kotak aman berhasil dibuka!';

  @override
  String get guideMineS2VisualCaption =>
      'Tandai kotak ranjau dengan Bendera (🚩) agar aman!';

  @override
  String get guideMineS3Badge => '3. TEKNIK PRO';

  @override
  String get guideMineS3Title => 'Chord: Ketuk Angka untuk Buka Cepat';

  @override
  String get guideMineS3Desc =>
      'Jika sebuah angka sudah dikelilingi jumlah Bendera (🚩) yang pas, ketuk angka tersebut untuk membuka semua sisa kotak tetangga sekaligus!';

  @override
  String get guideMineS3Bullets =>
      'Contoh: Angka \"1\" sudah menyentuh 1 Bendera → ketuk angka \"1\" itu!\nSemua kotak tertutup lain di sebelahnya langsung terbuka otomatis.\nHati-hati: pastikan posisi benderamu benar sebelum melakukan Chord!';

  @override
  String get guideMineS4Badge => '4. PERISAI PEMULA';

  @override
  String get guideMineS4Title => 'Perisai Defuse (🛡️) Penyelamat Nyawa';

  @override
  String get guideMineS4Desc =>
      'Khusus untuk pemula di Level 1–2, kamu dibekali Perisai Defuse (🛡️) yang otomatis menjinakkan ranjau jika kamu salah langkah!';

  @override
  String get guideMineS4Bullets =>
      'Ranjau yang dijinakkan berubah menjadi ikon ranjau hijau aman.\nDi akhir permainan, semua posisi ranjau & bendera yang salah akan ditampilkan.\nGunakan tombol View Board setelah selesai untuk belajar dari pola papan.';

  @override
  String get guideMineS4VisualCaption =>
      'Perisai Lv. 1–2 otomatis menjinakkan ranjau!';

  @override
  String get guideChessS1Badge => '1. GERAK 6 BIDAK';

  @override
  String get guideChessS1Title => 'Cara Jalan Setiap Bidak Catur';

  @override
  String get guideChessS1Desc =>
      'Ketuk bidakmu untuk melihat titik hijau langkah sah di papan. Hanya Kuda (♘) yang boleh melompati bidak lain!';

  @override
  String get guideChessS1Bullets =>
      '♔ Raja: 1 petak ke segala arah • ♕ Menteri: bebas lurus & diagonal.\n♖ Benteng: lurus vertikal/horizontal • ♗ Gajah: miring diagonal.\n♘ Kuda: huruf \"L\" (2+1 petak) • ♙ Pion: maju 1 (awal 2), makan miring.';

  @override
  String get guideChessS2Badge => '2. SKAKMAT VS STALEMATE';

  @override
  String get guideChessS2Title => 'Awas! Stalemate Itu Seri, Bukan Menang';

  @override
  String get guideChessS2Desc =>
      'Banyak pemula mengira mengurung Raja lawan tanpa skak adalah menang. Padahal jika lawan tidak sedang Skak tapi habis langkah sah, hasilnya SERI (Stalemate)!';

  @override
  String get guideChessS2Bullets =>
      'Skak (Check): Raja diserang — wajib menyelamatkan Raja di giliran itu.\nSkakmat (Checkmate): Raja diserang & tidak ada jalan selamat → MENANG!\nRemis (Draw): terjadi karena Stalemate, 3× posisi sama, atau 50 langkah kosong.';

  @override
  String get guideChessS2Checkmate => 'SKAKMAT (Menang)';

  @override
  String get guideChessS2Stalemate => 'STALEMATE (Seri!)';

  @override
  String get guideChessS3Badge => '3. ATURAN LANGKA #1';

  @override
  String get guideChessS3Title => 'Rokade (Castling ♔⇄♖): Amankan Raja';

  @override
  String get guideChessS3Desc =>
      'Satu-satunya langkah di mana 2 bidak bergerak sekaligus! Raja bergeser 2 petak mendekati Benteng, lalu Benteng melompat ke sebelahnya.';

  @override
  String get guideChessS3Bullets =>
      'Syarat 1: Raja dan Benteng tersebut sama-sama BELUM PERNAH bergerak.\nSyarat 2: Semua petak di antara Raja & Benteng harus kosong.\nSyarat 3: Raja tidak sedang Skak, dan tidak melewati petak yang diserang lawan.';

  @override
  String get guideChessS3VisualCaption =>
      'Rokade Pendek: Raja e1 → g1, Benteng h1 → f1 melompati Raja!';

  @override
  String get guideChessS4Badge => '4. ATURAN LANGKA #2';

  @override
  String get guideChessS4Title => 'En Passant & Promosi Pion (♙ → ♕)';

  @override
  String get guideChessS4Desc =>
      'Dua aturan pion yang sering mengejutkan pemain baru: tangkapan sambil lalu (En Passant) dan perubahan wujud pion di baris ujung!';

  @override
  String get guideChessS4Bullets =>
      'En Passant: Jika pion lawan loncat 2 petak tepat di samping pionmu, kamu boleh memakannya miring seolah ia baru maju 1 petak (wajib langsung di giliran itu!).\nPromosi: Pion yang mencapai baris paling ujung langsung berubah jadi Menteri (♕), Benteng, Gajah, atau Kuda!';

  @override
  String get guideChessS4VisualPromo => 'Promosi → Menteri';

  @override
  String get guideChessS5Badge => '5. FITUR CATUR ZETZY';

  @override
  String get guideChessS5Title => 'Konfirmasi Langkah, Flip Papan & Review';

  @override
  String get guideChessS5Desc =>
      'Zetzy menyediakan fitur bantu agar kamu tidak salah sentuh (blunder) saat bermain di layar sentuh.';

  @override
  String get guideChessS5Bullets =>
      'Touch Move Confirmation: pratinjau langkahmu sebelum menekan Confirm.\n4 Mode: Vs AI (Lv. 1–7), Pass & Play (2P satu HP), Friend Room, & Find Match ELO.\nSetelah selesai, gunakan tombol ⏮ ◀ ▶ ⏭ untuk memutar ulang seluruh langkah!';

  @override
  String get guideSnakeS1Badge => '1. KONTROL & GERAK';

  @override
  String get guideSnakeS1Title => 'Belok 90° & Jangan Menabrak Ekor Sendiri';

  @override
  String get guideSnakeS1Desc =>
      'Ular bergerak maju mengikuti ketukan grid. Arahkan kepala ular ke apel dan hindari menabrak tubuh sendiri atau dinding.';

  @override
  String get guideSnakeS1Bullets =>
      'Pilih gaya kontrol favorit di Profile: Swipe, Virtual D-Pad, atau Split-Screen Tap.\nUlar hanya bisa belok 90° (kiri/kanan dari arah jalan), tidak bisa putar balik 180°.\nDi desktop/web, kamu juga bisa memakai tombol Panah atau WASD.';

  @override
  String get guideSnakeS2Badge => '2. APEL & POWER-UP';

  @override
  String get guideSnakeS2Title => 'Apel Merah, Apel Emas, Gunting & Racun';

  @override
  String get guideSnakeS2Desc =>
      'Kenali setiap item yang muncul di arena agar skormu naik cepat dan tubuh ular tidak kepanjangan!';

  @override
  String get guideSnakeS2Bullets =>
      '🍎 Apel Merah (+10 poin): makanan utama untuk mencapai target kemenangan.\n🌟 Apel Emas (+30 poin): muncul sementara dengan poin ekstra besar!\n✂️ Gunting: memotong ekor ular agar kembali pendek & leluasa bergerak.\n☠️ Racun: hindari! Memakannya memicu penalti & bahaya.';

  @override
  String get guideSnakeS2Trim => 'Potong';

  @override
  String get guideSnakeS2Hazard => 'Awas!';

  @override
  String get guideSnakeS3Badge => '3. DINDING & RINTANGAN';

  @override
  String get guideSnakeS3Title => 'Dinding Bata & Rintangan Dinamis';

  @override
  String get guideSnakeS3Desc =>
      'Semakin tinggi level yang kamu pilih, arena akan memunculkan blok dinding bata di tengah papan yang harus kamu hindari.';

  @override
  String get guideSnakeS3Bullets =>
      'Input Queue 2-Langkah memungkinkan kamu melakukan belokan zig-zag cepat.\nAktifkan Assist Overlay di pengaturan untuk melihat indikator bahaya.';

  @override
  String get guideSnakeS3VisualCaption =>
      'Hindari dinding bata di tengah arena!';

  @override
  String get guideSnakeS4Badge => '4. BAR KELAPARAN';

  @override
  String get guideSnakeS4Title => 'Waspadai Bar Kelaparan di Level Tinggi!';

  @override
  String get guideSnakeS4Desc =>
      'Di Level 6–7, ular tidak boleh berlama-lama berputar tanpa makan! Bar stamina akan terus berkurang dan terisi penuh kembali setiap makan apel.';

  @override
  String get guideSnakeS4Bullets =>
      'Rencanakan rute terpendek menuju Apel Merah berikutnya.\nJika menabrak di Practice Mode, gunakan Rewind 1–3 langkah untuk lanjut main!';

  @override
  String get guideSnakeS4VisualCaption => 'Stamina Kelaparan (Lv. 6–7)';

  @override
  String get tutorialExitTooltip => 'Keluar Tutorial';

  @override
  String tutorialAppBarTitle(String game) {
    return 'Tutorial • $game';
  }

  @override
  String get tutorialPausedBadge => '⏸️ PAUSED • PENJELASAN';

  @override
  String get tutorialTryItBadge => '👆 GILIRANMU • PRAKTIK';

  @override
  String tutorialActionProgress(int current, int total) {
    return 'Aksi $current/$total';
  }

  @override
  String get tutorialGotItBtn => 'Mengerti, Coba Sekarang!';

  @override
  String get tutorialReadTipFirst =>
      'Baca penjelasan dulu, lalu tekan \"Mengerti, Coba Sekarang!\"';

  @override
  String get tutorialTapBlinking =>
      'Ketuk tombol / kotak yang sedang berkedip ya!';

  @override
  String get tutorialCompleteTitle => 'Tutorial Selesai! 🎉';

  @override
  String tutorialCompleteBody(String game) {
    return 'Kamu sudah mempraktikkan aturan inti $game. Siap main sungguhan?';
  }

  @override
  String get tutorialDoneBtn => 'Selesai';

  @override
  String get tutorialPlayNowBtn => 'Main Sekarang!';

  @override
  String get tutorialHudLabel => 'Tutorial';

  @override
  String get tutSudokuS1Title => 'Langkah 1/3: Pilih Kotak, Lalu Tekan Angka';

  @override
  String get tutSudokuS1Exp =>
      'Kotak 3×3 di tengah (disorot) sudah berisi 1, 2, 3, 4, 6, 7, 8, 9. Yang belum ada hanya angka 5! Cara mengisi di Sudoku: ketuk kotaknya dulu, lalu tekan angka pada tombol angka di bawah.';

  @override
  String get tutSudokuS1A1 =>
      'Ketuk kotak kosong yang berkedip di tengah papan.';

  @override
  String get tutSudokuS1A2 =>
      'Bagus! Sekarang tekan angka 5 pada tombol angka di bawah.';

  @override
  String get tutSudokuS2Title =>
      'Langkah 2/3: Catat Kandidat dengan Notes (✏️)';

  @override
  String get tutSudokuS2Exp =>
      'Baris paling atas (disorot) kehilangan 2 angka: 3 dan 4. Belum tahu mana yang di mana? Jangan menebak! Aktifkan Notes untuk menulis angka kandidat kecil — mencatat tidak akan mengurangi nyawa ♥.';

  @override
  String get tutSudokuS2A1 => 'Tekan tombol Notes yang berkedip.';

  @override
  String get tutSudokuS2A2 => 'Ketuk kotak kosong pertama di baris atas.';

  @override
  String get tutSudokuS2A3 => 'Tekan 3 untuk mencatat kandidat pertama.';

  @override
  String get tutSudokuS2A4 => 'Tekan 4 untuk mencatat kandidat kedua.';

  @override
  String get tutSudokuS3Title => 'Langkah 3/3: Eliminasi & Selesaikan!';

  @override
  String get tutSudokuS3Exp =>
      'Lihat kolom kotak tadi (disorot): di bagian bawah sudah ada angka 4 (kuning). Satu kolom tidak boleh kembar, jadi kotak bercatatan 3·4 pasti 3, dan kotak sebelahnya pasti 4! Matikan Notes dulu agar angka terisi penuh.';

  @override
  String get tutSudokuS3A1 => 'Matikan Notes dulu.';

  @override
  String get tutSudokuS3A2 => 'Ketuk kotak yang berisi catatan 3·4.';

  @override
  String get tutSudokuS3A3 => 'Tekan 3.';

  @override
  String get tutSudokuS3A4 =>
      'Sisa satu kotak kosong di sebelahnya. Ketuk kotaknya.';

  @override
  String get tutSudokuS3A5 => 'Tekan 4 untuk menyelesaikan papan!';

  @override
  String get tutSudokuWrongCellFirst =>
      'Pilih kotaknya dulu, baru tekan angka.';

  @override
  String get tutSudokuWrongPressDigit =>
      'Kotak sudah terpilih — sekarang tekan angka yang berkedip di bawah.';

  @override
  String get tutMineS1Title => 'Langkah 1/5: Gali Pertama Pasti Aman';

  @override
  String get tutMineS1Exp =>
      'Mode Gali (⛏️) sudah aktif. Di Zetzy, galian pertamamu dijamin aman dan akan membuka area kosong beserta angka petunjuk. Angka = jumlah ranjau di 8 kotak sekelilingnya.';

  @override
  String get tutMineS1A1 => 'Ketuk kotak tengah yang berkedip untuk menggali.';

  @override
  String get tutMineS2Title => 'Langkah 2/5: Tancapkan Bendera (🚩)';

  @override
  String get tutMineS2Exp =>
      'Lihat angka 1 yang disorot di baris atas. Dari semua tetangganya, hanya ADA SATU kotak yang masih tertutup — berarti kotak itu PASTI ranjau. Ganti ke mode Bendera, lalu tandai kotaknya.';

  @override
  String get tutMineS2A1 => 'Tekan tombol Bendera yang berkedip.';

  @override
  String get tutMineS2A2 =>
      'Ketuk kotak tertutup di samping angka 1 untuk memasang Bendera.';

  @override
  String get tutMineS3Title => 'Langkah 3/5: Ragu? Tandai dengan (?)';

  @override
  String get tutMineS3Exp =>
      'Angka 2 yang disorot butuh 2 ranjau. Sudah ada 1 bendera, jadi 1 ranjau lagi ada di antara 2 kotak pojok. Belum yakin yang mana? Pakai mode (?) sebagai pengingat — kotak ber-(?) tidak bisa tergali tanpa sengaja.';

  @override
  String get tutMineS3A1 => 'Tekan tombol (?) yang berkedip.';

  @override
  String get tutMineS3A2 => 'Ketuk kotak pojok kiri atas untuk menandai (?).';

  @override
  String get tutMineS4Title => 'Langkah 4/5: Temukan Ranjau Kedua';

  @override
  String get tutMineS4Exp =>
      'Sekarang lihat angka 1 yang disorot di kolom kiri. Tetangganya yang tertutup hanya satu — kotak di atasnya. Itu ranjau kedua! Ganti ke Bendera lagi.';

  @override
  String get tutMineS4A1 => 'Tekan tombol Bendera.';

  @override
  String get tutMineS4A2 =>
      'Ketuk kotak di atas angka 1 untuk memasang Bendera.';

  @override
  String get tutMineS5Title => 'Langkah 5/5: Gali Kotak Aman Terakhir!';

  @override
  String get tutMineS5Exp =>
      'Angka 2 yang disorot kini sudah menyentuh 2 bendera — jumlah ranjaunya lengkap. Maka kotak (?) di pojok PASTI aman. Kembali ke mode Gali lalu buka kotaknya untuk menang!';

  @override
  String get tutMineS5A1 => 'Tekan tombol Gali.';

  @override
  String get tutMineS5A2 =>
      'Ketuk kotak (?) di pojok kiri atas untuk menggalinya.';

  @override
  String get tutMineWrongSwitchTool =>
      'Ganti mode dulu dengan tombol yang berkedip di bawah.';

  @override
  String get tutChessS1Title => 'Langkah 1/4: Kuda (♘) Melompat Huruf L';

  @override
  String get tutChessS1Exp =>
      'Di catur, ketuk bidakmu dulu untuk melihat ke mana saja ia bisa bergerak. Titik = petak kosong yang bisa dituju, MERAH = bisa memakan bidak lawan. Kuda bergerak membentuk huruf L dan bisa melompati bidak lain.';

  @override
  String get tutChessS1A1 => 'Ketuk Kuda putih yang berkedip.';

  @override
  String get tutChessS1A2 =>
      'Lihat semua langkah Kuda yang disorot. Petak MERAH berisi Menteri lawan — ketuk untuk memakannya!';

  @override
  String get tutChessS2Title => 'Langkah 2/4: Rokade (♔⇄♖)';

  @override
  String get tutChessS2Exp =>
      'Rokade = Raja bergeser 2 petak ke arah Benteng, lalu Benteng melompat ke sisi sebelahnya. Syarat: Raja & Benteng belum pernah bergerak, jalur di antaranya kosong, dan Raja tidak sedang / tidak melewati petak yang diserang.';

  @override
  String get tutChessS2A1 => 'Ketuk Raja putih yang berkedip dulu.';

  @override
  String get tutChessS2A2 =>
      'Petak bertanda ⇄ adalah langkah Rokade. Ketuk untuk Rokade!';

  @override
  String get tutChessS3Title => 'Langkah 3/4: En Passant (♙↗)';

  @override
  String get tutChessS3Exp =>
      'Pion hitam baru saja maju 2 petak (d7 → d5, disorot kuning) dan berhenti tepat di samping pion putihmu. Khusus di giliran ini, pionmu boleh memakannya secara diagonal seolah ia baru maju 1 petak — disebut En Passant.';

  @override
  String get tutChessS3A1 => 'Ketuk pion putih di e5.';

  @override
  String get tutChessS3A2 =>
      'Ketuk petak MERAH di belakang pion hitam untuk En Passant!';

  @override
  String get tutChessS4Title => 'Langkah 4/4: Promosi Pion → Skakmat!';

  @override
  String get tutChessS4Exp =>
      'Pion yang mencapai baris paling ujung WAJIB berubah menjadi Menteri, Benteng, Gajah, atau Kuda. Raja hitam terkurung pionnya sendiri — promosi ke Menteri di a8 akan menjadi Skakmat!';

  @override
  String get tutChessS4A1 => 'Ketuk pion putih di a7.';

  @override
  String get tutChessS4A2 => 'Ketuk petak a8 di baris paling ujung.';

  @override
  String get tutChessS4A3 => 'Pilih Menteri (♕) — bidak terkuat!';

  @override
  String get tutChessWrongOtherLegal =>
      'Itu langkah sah, tapi di tutorial ini pilih petak yang berkedip ya.';

  @override
  String get tutChessWrongTapPieceFirst =>
      'Ketuk bidak yang berkedip dulu untuk melihat langkahnya.';

  @override
  String get tutChessPromoLabel => 'Promosi pion menjadi:';

  @override
  String get tutChessCheckmateStatus => '♛ SKAKMAT! Putih menang.';

  @override
  String get tutChessWhiteToMove => 'Giliran Putih';

  @override
  String get tutSnakeS1Title => 'Langkah 1/3: Belok 90° Menuju Apel 🍎';

  @override
  String get tutSnakeS1Exp =>
      'Ular bergerak terus ke kanan — dan di depannya ada RACUN ☠️! Apel merah (+10) ada di atas kepala ular. Belokkan ular ke atas. Ular hanya bisa belok 90°, tidak bisa putar balik 180°.';

  @override
  String get tutSnakeS2Title => 'Langkah 2/3: Ambil Gunting ✂️ Pemotong Ekor';

  @override
  String get tutSnakeS2Exp =>
      'Nyam! Skor +10 dan ular bertambah panjang. Di depan (atas) adalah tepi arena. Gunting ✂️ di sebelah kanan akan memotong ekormu agar ruang gerak lebih lega. Hindari dinding bata 🧱!';

  @override
  String get tutSnakeS3Title => 'Langkah 3/3: Apel Emas 🌟 (+30)';

  @override
  String get tutSnakeS3Exp =>
      'Ekor terpotong! Sekarang tepi arena ada di depan (kanan). Apel Emas (+30) ada di bawah, dan jalurnya aman dari racun ☠️. Belok ke bawah untuk mengambilnya!';

  @override
  String tutSnakePromptDpad(String dir) {
    return 'Tekan tombol arah $dir yang berkedip pada D-Pad.';
  }

  @override
  String get tutSnakePromptSplitLeft =>
      'Ketuk sisi KIRI (putar berlawanan jarum jam) yang berkedip.';

  @override
  String get tutSnakePromptSplitRight =>
      'Ketuk sisi KANAN (putar searah jarum jam) yang berkedip.';

  @override
  String tutSnakePromptSwipe(String dir) {
    return 'Usap arena ke $dir (atau ketuk panah yang berkedip).';
  }

  @override
  String get tutSnakeDirUp => 'ATAS';

  @override
  String get tutSnakeDirDown => 'BAWAH';

  @override
  String get tutSnakeDirLeft => 'KIRI';

  @override
  String get tutSnakeDirRight => 'KANAN';

  @override
  String get tutSnakeWrongUTurn =>
      'Ular tidak bisa putar balik 180° — itu akan menabrak tubuhnya sendiri!';

  @override
  String get tutSnakeCtrlLeftSide => 'Sisi Kiri';

  @override
  String get tutSnakeCtrlRightSide => 'Sisi Kanan';

  @override
  String get tutSnakeSwipeHint =>
      'Kontrol Swipe (sesuai Profile): usap arena ke arah tujuan.';
}
