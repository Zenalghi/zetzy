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
      'Nyawa tak terbatas. Skor tidak dikirim ke leaderboard.';

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
  String get chessInfoSummaryOnline => 'Online 1v1 • ELO Aktif via Kode Ruang';

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
  String get chessInfoDetailOnline =>
      '• Konsep: Duel 1v1 real-time yang terhubung langsung lewat Supabase Realtime.\n• Host (Buat Ruang): Masuk ke akun dulu, pilih Kontrol Waktu, lalu tekan Buat Ruang. Bagikan Kode Ruang 6 karakter yang muncul di layar ke teman Anda.\n• Teman (Gabung Ruang): Masuk ke akun, pilih Ruang Online, ketik Kode Ruang tersebut, lalu tekan Gabung Ruang. Laga otomatis dimulai saat terhubung.\n• Skor & ELO: Memperbarui ELO Catur serta mencatat kemenangan di Papan Skor + XP kesulitan (kecuali Mode Latihan aktif).';

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
}
