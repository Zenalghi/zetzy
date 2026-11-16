import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';
import 'package:zetzy/core/constants/app_constants.dart';
import 'package:zetzy/core/theme/zetzy_theme.dart';
import 'package:zetzy/core/widgets/game_type_icon.dart';

/// Opens the slideable visual guide modal for [game].
/// From any slide, the user can either close the guide ("Keluar Panduan")
/// or launch the pause-and-explain interactive tutorial ("Mulai Tutorial").
Future<void> showGameGuideModal(
  BuildContext context, {
  required GameType game,
  required VoidCallback onStartRealGame,
}) {
  final isId = Localizations.localeOf(context).languageCode == 'id';
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (_) => _GameGuideDialog(
      game: game,
      isId: isId,
      onStartTutorial: () {
        Navigator.of(context).pop();
        showGameInteractiveTutorial(
          context,
          game: game,
          onStartRealGame: onStartRealGame,
        );
      },
    ),
  );
}

/// Opens the step-by-step interactive guided tutorial with pause-to-explain
/// coach overlays and hands-on board practice.
Future<void> showGameInteractiveTutorial(
  BuildContext context, {
  required GameType game,
  required VoidCallback onStartRealGame,
}) {
  final isId = Localizations.localeOf(context).languageCode == 'id';
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _GameInteractiveTutorialDialog(
      game: game,
      isId: isId,
      onStartRealGame: onStartRealGame,
    ),
  );
}

class _GuideSlideData {
  const _GuideSlideData({
    required this.badge,
    required this.title,
    required this.description,
    required this.bullets,
    required this.visualBuilder,
  });

  final String badge;
  final String title;
  final String description;
  final List<String> bullets;
  final Widget Function(ZetzyPalette p, bool isId) visualBuilder;
}

class _GameGuideDialog extends StatefulWidget {
  const _GameGuideDialog({
    required this.game,
    required this.isId,
    required this.onStartTutorial,
  });

  final GameType game;
  final bool isId;
  final VoidCallback onStartTutorial;

  @override
  State<_GameGuideDialog> createState() => _GameGuideDialogState();
}

class _GameGuideDialogState extends State<_GameGuideDialog> {
  final PageController _pageCtrl = PageController();
  int _pageIndex = 0;

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  List<_GuideSlideData> _slides(bool isId) => switch (widget.game) {
    GameType.sudoku => _sudokuSlides(isId),
    GameType.minesweeper => _minesweeperSlides(isId),
    GameType.chess => _chessSlides(isId),
    GameType.snake => _snakeSlides(isId),
  };

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final isId = widget.isId;
    final slides = _slides(isId);

    return Dialog(
      backgroundColor: p.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: p.border),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 650),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
          child: Column(
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: p.surfaceElevated,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: p.border),
                    ),
                    child: GameTypeIcon(
                      game: widget.game,
                      size: 24,
                      color: p.accent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isId
                              ? 'Panduan & Aturan ${_gameName(widget.game)}'
                              : '${_gameName(widget.game)} Visual Guide',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          isId
                              ? 'Geser slide untuk melihat ilustrasi & aturan'
                              : 'Swipe slides to explore visual rules & tips',
                          style: TextStyle(
                            fontSize: 12,
                            color: p.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: p.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${_pageIndex + 1} / ${slides.length}',
                      style: ZetzyThemes.monoStyle(
                        fontSize: 12,
                        color: p.accent,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Slideable PageView
              Expanded(
                child: PageView.builder(
                  controller: _pageCtrl,
                  itemCount: slides.length,
                  onPageChanged: (idx) => setState(() => _pageIndex = idx),
                  itemBuilder: (context, idx) {
                    final s = slides[idx];
                    return SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Visual illustration container
                          Container(
                            width: double.infinity,
                            height: 176,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: p.surfaceElevated,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: p.border),
                            ),
                            child: Center(child: s.visualBuilder(p, isId)),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: p.accent.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              s.badge,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: p.accent,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            s.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            s.description,
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.4,
                              color: p.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          for (final b in s.bullets)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.check_circle_rounded,
                                    size: 15,
                                    color: p.accent,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      b,
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        height: 1.35,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 10),

              // Page indicator dots + prev/next
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: _pageIndex > 0
                        ? () => _pageCtrl.previousPage(
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOut,
                          )
                        : null,
                    icon: const Icon(Icons.chevron_left_rounded, size: 18),
                    label: Text(isId ? 'Sebelumnya' : 'Prev'),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var i = 0; i < slides.length; i++)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: i == _pageIndex ? 18 : 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: i == _pageIndex ? p.accent : p.border,
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                    ],
                  ),
                  TextButton.icon(
                    onPressed: _pageIndex < slides.length - 1
                        ? () => _pageCtrl.nextPage(
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOut,
                          )
                        : null,
                    icon: const Icon(Icons.chevron_right_rounded, size: 18),
                    label: Text(isId ? ' Berikutnya' : 'Next'),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Primary actions: Exit Guide OR Start Interactive Tutorial
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      key: const ValueKey('guide_close_btn'),
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded, size: 17),
                      label: Text(
                        isId ? 'Keluar Panduan' : 'Close Guide',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      key: const ValueKey('guide_start_tutorial_btn'),
                      onPressed: widget.onStartTutorial,
                      icon: const Icon(Icons.school_rounded, size: 17),
                      label: Text(
                        isId ? 'Mulai Tutorial' : 'Start Tutorial',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _gameName(GameType g) => switch (g) {
  GameType.sudoku => 'Sudoku',
  GameType.minesweeper => 'Minesweeper',
  GameType.chess => 'Chess',
  GameType.snake => 'Snake',
};

// ── Visual Slide Definitions for All 4 Games ───────────────────────────────

List<_GuideSlideData> _sudokuSlides(bool isId) => [
  _GuideSlideData(
    badge: isId ? '1. ATURAN DASAR' : '1. CORE RULE',
    title: isId
        ? 'Isi Angka 1–9 Tanpa Kembar'
        : 'Fill 1–9 Without Duplicates',
    description: isId
        ? 'Papan Sudoku berukuran 9×9 yang terbagi menjadi 9 blok kotak 3×3. Tugasmu mengisi semua kotak kosong dengan angka 1 sampai 9.'
        : 'A 9×9 Sudoku board is divided into nine 3×3 boxes. Fill every empty cell with a digit from 1 to 9.',
    bullets: isId
        ? [
            'Setiap BARIS mendatar wajib berisi angka 1–9 tanpa ada yang kembar.',
            'Setiap KOLOM menurun wajib berisi angka 1–9 tanpa ada yang kembar.',
            'Setiap KOTAK 3×3 tebal wajib berisi angka 1–9 tanpa ada yang kembar.',
          ]
        : [
            'Every horizontal ROW must contain 1–9 with no repeats.',
            'Every vertical COLUMN must contain 1–9 with no repeats.',
            'Every bold 3×3 BOX must contain 1–9 with no repeats.',
          ],
    visualBuilder: (p, _) => _SudokuBoxVisual(palette: p),
  ),
  _GuideSlideData(
    badge: isId ? '2. CARA BERMAIN' : '2. HOW TO PLAY',
    title: isId
        ? 'Ketuk Kotak & Gunakan Sorotan Angka'
        : 'Tap a Cell & Use Number Highlights',
    description: isId
        ? 'Saat kamu mengetuk sebuah angka di papan atau keypad bawah, semua angka yang sama otomatis disorot agar mudah mencari posisi kosong.'
        : 'Tapping any digit highlights all identical numbers across the board so you can quickly cross-check rows and columns.',
    bullets: isId
        ? [
            'Pilih kotak kosong lalu ketuk angka 1–9 di bagian bawah layar.',
            'Di Level 1–4, jawaban yang benar otomatis terkunci aman.',
            'Ketuk lagi kotak yang sama untuk mematikan sorotan.',
          ]
        : [
            'Select an empty cell, then tap 1–9 on the bottom keypad.',
            'On Levels 1–4, correct placements lock automatically.',
            'Tap the selected cell again to clear the highlight.',
          ],
    visualBuilder: (p, isId) => _SudokuKeypadVisual(palette: p, isId: isId),
  ),
  _GuideSlideData(
    badge: isId ? '3. STRATEGI AMAN' : '3. SAFE STRATEGY',
    title: isId
        ? 'Gunakan Mode Notes (Catatan Pensil)'
        : 'Use Pencil Notes & Smart Notes',
    description: isId
        ? 'Belum yakin antara 2 angka? Jangan menebak! Aktifkan tombol Notes (✏️) untuk menulis angka kandidat kecil di dalam kotak.'
        : 'Unsure between two numbers? Never guess blindly! Toggle Notes (✏️) to jot down mini candidate digits inside a cell.',
    bullets: isId
        ? [
            'Mode Notes tidak akan mengurangi nyawa (♥) meskipun angkanya belum pasti.',
            'Fitur Smart Notes otomatis menghapus catatan yang sudah tidak mungkin.',
            'Gunakan tombol Erase untuk membersihkan kotak atau catatan.',
          ]
        : [
            'Entering Notes never costs a life (♥).',
            'Smart Notes automatically prunes impossible candidates.',
            'Use Erase to clear a cell or its pencil marks.',
          ],
    visualBuilder: (p, isId) => _SudokuNotesVisual(palette: p, isId: isId),
  ),
  _GuideSlideData(
    badge: isId ? '4. NYAWA & BANTUAN' : '4. LIVES & ASSISTS',
    title: isId
        ? '3 Nyawa (♥), 3 Hint & ⚡ Auto-Finish'
        : '3 Lives (♥), 3 Hints & ⚡ Auto-Finish',
    description: isId
        ? 'Kamu punya 3 nyawa dan maksimal 3 Hint per permainan. Saat sisa kotak kosong tinggal sedikit, tombol kilat Auto-Finish akan muncul!'
        : 'You start with 3 lives and up to 3 Hints. When only a few empty cells remain, the lightning Auto-Finish button appears!',
    bullets: isId
        ? [
            'Salah isi angka akan memicu tanda merah & mengurangi 1 nyawa (♥).',
            'Tombol ⚡ Auto-Finish otomatis menyelesaikan sisa papan saat hampir menang.',
            'Di Practice Mode, kamu bebas memakai Undo & Rewind saat kalah!',
          ]
        : [
            'Mistakes flash red and cost 1 heart (♥).',
            '⚡ Auto-Finish completes the board when ≤ 5–7 cells remain.',
            'In Practice Mode, Undo and Rewind on Loss are freely available!',
          ],
    visualBuilder: (p, isId) => _SudokuHudVisual(palette: p, isId: isId),
  ),
];

List<_GuideSlideData> _minesweeperSlides(bool isId) => [
  _GuideSlideData(
    badge: isId ? '1. ARTI ANGKA' : '1. NUMBER MEANING',
    title: isId
        ? 'Angka = Jumlah Ranjau di Sekelilingnya'
        : 'Numbers Show Adjacent Mines',
    description: isId
        ? 'Setiap kotak yang terbuka dan berisi angka (1, 2, 3...) memberi tahu berapa banyak ranjau di 8 kotak tetangga yang menyentuhnya (termasuk miring/diagonal).'
        : 'Every revealed number (1, 2, 3...) tells you exactly how many mines hide in the 8 surrounding tiles (including diagonals).',
    bullets: isId
        ? [
            'Klik pertama dijamin 100% AMAN dan langsung membuka area bersih.',
            'Angka 1 berarti tepat ada 1 ranjau di antara kotak tertutup di sebelahnya.',
            'Kotak kosong (0) otomatis membuka seluruh tetangganya yang aman.',
          ]
        : [
            'Your first tap is ALWAYS 100% safe and opens a clear zone.',
            'A "1" means exactly 1 touching hidden tile contains a mine.',
            'Blank tiles (0) flood-fill open all safe neighbors automatically.',
          ],
    visualBuilder: (p, isId) => _MineNumberVisual(palette: p, isId: isId),
  ),
  _GuideSlideData(
    badge: isId ? '2. GALI VS BENDERA' : '2. DIG VS FLAG',
    title: isId
        ? 'Tancapkan Bendera (🚩) di Kotak Curiga'
        : 'Plant Flags (🚩) on Suspected Mines',
    description: isId
        ? 'Jangan pernah menggali kotak yang kamu yakini berisi ranjau! Pasang Bendera (🚩) agar kotak tersebut terkunci dan tidak sengaja tergali.'
        : 'Never dig a tile you suspect is a mine! Mark it with a Flag (🚩) so it cannot be accidentally tapped.',
    bullets: isId
        ? [
            'Tahan lama (Long-Press) pada kotak tertutup untuk pasang/cabut Bendera.',
            'Atau gunakan tombol 1-Tap Swap di bawah untuk berganti mode Gali ⇄ Bendera.',
            'Menang terjadi saat SEMUA kotak aman berhasil dibuka!',
          ]
        : [
            'Long-press any hidden tile to place or remove a Flag.',
            'Or toggle the 1-Tap Swap button between Dig ⛏️ and Flag 🚩.',
            'You win as soon as all safe non-mine tiles are revealed!',
          ],
    visualBuilder: (p, isId) => _MineFlagVisual(palette: p, isId: isId),
  ),
  _GuideSlideData(
    badge: isId ? '3. TEKNIK PRO' : '3. PRO TECHNIQUE',
    title: isId
        ? 'Chord: Ketuk Angka untuk Buka Cepat'
        : 'Chording: Fast-Open Safe Neighbors',
    description: isId
        ? 'Jika sebuah angka sudah dikelilingi jumlah Bendera (🚩) yang pas, ketuk angka tersebut untuk membuka semua sisa kotak tetangga sekaligus!'
        : 'When an open number already touches the matching number of Flags (🚩), tap the number itself to open all remaining neighbors instantly!',
    bullets: isId
        ? [
            'Contoh: Angka "1" sudah menyentuh 1 Bendera → ketuk angka "1" itu!',
            'Semua kotak tertutup lain di sebelahnya langsung terbuka otomatis.',
            'Hati-hati: pastikan posisi benderamu benar sebelum melakukan Chord!',
          ]
        : [
            'Example: A "1" already touches 1 Flag → tap that "1"!',
            'All other hidden tiles touching that "1" open at once.',
            'Make sure your flag placement is accurate before chording!',
          ],
    visualBuilder: (p, isId) => _MineChordVisual(palette: p, isId: isId),
  ),
  _GuideSlideData(
    badge: isId ? '4. PERISAI PEMULA' : '4. BEGINNER SHIELD',
    title: isId
        ? 'Perisai Defuse (🛡️) Penyelamat Nyawa'
        : 'Defuse Shield (🛡️) Saves You',
    description: isId
        ? 'Khusus untuk pemula di Level 1–2, kamu dibekali Perisai Defuse (🛡️) yang otomatis menjinakkan ranjau jika kamu salah langkah!'
        : 'On Beginner Levels 1–2, you start with a Defuse Shield (🛡️) that automatically disarms a mine if you make a mistake!',
    bullets: isId
        ? [
            'Ranjau yang dijinakkan berubah menjadi ikon ranjau hijau aman.',
            'Di akhir permainan, semua posisi ranjau & bendera yang salah akan ditampilkan.',
            'Gunakan tombol View Board setelah selesai untuk belajar dari pola papan.',
          ]
        : [
            'Defused mines appear safely disarmed on the board.',
            'Post-game review highlights all mines and any misplaced flags.',
            'Tap View Board after a match to inspect the full mine layout.',
          ],
    visualBuilder: (p, isId) => _MineShieldVisual(palette: p, isId: isId),
  ),
];

List<_GuideSlideData> _chessSlides(bool isId) => [
  _GuideSlideData(
    badge: isId ? '1. GERAK 6 BIDAK' : '1. PIECE MOVEMENTS',
    title: isId
        ? 'Cara Jalan Setiap Bidak Catur'
        : 'How All 6 Chess Pieces Move',
    description: isId
        ? 'Ketuk bidakmu untuk melihat titik hijau langkah sah di papan. Hanya Kuda (♘) yang boleh melompati bidak lain!'
        : 'Tap any of your pieces to see legal target dots on the board. Only the Knight (♘) can jump over other pieces!',
    bullets: isId
        ? [
            '♔ Raja: 1 petak ke segala arah • ♕ Menteri: bebas lurus & diagonal.',
            '♖ Benteng: lurus vertikal/horizontal • ♗ Gajah: miring diagonal.',
            '♘ Kuda: huruf "L" (2+1 petak) • ♙ Pion: maju 1 (awal 2), makan miring.',
          ]
        : [
            '♔ King: 1 step any way • ♕ Queen: any distance straight or diagonal.',
            '♖ Rook: straight lines • ♗ Bishop: diagonals only.',
            '♘ Knight: L-shape jump (2+1) • ♙ Pawn: moves forward, captures diagonally.',
          ],
    visualBuilder: (p, isId) => _ChessPiecesVisual(palette: p, isId: isId),
  ),
  _GuideSlideData(
    badge: isId ? '2. SKAKMAT VS STALEMATE' : '2. CHECKMATE VS STALEMATE',
    title: isId
        ? 'Awas! Stalemate Itu Seri, Bukan Menang'
        : 'Watch Out: Stalemate Is a Draw!',
    description: isId
        ? 'Banyak pemula mengira mengurung Raja lawan tanpa skak adalah menang. Padahal jika lawan tidak sedang Skak tapi habis langkah sah, hasilnya SERI (Stalemate)!'
        : 'Trapping the enemy King without putting it in Check leaves them with zero legal moves—resulting in a STALEMATE (Draw), not a win!',
    bullets: isId
        ? [
            'Skak (Check): Raja diserang — wajib menyelamatkan Raja di giliran itu.',
            'Skakmat (Checkmate): Raja diserang & tidak ada jalan selamat → MENANG!',
            'Remis (Draw): terjadi karena Stalemate, 3× posisi sama, atau 50 langkah kosong.',
          ]
        : [
            'Check: King is under attack and must escape immediately.',
            'Checkmate: King is in Check with no legal escape → YOU WIN!',
            'Draw: Stalemate, 3-fold repetition, 50-move rule, or insufficient material.',
          ],
    visualBuilder: (p, isId) => _ChessCheckVisual(palette: p, isId: isId),
  ),
  _GuideSlideData(
    badge: isId ? '3. ATURAN LANGKA #1' : '3. SPECIAL RULE #1',
    title: isId
        ? 'Rokade (Castling ♔⇄♖): Amankan Raja'
        : 'Castling (♔⇄♖): King + Rook Double Move',
    description: isId
        ? 'Satu-satunya langkah di mana 2 bidak bergerak sekaligus! Raja bergeser 2 petak mendekati Benteng, lalu Benteng melompat ke sebelahnya.'
        : 'The only move where two pieces move at once! Move your King 2 squares toward your Rook, and the Rook jumps over to the other side.',
    bullets: isId
        ? [
            'Syarat 1: Raja dan Benteng tersebut sama-sama BELUM PERNAH bergerak.',
            'Syarat 2: Semua petak di antara Raja & Benteng harus kosong.',
            'Syarat 3: Raja tidak sedang Skak, dan tidak melewati petak yang diserang lawan.',
          ]
        : [
            'Rule 1: Neither the King nor that Rook has moved yet.',
            'Rule 2: Every square between King and Rook must be empty.',
            'Rule 3: The King cannot be in Check or pass through an attacked square.',
          ],
    visualBuilder: (p, isId) => _ChessCastlingVisual(palette: p, isId: isId),
  ),
  _GuideSlideData(
    badge: isId ? '4. ATURAN LANGKA #2' : '4. SPECIAL RULE #2',
    title: isId
        ? 'En Passant & Promosi Pion (♙ → ♕)'
        : 'En Passant & Pawn Promotion (♙ → ♕)',
    description: isId
        ? 'Dua aturan pion yang sering mengejutkan pemain baru: tangkapan sambil lalu (En Passant) dan perubahan wujud pion di baris ujung!'
        : 'Two crucial pawn rules that often surprise players: capturing "in passing" (En Passant) and promoting at the 8th rank!',
    bullets: isId
        ? [
            'En Passant: Jika pion lawan loncat 2 petak tepat di samping pionmu, kamu boleh memakannya miring seolah ia baru maju 1 petak (wajib langsung di giliran itu!).',
            'Promosi: Pion yang mencapai baris paling ujung langsung berubah jadi Menteri (♕), Benteng, Gajah, atau Kuda!',
          ]
        : [
            'En Passant: When an enemy pawn advances 2 squares beside yours, you can capture it diagonally on the very next turn as if it moved 1 square.',
            'Promotion: Reaching the last rank transforms your pawn into a Queen (♕), Rook, Bishop, or Knight!',
          ],
    visualBuilder: (p, isId) => _ChessSpecialPawnVisual(palette: p, isId: isId),
  ),
  _GuideSlideData(
    badge: isId ? '5. FITUR CATUR ZETZY' : '5. ZETZY CHESS FEATURES',
    title: isId
        ? 'Konfirmasi Langkah, Flip Papan & Review'
        : 'Touch Confirmation, Board Flip & Review',
    description: isId
        ? 'Zetzy menyediakan fitur bantu agar kamu tidak salah sentuh (blunder) saat bermain di layar sentuh.'
        : 'Zetzy includes thoughtful touch safeguards and post-match analysis tools.',
    bullets: isId
        ? [
            'Touch Move Confirmation: pratinjau langkahmu sebelum menekan Confirm.',
            '4 Mode: Vs AI (Lv. 1–7), Pass & Play (2P satu HP), Friend Room, & Find Match ELO.',
            'Setelah selesai, gunakan tombol ⏮ ◀ ▶ ⏭ untuk memutar ulang seluruh langkah!',
          ]
        : [
            'Touch Move Confirmation previews your move before locking it in.',
            '4 Modes: Vs AI (Lv. 1–7), Pass & Play (2P), Friend Room, & Rated Matchmaking.',
            'Use the post-game move scrubber (⏮ ◀ ▶ ⏭) to replay every turn!',
          ],
    visualBuilder: (p, isId) => _ChessHudVisual(palette: p, isId: isId),
  ),
];

List<_GuideSlideData> _snakeSlides(bool isId) => [
  _GuideSlideData(
    badge: isId ? '1. KONTROL & GERAK' : '1. CONTROLS & MOVEMENT',
    title: isId
        ? 'Belok 90° & Jangan Menabrak Ekor Sendiri'
        : 'Turn 90° & Never Bite Your Own Tail',
    description: isId
        ? 'Ular bergerak maju mengikuti ketukan grid. Arahkan kepala ular ke apel dan hindari menabrak tubuh sendiri atau dinding.'
        : 'Your snake advances smoothly across the grid. Steer toward apples while avoiding walls and your own growing body.',
    bullets: isId
        ? [
            'Pilih gaya kontrol favorit di Profile: Swipe, Virtual D-Pad, atau Split-Screen Tap.',
            'Ular hanya bisa belok 90° (kiri/kanan dari arah jalan), tidak bisa putar balik 180°.',
            'Di desktop/web, kamu juga bisa memakai tombol Panah atau WASD.',
          ]
        : [
            'Choose Swipe, Virtual D-Pad, or Split-Screen Tap in Profile settings.',
            'You can turn 90° perpendicular to your heading, never 180° backward.',
            'Arrow keys and WASD are also supported on keyboard devices.',
          ],
    visualBuilder: (p, isId) => _SnakeControlVisual(palette: p, isId: isId),
  ),
  _GuideSlideData(
    badge: isId ? '2. APEL & POWER-UP' : '2. APPLES & POWER-UPS',
    title: isId
        ? 'Apel Merah, Apel Emas, Gunting & Racun'
        : 'Red Apples, Golden Bonus, Scissors & Poison',
    description: isId
        ? 'Kenali setiap item yang muncul di arena agar skormu naik cepat dan tubuh ular tidak kepanjangan!'
        : 'Learn what each arena item does to maximize your score and manage tail length!',
    bullets: isId
        ? [
            '🍎 Apel Merah (+10 poin): makanan utama untuk mencapai target kemenangan.',
            '🌟 Apel Emas (+30 poin): muncul sementara dengan poin ekstra besar!',
            '✂️ Gunting: memotong ekor ular agar kembali pendek & leluasa bergerak.',
            '☠️ Racun: hindari! Memakannya memicu penalti & bahaya.',
          ]
        : [
            '🍎 Red Apple (+10 pts): core food needed to reach the level target.',
            '🌟 Golden Apple (+30 pts): timed bonus item for massive points!',
            '✂️ Scissors: trims your tail shorter to free up space on the board.',
            '☠️ Poison: avoid! Stepping on poison triggers a hazard penalty.',
          ],
    visualBuilder: (p, isId) => _SnakeItemsVisual(palette: p, isId: isId),
  ),
  _GuideSlideData(
    badge: isId ? '3. DINDING & RINTANGAN' : '3. WALLS & OBSTACLES',
    title: isId
        ? 'Dinding Bata & Rintangan Dinamis'
        : 'Brick Walls & Dynamic Obstacles',
    description: isId
        ? 'Semakin tinggi level yang kamu pilih, arena akan memunculkan blok dinding bata di tengah papan yang harus kamu hindari.'
        : 'Higher difficulty tiers introduce brick wall obstacles inside the arena that require sharp turns.',
    bullets: isId
        ? [
            'Input Queue 2-Langkah memungkinkan kamu melakukan belokan zig-zag cepat.',
            'Aktifkan Assist Overlay di pengaturan untuk melihat indikator bahaya.',
          ]
        : [
            '2-Step Input Queue lets you buffer quick zig-zag turns cleanly.',
            'Enable Assist Overlay in settings for helpful hazard indicators.',
          ],
    visualBuilder: (p, isId) => _SnakeWallVisual(palette: p, isId: isId),
  ),
  _GuideSlideData(
    badge: isId ? '4. BAR KELAPARAN' : '4. STARVATION BAR',
    title: isId
        ? 'Waspadai Bar Kelaparan di Level Tinggi!'
        : 'Watch the Starvation Bar on High Tiers!',
    description: isId
        ? 'Di Level 6–7, ular tidak boleh berlama-lama berputar tanpa makan! Bar stamina akan terus berkurang dan terisi penuh kembali setiap makan apel.'
        : 'On Levels 6–7, a Starvation Bar drains over time. Eat apples promptly to refill your stamina before it runs out!',
    bullets: isId
        ? [
            'Rencanakan rute terpendek menuju Apel Merah berikutnya.',
            'Jika menabrak di Practice Mode, gunakan Rewind 1–3 langkah untuk lanjut main!',
          ]
        : [
            'Plan the shortest path toward the next Red Apple.',
            'In Practice Mode, use Rewind 1–3 steps to recover from any crash!',
          ],
    visualBuilder: (p, isId) => _SnakeStarvationVisual(palette: p, isId: isId),
  ),
];

// ── Compact Visual Illustration Widgets for Guide Slides ──────────────────

class _SudokuBoxVisual extends StatelessWidget {
  const _SudokuBoxVisual({required this.palette});
  final ZetzyPalette palette;

  @override
  Widget build(BuildContext context) {
    const nums = ['1', '2', '3', '4', '?', '6', '7', '8', '9'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 126,
          height: 126,
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 9,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
            ),
            itemBuilder: (_, i) {
              final isTarget = nums[i] == '?';
              return Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isTarget
                      ? palette.accent.withValues(alpha: 0.25)
                      : palette.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isTarget ? palette.accent : palette.border,
                    width: isTarget ? 2 : 1,
                  ),
                ),
                child: Text(
                  isTarget ? '5' : nums[i],
                  style: ZetzyThemes.monoStyle(
                    fontSize: 16,
                    color: isTarget ? palette.accent : palette.textPrimary,
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 16),
        Flexible(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _MiniBadge(
                palette: palette,
                icon: Icons.check_rounded,
                text: '1 2 3 4 [5] 6 7 8 9',
              ),
              const SizedBox(height: 8),
              Text(
                'Kotak tengah hanya kurang angka 5!',
                style: TextStyle(fontSize: 12, color: palette.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SudokuKeypadVisual extends StatelessWidget {
  const _SudokuKeypadVisual({required this.palette, required this.isId});
  final ZetzyPalette palette;
  final bool isId;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (final d in ['7', ' ', '7'])
              Container(
                width: 42,
                height: 42,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: d == '7'
                      ? palette.accent.withValues(alpha: 0.22)
                      : palette.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: palette.accent),
                ),
                child: Text(
                  d,
                  style: ZetzyThemes.monoStyle(
                    fontSize: 16,
                    color: palette.accent,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Icon(Icons.arrow_upward_rounded, size: 18, color: palette.accent),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          children: [
            for (var n = 1; n <= 9; n++)
              Container(
                width: 28,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: n == 7 ? palette.accent : palette.surface,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: palette.border),
                ),
                child: Text(
                  '$n',
                  style: ZetzyThemes.monoStyle(
                    fontSize: 13,
                    color: n == 7 ? Colors.black : palette.textPrimary,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _SudokuNotesVisual extends StatelessWidget {
  const _SudokuNotesVisual({required this.palette, required this.isId});
  final ZetzyPalette palette;
  final bool isId;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 78,
          height: 78,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: palette.accent, width: 1.5),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('1', style: TextStyle(fontSize: 11, color: palette.accent)),
                  const Text(' ', style: TextStyle(fontSize: 11)),
                  Text('3', style: TextStyle(fontSize: 11, color: palette.accent)),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(' ', style: TextStyle(fontSize: 11)),
                  Text('5', style: TextStyle(fontSize: 11, color: palette.accent)),
                  const Text(' ', style: TextStyle(fontSize: 11)),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
        const SizedBox(width: 14),
        Icon(Icons.arrow_forward_rounded, color: palette.accent),
        const SizedBox(width: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: palette.accent.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: palette.accent),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.edit_note_rounded, color: palette.accent),
              const SizedBox(width: 6),
              Text(
                isId ? 'Notes ON (Aman)' : 'Notes ON (Safe)',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: palette.accent,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SudokuHudVisual extends StatelessWidget {
  const _SudokuHudVisual({required this.palette, required this.isId});
  final ZetzyPalette palette;
  final bool isId;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < 3; i++)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 3),
                child: Icon(
                  Icons.favorite_rounded,
                  color: Colors.redAccent,
                  size: 24,
                ),
              ),
            const SizedBox(width: 16),
            _MiniBadge(
              palette: palette,
              icon: Icons.lightbulb_outline_rounded,
              text: 'Hint 3/3',
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: palette.accent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.bolt_rounded, size: 18, color: Colors.black),
              const SizedBox(width: 6),
              Text(
                isId ? 'Auto-Finish (Sisa ≤ 5 Kotak)' : 'Auto-Finish (≤ 5 Left)',
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MineNumberVisual extends StatelessWidget {
  const _MineNumberVisual({required this.palette, required this.isId});
  final ZetzyPalette palette;
  final bool isId;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 118,
          height: 118,
          child: GridView.count(
            crossAxisCount: 3,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _mineTile(palette, ''),
              _mineTile(palette, ''),
              _mineTile(palette, 'mine'),
              _mineTile(palette, ''),
              _mineTile(palette, '1', highlight: true),
              _mineTile(palette, ''),
              _mineTile(palette, ''),
              _mineTile(palette, ''),
              _mineTile(palette, ''),
            ],
          ),
        ),
        const SizedBox(width: 14),
        Flexible(
          child: Text(
            isId
                ? 'Angka "1" di tengah menyentuh tepat 1 ranjau di pojok kanan atas!'
                : 'The center "1" touches exactly 1 mine in the top-right corner!',
            style: TextStyle(fontSize: 12, color: palette.textSecondary),
          ),
        ),
      ],
    );
  }
}

class _MineFlagVisual extends StatelessWidget {
  const _MineFlagVisual({required this.palette, required this.isId});
  final ZetzyPalette palette;
  final bool isId;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _mineTile(palette, '1', size: 48),
        const SizedBox(width: 10),
        Icon(Icons.arrow_forward_rounded, color: palette.accent),
        const SizedBox(width: 10),
        Container(
          width: 52,
          height: 52,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: palette.accent.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: palette.accent, width: 2),
          ),
          child: Image.asset(AssetPaths.mineFlag),
        ),
        const SizedBox(width: 14),
        Flexible(
          child: Text(
            isId
                ? 'Tandai kotak ranjau dengan Bendera (🚩) agar aman!'
                : 'Lock suspected mine tiles with a Flag (🚩)!',
            style: TextStyle(fontSize: 12, color: palette.textSecondary),
          ),
        ),
      ],
    );
  }
}

class _MineChordVisual extends StatelessWidget {
  const _MineChordVisual({required this.palette, required this.isId});
  final ZetzyPalette palette;
  final bool isId;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _mineTile(palette, 'flag', size: 44),
        const SizedBox(width: 6),
        _mineTile(palette, '1', size: 48, highlight: true),
        const SizedBox(width: 6),
        Icon(Icons.bolt_rounded, color: palette.accent, size: 26),
        const SizedBox(width: 6),
        _mineTile(palette, 'safe', size: 44),
      ],
    );
  }
}

class _MineShieldVisual extends StatelessWidget {
  const _MineShieldVisual({required this.palette, required this.isId});
  final ZetzyPalette palette;
  final bool isId;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(AssetPaths.mineShield, width: 48, height: 48),
        const SizedBox(width: 12),
        Icon(Icons.arrow_forward_rounded, color: palette.accent),
        const SizedBox(width: 12),
        Image.asset(AssetPaths.mineDefused, width: 48, height: 48),
        const SizedBox(width: 14),
        Flexible(
          child: Text(
            isId
                ? 'Perisai Lv. 1–2 otomatis menjinakkan ranjau!'
                : 'Lv. 1–2 Shield automatically defuses a mine!',
            style: TextStyle(fontSize: 12, color: palette.textSecondary),
          ),
        ),
      ],
    );
  }
}

Widget _mineTile(
  ZetzyPalette p,
  String kind, {
  double size = 34,
  bool highlight = false,
}) {
  return Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: highlight ? p.accent.withValues(alpha: 0.22) : p.surface,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(
        color: highlight ? p.accent : p.border,
        width: highlight ? 2 : 1,
      ),
    ),
    child: switch (kind) {
      'mine' => Padding(
        padding: const EdgeInsets.all(5),
        child: Image.asset(AssetPaths.mineNormal),
      ),
      'flag' => Padding(
        padding: const EdgeInsets.all(6),
        child: Image.asset(AssetPaths.mineFlag),
      ),
      'safe' => Icon(Icons.check_circle_rounded, size: 20, color: p.accent),
      _ => Text(
        kind,
        style: ZetzyThemes.monoStyle(fontSize: 15, color: p.accent),
      ),
    },
  );
}

class _ChessPiecesVisual extends StatelessWidget {
  const _ChessPiecesVisual({required this.palette, required this.isId});
  final ZetzyPalette palette;
  final bool isId;

  @override
  Widget build(BuildContext context) {
    const pieces = [
      ('wK', 'King'),
      ('wQ', 'Queen'),
      ('wR', 'Rook'),
      ('wB', 'Bishop'),
      ('wN', 'Knight'),
      ('wP', 'Pawn'),
    ];
    return Wrap(
      spacing: 10,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        for (final item in pieces)
          Container(
            width: 72,
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: palette.border),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset(
                  'assets/icons/chess/cburnett-v2/${item.$1}.svg',
                  width: 30,
                  height: 30,
                ),
                const SizedBox(height: 3),
                Text(
                  item.$2,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ChessCheckVisual extends StatelessWidget {
  const _ChessCheckVisual({required this.palette, required this.isId});
  final ZetzyPalette palette;
  final bool isId;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _chessCard(
          palette,
          piece: 'bK',
          badge: isId ? 'SKAKMAT (Menang)' : 'CHECKMATE (Win)',
          badgeColor: palette.accent,
        ),
        _chessCard(
          palette,
          piece: 'bK',
          badge: isId ? 'STALEMATE (Seri!)' : 'STALEMATE (Draw!)',
          badgeColor: palette.warning,
        ),
      ],
    );
  }

  Widget _chessCard(
    ZetzyPalette p, {
    required String piece,
    required String badge,
    required Color badgeColor,
  }) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: p.surface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: badgeColor, width: 1.5),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(
          'assets/icons/chess/cburnett-v2/$piece.svg',
          width: 38,
          height: 38,
        ),
        const SizedBox(height: 6),
        Text(
          badge,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: badgeColor,
          ),
        ),
      ],
    ),
  );
}

class _ChessCastlingVisual extends StatelessWidget {
  const _ChessCastlingVisual({required this.palette, required this.isId});
  final ZetzyPalette palette;
  final bool isId;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _squarePiece(palette, 'wK', 'e1'),
            _squarePiece(palette, null, 'f1'),
            _squarePiece(palette, null, 'g1', highlight: true),
            _squarePiece(palette, 'wR', 'h1'),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          isId
              ? 'Rokade Pendek: Raja e1 → g1, Benteng h1 → f1 melompati Raja!'
              : 'Kingside Castling: King e1 → g1, Rook h1 → f1 jumps over!',
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: palette.accent,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _ChessSpecialPawnVisual extends StatelessWidget {
  const _ChessSpecialPawnVisual({required this.palette, required this.isId});
  final ZetzyPalette palette;
  final bool isId;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                _squarePiece(palette, 'bP', 'd5'),
                _squarePiece(palette, 'wP', 'e5', highlight: true),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'En Passant (↗ d6)',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: palette.accent,
              ),
            ),
          ],
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                _squarePiece(palette, 'wP', 'a7'),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(Icons.arrow_forward_rounded, color: palette.accent),
                ),
                _squarePiece(palette, 'wQ', 'a8', highlight: true),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              isId ? 'Promosi → Menteri' : 'Promotion → Queen',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: palette.accent,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ChessHudVisual extends StatelessWidget {
  const _ChessHudVisual({required this.palette, required this.isId});
  final ZetzyPalette palette;
  final bool isId;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _MiniBadge(
          palette: palette,
          icon: Icons.touch_app_rounded,
          text: isId ? 'Confirm Move: e2 → e4' : 'Confirm Move: e2 → e4',
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (final ic in [
              Icons.first_page_rounded,
              Icons.chevron_left_rounded,
              Icons.chevron_right_rounded,
              Icons.last_page_rounded,
            ])
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: palette.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: palette.border),
                ),
                child: Icon(ic, size: 18, color: palette.accent),
              ),
          ],
        ),
      ],
    );
  }
}

Widget _squarePiece(
  ZetzyPalette p,
  String? piece,
  String coord, {
  bool highlight = false,
}) => Container(
  width: 44,
  height: 48,
  margin: const EdgeInsets.symmetric(horizontal: 2),
  decoration: BoxDecoration(
    color: highlight ? p.accent.withValues(alpha: 0.22) : p.surface,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(
      color: highlight ? p.accent : p.border,
      width: highlight ? 2 : 1,
    ),
  ),
  child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      if (piece != null)
        SvgPicture.asset(
          'assets/icons/chess/cburnett-v2/$piece.svg',
          width: 24,
          height: 24,
        )
      else
        Icon(Icons.circle, size: 8, color: p.accent),
      Text(coord, style: TextStyle(fontSize: 9, color: p.textSecondary)),
    ],
  ),
);

class _SnakeControlVisual extends StatelessWidget {
  const _SnakeControlVisual({required this.palette, required this.isId});
  final ZetzyPalette palette;
  final bool isId;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < 3; i++)
          Container(
            width: 28,
            height: 28,
            margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(
              color: i == 2 ? palette.accent : palette.accent.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        Icon(Icons.subdirectory_arrow_right_rounded, color: palette.accent),
        const SizedBox(width: 8),
        Image.asset(AssetPaths.snakeApple, width: 32, height: 32),
      ],
    );
  }
}

class _SnakeItemsVisual extends StatelessWidget {
  const _SnakeItemsVisual({required this.palette, required this.isId});
  final ZetzyPalette palette;
  final bool isId;

  @override
  Widget build(BuildContext context) {
    final items = [
      (AssetPaths.snakeApple, '+10'),
      (AssetPaths.snakeGolden, '+30'),
      (AssetPaths.snakeScissors, isId ? 'Potong' : 'Trim'),
      (AssetPaths.snakePoison, isId ? 'Awas!' : 'Hazard'),
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        for (final item in items)
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: palette.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: palette.border),
                ),
                child: Image.asset(item.$1, width: 32, height: 32),
              ),
              const SizedBox(height: 6),
              Text(
                item.$2,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _SnakeWallVisual extends StatelessWidget {
  const _SnakeWallVisual({required this.palette, required this.isId});
  final ZetzyPalette palette;
  final bool isId;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(AssetPaths.snakeWall, width: 42, height: 42),
        const SizedBox(width: 8),
        Image.asset(AssetPaths.snakeWall, width: 42, height: 42),
        const SizedBox(width: 14),
        Flexible(
          child: Text(
            isId
                ? 'Hindari dinding bata di tengah arena!'
                : 'Dodge brick walls inside the arena!',
            style: TextStyle(fontSize: 12, color: palette.textSecondary),
          ),
        ),
      ],
    );
  }
}

class _SnakeStarvationVisual extends StatelessWidget {
  const _SnakeStarvationVisual({required this.palette, required this.isId});
  final ZetzyPalette palette;
  final bool isId;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(AssetPaths.snakeApple, width: 24, height: 24),
            const SizedBox(width: 8),
            Text(
              isId ? 'Stamina Kelaparan (Lv. 6–7)' : 'Starvation Timer (Lv. 6–7)',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: 0.65,
            minHeight: 12,
            backgroundColor: palette.surface,
            color: palette.warning,
          ),
        ),
      ],
    );
  }
}

class _MiniBadge extends StatelessWidget {
  const _MiniBadge({
    required this.palette,
    required this.icon,
    required this.text,
  });
  final ZetzyPalette palette;
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: palette.surface,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: palette.accent),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: palette.accent),
        const SizedBox(width: 6),
        Text(
          text,
          style: ZetzyThemes.monoStyle(fontSize: 11.5, color: palette.accent),
        ),
      ],
    ),
  );
}

// ── Interactive Guided Tutorial (Pause-to-Explain + Hands-On Practice) ─────

class _TutorialStepSpec {
  const _TutorialStepSpec({
    required this.stepTitle,
    required this.pauseExplanation,
    required this.actionPrompt,
    required this.targetLabel,
    required this.boardCells,
    required this.targetIndex,
  });

  final String stepTitle;
  final String pauseExplanation;
  final String actionPrompt;
  final String targetLabel;
  final List<String> boardCells;
  final int targetIndex;
}

class _GameInteractiveTutorialDialog extends StatefulWidget {
  const _GameInteractiveTutorialDialog({
    required this.game,
    required this.isId,
    required this.onStartRealGame,
  });

  final GameType game;
  final bool isId;
  final VoidCallback onStartRealGame;

  @override
  State<_GameInteractiveTutorialDialog> createState() =>
      _GameInteractiveTutorialDialogState();
}

class _GameInteractiveTutorialDialogState
    extends State<_GameInteractiveTutorialDialog> {
  int _stepIndex = 0;
  bool _isPausedForExplanation = true;
  bool _completed = false;
  String? _wrongTapHint;

  List<_TutorialStepSpec> _steps(bool isId) => switch (widget.game) {
    GameType.sudoku => [
      _TutorialStepSpec(
        stepTitle: isId
            ? 'Langkah 1/3: Lengkapi Kotak 3×3'
            : 'Step 1/3: Complete the 3×3 Box',
        pauseExplanation: isId
            ? '⏸️ GAME DI-PAUSE: Lihat kotak 3×3 ini. Sudah ada angka 1, 2, 3, 4, 6, 7, 8, 9. Hanya kurang angka 5 di tengah!'
            : '⏸️ PAUSED: Look at this 3×3 box. Digits 1, 2, 3, 4, 6, 7, 8, 9 are present. Only 5 is missing in the center!',
        actionPrompt: isId
            ? '👆 Ketuk kotak tengah [?] yang berkedip untuk mengisi angka 5!'
            : '👆 Tap the pulsing center [?] cell to place 5!',
        targetLabel: '5',
        boardCells: const ['1', '2', '3', '4', '?', '6', '7', '8', '9'],
        targetIndex: 4,
      ),
      _TutorialStepSpec(
        stepTitle: isId
            ? 'Langkah 2/3: Gunakan Mode Notes (✏️)'
            : 'Step 2/3: Use Pencil Notes (✏️)',
        pauseExplanation: isId
            ? '⏸️ GAME DI-PAUSE: Saat ada 2 kotak kosong dan kamu belum yakin, jangan menebak! Gunakan Notes (✏️) untuk menulis angka kandidat kecil tanpa risiko kehilangan nyawa ♥.'
            : '⏸️ PAUSED: When two cells remain uncertain, toggle Notes (✏️) to write small candidate numbers safely without risking a heart ♥.',
        actionPrompt: isId
            ? '👆 Ketuk kotak [✏️] yang disorot untuk mencatat kandidat 2 & 8!'
            : '👆 Tap the highlighted [✏️] cell to jot down candidates 2 & 8!',
        targetLabel: '2,8',
        boardCells: const ['1', '✏️', '3', '4', '5', '6', '7', '?', '9'],
        targetIndex: 1,
      ),
      _TutorialStepSpec(
        stepTitle: isId
            ? 'Langkah 3/3: Selesaikan Kotak Terakhir!'
            : 'Step 3/3: Solve the Final Cell!',
        pauseExplanation: isId
            ? '⏸️ GAME DI-PAUSE: Karena angka 2 sudah terpakai di kolom kiri, maka kotak bawah pasti angka 8!'
            : '⏸️ PAUSED: Since 2 is now resolved in the top row, the bottom cell must be 8!',
        actionPrompt: isId
            ? '👆 Ketuk kotak [?] terakhir untuk menyelesaikan papan Sudoku!'
            : '👆 Tap the final [?] cell to complete the Sudoku board!',
        targetLabel: '8',
        boardCells: const ['1', '2', '3', '4', '5', '6', '7', '?', '9'],
        targetIndex: 7,
      ),
    ],
    GameType.minesweeper => [
      _TutorialStepSpec(
        stepTitle: isId
            ? 'Langkah 1/3: Klik Pertama Pasti Aman (⛏️)'
            : 'Step 1/3: First Dig Is Always Safe (⛏️)',
        pauseExplanation: isId
            ? '⏸️ GAME DI-PAUSE: Di Minesweeper Zetzy, ketukan pertamamu dijamin 100% AMAN dari ranjau dan akan membuka area petunjuk angka.'
            : '⏸️ PAUSED: In Zetzy Minesweeper, your first tap is guaranteed 100% safe and reveals clue numbers.',
        actionPrompt: isId
            ? '👆 Ketuk kotak tengah [⛏️] yang berkedip untuk menggali!'
            : '👆 Tap the pulsing center [⛏️] tile to dig safely!',
        targetLabel: '⛏️',
        boardCells: const ['■', '■', '■', '■', '⛏️', '■', '■', '■', '■'],
        targetIndex: 4,
      ),
      _TutorialStepSpec(
        stepTitle: isId
            ? 'Langkah 2/3: Pasang Bendera (🚩) di Ranjau'
            : 'Step 2/3: Plant a Flag (🚩) on the Mine',
        pauseExplanation: isId
            ? '⏸️ GAME DI-PAUSE: Angka "1" berarti tepat ada 1 ranjau di kotak tertutup sebelahnya. Karena hanya pojok kanan atas yang masih tertutup di dekatnya, itu PASTI ranjau!'
            : '⏸️ PAUSED: The "1" means 1 adjacent hidden tile is a mine. Since only the top-right corner is hidden next to it, that tile MUST be a mine!',
        actionPrompt: isId
            ? '👆 Ketuk pojok kanan atas [🚩] yang berkedip untuk menancapkan Bendera!'
            : '👆 Tap the pulsing top-right [🚩] corner to plant a Flag!',
        targetLabel: '🚩',
        boardCells: const ['0', '1', '🚩', '0', '1', '1', '0', '0', '■'],
        targetIndex: 2,
      ),
      _TutorialStepSpec(
        stepTitle: isId
            ? 'Langkah 3/3: Buka Kotak Aman Terakhir!'
            : 'Step 3/3: Open the Final Safe Tile!',
        pauseExplanation: isId
            ? '⏸️ GAME DI-PAUSE: Karena satu-satunya ranjau di dekat angka "1" sudah kita kunci dengan Bendera (🚩), maka kotak tertutup di pojok kanan bawah PASTI AMAN!'
            : '⏸️ PAUSED: Because the single mine touching "1" is already flagged (🚩), the remaining bottom-right tile is 100% SAFE!',
        actionPrompt: isId
            ? '👆 Ketuk kotak [✓] di pojok kanan bawah untuk menang!'
            : '👆 Tap the bottom-right [✓] tile to win!',
        targetLabel: '✓',
        boardCells: const ['0', '1', '🚩', '0', '1', '1', '0', '0', '✓'],
        targetIndex: 8,
      ),
    ],
    GameType.chess => [
      _TutorialStepSpec(
        stepTitle: isId
            ? 'Langkah 1/4: Lompatan Kuda (♘) Huruf L'
            : 'Step 1/4: Knight (♘) L-Shape Jump',
        pauseExplanation: isId
            ? '⏸️ GAME DI-PAUSE: Kuda (♘) bergerak membentuk huruf "L" dan satu-satunya bidak yang bisa melompati bidak lain.'
            : '⏸️ PAUSED: The Knight (♘) moves in an "L" shape and is the only piece that can jump over other pieces.',
        actionPrompt: isId
            ? '👆 Ketuk petak tujuan [🎯] untuk melompatkan Kuda!'
            : '👆 Tap the target square [🎯] to jump your Knight!',
        targetLabel: '♘',
        boardCells: const [' ', ' ', '🎯', ' ', ' ', ' ', ' ', '♘', ' '],
        targetIndex: 2,
      ),
      _TutorialStepSpec(
        stepTitle: isId
            ? 'Langkah 2/4: Rokade (Castling ♔⇄♖)'
            : 'Step 2/4: Castling (♔⇄♖)',
        pauseExplanation: isId
            ? '⏸️ GAME DI-PAUSE: Saat jalur antara Raja (♔) dan Benteng (♖) kosong dan keduanya belum pernah gerak, geser Raja 2 petak ke kanan untuk Rokade!'
            : '⏸️ PAUSED: With clear squares between an unmoved King (♔) and Rook (♖), move the King 2 squares right to Castle!',
        actionPrompt: isId
            ? '👆 Ketuk petak Rokade [♔⇄♖] agar Raja & Benteng bertukar posisi aman!'
            : '👆 Tap the Castling square [♔⇄♖] to castle your King and Rook!',
        targetLabel: '♔⇄♖',
        boardCells: const [' ', ' ', ' ', ' ', ' ', ' ', '♔', '♔⇄♖', '♖'],
        targetIndex: 7,
      ),
      _TutorialStepSpec(
        stepTitle: isId
            ? 'Langkah 3/4: Tangkap En Passant (♙↗)'
            : 'Step 3/4: En Passant Capture (♙↗)',
        pauseExplanation: isId
            ? '⏸️ GAME DI-PAUSE: Pion hitam (♟) baru saja loncat 2 petak ke samping pion putihmu (♙). Kamu berhak memakannya secara diagonal (En Passant)!'
            : '⏸️ PAUSED: Black\'s pawn (♟) just jumped 2 squares beside your pawn (♙). Capture it diagonally via En Passant!',
        actionPrompt: isId
            ? '👆 Ketuk petak diagonal [↗] di belakang pion lawan untuk En Passant!'
            : '👆 Tap the diagonal [↗] square behind the enemy pawn for En Passant!',
        targetLabel: '↗',
        boardCells: const [' ', '↗', ' ', ' ', '♟', '♙', ' ', ' ', ' '],
        targetIndex: 1,
      ),
      _TutorialStepSpec(
        stepTitle: isId
            ? 'Langkah 4/4: Promosi Pion → Menteri & Skakmat!'
            : 'Step 4/4: Pawn Promotion → Queen & Checkmate!',
        pauseExplanation: isId
            ? '⏸️ GAME DI-PAUSE: Pionmu sudah di baris ke-7! Majukan ke baris ujung untuk mengubahnya menjadi Menteri (♕) sekaligus Skakmat!'
            : '⏸️ PAUSED: Your pawn is on the 7th rank! Advance to the top rank to promote to a Queen (♕) and deliver Checkmate!',
        actionPrompt: isId
            ? '👆 Ketuk petak ujung [♕] untuk Promosi Pion menjadi Menteri!'
            : '👆 Tap the top square [♕] to promote your Pawn to a Queen!',
        targetLabel: '♕',
        boardCells: const ['♕', ' ', '♚', '♙', ' ', ' ', ' ', ' ', '♔'],
        targetIndex: 0,
      ),
    ],
    GameType.snake => [
      _TutorialStepSpec(
        stepTitle: isId
            ? 'Langkah 1/3: Belok 90° Makan Apel Merah (🍎)'
            : 'Step 1/3: Turn 90° to Eat the Red Apple (🍎)',
        pauseExplanation: isId
            ? '⏸️ GAME DI-PAUSE: Ular sedang bergerak ke kanan. Di atas kepala ular ada Apel Merah (+10 poin). Belokkan ular ke atas!'
            : '⏸️ PAUSED: Your snake is heading right and a Red Apple (+10 pts) is above. Turn upward to eat it!',
        actionPrompt: isId
            ? '👆 Ketuk petak [🍎] di atas kepala ular untuk berbelok memakannya!'
            : '👆 Tap the [🍎] tile above the snake\'s head to turn and eat it!',
        targetLabel: '🍎',
        boardCells: const [' ', '🍎', ' ', '🟢', '🐍', ' ', ' ', ' ', ' '],
        targetIndex: 1,
      ),
      _TutorialStepSpec(
        stepTitle: isId
            ? 'Langkah 2/3: Ambil Gunting (✂️) Pemotong Ekor'
            : 'Step 2/3: Grab Scissors (✂️) to Trim Your Tail',
        pauseExplanation: isId
            ? '⏸️ GAME DI-PAUSE: Saat tubuh ular mulai panjang, ambil item Gunting (✂️) untuk memotong ekor agar ruang gerak kembali lega!'
            : '⏸️ PAUSED: When your snake grows long, grab Scissors (✂️) to trim your tail and free up board space!',
        actionPrompt: isId
            ? '👆 Ketuk petak [✂️] untuk memotong ekor ular!'
            : '👆 Tap the [✂️] tile to trim your snake\'s tail!',
        targetLabel: '✂️',
        boardCells: const [' ', '🐍', '✂️', ' ', '🟢', ' ', ' ', '🟢', ' '],
        targetIndex: 2,
      ),
      _TutorialStepSpec(
        stepTitle: isId
            ? 'Langkah 3/3: Hindari Racun (☠️) & Ambil Apel Emas (🌟)'
            : 'Step 3/3: Dodge Poison (☠️) & Grab Golden Apple (🌟)',
        pauseExplanation: isId
            ? '⏸️ GAME DI-PAUSE: Di bawah ada Racun (☠️) dan Dinding Bata (🧱). Jangan lewat sana! Ambil jalur aman menuju Apel Emas (+30 poin)!'
            : '⏸️ PAUSED: Poison (☠️) and a Brick Wall (🧱) block the middle. Steer safely to the Golden Apple (+30 pts)!',
        actionPrompt: isId
            ? '👆 Ketuk petak Apel Emas [🌟] untuk menyelesaikan tutorial Snake!'
            : '👆 Tap the Golden Apple [🌟] tile to finish the Snake tutorial!',
        targetLabel: '🌟',
        boardCells: const [' ', ' ', '🐍', ' ', '☠️', '🌟', ' ', '🧱', ' '],
        targetIndex: 5,
      ),
    ],
  };

  void _onTapCell(int index, List<_TutorialStepSpec> steps) {
    final current = steps[_stepIndex];
    if (index != current.targetIndex) {
      setState(() {
        _wrongTapHint = widget.isId
            ? 'Ketuk kotak yang berkedip (disorot warna aksen) untuk langkah tutorial ini ya!'
            : 'Tap the highlighted pulsing tile for this tutorial step!';
      });
      return;
    }

    setState(() {
      _wrongTapHint = null;
      if (_stepIndex < steps.length - 1) {
        _stepIndex++;
        _isPausedForExplanation = true;
      } else {
        _completed = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final isId = widget.isId;
    final steps = _steps(isId);
    final step = steps[_stepIndex];

    return Dialog(
      backgroundColor: p.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: p.border),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: _completed
              ? _buildCompletedView(context, p, isId)
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top status bar
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _isPausedForExplanation
                                ? p.warning.withValues(alpha: 0.18)
                                : p.accent.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            _isPausedForExplanation
                                ? (isId
                                      ? '⏸️ PAUSED • PENJELASAN'
                                      : '⏸️ PAUSED • COACH GUIDE')
                                : (isId
                                      ? '👆 GILIRANMU • PRAKTIK'
                                      : '👆 YOUR TURN • TRY IT'),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: _isPausedForExplanation
                                  ? p.warning
                                  : p.accent,
                            ),
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close_rounded, size: 20),
                          tooltip: isId ? 'Keluar Tutorial' : 'Exit Tutorial',
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      step.stepTitle,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Coach explanation banner
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: p.surfaceElevated,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _isPausedForExplanation ? p.warning : p.accent,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isPausedForExplanation
                                ? step.pauseExplanation
                                : step.actionPrompt,
                            style: const TextStyle(fontSize: 13, height: 1.4),
                          ),
                          if (_isPausedForExplanation) ...[
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                key: const ValueKey(
                                  'tutorial_resume_action_btn',
                                ),
                                onPressed: () => setState(
                                  () => _isPausedForExplanation = false,
                                ),
                                icon: const Icon(
                                  Icons.play_arrow_rounded,
                                  size: 18,
                                ),
                                label: Text(
                                  isId
                                      ? 'Mengerti, Coba Sekarang!'
                                      : 'Got It, Try Now!',
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Interactive 3x3 Guided Board
                    Center(
                      child: SizedBox(
                        width: 228,
                        height: 228,
                        child: GridView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: 9,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                mainAxisSpacing: 8,
                                crossAxisSpacing: 8,
                              ),
                          itemBuilder: (_, idx) {
                            final isTarget = idx == step.targetIndex;
                            final label = step.boardCells[idx];
                            return InkWell(
                              key: isTarget
                                  ? const ValueKey('tutorial_target_cell')
                                  : ValueKey('tutorial_cell_$idx'),
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                if (_isPausedForExplanation && isTarget) {
                                  setState(
                                    () => _isPausedForExplanation = false,
                                  );
                                }
                                _onTapCell(idx, steps);
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: isTarget
                                      ? p.accent.withValues(alpha: 0.24)
                                      : p.surfaceElevated,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isTarget ? p.accent : p.border,
                                    width: isTarget ? 2.5 : 1,
                                  ),
                                ),
                                child: Text(
                                  label,
                                  style: ZetzyThemes.monoStyle(
                                    fontSize: 20,
                                    color: isTarget ? p.accent : p.textPrimary,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    if (_wrongTapHint != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        _wrongTapHint!,
                        style: TextStyle(fontSize: 12, color: p.warning),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildCompletedView(
    BuildContext context,
    ZetzyPalette p,
    bool isId,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.emoji_events_rounded, size: 54, color: p.accent),
        const SizedBox(height: 10),
        Text(
          isId ? 'Tutorial Selesai! 🎉' : 'Tutorial Complete! 🎉',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          isId
              ? 'Kamu sudah menguasai aturan & cara main ${_gameName(widget.game)}. Siap mencoba permainan sesungguhnya?'
              : 'You have mastered the core rules of ${_gameName(widget.game)}. Ready to jump into a real match?',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: p.textSecondary, height: 1.4),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                key: const ValueKey('tutorial_finish_close_btn'),
                onPressed: () => Navigator.of(context).pop(),
                child: Text(isId ? 'Selesai' : 'Done'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                key: const ValueKey('tutorial_play_real_btn'),
                onPressed: () {
                  Navigator.of(context).pop();
                  widget.onStartRealGame();
                },
                icon: const Icon(Icons.play_arrow_rounded, size: 18),
                label: Text(isId ? 'Main Sekarang!' : 'Play Now!'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
