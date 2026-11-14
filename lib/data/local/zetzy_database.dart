import 'package:drift/drift.dart';

part 'zetzy_database.g.dart';

/// 4 independent auto-save slots keyed by `gameType` (PRD 2.1 / 10B).
class AutoSaveSlots extends Table {
  TextColumn get gameType => text()();
  IntColumn get difficulty => integer()();
  IntColumn get elapsedMs => integer()();
  TextColumn get stateJson => text()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {gameType};
}

/// Offline queue of scores awaiting Supabase sync (PRD 2.1 / 9B / 27A).
class OfflineScoreQueue extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get gameType => text()();
  IntColumn get difficulty => integer()();
  BoolColumn get isWon => boolean()();
  IntColumn get score => integer()();
  IntColumn get durationMs => integer()();
  TextColumn get platform => text()();
  TextColumn get metadataJson => text()();
  DateTimeColumn get playedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Local history of all played games for offline stats & Personal Best.
class LocalGameRecords extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get username => text()();
  TextColumn get gameType => text()();
  IntColumn get difficulty => integer()();
  BoolColumn get isWon => boolean()();
  IntColumn get score => integer()();
  IntColumn get durationMs => integer()();
  TextColumn get platform => text()();
  TextColumn get metadataJson => text()();
  DateTimeColumn get playedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DriftDatabase(tables: [AutoSaveSlots, OfflineScoreQueue, LocalGameRecords])
class ZetzyDatabase extends _$ZetzyDatabase {
  ZetzyDatabase(super.e);

  @override
  int get schemaVersion => 1;
}
