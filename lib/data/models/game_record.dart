import 'dart:convert';
import 'package:zetzy/core/constants/app_constants.dart';

/// Represents a completed game session record (local & Supabase `game_records`).
class GameRecord {
  const GameRecord({
    required this.id,
    required this.userId,
    required this.username,
    required this.gameType,
    required this.difficulty,
    required this.isWon,
    required this.score,
    required this.durationMs,
    required this.platform,
    required this.playedAt,
    this.avatarUrl,
    this.metadata = const {},
  });

  final String id;
  final String userId;
  final String username;
  final String? avatarUrl;
  final GameType gameType;
  final int difficulty;
  final bool isWon;
  final int score;
  final int durationMs;
  final String platform;
  final DateTime playedAt;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'username': username,
    'avatar_url': avatarUrl,
    'game_type': gameType.id,
    'difficulty': difficulty,
    'is_won': isWon,
    'score': score,
    'duration_ms': durationMs,
    'platform': platform,
    'played_at': playedAt.toIso8601String(),
    'metadata': metadata,
  };

  factory GameRecord.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>?;
    final rawMeta = json['metadata'];
    Map<String, dynamic> parsedMeta = const {};
    if (rawMeta is Map<String, dynamic>) {
      parsedMeta = rawMeta;
    } else if (rawMeta is String && rawMeta.isNotEmpty) {
      try {
        parsedMeta = jsonDecode(rawMeta) as Map<String, dynamic>;
      } catch (_) {}
    }

    return GameRecord(
      id: (json['id'] ?? '').toString(),
      userId: (json['user_id'] ?? 'guest').toString(),
      username:
          (profile?['username'] ?? json['username'] ?? 'guest').toString(),
      avatarUrl: (profile?['avatar_url'] ?? json['avatar_url']) as String?,
      gameType: GameType.fromId((json['game_type'] ?? 'sudoku').toString()),
      difficulty: (json['difficulty'] as num?)?.toInt() ?? 1,
      isWon: json['is_won'] == true,
      score: (json['score'] as num?)?.toInt() ?? 0,
      durationMs: (json['duration_ms'] as num?)?.toInt() ?? 0,
      platform: (json['platform'] ?? 'web').toString(),
      playedAt:
          DateTime.tryParse((json['played_at'] ?? '').toString()) ??
          DateTime.now(),
      metadata: parsedMeta,
    );
  }
}
