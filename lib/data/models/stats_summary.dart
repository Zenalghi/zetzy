import 'dart:math';

import 'package:zetzy/core/constants/app_constants.dart';
import 'package:zetzy/data/models/game_record.dart';

/// Compact match bar data used for the 20-match trend chart on [StatisticsScreen].
class RecentMatchStat {
  const RecentMatchStat({
    required this.isWon,
    required this.durationMs,
  });

  final bool isWon;
  final int durationMs;

  factory RecentMatchStat.fromJson(Map<String, dynamic> json) =>
      RecentMatchStat(
        isWon: json['is_won'] == true,
        durationMs: (json['duration_ms'] as num?)?.toInt() ?? 3000,
      );

  Map<String, dynamic> toJson() => {
    'is_won': isWon,
    'duration_ms': durationMs,
  };
}

/// Per-game aggregate counters shown at the bottom of [StatisticsScreen].
class GameStatsBreakdown {
  const GameStatsBreakdown({
    this.totalPlayed = 0,
    this.wins = 0,
    this.totalDurationMs = 0,
  });

  final int totalPlayed;
  final int wins;
  final int totalDurationMs;

  factory GameStatsBreakdown.fromJson(Map<String, dynamic> json) =>
      GameStatsBreakdown(
        totalPlayed: (json['total_played'] as num?)?.toInt() ?? 0,
        wins: (json['wins'] as num?)?.toInt() ?? 0,
        totalDurationMs: (json['total_duration_ms'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toJson() => {
    'total_played': totalPlayed,
    'wins': wins,
    'total_duration_ms': totalDurationMs,
  };
}

/// Snapshot of all metrics rendered on the Statistics page, computable from
/// local [GameRecord]s and synced to `public.profiles.account_data['stats']`.
class StatsSummary {
  const StatsSummary({
    required this.totalPlayed,
    required this.wins,
    required this.winRate,
    required this.totalDurationMs,
    required this.avgMs,
    required this.bestStreak,
    required this.totalXp,
    required this.playerLevel,
    required this.levelProgress,
    required this.perGame,
    required this.recentMatches,
  });

  final int totalPlayed;
  final int wins;
  final double winRate;
  final int totalDurationMs;
  final int avgMs;
  final int bestStreak;
  final int totalXp;
  final int playerLevel;
  final double levelProgress;
  final Map<GameType, GameStatsBreakdown> perGame;
  final List<RecentMatchStat> recentMatches;

  static const StatsSummary empty = StatsSummary(
    totalPlayed: 0,
    wins: 0,
    winRate: 0,
    totalDurationMs: 0,
    avgMs: 0,
    bestStreak: 0,
    totalXp: 0,
    playerLevel: 1,
    levelProgress: 0,
    perGame: {},
    recentMatches: [],
  );

  GameStatsBreakdown breakdownFor(GameType game) =>
      perGame[game] ?? const GameStatsBreakdown();

  factory StatsSummary.fromRecords(List<GameRecord> records) {
    final totalPlayed = records.length;
    final wins = records.where((r) => r.isWon).length;
    final winRate = totalPlayed == 0 ? 0.0 : (wins / totalPlayed) * 100;
    final totalDurationMs = records.fold<int>(
      0,
      (sum, r) => sum + r.durationMs,
    );
    final avgMs = totalPlayed == 0 ? 0 : totalDurationMs ~/ totalPlayed;
    final bestStreak = _computeBestStreak(records);
    final totalXp = _computeTotalXp(records);
    final playerLevel = 1 + (totalXp ~/ 250);
    final levelProgress = (totalXp % 250) / 250.0;

    final perGame = <GameType, GameStatsBreakdown>{};
    for (final game in GameType.values) {
      final gameRecords = records.where((r) => r.gameType == game);
      var count = 0;
      var won = 0;
      var dur = 0;
      for (final r in gameRecords) {
        count++;
        if (r.isWon) won++;
        dur += r.durationMs;
      }
      perGame[game] = GameStatsBreakdown(
        totalPlayed: count,
        wins: won,
        totalDurationMs: dur,
      );
    }

    final sortedRecent = List<GameRecord>.from(records)
      ..sort((a, b) => b.playedAt.compareTo(a.playedAt));
    final recentMatches = sortedRecent
        .take(20)
        .toList()
        .reversed
        .map((r) => RecentMatchStat(isWon: r.isWon, durationMs: r.durationMs))
        .toList(growable: false);

    return StatsSummary(
      totalPlayed: totalPlayed,
      wins: wins,
      winRate: winRate,
      totalDurationMs: totalDurationMs,
      avgMs: avgMs,
      bestStreak: bestStreak,
      totalXp: totalXp,
      playerLevel: playerLevel,
      levelProgress: levelProgress,
      perGame: perGame,
      recentMatches: recentMatches,
    );
  }

  factory StatsSummary.fromJson(Map<String, dynamic> json) {
    final totalPlayed = (json['total_played'] as num?)?.toInt() ?? 0;
    final wins = (json['wins'] as num?)?.toInt() ?? 0;
    final totalDurationMs = (json['total_duration_ms'] as num?)?.toInt() ?? 0;
    final totalXp = (json['total_xp'] as num?)?.toInt() ?? 0;
    final rawPerGame = json['per_game'];
    final perGame = <GameType, GameStatsBreakdown>{};
    if (rawPerGame is Map) {
      for (final g in GameType.values) {
        final raw = rawPerGame[g.id];
        if (raw is Map) {
          perGame[g] = GameStatsBreakdown.fromJson(
            Map<String, dynamic>.from(raw),
          );
        } else {
          perGame[g] = const GameStatsBreakdown();
        }
      }
    }
    final rawRecent = json['recent_matches'];
    final recent = <RecentMatchStat>[];
    if (rawRecent is List) {
      for (final item in rawRecent) {
        if (item is Map) {
          recent.add(RecentMatchStat.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    return StatsSummary(
      totalPlayed: totalPlayed,
      wins: wins,
      winRate: (json['win_rate'] as num?)?.toDouble() ??
          (totalPlayed == 0 ? 0.0 : (wins / totalPlayed) * 100),
      totalDurationMs: totalDurationMs,
      avgMs: (json['avg_duration_ms'] as num?)?.toInt() ??
          (totalPlayed == 0 ? 0 : totalDurationMs ~/ totalPlayed),
      bestStreak: (json['best_streak'] as num?)?.toInt() ?? 0,
      totalXp: totalXp,
      playerLevel: (json['player_level'] as num?)?.toInt() ??
          (1 + (totalXp ~/ 250)),
      levelProgress: (json['level_progress'] as num?)?.toDouble() ??
          ((totalXp % 250) / 250.0),
      perGame: perGame,
      recentMatches: recent,
    );
  }

  Map<String, dynamic> toJson() => {
    'total_played': totalPlayed,
    'wins': wins,
    'win_rate': winRate,
    'total_duration_ms': totalDurationMs,
    'avg_duration_ms': avgMs,
    'best_streak': bestStreak,
    'total_xp': totalXp,
    'player_level': playerLevel,
    'level_progress': levelProgress,
    'per_game': {
      for (final g in GameType.values) g.id: breakdownFor(g).toJson(),
    },
    'recent_matches': [for (final m in recentMatches) m.toJson()],
  };

  static int _computeBestStreak(List<GameRecord> records) {
    final sorted = List<GameRecord>.from(records)
      ..sort((a, b) => a.playedAt.compareTo(b.playedAt));
    var best = 0;
    var current = 0;
    for (final r in sorted) {
      if (r.isWon) {
        current++;
        best = max(best, current);
      } else {
        current = 0;
      }
    }
    return best;
  }

  static int _computeTotalXp(List<GameRecord> records) {
    var xp = 0;
    for (final r in records) {
      if (r.isWon) {
        xp += DifficultyLevel.fromLevel(r.difficulty).xpReward;
      } else {
        xp += 5;
      }
    }
    return xp;
  }
}
