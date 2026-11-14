import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zetzy/core/constants/app_constants.dart';
import 'package:zetzy/data/local/database_opener_web.dart'
    if (dart.library.io) 'package:zetzy/data/local/database_opener_native.dart';
import 'package:zetzy/data/local/zetzy_database.dart' hide AutoSaveSlot;
import 'package:zetzy/data/models/auto_save_slot.dart';
import 'package:zetzy/data/models/game_record.dart';

/// Unified local storage service: uses Drift (SQLite) on native platforms
/// and SharedPreferences fallback on Web (where sqlite3.wasm is optional).
class LocalStorageService {
  LocalStorageService({
    ZetzyDatabase? database,
    required this._prefs,
  }) : _db = database;

  final ZetzyDatabase? _db;
  final SharedPreferences _prefs;

  static const _webSavesKey = 'zetzy_web_auto_saves';
  static const _webQueueKey = 'zetzy_web_score_queue';
  static const _webRecordsKey = 'zetzy_web_local_records';

  static Future<LocalStorageService> create() async {
    final prefs = await SharedPreferences.getInstance();
    final db = await openNativeDatabase();
    return LocalStorageService(database: db, prefs: prefs);
  }

  /// Creates an in-memory storage instance (ideal for unit/widget tests).
  factory LocalStorageService.forTesting({
    ZetzyDatabase? database,
    required SharedPreferences prefs,
  }) => LocalStorageService(database: database, prefs: prefs);

  // ── Auto-Save Slots (4 independent slots per game) ──────────────────────

  Future<void> saveGameSlot(AutoSaveSlot slot) async {
    final db = _db;
    if (db != null) {
      await db
          .into(db.autoSaveSlots)
          .insertOnConflictUpdate(
            AutoSaveSlotsCompanion.insert(
              gameType: slot.gameType.id,
              difficulty: slot.difficulty,
              elapsedMs: slot.elapsedMs,
              stateJson: jsonEncode(slot.stateJson),
              updatedAt: slot.updatedAt,
            ),
          );
      return;
    }

    final map = _readWebMap(_webSavesKey);
    map[slot.gameType.id] = slot.toJson();
    await _prefs.setString(_webSavesKey, jsonEncode(map));
  }

  Future<AutoSaveSlot?> loadGameSlot(GameType gameType) async {
    final db = _db;
    if (db != null) {
      final row = await (db.select(
        db.autoSaveSlots,
      )..where((t) => t.gameType.equals(gameType.id))).getSingleOrNull();
      if (row == null) return null;
      return AutoSaveSlot(
        gameType: GameType.fromId(row.gameType),
        difficulty: row.difficulty,
        elapsedMs: row.elapsedMs,
        stateJson: jsonDecode(row.stateJson) as Map<String, dynamic>,
        updatedAt: row.updatedAt,
      );
    }

    final map = _readWebMap(_webSavesKey);
    final raw = map[gameType.id];
    if (raw is! Map<String, dynamic>) return null;
    return AutoSaveSlot.fromJson(raw);
  }

  Future<Map<GameType, AutoSaveSlot>> loadAllGameSlots() async {
    final db = _db;
    if (db != null) {
      final rows = await db.select(db.autoSaveSlots).get();
      return {
        for (final row in rows)
          GameType.fromId(row.gameType): AutoSaveSlot(
            gameType: GameType.fromId(row.gameType),
            difficulty: row.difficulty,
            elapsedMs: row.elapsedMs,
            stateJson: jsonDecode(row.stateJson) as Map<String, dynamic>,
            updatedAt: row.updatedAt,
          ),
      };
    }

    final map = _readWebMap(_webSavesKey);
    final result = <GameType, AutoSaveSlot>{};
    for (final entry in map.entries) {
      if (entry.value is Map<String, dynamic>) {
        result[GameType.fromId(entry.key)] = AutoSaveSlot.fromJson(
          entry.value as Map<String, dynamic>,
        );
      }
    }
    return result;
  }

  Future<void> clearGameSlot(GameType gameType) async {
    final db = _db;
    if (db != null) {
      await (db.delete(
        db.autoSaveSlots,
      )..where((t) => t.gameType.equals(gameType.id))).go();
      return;
    }

    final map = _readWebMap(_webSavesKey);
    map.remove(gameType.id);
    await _prefs.setString(_webSavesKey, jsonEncode(map));
  }

  // ── Local Game Records ──────────────────────────────────────────────────

  Future<void> saveLocalRecord(GameRecord record) async {
    final db = _db;
    if (db != null) {
      await db
          .into(db.localGameRecords)
          .insertOnConflictUpdate(
            LocalGameRecordsCompanion.insert(
              id: record.id,
              userId: record.userId,
              username: record.username,
              gameType: record.gameType.id,
              difficulty: record.difficulty,
              isWon: record.isWon,
              score: record.score,
              durationMs: record.durationMs,
              platform: record.platform,
              metadataJson: jsonEncode(record.metadata),
              playedAt: record.playedAt,
            ),
          );
      return;
    }

    final list = _readWebList(_webRecordsKey);
    list.removeWhere((item) => item['id'] == record.id);
    list.insert(0, record.toJson());
    await _prefs.setString(_webRecordsKey, jsonEncode(list));
  }

  Future<List<GameRecord>> fetchLocalRecords({
    GameType? gameType,
    int? difficulty,
  }) async {
    final db = _db;
    if (db != null) {
      final query = db.select(db.localGameRecords);
      if (gameType != null) {
        query.where((t) => t.gameType.equals(gameType.id));
      }
      if (difficulty != null) {
        query.where((t) => t.difficulty.equals(difficulty));
      }
      query.orderBy([(t) => OrderingTerm.desc(t.playedAt)]);
      final rows = await query.get();
      return rows
          .map(
            (r) => GameRecord(
              id: r.id,
              userId: r.userId,
              username: r.username,
              gameType: GameType.fromId(r.gameType),
              difficulty: r.difficulty,
              isWon: r.isWon,
              score: r.score,
              durationMs: r.durationMs,
              platform: r.platform,
              playedAt: r.playedAt,
              metadata:
                  jsonDecode(r.metadataJson) as Map<String, dynamic>? ?? {},
            ),
          )
          .toList();
    }

    final list = _readWebList(_webRecordsKey);
    return list
        .map(GameRecord.fromJson)
        .where((r) => gameType == null || r.gameType == gameType)
        .where((r) => difficulty == null || r.difficulty == difficulty)
        .toList()
      ..sort((a, b) => b.playedAt.compareTo(a.playedAt));
  }

  Future<void> clearAllLocalRecords() async {
    final db = _db;
    if (db != null) {
      await db.delete(db.localGameRecords).go();
      await db.delete(db.offlineScoreQueue).go();
      return;
    }
    await _prefs.remove(_webRecordsKey);
    await _prefs.remove(_webQueueKey);
  }

  // ── Offline Score Queue ─────────────────────────────────────────────────

  Future<void> enqueueScore(GameRecord record) async {
    final db = _db;
    if (db != null) {
      await db
          .into(db.offlineScoreQueue)
          .insertOnConflictUpdate(
            OfflineScoreQueueCompanion.insert(
              id: record.id,
              userId: record.userId,
              gameType: record.gameType.id,
              difficulty: record.difficulty,
              isWon: record.isWon,
              score: record.score,
              durationMs: record.durationMs,
              platform: record.platform,
              metadataJson: jsonEncode(record.metadata),
              playedAt: record.playedAt,
            ),
          );
      return;
    }

    final list = _readWebList(_webQueueKey);
    list.removeWhere((item) => item['id'] == record.id);
    list.add(record.toJson());
    await _prefs.setString(_webQueueKey, jsonEncode(list));
  }

  Future<List<GameRecord>> getQueuedScores() async {
    final db = _db;
    if (db != null) {
      final rows = await db.select(db.offlineScoreQueue).get();
      return rows
          .map(
            (r) => GameRecord(
              id: r.id,
              userId: r.userId,
              username: 'pending',
              gameType: GameType.fromId(r.gameType),
              difficulty: r.difficulty,
              isWon: r.isWon,
              score: r.score,
              durationMs: r.durationMs,
              platform: r.platform,
              playedAt: r.playedAt,
              metadata:
                  jsonDecode(r.metadataJson) as Map<String, dynamic>? ?? {},
            ),
          )
          .toList();
    }

    return _readWebList(_webQueueKey).map(GameRecord.fromJson).toList();
  }

  Future<void> removeQueuedScore(String id) async {
    final db = _db;
    if (db != null) {
      await (db.delete(
        db.offlineScoreQueue,
      )..where((t) => t.id.equals(id))).go();
      return;
    }
    final list = _readWebList(_webQueueKey);
    list.removeWhere((item) => item['id'] == id);
    await _prefs.setString(_webQueueKey, jsonEncode(list));
  }

  Map<String, dynamic> _readWebMap(String key) {
    final raw = _prefs.getString(key);
    if (raw == null || raw.isEmpty) return {};
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return {};
    }
  }

  List<Map<String, dynamic>> _readWebList(String key) {
    final raw = _prefs.getString(key);
    if (raw == null || raw.isEmpty) return [];
    try {
      return (jsonDecode(raw) as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> close() async {
    await _db?.close();
  }
}
