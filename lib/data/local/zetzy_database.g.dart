// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'zetzy_database.dart';

// ignore_for_file: type=lint
class $AutoSaveSlotsTable extends AutoSaveSlots
    with TableInfo<$AutoSaveSlotsTable, AutoSaveSlot> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AutoSaveSlotsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _gameTypeMeta = const VerificationMeta(
    'gameType',
  );
  @override
  late final GeneratedColumn<String> gameType = GeneratedColumn<String>(
    'game_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _difficultyMeta = const VerificationMeta(
    'difficulty',
  );
  @override
  late final GeneratedColumn<int> difficulty = GeneratedColumn<int>(
    'difficulty',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _elapsedMsMeta = const VerificationMeta(
    'elapsedMs',
  );
  @override
  late final GeneratedColumn<int> elapsedMs = GeneratedColumn<int>(
    'elapsed_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stateJsonMeta = const VerificationMeta(
    'stateJson',
  );
  @override
  late final GeneratedColumn<String> stateJson = GeneratedColumn<String>(
    'state_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    gameType,
    difficulty,
    elapsedMs,
    stateJson,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'auto_save_slots';
  @override
  VerificationContext validateIntegrity(
    Insertable<AutoSaveSlot> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('game_type')) {
      context.handle(
        _gameTypeMeta,
        gameType.isAcceptableOrUnknown(data['game_type']!, _gameTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_gameTypeMeta);
    }
    if (data.containsKey('difficulty')) {
      context.handle(
        _difficultyMeta,
        difficulty.isAcceptableOrUnknown(data['difficulty']!, _difficultyMeta),
      );
    } else if (isInserting) {
      context.missing(_difficultyMeta);
    }
    if (data.containsKey('elapsed_ms')) {
      context.handle(
        _elapsedMsMeta,
        elapsedMs.isAcceptableOrUnknown(data['elapsed_ms']!, _elapsedMsMeta),
      );
    } else if (isInserting) {
      context.missing(_elapsedMsMeta);
    }
    if (data.containsKey('state_json')) {
      context.handle(
        _stateJsonMeta,
        stateJson.isAcceptableOrUnknown(data['state_json']!, _stateJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_stateJsonMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {gameType};
  @override
  AutoSaveSlot map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AutoSaveSlot(
      gameType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}game_type'],
      )!,
      difficulty: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}difficulty'],
      )!,
      elapsedMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}elapsed_ms'],
      )!,
      stateJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}state_json'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $AutoSaveSlotsTable createAlias(String alias) {
    return $AutoSaveSlotsTable(attachedDatabase, alias);
  }
}

class AutoSaveSlot extends DataClass implements Insertable<AutoSaveSlot> {
  final String gameType;
  final int difficulty;
  final int elapsedMs;
  final String stateJson;
  final DateTime updatedAt;
  const AutoSaveSlot({
    required this.gameType,
    required this.difficulty,
    required this.elapsedMs,
    required this.stateJson,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['game_type'] = Variable<String>(gameType);
    map['difficulty'] = Variable<int>(difficulty);
    map['elapsed_ms'] = Variable<int>(elapsedMs);
    map['state_json'] = Variable<String>(stateJson);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  AutoSaveSlotsCompanion toCompanion(bool nullToAbsent) {
    return AutoSaveSlotsCompanion(
      gameType: Value(gameType),
      difficulty: Value(difficulty),
      elapsedMs: Value(elapsedMs),
      stateJson: Value(stateJson),
      updatedAt: Value(updatedAt),
    );
  }

  factory AutoSaveSlot.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AutoSaveSlot(
      gameType: serializer.fromJson<String>(json['gameType']),
      difficulty: serializer.fromJson<int>(json['difficulty']),
      elapsedMs: serializer.fromJson<int>(json['elapsedMs']),
      stateJson: serializer.fromJson<String>(json['stateJson']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'gameType': serializer.toJson<String>(gameType),
      'difficulty': serializer.toJson<int>(difficulty),
      'elapsedMs': serializer.toJson<int>(elapsedMs),
      'stateJson': serializer.toJson<String>(stateJson),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  AutoSaveSlot copyWith({
    String? gameType,
    int? difficulty,
    int? elapsedMs,
    String? stateJson,
    DateTime? updatedAt,
  }) => AutoSaveSlot(
    gameType: gameType ?? this.gameType,
    difficulty: difficulty ?? this.difficulty,
    elapsedMs: elapsedMs ?? this.elapsedMs,
    stateJson: stateJson ?? this.stateJson,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  AutoSaveSlot copyWithCompanion(AutoSaveSlotsCompanion data) {
    return AutoSaveSlot(
      gameType: data.gameType.present ? data.gameType.value : this.gameType,
      difficulty: data.difficulty.present
          ? data.difficulty.value
          : this.difficulty,
      elapsedMs: data.elapsedMs.present ? data.elapsedMs.value : this.elapsedMs,
      stateJson: data.stateJson.present ? data.stateJson.value : this.stateJson,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AutoSaveSlot(')
          ..write('gameType: $gameType, ')
          ..write('difficulty: $difficulty, ')
          ..write('elapsedMs: $elapsedMs, ')
          ..write('stateJson: $stateJson, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(gameType, difficulty, elapsedMs, stateJson, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AutoSaveSlot &&
          other.gameType == this.gameType &&
          other.difficulty == this.difficulty &&
          other.elapsedMs == this.elapsedMs &&
          other.stateJson == this.stateJson &&
          other.updatedAt == this.updatedAt);
}

class AutoSaveSlotsCompanion extends UpdateCompanion<AutoSaveSlot> {
  final Value<String> gameType;
  final Value<int> difficulty;
  final Value<int> elapsedMs;
  final Value<String> stateJson;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const AutoSaveSlotsCompanion({
    this.gameType = const Value.absent(),
    this.difficulty = const Value.absent(),
    this.elapsedMs = const Value.absent(),
    this.stateJson = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AutoSaveSlotsCompanion.insert({
    required String gameType,
    required int difficulty,
    required int elapsedMs,
    required String stateJson,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : gameType = Value(gameType),
       difficulty = Value(difficulty),
       elapsedMs = Value(elapsedMs),
       stateJson = Value(stateJson),
       updatedAt = Value(updatedAt);
  static Insertable<AutoSaveSlot> custom({
    Expression<String>? gameType,
    Expression<int>? difficulty,
    Expression<int>? elapsedMs,
    Expression<String>? stateJson,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (gameType != null) 'game_type': gameType,
      if (difficulty != null) 'difficulty': difficulty,
      if (elapsedMs != null) 'elapsed_ms': elapsedMs,
      if (stateJson != null) 'state_json': stateJson,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AutoSaveSlotsCompanion copyWith({
    Value<String>? gameType,
    Value<int>? difficulty,
    Value<int>? elapsedMs,
    Value<String>? stateJson,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return AutoSaveSlotsCompanion(
      gameType: gameType ?? this.gameType,
      difficulty: difficulty ?? this.difficulty,
      elapsedMs: elapsedMs ?? this.elapsedMs,
      stateJson: stateJson ?? this.stateJson,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (gameType.present) {
      map['game_type'] = Variable<String>(gameType.value);
    }
    if (difficulty.present) {
      map['difficulty'] = Variable<int>(difficulty.value);
    }
    if (elapsedMs.present) {
      map['elapsed_ms'] = Variable<int>(elapsedMs.value);
    }
    if (stateJson.present) {
      map['state_json'] = Variable<String>(stateJson.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AutoSaveSlotsCompanion(')
          ..write('gameType: $gameType, ')
          ..write('difficulty: $difficulty, ')
          ..write('elapsedMs: $elapsedMs, ')
          ..write('stateJson: $stateJson, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OfflineScoreQueueTable extends OfflineScoreQueue
    with TableInfo<$OfflineScoreQueueTable, OfflineScoreQueueData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OfflineScoreQueueTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _gameTypeMeta = const VerificationMeta(
    'gameType',
  );
  @override
  late final GeneratedColumn<String> gameType = GeneratedColumn<String>(
    'game_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _difficultyMeta = const VerificationMeta(
    'difficulty',
  );
  @override
  late final GeneratedColumn<int> difficulty = GeneratedColumn<int>(
    'difficulty',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isWonMeta = const VerificationMeta('isWon');
  @override
  late final GeneratedColumn<bool> isWon = GeneratedColumn<bool>(
    'is_won',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_won" IN (0, 1))',
    ),
  );
  static const VerificationMeta _scoreMeta = const VerificationMeta('score');
  @override
  late final GeneratedColumn<int> score = GeneratedColumn<int>(
    'score',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _durationMsMeta = const VerificationMeta(
    'durationMs',
  );
  @override
  late final GeneratedColumn<int> durationMs = GeneratedColumn<int>(
    'duration_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _platformMeta = const VerificationMeta(
    'platform',
  );
  @override
  late final GeneratedColumn<String> platform = GeneratedColumn<String>(
    'platform',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _metadataJsonMeta = const VerificationMeta(
    'metadataJson',
  );
  @override
  late final GeneratedColumn<String> metadataJson = GeneratedColumn<String>(
    'metadata_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _playedAtMeta = const VerificationMeta(
    'playedAt',
  );
  @override
  late final GeneratedColumn<DateTime> playedAt = GeneratedColumn<DateTime>(
    'played_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    gameType,
    difficulty,
    isWon,
    score,
    durationMs,
    platform,
    metadataJson,
    playedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'offline_score_queue';
  @override
  VerificationContext validateIntegrity(
    Insertable<OfflineScoreQueueData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('game_type')) {
      context.handle(
        _gameTypeMeta,
        gameType.isAcceptableOrUnknown(data['game_type']!, _gameTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_gameTypeMeta);
    }
    if (data.containsKey('difficulty')) {
      context.handle(
        _difficultyMeta,
        difficulty.isAcceptableOrUnknown(data['difficulty']!, _difficultyMeta),
      );
    } else if (isInserting) {
      context.missing(_difficultyMeta);
    }
    if (data.containsKey('is_won')) {
      context.handle(
        _isWonMeta,
        isWon.isAcceptableOrUnknown(data['is_won']!, _isWonMeta),
      );
    } else if (isInserting) {
      context.missing(_isWonMeta);
    }
    if (data.containsKey('score')) {
      context.handle(
        _scoreMeta,
        score.isAcceptableOrUnknown(data['score']!, _scoreMeta),
      );
    } else if (isInserting) {
      context.missing(_scoreMeta);
    }
    if (data.containsKey('duration_ms')) {
      context.handle(
        _durationMsMeta,
        durationMs.isAcceptableOrUnknown(data['duration_ms']!, _durationMsMeta),
      );
    } else if (isInserting) {
      context.missing(_durationMsMeta);
    }
    if (data.containsKey('platform')) {
      context.handle(
        _platformMeta,
        platform.isAcceptableOrUnknown(data['platform']!, _platformMeta),
      );
    } else if (isInserting) {
      context.missing(_platformMeta);
    }
    if (data.containsKey('metadata_json')) {
      context.handle(
        _metadataJsonMeta,
        metadataJson.isAcceptableOrUnknown(
          data['metadata_json']!,
          _metadataJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_metadataJsonMeta);
    }
    if (data.containsKey('played_at')) {
      context.handle(
        _playedAtMeta,
        playedAt.isAcceptableOrUnknown(data['played_at']!, _playedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_playedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OfflineScoreQueueData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OfflineScoreQueueData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      gameType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}game_type'],
      )!,
      difficulty: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}difficulty'],
      )!,
      isWon: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_won'],
      )!,
      score: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}score'],
      )!,
      durationMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_ms'],
      )!,
      platform: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}platform'],
      )!,
      metadataJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}metadata_json'],
      )!,
      playedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}played_at'],
      )!,
    );
  }

  @override
  $OfflineScoreQueueTable createAlias(String alias) {
    return $OfflineScoreQueueTable(attachedDatabase, alias);
  }
}

class OfflineScoreQueueData extends DataClass
    implements Insertable<OfflineScoreQueueData> {
  final String id;
  final String userId;
  final String gameType;
  final int difficulty;
  final bool isWon;
  final int score;
  final int durationMs;
  final String platform;
  final String metadataJson;
  final DateTime playedAt;
  const OfflineScoreQueueData({
    required this.id,
    required this.userId,
    required this.gameType,
    required this.difficulty,
    required this.isWon,
    required this.score,
    required this.durationMs,
    required this.platform,
    required this.metadataJson,
    required this.playedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['game_type'] = Variable<String>(gameType);
    map['difficulty'] = Variable<int>(difficulty);
    map['is_won'] = Variable<bool>(isWon);
    map['score'] = Variable<int>(score);
    map['duration_ms'] = Variable<int>(durationMs);
    map['platform'] = Variable<String>(platform);
    map['metadata_json'] = Variable<String>(metadataJson);
    map['played_at'] = Variable<DateTime>(playedAt);
    return map;
  }

  OfflineScoreQueueCompanion toCompanion(bool nullToAbsent) {
    return OfflineScoreQueueCompanion(
      id: Value(id),
      userId: Value(userId),
      gameType: Value(gameType),
      difficulty: Value(difficulty),
      isWon: Value(isWon),
      score: Value(score),
      durationMs: Value(durationMs),
      platform: Value(platform),
      metadataJson: Value(metadataJson),
      playedAt: Value(playedAt),
    );
  }

  factory OfflineScoreQueueData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OfflineScoreQueueData(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      gameType: serializer.fromJson<String>(json['gameType']),
      difficulty: serializer.fromJson<int>(json['difficulty']),
      isWon: serializer.fromJson<bool>(json['isWon']),
      score: serializer.fromJson<int>(json['score']),
      durationMs: serializer.fromJson<int>(json['durationMs']),
      platform: serializer.fromJson<String>(json['platform']),
      metadataJson: serializer.fromJson<String>(json['metadataJson']),
      playedAt: serializer.fromJson<DateTime>(json['playedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'gameType': serializer.toJson<String>(gameType),
      'difficulty': serializer.toJson<int>(difficulty),
      'isWon': serializer.toJson<bool>(isWon),
      'score': serializer.toJson<int>(score),
      'durationMs': serializer.toJson<int>(durationMs),
      'platform': serializer.toJson<String>(platform),
      'metadataJson': serializer.toJson<String>(metadataJson),
      'playedAt': serializer.toJson<DateTime>(playedAt),
    };
  }

  OfflineScoreQueueData copyWith({
    String? id,
    String? userId,
    String? gameType,
    int? difficulty,
    bool? isWon,
    int? score,
    int? durationMs,
    String? platform,
    String? metadataJson,
    DateTime? playedAt,
  }) => OfflineScoreQueueData(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    gameType: gameType ?? this.gameType,
    difficulty: difficulty ?? this.difficulty,
    isWon: isWon ?? this.isWon,
    score: score ?? this.score,
    durationMs: durationMs ?? this.durationMs,
    platform: platform ?? this.platform,
    metadataJson: metadataJson ?? this.metadataJson,
    playedAt: playedAt ?? this.playedAt,
  );
  OfflineScoreQueueData copyWithCompanion(OfflineScoreQueueCompanion data) {
    return OfflineScoreQueueData(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      gameType: data.gameType.present ? data.gameType.value : this.gameType,
      difficulty: data.difficulty.present
          ? data.difficulty.value
          : this.difficulty,
      isWon: data.isWon.present ? data.isWon.value : this.isWon,
      score: data.score.present ? data.score.value : this.score,
      durationMs: data.durationMs.present
          ? data.durationMs.value
          : this.durationMs,
      platform: data.platform.present ? data.platform.value : this.platform,
      metadataJson: data.metadataJson.present
          ? data.metadataJson.value
          : this.metadataJson,
      playedAt: data.playedAt.present ? data.playedAt.value : this.playedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OfflineScoreQueueData(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('gameType: $gameType, ')
          ..write('difficulty: $difficulty, ')
          ..write('isWon: $isWon, ')
          ..write('score: $score, ')
          ..write('durationMs: $durationMs, ')
          ..write('platform: $platform, ')
          ..write('metadataJson: $metadataJson, ')
          ..write('playedAt: $playedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    gameType,
    difficulty,
    isWon,
    score,
    durationMs,
    platform,
    metadataJson,
    playedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OfflineScoreQueueData &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.gameType == this.gameType &&
          other.difficulty == this.difficulty &&
          other.isWon == this.isWon &&
          other.score == this.score &&
          other.durationMs == this.durationMs &&
          other.platform == this.platform &&
          other.metadataJson == this.metadataJson &&
          other.playedAt == this.playedAt);
}

class OfflineScoreQueueCompanion
    extends UpdateCompanion<OfflineScoreQueueData> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> gameType;
  final Value<int> difficulty;
  final Value<bool> isWon;
  final Value<int> score;
  final Value<int> durationMs;
  final Value<String> platform;
  final Value<String> metadataJson;
  final Value<DateTime> playedAt;
  final Value<int> rowid;
  const OfflineScoreQueueCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.gameType = const Value.absent(),
    this.difficulty = const Value.absent(),
    this.isWon = const Value.absent(),
    this.score = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.platform = const Value.absent(),
    this.metadataJson = const Value.absent(),
    this.playedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OfflineScoreQueueCompanion.insert({
    required String id,
    required String userId,
    required String gameType,
    required int difficulty,
    required bool isWon,
    required int score,
    required int durationMs,
    required String platform,
    required String metadataJson,
    required DateTime playedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       userId = Value(userId),
       gameType = Value(gameType),
       difficulty = Value(difficulty),
       isWon = Value(isWon),
       score = Value(score),
       durationMs = Value(durationMs),
       platform = Value(platform),
       metadataJson = Value(metadataJson),
       playedAt = Value(playedAt);
  static Insertable<OfflineScoreQueueData> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? gameType,
    Expression<int>? difficulty,
    Expression<bool>? isWon,
    Expression<int>? score,
    Expression<int>? durationMs,
    Expression<String>? platform,
    Expression<String>? metadataJson,
    Expression<DateTime>? playedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (gameType != null) 'game_type': gameType,
      if (difficulty != null) 'difficulty': difficulty,
      if (isWon != null) 'is_won': isWon,
      if (score != null) 'score': score,
      if (durationMs != null) 'duration_ms': durationMs,
      if (platform != null) 'platform': platform,
      if (metadataJson != null) 'metadata_json': metadataJson,
      if (playedAt != null) 'played_at': playedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OfflineScoreQueueCompanion copyWith({
    Value<String>? id,
    Value<String>? userId,
    Value<String>? gameType,
    Value<int>? difficulty,
    Value<bool>? isWon,
    Value<int>? score,
    Value<int>? durationMs,
    Value<String>? platform,
    Value<String>? metadataJson,
    Value<DateTime>? playedAt,
    Value<int>? rowid,
  }) {
    return OfflineScoreQueueCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      gameType: gameType ?? this.gameType,
      difficulty: difficulty ?? this.difficulty,
      isWon: isWon ?? this.isWon,
      score: score ?? this.score,
      durationMs: durationMs ?? this.durationMs,
      platform: platform ?? this.platform,
      metadataJson: metadataJson ?? this.metadataJson,
      playedAt: playedAt ?? this.playedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (gameType.present) {
      map['game_type'] = Variable<String>(gameType.value);
    }
    if (difficulty.present) {
      map['difficulty'] = Variable<int>(difficulty.value);
    }
    if (isWon.present) {
      map['is_won'] = Variable<bool>(isWon.value);
    }
    if (score.present) {
      map['score'] = Variable<int>(score.value);
    }
    if (durationMs.present) {
      map['duration_ms'] = Variable<int>(durationMs.value);
    }
    if (platform.present) {
      map['platform'] = Variable<String>(platform.value);
    }
    if (metadataJson.present) {
      map['metadata_json'] = Variable<String>(metadataJson.value);
    }
    if (playedAt.present) {
      map['played_at'] = Variable<DateTime>(playedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OfflineScoreQueueCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('gameType: $gameType, ')
          ..write('difficulty: $difficulty, ')
          ..write('isWon: $isWon, ')
          ..write('score: $score, ')
          ..write('durationMs: $durationMs, ')
          ..write('platform: $platform, ')
          ..write('metadataJson: $metadataJson, ')
          ..write('playedAt: $playedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalGameRecordsTable extends LocalGameRecords
    with TableInfo<$LocalGameRecordsTable, LocalGameRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalGameRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _usernameMeta = const VerificationMeta(
    'username',
  );
  @override
  late final GeneratedColumn<String> username = GeneratedColumn<String>(
    'username',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _gameTypeMeta = const VerificationMeta(
    'gameType',
  );
  @override
  late final GeneratedColumn<String> gameType = GeneratedColumn<String>(
    'game_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _difficultyMeta = const VerificationMeta(
    'difficulty',
  );
  @override
  late final GeneratedColumn<int> difficulty = GeneratedColumn<int>(
    'difficulty',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isWonMeta = const VerificationMeta('isWon');
  @override
  late final GeneratedColumn<bool> isWon = GeneratedColumn<bool>(
    'is_won',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_won" IN (0, 1))',
    ),
  );
  static const VerificationMeta _scoreMeta = const VerificationMeta('score');
  @override
  late final GeneratedColumn<int> score = GeneratedColumn<int>(
    'score',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _durationMsMeta = const VerificationMeta(
    'durationMs',
  );
  @override
  late final GeneratedColumn<int> durationMs = GeneratedColumn<int>(
    'duration_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _platformMeta = const VerificationMeta(
    'platform',
  );
  @override
  late final GeneratedColumn<String> platform = GeneratedColumn<String>(
    'platform',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _metadataJsonMeta = const VerificationMeta(
    'metadataJson',
  );
  @override
  late final GeneratedColumn<String> metadataJson = GeneratedColumn<String>(
    'metadata_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _playedAtMeta = const VerificationMeta(
    'playedAt',
  );
  @override
  late final GeneratedColumn<DateTime> playedAt = GeneratedColumn<DateTime>(
    'played_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    username,
    gameType,
    difficulty,
    isWon,
    score,
    durationMs,
    platform,
    metadataJson,
    playedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_game_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalGameRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('username')) {
      context.handle(
        _usernameMeta,
        username.isAcceptableOrUnknown(data['username']!, _usernameMeta),
      );
    } else if (isInserting) {
      context.missing(_usernameMeta);
    }
    if (data.containsKey('game_type')) {
      context.handle(
        _gameTypeMeta,
        gameType.isAcceptableOrUnknown(data['game_type']!, _gameTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_gameTypeMeta);
    }
    if (data.containsKey('difficulty')) {
      context.handle(
        _difficultyMeta,
        difficulty.isAcceptableOrUnknown(data['difficulty']!, _difficultyMeta),
      );
    } else if (isInserting) {
      context.missing(_difficultyMeta);
    }
    if (data.containsKey('is_won')) {
      context.handle(
        _isWonMeta,
        isWon.isAcceptableOrUnknown(data['is_won']!, _isWonMeta),
      );
    } else if (isInserting) {
      context.missing(_isWonMeta);
    }
    if (data.containsKey('score')) {
      context.handle(
        _scoreMeta,
        score.isAcceptableOrUnknown(data['score']!, _scoreMeta),
      );
    } else if (isInserting) {
      context.missing(_scoreMeta);
    }
    if (data.containsKey('duration_ms')) {
      context.handle(
        _durationMsMeta,
        durationMs.isAcceptableOrUnknown(data['duration_ms']!, _durationMsMeta),
      );
    } else if (isInserting) {
      context.missing(_durationMsMeta);
    }
    if (data.containsKey('platform')) {
      context.handle(
        _platformMeta,
        platform.isAcceptableOrUnknown(data['platform']!, _platformMeta),
      );
    } else if (isInserting) {
      context.missing(_platformMeta);
    }
    if (data.containsKey('metadata_json')) {
      context.handle(
        _metadataJsonMeta,
        metadataJson.isAcceptableOrUnknown(
          data['metadata_json']!,
          _metadataJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_metadataJsonMeta);
    }
    if (data.containsKey('played_at')) {
      context.handle(
        _playedAtMeta,
        playedAt.isAcceptableOrUnknown(data['played_at']!, _playedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_playedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalGameRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalGameRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      username: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}username'],
      )!,
      gameType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}game_type'],
      )!,
      difficulty: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}difficulty'],
      )!,
      isWon: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_won'],
      )!,
      score: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}score'],
      )!,
      durationMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_ms'],
      )!,
      platform: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}platform'],
      )!,
      metadataJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}metadata_json'],
      )!,
      playedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}played_at'],
      )!,
    );
  }

  @override
  $LocalGameRecordsTable createAlias(String alias) {
    return $LocalGameRecordsTable(attachedDatabase, alias);
  }
}

class LocalGameRecord extends DataClass implements Insertable<LocalGameRecord> {
  final String id;
  final String userId;
  final String username;
  final String gameType;
  final int difficulty;
  final bool isWon;
  final int score;
  final int durationMs;
  final String platform;
  final String metadataJson;
  final DateTime playedAt;
  const LocalGameRecord({
    required this.id,
    required this.userId,
    required this.username,
    required this.gameType,
    required this.difficulty,
    required this.isWon,
    required this.score,
    required this.durationMs,
    required this.platform,
    required this.metadataJson,
    required this.playedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['username'] = Variable<String>(username);
    map['game_type'] = Variable<String>(gameType);
    map['difficulty'] = Variable<int>(difficulty);
    map['is_won'] = Variable<bool>(isWon);
    map['score'] = Variable<int>(score);
    map['duration_ms'] = Variable<int>(durationMs);
    map['platform'] = Variable<String>(platform);
    map['metadata_json'] = Variable<String>(metadataJson);
    map['played_at'] = Variable<DateTime>(playedAt);
    return map;
  }

  LocalGameRecordsCompanion toCompanion(bool nullToAbsent) {
    return LocalGameRecordsCompanion(
      id: Value(id),
      userId: Value(userId),
      username: Value(username),
      gameType: Value(gameType),
      difficulty: Value(difficulty),
      isWon: Value(isWon),
      score: Value(score),
      durationMs: Value(durationMs),
      platform: Value(platform),
      metadataJson: Value(metadataJson),
      playedAt: Value(playedAt),
    );
  }

  factory LocalGameRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalGameRecord(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      username: serializer.fromJson<String>(json['username']),
      gameType: serializer.fromJson<String>(json['gameType']),
      difficulty: serializer.fromJson<int>(json['difficulty']),
      isWon: serializer.fromJson<bool>(json['isWon']),
      score: serializer.fromJson<int>(json['score']),
      durationMs: serializer.fromJson<int>(json['durationMs']),
      platform: serializer.fromJson<String>(json['platform']),
      metadataJson: serializer.fromJson<String>(json['metadataJson']),
      playedAt: serializer.fromJson<DateTime>(json['playedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'username': serializer.toJson<String>(username),
      'gameType': serializer.toJson<String>(gameType),
      'difficulty': serializer.toJson<int>(difficulty),
      'isWon': serializer.toJson<bool>(isWon),
      'score': serializer.toJson<int>(score),
      'durationMs': serializer.toJson<int>(durationMs),
      'platform': serializer.toJson<String>(platform),
      'metadataJson': serializer.toJson<String>(metadataJson),
      'playedAt': serializer.toJson<DateTime>(playedAt),
    };
  }

  LocalGameRecord copyWith({
    String? id,
    String? userId,
    String? username,
    String? gameType,
    int? difficulty,
    bool? isWon,
    int? score,
    int? durationMs,
    String? platform,
    String? metadataJson,
    DateTime? playedAt,
  }) => LocalGameRecord(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    username: username ?? this.username,
    gameType: gameType ?? this.gameType,
    difficulty: difficulty ?? this.difficulty,
    isWon: isWon ?? this.isWon,
    score: score ?? this.score,
    durationMs: durationMs ?? this.durationMs,
    platform: platform ?? this.platform,
    metadataJson: metadataJson ?? this.metadataJson,
    playedAt: playedAt ?? this.playedAt,
  );
  LocalGameRecord copyWithCompanion(LocalGameRecordsCompanion data) {
    return LocalGameRecord(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      username: data.username.present ? data.username.value : this.username,
      gameType: data.gameType.present ? data.gameType.value : this.gameType,
      difficulty: data.difficulty.present
          ? data.difficulty.value
          : this.difficulty,
      isWon: data.isWon.present ? data.isWon.value : this.isWon,
      score: data.score.present ? data.score.value : this.score,
      durationMs: data.durationMs.present
          ? data.durationMs.value
          : this.durationMs,
      platform: data.platform.present ? data.platform.value : this.platform,
      metadataJson: data.metadataJson.present
          ? data.metadataJson.value
          : this.metadataJson,
      playedAt: data.playedAt.present ? data.playedAt.value : this.playedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalGameRecord(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('username: $username, ')
          ..write('gameType: $gameType, ')
          ..write('difficulty: $difficulty, ')
          ..write('isWon: $isWon, ')
          ..write('score: $score, ')
          ..write('durationMs: $durationMs, ')
          ..write('platform: $platform, ')
          ..write('metadataJson: $metadataJson, ')
          ..write('playedAt: $playedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    username,
    gameType,
    difficulty,
    isWon,
    score,
    durationMs,
    platform,
    metadataJson,
    playedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalGameRecord &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.username == this.username &&
          other.gameType == this.gameType &&
          other.difficulty == this.difficulty &&
          other.isWon == this.isWon &&
          other.score == this.score &&
          other.durationMs == this.durationMs &&
          other.platform == this.platform &&
          other.metadataJson == this.metadataJson &&
          other.playedAt == this.playedAt);
}

class LocalGameRecordsCompanion extends UpdateCompanion<LocalGameRecord> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> username;
  final Value<String> gameType;
  final Value<int> difficulty;
  final Value<bool> isWon;
  final Value<int> score;
  final Value<int> durationMs;
  final Value<String> platform;
  final Value<String> metadataJson;
  final Value<DateTime> playedAt;
  final Value<int> rowid;
  const LocalGameRecordsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.username = const Value.absent(),
    this.gameType = const Value.absent(),
    this.difficulty = const Value.absent(),
    this.isWon = const Value.absent(),
    this.score = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.platform = const Value.absent(),
    this.metadataJson = const Value.absent(),
    this.playedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalGameRecordsCompanion.insert({
    required String id,
    required String userId,
    required String username,
    required String gameType,
    required int difficulty,
    required bool isWon,
    required int score,
    required int durationMs,
    required String platform,
    required String metadataJson,
    required DateTime playedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       userId = Value(userId),
       username = Value(username),
       gameType = Value(gameType),
       difficulty = Value(difficulty),
       isWon = Value(isWon),
       score = Value(score),
       durationMs = Value(durationMs),
       platform = Value(platform),
       metadataJson = Value(metadataJson),
       playedAt = Value(playedAt);
  static Insertable<LocalGameRecord> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? username,
    Expression<String>? gameType,
    Expression<int>? difficulty,
    Expression<bool>? isWon,
    Expression<int>? score,
    Expression<int>? durationMs,
    Expression<String>? platform,
    Expression<String>? metadataJson,
    Expression<DateTime>? playedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (username != null) 'username': username,
      if (gameType != null) 'game_type': gameType,
      if (difficulty != null) 'difficulty': difficulty,
      if (isWon != null) 'is_won': isWon,
      if (score != null) 'score': score,
      if (durationMs != null) 'duration_ms': durationMs,
      if (platform != null) 'platform': platform,
      if (metadataJson != null) 'metadata_json': metadataJson,
      if (playedAt != null) 'played_at': playedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalGameRecordsCompanion copyWith({
    Value<String>? id,
    Value<String>? userId,
    Value<String>? username,
    Value<String>? gameType,
    Value<int>? difficulty,
    Value<bool>? isWon,
    Value<int>? score,
    Value<int>? durationMs,
    Value<String>? platform,
    Value<String>? metadataJson,
    Value<DateTime>? playedAt,
    Value<int>? rowid,
  }) {
    return LocalGameRecordsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      gameType: gameType ?? this.gameType,
      difficulty: difficulty ?? this.difficulty,
      isWon: isWon ?? this.isWon,
      score: score ?? this.score,
      durationMs: durationMs ?? this.durationMs,
      platform: platform ?? this.platform,
      metadataJson: metadataJson ?? this.metadataJson,
      playedAt: playedAt ?? this.playedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (username.present) {
      map['username'] = Variable<String>(username.value);
    }
    if (gameType.present) {
      map['game_type'] = Variable<String>(gameType.value);
    }
    if (difficulty.present) {
      map['difficulty'] = Variable<int>(difficulty.value);
    }
    if (isWon.present) {
      map['is_won'] = Variable<bool>(isWon.value);
    }
    if (score.present) {
      map['score'] = Variable<int>(score.value);
    }
    if (durationMs.present) {
      map['duration_ms'] = Variable<int>(durationMs.value);
    }
    if (platform.present) {
      map['platform'] = Variable<String>(platform.value);
    }
    if (metadataJson.present) {
      map['metadata_json'] = Variable<String>(metadataJson.value);
    }
    if (playedAt.present) {
      map['played_at'] = Variable<DateTime>(playedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalGameRecordsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('username: $username, ')
          ..write('gameType: $gameType, ')
          ..write('difficulty: $difficulty, ')
          ..write('isWon: $isWon, ')
          ..write('score: $score, ')
          ..write('durationMs: $durationMs, ')
          ..write('platform: $platform, ')
          ..write('metadataJson: $metadataJson, ')
          ..write('playedAt: $playedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$ZetzyDatabase extends GeneratedDatabase {
  _$ZetzyDatabase(QueryExecutor e) : super(e);
  $ZetzyDatabaseManager get managers => $ZetzyDatabaseManager(this);
  late final $AutoSaveSlotsTable autoSaveSlots = $AutoSaveSlotsTable(this);
  late final $OfflineScoreQueueTable offlineScoreQueue =
      $OfflineScoreQueueTable(this);
  late final $LocalGameRecordsTable localGameRecords = $LocalGameRecordsTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    autoSaveSlots,
    offlineScoreQueue,
    localGameRecords,
  ];
}

typedef $$AutoSaveSlotsTableCreateCompanionBuilder =
    AutoSaveSlotsCompanion Function({
      required String gameType,
      required int difficulty,
      required int elapsedMs,
      required String stateJson,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$AutoSaveSlotsTableUpdateCompanionBuilder =
    AutoSaveSlotsCompanion Function({
      Value<String> gameType,
      Value<int> difficulty,
      Value<int> elapsedMs,
      Value<String> stateJson,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$AutoSaveSlotsTableFilterComposer
    extends Composer<_$ZetzyDatabase, $AutoSaveSlotsTable> {
  $$AutoSaveSlotsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get gameType => $composableBuilder(
    column: $table.gameType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get elapsedMs => $composableBuilder(
    column: $table.elapsedMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get stateJson => $composableBuilder(
    column: $table.stateJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AutoSaveSlotsTableOrderingComposer
    extends Composer<_$ZetzyDatabase, $AutoSaveSlotsTable> {
  $$AutoSaveSlotsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get gameType => $composableBuilder(
    column: $table.gameType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get elapsedMs => $composableBuilder(
    column: $table.elapsedMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get stateJson => $composableBuilder(
    column: $table.stateJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AutoSaveSlotsTableAnnotationComposer
    extends Composer<_$ZetzyDatabase, $AutoSaveSlotsTable> {
  $$AutoSaveSlotsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get gameType =>
      $composableBuilder(column: $table.gameType, builder: (column) => column);

  GeneratedColumn<int> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => column,
  );

  GeneratedColumn<int> get elapsedMs =>
      $composableBuilder(column: $table.elapsedMs, builder: (column) => column);

  GeneratedColumn<String> get stateJson =>
      $composableBuilder(column: $table.stateJson, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$AutoSaveSlotsTableTableManager
    extends
        RootTableManager<
          _$ZetzyDatabase,
          $AutoSaveSlotsTable,
          AutoSaveSlot,
          $$AutoSaveSlotsTableFilterComposer,
          $$AutoSaveSlotsTableOrderingComposer,
          $$AutoSaveSlotsTableAnnotationComposer,
          $$AutoSaveSlotsTableCreateCompanionBuilder,
          $$AutoSaveSlotsTableUpdateCompanionBuilder,
          (
            AutoSaveSlot,
            BaseReferences<_$ZetzyDatabase, $AutoSaveSlotsTable, AutoSaveSlot>,
          ),
          AutoSaveSlot,
          PrefetchHooks Function()
        > {
  $$AutoSaveSlotsTableTableManager(
    _$ZetzyDatabase db,
    $AutoSaveSlotsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AutoSaveSlotsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AutoSaveSlotsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AutoSaveSlotsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> gameType = const Value.absent(),
                Value<int> difficulty = const Value.absent(),
                Value<int> elapsedMs = const Value.absent(),
                Value<String> stateJson = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AutoSaveSlotsCompanion(
                gameType: gameType,
                difficulty: difficulty,
                elapsedMs: elapsedMs,
                stateJson: stateJson,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String gameType,
                required int difficulty,
                required int elapsedMs,
                required String stateJson,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => AutoSaveSlotsCompanion.insert(
                gameType: gameType,
                difficulty: difficulty,
                elapsedMs: elapsedMs,
                stateJson: stateJson,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AutoSaveSlotsTable, AutoSaveSlot>(table),
                  BaseReferences<
                    _$ZetzyDatabase,
                    $AutoSaveSlotsTable,
                    AutoSaveSlot
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AutoSaveSlotsTableProcessedTableManager =
    ProcessedTableManager<
      _$ZetzyDatabase,
      $AutoSaveSlotsTable,
      AutoSaveSlot,
      $$AutoSaveSlotsTableFilterComposer,
      $$AutoSaveSlotsTableOrderingComposer,
      $$AutoSaveSlotsTableAnnotationComposer,
      $$AutoSaveSlotsTableCreateCompanionBuilder,
      $$AutoSaveSlotsTableUpdateCompanionBuilder,
      (
        AutoSaveSlot,
        BaseReferences<_$ZetzyDatabase, $AutoSaveSlotsTable, AutoSaveSlot>,
      ),
      AutoSaveSlot,
      PrefetchHooks Function()
    >;
typedef $$OfflineScoreQueueTableCreateCompanionBuilder =
    OfflineScoreQueueCompanion Function({
      required String id,
      required String userId,
      required String gameType,
      required int difficulty,
      required bool isWon,
      required int score,
      required int durationMs,
      required String platform,
      required String metadataJson,
      required DateTime playedAt,
      Value<int> rowid,
    });
typedef $$OfflineScoreQueueTableUpdateCompanionBuilder =
    OfflineScoreQueueCompanion Function({
      Value<String> id,
      Value<String> userId,
      Value<String> gameType,
      Value<int> difficulty,
      Value<bool> isWon,
      Value<int> score,
      Value<int> durationMs,
      Value<String> platform,
      Value<String> metadataJson,
      Value<DateTime> playedAt,
      Value<int> rowid,
    });

class $$OfflineScoreQueueTableFilterComposer
    extends Composer<_$ZetzyDatabase, $OfflineScoreQueueTable> {
  $$OfflineScoreQueueTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get gameType => $composableBuilder(
    column: $table.gameType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isWon => $composableBuilder(
    column: $table.isWon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get platform => $composableBuilder(
    column: $table.platform,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get metadataJson => $composableBuilder(
    column: $table.metadataJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get playedAt => $composableBuilder(
    column: $table.playedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OfflineScoreQueueTableOrderingComposer
    extends Composer<_$ZetzyDatabase, $OfflineScoreQueueTable> {
  $$OfflineScoreQueueTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get gameType => $composableBuilder(
    column: $table.gameType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isWon => $composableBuilder(
    column: $table.isWon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get platform => $composableBuilder(
    column: $table.platform,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get metadataJson => $composableBuilder(
    column: $table.metadataJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get playedAt => $composableBuilder(
    column: $table.playedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OfflineScoreQueueTableAnnotationComposer
    extends Composer<_$ZetzyDatabase, $OfflineScoreQueueTable> {
  $$OfflineScoreQueueTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get gameType =>
      $composableBuilder(column: $table.gameType, builder: (column) => column);

  GeneratedColumn<int> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isWon =>
      $composableBuilder(column: $table.isWon, builder: (column) => column);

  GeneratedColumn<int> get score =>
      $composableBuilder(column: $table.score, builder: (column) => column);

  GeneratedColumn<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => column,
  );

  GeneratedColumn<String> get platform =>
      $composableBuilder(column: $table.platform, builder: (column) => column);

  GeneratedColumn<String> get metadataJson => $composableBuilder(
    column: $table.metadataJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get playedAt =>
      $composableBuilder(column: $table.playedAt, builder: (column) => column);
}

class $$OfflineScoreQueueTableTableManager
    extends
        RootTableManager<
          _$ZetzyDatabase,
          $OfflineScoreQueueTable,
          OfflineScoreQueueData,
          $$OfflineScoreQueueTableFilterComposer,
          $$OfflineScoreQueueTableOrderingComposer,
          $$OfflineScoreQueueTableAnnotationComposer,
          $$OfflineScoreQueueTableCreateCompanionBuilder,
          $$OfflineScoreQueueTableUpdateCompanionBuilder,
          (
            OfflineScoreQueueData,
            BaseReferences<
              _$ZetzyDatabase,
              $OfflineScoreQueueTable,
              OfflineScoreQueueData
            >,
          ),
          OfflineScoreQueueData,
          PrefetchHooks Function()
        > {
  $$OfflineScoreQueueTableTableManager(
    _$ZetzyDatabase db,
    $OfflineScoreQueueTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OfflineScoreQueueTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OfflineScoreQueueTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OfflineScoreQueueTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> gameType = const Value.absent(),
                Value<int> difficulty = const Value.absent(),
                Value<bool> isWon = const Value.absent(),
                Value<int> score = const Value.absent(),
                Value<int> durationMs = const Value.absent(),
                Value<String> platform = const Value.absent(),
                Value<String> metadataJson = const Value.absent(),
                Value<DateTime> playedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OfflineScoreQueueCompanion(
                id: id,
                userId: userId,
                gameType: gameType,
                difficulty: difficulty,
                isWon: isWon,
                score: score,
                durationMs: durationMs,
                platform: platform,
                metadataJson: metadataJson,
                playedAt: playedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String userId,
                required String gameType,
                required int difficulty,
                required bool isWon,
                required int score,
                required int durationMs,
                required String platform,
                required String metadataJson,
                required DateTime playedAt,
                Value<int> rowid = const Value.absent(),
              }) => OfflineScoreQueueCompanion.insert(
                id: id,
                userId: userId,
                gameType: gameType,
                difficulty: difficulty,
                isWon: isWon,
                score: score,
                durationMs: durationMs,
                platform: platform,
                metadataJson: metadataJson,
                playedAt: playedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$OfflineScoreQueueTable, OfflineScoreQueueData>(
                    table,
                  ),
                  BaseReferences<
                    _$ZetzyDatabase,
                    $OfflineScoreQueueTable,
                    OfflineScoreQueueData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OfflineScoreQueueTableProcessedTableManager =
    ProcessedTableManager<
      _$ZetzyDatabase,
      $OfflineScoreQueueTable,
      OfflineScoreQueueData,
      $$OfflineScoreQueueTableFilterComposer,
      $$OfflineScoreQueueTableOrderingComposer,
      $$OfflineScoreQueueTableAnnotationComposer,
      $$OfflineScoreQueueTableCreateCompanionBuilder,
      $$OfflineScoreQueueTableUpdateCompanionBuilder,
      (
        OfflineScoreQueueData,
        BaseReferences<
          _$ZetzyDatabase,
          $OfflineScoreQueueTable,
          OfflineScoreQueueData
        >,
      ),
      OfflineScoreQueueData,
      PrefetchHooks Function()
    >;
typedef $$LocalGameRecordsTableCreateCompanionBuilder =
    LocalGameRecordsCompanion Function({
      required String id,
      required String userId,
      required String username,
      required String gameType,
      required int difficulty,
      required bool isWon,
      required int score,
      required int durationMs,
      required String platform,
      required String metadataJson,
      required DateTime playedAt,
      Value<int> rowid,
    });
typedef $$LocalGameRecordsTableUpdateCompanionBuilder =
    LocalGameRecordsCompanion Function({
      Value<String> id,
      Value<String> userId,
      Value<String> username,
      Value<String> gameType,
      Value<int> difficulty,
      Value<bool> isWon,
      Value<int> score,
      Value<int> durationMs,
      Value<String> platform,
      Value<String> metadataJson,
      Value<DateTime> playedAt,
      Value<int> rowid,
    });

class $$LocalGameRecordsTableFilterComposer
    extends Composer<_$ZetzyDatabase, $LocalGameRecordsTable> {
  $$LocalGameRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get username => $composableBuilder(
    column: $table.username,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get gameType => $composableBuilder(
    column: $table.gameType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isWon => $composableBuilder(
    column: $table.isWon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get platform => $composableBuilder(
    column: $table.platform,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get metadataJson => $composableBuilder(
    column: $table.metadataJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get playedAt => $composableBuilder(
    column: $table.playedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalGameRecordsTableOrderingComposer
    extends Composer<_$ZetzyDatabase, $LocalGameRecordsTable> {
  $$LocalGameRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get username => $composableBuilder(
    column: $table.username,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get gameType => $composableBuilder(
    column: $table.gameType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isWon => $composableBuilder(
    column: $table.isWon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get platform => $composableBuilder(
    column: $table.platform,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get metadataJson => $composableBuilder(
    column: $table.metadataJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get playedAt => $composableBuilder(
    column: $table.playedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalGameRecordsTableAnnotationComposer
    extends Composer<_$ZetzyDatabase, $LocalGameRecordsTable> {
  $$LocalGameRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get username =>
      $composableBuilder(column: $table.username, builder: (column) => column);

  GeneratedColumn<String> get gameType =>
      $composableBuilder(column: $table.gameType, builder: (column) => column);

  GeneratedColumn<int> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isWon =>
      $composableBuilder(column: $table.isWon, builder: (column) => column);

  GeneratedColumn<int> get score =>
      $composableBuilder(column: $table.score, builder: (column) => column);

  GeneratedColumn<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => column,
  );

  GeneratedColumn<String> get platform =>
      $composableBuilder(column: $table.platform, builder: (column) => column);

  GeneratedColumn<String> get metadataJson => $composableBuilder(
    column: $table.metadataJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get playedAt =>
      $composableBuilder(column: $table.playedAt, builder: (column) => column);
}

class $$LocalGameRecordsTableTableManager
    extends
        RootTableManager<
          _$ZetzyDatabase,
          $LocalGameRecordsTable,
          LocalGameRecord,
          $$LocalGameRecordsTableFilterComposer,
          $$LocalGameRecordsTableOrderingComposer,
          $$LocalGameRecordsTableAnnotationComposer,
          $$LocalGameRecordsTableCreateCompanionBuilder,
          $$LocalGameRecordsTableUpdateCompanionBuilder,
          (
            LocalGameRecord,
            BaseReferences<
              _$ZetzyDatabase,
              $LocalGameRecordsTable,
              LocalGameRecord
            >,
          ),
          LocalGameRecord,
          PrefetchHooks Function()
        > {
  $$LocalGameRecordsTableTableManager(
    _$ZetzyDatabase db,
    $LocalGameRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalGameRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalGameRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalGameRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> username = const Value.absent(),
                Value<String> gameType = const Value.absent(),
                Value<int> difficulty = const Value.absent(),
                Value<bool> isWon = const Value.absent(),
                Value<int> score = const Value.absent(),
                Value<int> durationMs = const Value.absent(),
                Value<String> platform = const Value.absent(),
                Value<String> metadataJson = const Value.absent(),
                Value<DateTime> playedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalGameRecordsCompanion(
                id: id,
                userId: userId,
                username: username,
                gameType: gameType,
                difficulty: difficulty,
                isWon: isWon,
                score: score,
                durationMs: durationMs,
                platform: platform,
                metadataJson: metadataJson,
                playedAt: playedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String userId,
                required String username,
                required String gameType,
                required int difficulty,
                required bool isWon,
                required int score,
                required int durationMs,
                required String platform,
                required String metadataJson,
                required DateTime playedAt,
                Value<int> rowid = const Value.absent(),
              }) => LocalGameRecordsCompanion.insert(
                id: id,
                userId: userId,
                username: username,
                gameType: gameType,
                difficulty: difficulty,
                isWon: isWon,
                score: score,
                durationMs: durationMs,
                platform: platform,
                metadataJson: metadataJson,
                playedAt: playedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LocalGameRecordsTable, LocalGameRecord>(table),
                  BaseReferences<
                    _$ZetzyDatabase,
                    $LocalGameRecordsTable,
                    LocalGameRecord
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalGameRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$ZetzyDatabase,
      $LocalGameRecordsTable,
      LocalGameRecord,
      $$LocalGameRecordsTableFilterComposer,
      $$LocalGameRecordsTableOrderingComposer,
      $$LocalGameRecordsTableAnnotationComposer,
      $$LocalGameRecordsTableCreateCompanionBuilder,
      $$LocalGameRecordsTableUpdateCompanionBuilder,
      (
        LocalGameRecord,
        BaseReferences<
          _$ZetzyDatabase,
          $LocalGameRecordsTable,
          LocalGameRecord
        >,
      ),
      LocalGameRecord,
      PrefetchHooks Function()
    >;

class $ZetzyDatabaseManager {
  final _$ZetzyDatabase _db;
  $ZetzyDatabaseManager(this._db);
  $$AutoSaveSlotsTableTableManager get autoSaveSlots =>
      $$AutoSaveSlotsTableTableManager(_db, _db.autoSaveSlots);
  $$OfflineScoreQueueTableTableManager get offlineScoreQueue =>
      $$OfflineScoreQueueTableTableManager(_db, _db.offlineScoreQueue);
  $$LocalGameRecordsTableTableManager get localGameRecords =>
      $$LocalGameRecordsTableTableManager(_db, _db.localGameRecords);
}
