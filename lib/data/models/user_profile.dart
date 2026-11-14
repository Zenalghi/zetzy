import 'package:zetzy/core/constants/app_constants.dart';

/// User profile & progression state (local guest or Supabase `public.profiles`).
class UserProfile {
  const UserProfile({
    required this.id,
    required this.username,
    this.avatarUrl,
    this.chessElo = 1000,
    this.hasRecoveryCode = false,
    this.unlockedLevels = const {
      GameType.sudoku: 5,
      GameType.chess: 5,
      GameType.minesweeper: 5,
      GameType.snake: 5,
    },
    this.isGuest = true,
  });

  final String id;
  final String username;
  final String? avatarUrl;
  final int chessElo;
  final bool hasRecoveryCode;
  final Map<GameType, int> unlockedLevels;
  final bool isGuest;

  int unlockedFor(GameType game) =>
      unlockedLevels[game] ?? DifficultyLevel.defaultUnlockedLevel;

  UserProfile copyWith({
    String? id,
    String? username,
    String? avatarUrl,
    bool clearAvatar = false,
    int? chessElo,
    bool? hasRecoveryCode,
    Map<GameType, int>? unlockedLevels,
    bool? isGuest,
  }) {
    return UserProfile(
      id: id ?? this.id,
      username: username ?? this.username,
      avatarUrl: clearAvatar ? null : (avatarUrl ?? this.avatarUrl),
      chessElo: chessElo ?? this.chessElo,
      hasRecoveryCode: hasRecoveryCode ?? this.hasRecoveryCode,
      unlockedLevels: unlockedLevels ?? this.unlockedLevels,
      isGuest: isGuest ?? this.isGuest,
    );
  }

  factory UserProfile.guest({Map<GameType, int>? unlockedLevels, int? chessElo}) {
    return UserProfile(
      id: 'guest',
      username: 'guest',
      chessElo: chessElo ?? 1000,
      unlockedLevels: unlockedLevels ??
          const {
            GameType.sudoku: 5,
            GameType.chess: 5,
            GameType.minesweeper: 5,
            GameType.snake: 5,
          },
      isGuest: true,
    );
  }

  factory UserProfile.fromSupabase(Map<String, dynamic> json) {
    final rawLevels = json['unlocked_levels'] as Map<String, dynamic>? ?? {};
    final levels = <GameType, int>{};
    for (final g in GameType.values) {
      levels[g] =
          (rawLevels[g.id] as num?)?.toInt() ??
          DifficultyLevel.defaultUnlockedLevel;
    }
    return UserProfile(
      id: json['id'].toString(),
      username: (json['username'] ?? 'player').toString(),
      avatarUrl: json['avatar_url'] as String?,
      chessElo: (json['chess_elo'] as num?)?.toInt() ?? 1000,
      hasRecoveryCode: json['recovery_hash'] != null,
      unlockedLevels: levels,
      isGuest: false,
    );
  }

  Map<String, dynamic> unlockedLevelsJson() => {
    for (final entry in unlockedLevels.entries) entry.key.id: entry.value,
  };
}
