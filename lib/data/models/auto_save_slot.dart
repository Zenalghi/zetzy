import 'dart:convert';
import 'package:zetzy/core/constants/app_constants.dart';

/// Represents 1 of the 4 independent auto-save slots (one per game type).
class AutoSaveSlot {
  const AutoSaveSlot({
    required this.gameType,
    required this.difficulty,
    required this.elapsedMs,
    required this.stateJson,
    required this.updatedAt,
  });

  final GameType gameType;
  final int difficulty;
  final int elapsedMs;
  final Map<String, dynamic> stateJson;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() => {
    'game_type': gameType.id,
    'difficulty': difficulty,
    'elapsed_ms': elapsedMs,
    'state_json': stateJson,
    'updated_at': updatedAt.toIso8601String(),
  };

  factory AutoSaveSlot.fromJson(Map<String, dynamic> json) {
    final rawState = json['state_json'];
    Map<String, dynamic> decodedState = {};
    if (rawState is Map<String, dynamic>) {
      decodedState = rawState;
    } else if (rawState is String && rawState.isNotEmpty) {
      decodedState = jsonDecode(rawState) as Map<String, dynamic>;
    }
    return AutoSaveSlot(
      gameType: GameType.fromId((json['game_type'] ?? 'sudoku').toString()),
      difficulty: (json['difficulty'] as num?)?.toInt() ?? 1,
      elapsedMs: (json['elapsed_ms'] as num?)?.toInt() ?? 0,
      stateJson: decodedState,
      updatedAt:
          DateTime.tryParse((json['updated_at'] ?? '').toString()) ??
          DateTime.now(),
    );
  }
}
