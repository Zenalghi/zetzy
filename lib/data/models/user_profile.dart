import 'package:zetzy/core/constants/app_constants.dart';
import 'package:zetzy/data/models/stats_summary.dart';

/// Authorization role assigned in Supabase `public.profiles.role`.
enum UserRole {
  player('player'),
  admin('admin');

  const UserRole(this.id);
  final String id;

  static UserRole fromId(String? raw) =>
      raw == UserRole.admin.id ? UserRole.admin : UserRole.player;
}

/// User profile & progression state (local guest or Supabase `public.profiles`).
class UserProfile {
  const UserProfile({
    required this.id,
    required this.username,
    this.avatarUrl,
    this.chessElo = 1000,
    this.hasRecoveryCode = false,
    this.role = UserRole.player,
    this.unlockedLevels = const {
      GameType.sudoku: 5,
      GameType.chess: 5,
      GameType.minesweeper: 5,
      GameType.snake: 5,
    },
    this.accountData = const {},
    this.isGuest = true,
  });

  final String id;
  final String username;
  final String? avatarUrl;
  final int chessElo;
  final bool hasRecoveryCode;
  final UserRole role;
  final Map<GameType, int> unlockedLevels;
  final Map<String, dynamic> accountData;
  final bool isGuest;

  bool get isAdmin => !isGuest && role == UserRole.admin;

  int unlockedFor(GameType game) =>
      unlockedLevels[game] ?? DifficultyLevel.defaultUnlockedLevel;

  Map<String, dynamic>? get syncedSettingsJson {
    final raw = accountData['settings'];
    return raw is Map ? Map<String, dynamic>.from(raw) : null;
  }

  StatsSummary? get syncedStats {
    final raw = accountData['stats'];
    return raw is Map
        ? StatsSummary.fromJson(Map<String, dynamic>.from(raw))
        : null;
  }

  UserProfile copyWith({
    String? id,
    String? username,
    String? avatarUrl,
    bool clearAvatar = false,
    int? chessElo,
    bool? hasRecoveryCode,
    UserRole? role,
    Map<GameType, int>? unlockedLevels,
    Map<String, dynamic>? accountData,
    bool? isGuest,
  }) {
    return UserProfile(
      id: id ?? this.id,
      username: username ?? this.username,
      avatarUrl: clearAvatar ? null : (avatarUrl ?? this.avatarUrl),
      chessElo: chessElo ?? this.chessElo,
      hasRecoveryCode: hasRecoveryCode ?? this.hasRecoveryCode,
      role: role ?? this.role,
      unlockedLevels: unlockedLevels ?? this.unlockedLevels,
      accountData: accountData ?? this.accountData,
      isGuest: isGuest ?? this.isGuest,
    );
  }

  factory UserProfile.guest({Map<GameType, int>? unlockedLevels, int? chessElo}) {
    return UserProfile(
      id: 'guest',
      username: 'guest',
      chessElo: chessElo ?? 1000,
      role: UserRole.player,
      unlockedLevels: unlockedLevels ??
          const {
            GameType.sudoku: 5,
            GameType.chess: 5,
            GameType.minesweeper: 5,
            GameType.snake: 5,
          },
      accountData: const {},
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
    final rawAccountData = json['account_data'];
    return UserProfile(
      id: json['id'].toString(),
      username: (json['username'] ?? 'player').toString(),
      avatarUrl: json['avatar_url'] as String?,
      chessElo: (json['chess_elo'] as num?)?.toInt() ?? 1000,
      hasRecoveryCode: json['recovery_hash'] != null,
      role: UserRole.fromId(json['role']?.toString()),
      unlockedLevels: levels,
      accountData: rawAccountData is Map
          ? Map<String, dynamic>.from(rawAccountData)
          : const {},
      isGuest: false,
    );
  }

  Map<String, dynamic> unlockedLevelsJson() => {
    for (final entry in unlockedLevels.entries) entry.key.id: entry.value,
  };
}
