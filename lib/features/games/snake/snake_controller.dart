import 'dart:async';
import 'dart:collection';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:zetzy/core/constants/app_constants.dart';
import 'package:zetzy/core/services/audio_service.dart';
import 'package:zetzy/core/services/haptic_service.dart';
import 'package:zetzy/data/models/auto_save_slot.dart';

enum SnakeDirection {
  up(0, -1),
  down(0, 1),
  left(-1, 0),
  right(1, 0);

  const SnakeDirection(this.dx, this.dy);
  final int dx;
  final int dy;

  bool isOpposite(SnakeDirection other) => dx == -other.dx && dy == -other.dy;

  SnakeDirection turnLeft() => switch (this) {
    SnakeDirection.up => SnakeDirection.left,
    SnakeDirection.left => SnakeDirection.down,
    SnakeDirection.down => SnakeDirection.right,
    SnakeDirection.right => SnakeDirection.up,
  };

  SnakeDirection turnRight() => switch (this) {
    SnakeDirection.up => SnakeDirection.right,
    SnakeDirection.right => SnakeDirection.down,
    SnakeDirection.down => SnakeDirection.left,
    SnakeDirection.left => SnakeDirection.up,
  };
}

@immutable
class GridPoint {
  const GridPoint(this.x, this.y);
  final int x;
  final int y;

  Map<String, int> toJson() => {'x': x, 'y': y};
  factory GridPoint.fromJson(Map<String, dynamic> j) =>
      GridPoint((j['x'] as num).toInt(), (j['y'] as num).toInt());

  @override
  bool operator ==(Object other) =>
      other is GridPoint && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);
}

enum SnakeSpecialKind { golden, scissors, poison }

enum SnakeDeathReason { wall, obstacle, selfCollision, starvation }

@immutable
class SnakeSpecialItem {
  const SnakeSpecialItem({
    required this.point,
    required this.kind,
    required this.remainingMs,
    required this.totalMs,
  });

  final GridPoint point;
  final SnakeSpecialKind kind;
  final int remainingMs;
  final int totalMs;

  SnakeSpecialItem copyWith({int? remainingMs}) => SnakeSpecialItem(
    point: point,
    kind: kind,
    remainingMs: remainingMs ?? this.remainingMs,
    totalMs: totalMs,
  );
}

@immutable
class SnakeGameState {
  const SnakeGameState({
    required this.difficulty,
    required this.isPractice,
    required this.gridSize,
    required this.snake,
    required this.direction,
    required this.apple,
    required this.obstacles,
    required this.warningObstacles,
    required this.specialItem,
    required this.score,
    required this.foodsEaten,
    required this.elapsedMs,
    required this.tickMs,
    required this.starvationMaxMs,
    required this.starvationRemainingMs,
    required this.poisonRemainingMs,
    required this.obstacleWarningRemainingMs,
    required this.isPaused,
    required this.isGameOver,
    required this.isWon,
    this.canPracticeUndo = false,
    this.deathReason,
    this.crashPoint,
  });

  final DifficultyLevel difficulty;
  final bool isPractice;
  final int gridSize;
  final List<GridPoint> snake;
  final SnakeDirection direction;
  final GridPoint apple;
  final Set<GridPoint> obstacles;
  final Set<GridPoint> warningObstacles;
  final SnakeSpecialItem? specialItem;
  final int score;
  final int foodsEaten;
  final int elapsedMs;
  final int tickMs;
  final int starvationMaxMs;
  final int starvationRemainingMs;
  final int poisonRemainingMs;
  final int obstacleWarningRemainingMs;
  final bool isPaused;
  final bool isGameOver;
  final bool isWon;
  final bool canPracticeUndo;
  final SnakeDeathReason? deathReason;
  final GridPoint? crashPoint;

  bool get wrapWalls => difficulty.level == 1;
  bool get hasStarvation => difficulty.level >= 6;
  bool get hasDynamicObstacles => difficulty.level >= 6;
  bool get isPoisoned => poisonRemainingMs > 0;
  double get starvationProgress => starvationMaxMs == 0
      ? 1.0
      : (starvationRemainingMs / starvationMaxMs).clamp(0.0, 1.0);

  SnakeGameState copyWith({
    List<GridPoint>? snake,
    SnakeDirection? direction,
    GridPoint? apple,
    Set<GridPoint>? obstacles,
    Set<GridPoint>? warningObstacles,
    SnakeSpecialItem? specialItem,
    bool clearSpecial = false,
    int? score,
    int? foodsEaten,
    int? elapsedMs,
    int? tickMs,
    int? starvationRemainingMs,
    int? poisonRemainingMs,
    int? obstacleWarningRemainingMs,
    bool? isPaused,
    bool? isGameOver,
    bool? isWon,
    bool? canPracticeUndo,
    SnakeDeathReason? deathReason,
    bool clearDeathReason = false,
    GridPoint? crashPoint,
    bool clearCrashPoint = false,
  }) {
    return SnakeGameState(
      difficulty: difficulty,
      isPractice: isPractice,
      gridSize: gridSize,
      snake: snake ?? this.snake,
      direction: direction ?? this.direction,
      apple: apple ?? this.apple,
      obstacles: obstacles ?? this.obstacles,
      warningObstacles: warningObstacles ?? this.warningObstacles,
      specialItem: clearSpecial ? null : (specialItem ?? this.specialItem),
      score: score ?? this.score,
      foodsEaten: foodsEaten ?? this.foodsEaten,
      elapsedMs: elapsedMs ?? this.elapsedMs,
      tickMs: tickMs ?? this.tickMs,
      starvationMaxMs: starvationMaxMs,
      starvationRemainingMs:
          starvationRemainingMs ?? this.starvationRemainingMs,
      poisonRemainingMs: poisonRemainingMs ?? this.poisonRemainingMs,
      obstacleWarningRemainingMs:
          obstacleWarningRemainingMs ?? this.obstacleWarningRemainingMs,
      isPaused: isPaused ?? this.isPaused,
      isGameOver: isGameOver ?? this.isGameOver,
      isWon: isWon ?? this.isWon,
      canPracticeUndo: canPracticeUndo ?? this.canPracticeUndo,
      deathReason:
          clearDeathReason ? null : (deathReason ?? this.deathReason),
      crashPoint: clearCrashPoint ? null : (crashPoint ?? this.crashPoint),
    );
  }
}

class _SnakeSnapshot {
  const _SnakeSnapshot({
    required this.snake,
    required this.direction,
    required this.apple,
    required this.obstacles,
    required this.warningObstacles,
    required this.specialItem,
    required this.score,
    required this.foodsEaten,
    required this.elapsedMs,
    required this.tickMs,
    required this.starvationRemainingMs,
    required this.poisonRemainingMs,
    required this.obstacleWarningRemainingMs,
  });

  final List<GridPoint> snake;
  final SnakeDirection direction;
  final GridPoint apple;
  final Set<GridPoint> obstacles;
  final Set<GridPoint> warningObstacles;
  final SnakeSpecialItem? specialItem;
  final int score;
  final int foodsEaten;
  final int elapsedMs;
  final int tickMs;
  final int starvationRemainingMs;
  final int poisonRemainingMs;
  final int obstacleWarningRemainingMs;
}

class SnakeController extends ChangeNotifier {
  SnakeController({
    required this._audio,
    required this._haptics,
    required this.onFinished,
    required this.onAutoSave,
  });

  final AudioService _audio;
  final HapticService _haptics;
  final void Function(SnakeGameState finalState) onFinished;
  final void Function(AutoSaveSlot slot) onAutoSave;

  final Random _rng = Random();
  final Queue<SnakeDirection> _inputQueue = Queue<SnakeDirection>();
  final List<_SnakeSnapshot> _practiceHistory = [];
  Timer? _frameTimer;
  int _moveAccumulatorMs = 0;
  int _specialSpawnCooldownMs = 6000;
  static const int _frameStepMs = 20;

  late SnakeGameState _state;
  SnakeGameState get state => _state;

  static int gridSizeFor(DifficultyLevel diff) => switch (diff.level) {
    1 => 15,
    2 => 17,
    3 => 19,
    4 => 21,
    5 => 23,
    _ => 25,
  };

  static int baseTickFor(DifficultyLevel diff) => switch (diff.level) {
    1 => 190,
    2 => 170,
    3 => 155,
    4 => 140,
    5 => 125,
    6 => 115,
    _ => 102,
  };

  static int starvationFor(DifficultyLevel diff) => switch (diff.level) {
    6 => 12000,
    7 => 10000,
    _ => 0,
  };

  void startNew({
    required DifficultyLevel difficulty,
    required bool isPractice,
  }) {
    _stopTimers();
    _inputQueue.clear();
    _practiceHistory.clear();
    _moveAccumulatorMs = 0;
    _specialSpawnCooldownMs = 5500;

    final size = gridSizeFor(difficulty);
    final mid = size ~/ 2;
    final initialSnake = [
      GridPoint(mid, mid),
      GridPoint(mid - 1, mid),
      GridPoint(mid - 2, mid),
    ];

    final obstacles = _buildStaticMaze(size, difficulty.level, initialSnake);
    final apple = _randomFreeCell(size, initialSnake.toSet(), obstacles);
    final starvMax = starvationFor(difficulty);

    _state = SnakeGameState(
      difficulty: difficulty,
      isPractice: isPractice,
      gridSize: size,
      snake: initialSnake,
      direction: SnakeDirection.right,
      apple: apple,
      obstacles: obstacles,
      warningObstacles: const {},
      specialItem: null,
      score: 0,
      foodsEaten: 0,
      elapsedMs: 0,
      tickMs: baseTickFor(difficulty),
      starvationMaxMs: starvMax,
      starvationRemainingMs: starvMax,
      poisonRemainingMs: 0,
      obstacleWarningRemainingMs: 0,
      isPaused: false,
      isGameOver: false,
      isWon: false,
    );
    notifyListeners();
    _startTimers();
  }

  void restoreFromSlot(AutoSaveSlot slot) {
    _stopTimers();
    _inputQueue.clear();
    _practiceHistory.clear();
    _moveAccumulatorMs = 0;
    final s = slot.stateJson;
    final diff = DifficultyLevel.fromLevel(slot.difficulty);
    final size = (s['gridSize'] as num?)?.toInt() ?? gridSizeFor(diff);
    final snake = ((s['snake'] as List?) ?? [])
        .map((e) => GridPoint.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    final obstacles = ((s['obstacles'] as List?) ?? [])
        .map((e) => GridPoint.fromJson(Map<String, dynamic>.from(e as Map)))
        .toSet();
    final appleMap = s['apple'] as Map?;
    final apple = appleMap != null
        ? GridPoint.fromJson(Map<String, dynamic>.from(appleMap))
        : _randomFreeCell(size, snake.toSet(), obstacles);
    final starvMax = starvationFor(diff);

    _state = SnakeGameState(
      difficulty: diff,
      isPractice: s['isPractice'] == true,
      gridSize: size,
      snake: snake.isEmpty
          ? [GridPoint(size ~/ 2, size ~/ 2)]
          : snake,
      direction: SnakeDirection.values.firstWhere(
        (d) => d.name == s['direction'],
        orElse: () => SnakeDirection.right,
      ),
      apple: apple,
      obstacles: obstacles,
      warningObstacles: const {},
      specialItem: null,
      score: (s['score'] as num?)?.toInt() ?? 0,
      foodsEaten: (s['foodsEaten'] as num?)?.toInt() ?? 0,
      elapsedMs: slot.elapsedMs,
      tickMs: (s['tickMs'] as num?)?.toInt() ?? baseTickFor(diff),
      starvationMaxMs: starvMax,
      starvationRemainingMs:
          (s['starvationRemainingMs'] as num?)?.toInt() ?? starvMax,
      poisonRemainingMs: 0,
      obstacleWarningRemainingMs: 0,
      isPaused: true,
      isGameOver: false,
      isWon: false,
    );
    notifyListeners();
  }

  AutoSaveSlot exportSlot() {
    return AutoSaveSlot(
      gameType: GameType.snake,
      difficulty: _state.difficulty.level,
      elapsedMs: _state.elapsedMs,
      updatedAt: DateTime.now().toUtc(),
      stateJson: {
        'isPractice': _state.isPractice,
        'gridSize': _state.gridSize,
        'snake': _state.snake.map((p) => p.toJson()).toList(),
        'direction': _state.direction.name,
        'apple': _state.apple.toJson(),
        'obstacles': _state.obstacles.map((p) => p.toJson()).toList(),
        'score': _state.score,
        'foodsEaten': _state.foodsEaten,
        'tickMs': _state.tickMs,
        'starvationRemainingMs': _state.starvationRemainingMs,
      },
    );
  }

  /// 2-Step Input Buffer Queue (PRD 67A).
  void queueDirection(SnakeDirection rawDir) {
    if (_state.isPaused || _state.isGameOver) return;
    final effective = _state.isPoisoned
        ? switch (rawDir) {
            SnakeDirection.up => SnakeDirection.down,
            SnakeDirection.down => SnakeDirection.up,
            SnakeDirection.left => SnakeDirection.right,
            SnakeDirection.right => SnakeDirection.left,
          }
        : rawDir;

    final lastScheduled = _inputQueue.isNotEmpty
        ? _inputQueue.last
        : _state.direction;
    if (effective == lastScheduled || effective.isOpposite(lastScheduled)) {
      return;
    }
    if (_inputQueue.length < 2) {
      _inputQueue.add(effective);
    }
  }

  void turnRelative(bool right) {
    final base = _inputQueue.isNotEmpty ? _inputQueue.last : _state.direction;
    final raw = right ? base.turnRight() : base.turnLeft();
    queueDirection(raw);
  }

  void pause({bool save = true}) {
    if (_state.isGameOver || _state.isPaused) return;
    _stopTimers();
    _state = _state.copyWith(isPaused: true);
    if (save) {
      onAutoSave(exportSlot());
    }
    notifyListeners();
  }

  void resume() {
    if (_state.isGameOver || !_state.isPaused) return;
    _state = _state.copyWith(isPaused: false);
    notifyListeners();
    _startTimers();
  }

  void _startTimers() {
    _stopTimers();
    _frameTimer = Timer.periodic(
      const Duration(milliseconds: _frameStepMs),
      (_) => _onFrameTick(),
    );
  }

  void _stopTimers() {
    _frameTimer?.cancel();
    _frameTimer = null;
  }

  void _onFrameTick() {
    if (_state.isPaused || _state.isGameOver) return;

    var nextElapsed = _state.elapsedMs + _frameStepMs;
    var nextPoison = max(0, _state.poisonRemainingMs - _frameStepMs);
    var nextStarv = _state.hasStarvation
        ? max(0, _state.starvationRemainingMs - _frameStepMs)
        : _state.starvationRemainingMs;

    SnakeSpecialItem? nextSpecial = _state.specialItem;
    if (nextSpecial != null) {
      final rem = nextSpecial.remainingMs - _frameStepMs;
      nextSpecial = rem <= 0 ? null : nextSpecial.copyWith(remainingMs: rem);
    } else {
      _specialSpawnCooldownMs -= _frameStepMs;
      if (_specialSpawnCooldownMs <= 0) {
        nextSpecial = _spawnSpecialItem();
        _specialSpawnCooldownMs = 8000 + _rng.nextInt(5000);
      }
    }

    var nextObstacles = _state.obstacles;
    var nextWarnings = _state.warningObstacles;
    var nextWarnRem = _state.obstacleWarningRemainingMs;

    if (nextWarnings.isNotEmpty) {
      nextWarnRem -= _frameStepMs;
      if (nextWarnRem <= 0) {
        final snakeSet = _state.snake.toSet();
        nextObstacles = nextWarnings.where((p) => !snakeSet.contains(p)).toSet();
        nextWarnings = const {};
        nextWarnRem = 0;
      }
    }

    _state = _state.copyWith(
      elapsedMs: nextElapsed,
      poisonRemainingMs: nextPoison,
      starvationRemainingMs: nextStarv,
      specialItem: nextSpecial,
      clearSpecial: nextSpecial == null,
      obstacles: nextObstacles,
      warningObstacles: nextWarnings,
      obstacleWarningRemainingMs: nextWarnRem,
    );

    if (_state.hasStarvation && nextStarv <= 0) {
      _endGame(
        won: false,
        deathReason: SnakeDeathReason.starvation,
        crashPoint: _state.snake.first,
      );
      return;
    }

    _moveAccumulatorMs += _frameStepMs;
    if (_moveAccumulatorMs >= _state.tickMs) {
      _moveAccumulatorMs -= _state.tickMs;
      _stepSnake();
    } else {
      notifyListeners();
    }
  }

  void _stepSnake() {
    _pushPracticeSnapshot();
    final nextDir = _inputQueue.isNotEmpty
        ? _inputQueue.removeFirst()
        : _state.direction;
    final head = _state.snake.first;
    var nx = head.x + nextDir.dx;
    var ny = head.y + nextDir.dy;

    if (_state.wrapWalls) {
      nx = (nx + _state.gridSize) % _state.gridSize;
      ny = (ny + _state.gridSize) % _state.gridSize;
    } else {
      if (nx < 0 ||
          ny < 0 ||
          nx >= _state.gridSize ||
          ny >= _state.gridSize) {
        _endGame(
          won: false,
          deathReason: SnakeDeathReason.wall,
          crashPoint: head,
        );
        return;
      }
    }

    final nextHead = GridPoint(nx, ny);
    if (_state.obstacles.contains(nextHead)) {
      _endGame(
        won: false,
        deathReason: SnakeDeathReason.obstacle,
        crashPoint: nextHead,
      );
      return;
    }

    final willEatApple = nextHead == _state.apple;
    final bodyToCheck = willEatApple
        ? _state.snake
        : _state.snake.sublist(0, _state.snake.length - 1);
    if (bodyToCheck.contains(nextHead)) {
      _endGame(
        won: false,
        deathReason: SnakeDeathReason.selfCollision,
        crashPoint: nextHead,
      );
      return;
    }

    final nextSnake = <GridPoint>[nextHead, ..._state.snake];
    if (!willEatApple) {
      nextSnake.removeLast();
    }

    var nextScore = _state.score;
    var nextFoods = _state.foodsEaten;
    var nextApple = _state.apple;
    var nextTick = _state.tickMs;
    var nextStarv = _state.starvationRemainingMs;
    var nextPoison = _state.poisonRemainingMs;
    var nextWarnings = _state.warningObstacles;
    var nextWarnRem = _state.obstacleWarningRemainingMs;
    var nextSpecial = _state.specialItem;
    var clearSpecial = false;

    if (willEatApple) {
      nextScore += 10;
      nextFoods += 1;
      if (_state.hasStarvation) {
        nextStarv = _state.starvationMaxMs;
      }
      // Progressive speed boost (PRD 61B)
      final minTick = max(58, baseTickFor(_state.difficulty) - 42);
      nextTick = max(minTick, baseTickFor(_state.difficulty) - (nextSnake.length ~/ 2));

      _audio.playSfx(ZetzySfx.snakeEat);
      _haptics.light();

      // Check 100% grid fill win condition (PRD 65A)
      final totalPlayable =
          (_state.gridSize * _state.gridSize) - _state.obstacles.length;
      if (nextSnake.length >= totalPlayable) {
        _state = _state.copyWith(
          snake: nextSnake,
          direction: nextDir,
          score: nextScore,
          foodsEaten: nextFoods,
          canPracticeUndo: _state.isPractice && _practiceHistory.isNotEmpty,
        );
        _endGame(won: true);
        return;
      }

      nextApple = _randomFreeCell(
        _state.gridSize,
        nextSnake.toSet(),
        _state.obstacles,
        exclude: nextSpecial?.point,
      );

      // Dynamic shifting obstacles every 5 foods on Level 6-7 with 2s warning (PRD 60B)
      if (_state.hasDynamicObstacles && nextFoods % 5 == 0) {
        nextWarnings = _generateDynamicObstacles(
          _state.gridSize,
          nextSnake,
          nextApple,
        );
        nextWarnRem = 2000;
      }
    }

    if (nextSpecial != null && nextHead == nextSpecial.point) {
      clearSpecial = true;
      switch (nextSpecial.kind) {
        case SnakeSpecialKind.golden:
          nextScore += 50;
          if (_state.hasStarvation) nextStarv = _state.starvationMaxMs;
          _audio.playSfx(ZetzySfx.snakePowerup);
          _haptics.medium();
        case SnakeSpecialKind.scissors:
          nextScore += 15;
          final trimCount = min(3, max(0, nextSnake.length - 3));
          for (var i = 0; i < trimCount; i++) {
            nextSnake.removeLast();
          }
          _audio.playSfx(ZetzySfx.snakePowerup);
          _haptics.medium();
        case SnakeSpecialKind.poison:
          nextPoison = 5000;
          _audio.playSfx(ZetzySfx.errorBuzz);
          _haptics.heavy();
      }
    }

    _state = _state.copyWith(
      snake: nextSnake,
      direction: nextDir,
      apple: nextApple,
      score: nextScore,
      foodsEaten: nextFoods,
      tickMs: nextTick,
      starvationRemainingMs: nextStarv,
      poisonRemainingMs: nextPoison,
      warningObstacles: nextWarnings,
      obstacleWarningRemainingMs: nextWarnRem,
      specialItem: nextSpecial,
      clearSpecial: clearSpecial,
      canPracticeUndo: _state.isPractice && _practiceHistory.isNotEmpty,
    );
    notifyListeners();
  }

  void _pushPracticeSnapshot() {
    if (!_state.isPractice) return;
    if (_practiceHistory.length >= 30) {
      _practiceHistory.removeAt(0);
    }
    _practiceHistory.add(
      _SnakeSnapshot(
        snake: List<GridPoint>.from(_state.snake),
        direction: _state.direction,
        apple: _state.apple,
        obstacles: Set<GridPoint>.from(_state.obstacles),
        warningObstacles: Set<GridPoint>.from(_state.warningObstacles),
        specialItem: _state.specialItem?.copyWith(),
        score: _state.score,
        foodsEaten: _state.foodsEaten,
        elapsedMs: _state.elapsedMs,
        tickMs: _state.tickMs,
        starvationRemainingMs: _state.starvationRemainingMs,
        poisonRemainingMs: _state.poisonRemainingMs,
        obstacleWarningRemainingMs: _state.obstacleWarningRemainingMs,
      ),
    );
  }

  void practiceUndo({bool pauseAfterRewind = true}) =>
      practiceRewind(1, pauseAfterRewind: pauseAfterRewind);

  @visibleForTesting
  void stepForTest() => _stepSnake();

  void practiceRewind(int steps, {bool pauseAfterRewind = true}) {
    if (!_state.isPractice || _practiceHistory.isEmpty) return;
    _stopTimers();
    _inputQueue.clear();
    _moveAccumulatorMs = 0;

    final count = min(steps.clamp(1, 3), _practiceHistory.length);
    _SnakeSnapshot? chosen;
    for (var i = 0; i < count; i++) {
      chosen = _practiceHistory.removeLast();
    }
    if (chosen == null) return;

    var nextStarv = chosen.starvationRemainingMs;
    if (_state.hasStarvation && (_state.isGameOver || nextStarv < 2500)) {
      nextStarv = max(nextStarv, min(_state.starvationMaxMs, 3500));
    }

    _state = _state.copyWith(
      snake: List<GridPoint>.from(chosen.snake),
      direction: chosen.direction,
      apple: chosen.apple,
      obstacles: Set<GridPoint>.from(chosen.obstacles),
      warningObstacles: Set<GridPoint>.from(chosen.warningObstacles),
      specialItem: chosen.specialItem?.copyWith(),
      clearSpecial: chosen.specialItem == null,
      score: chosen.score,
      foodsEaten: chosen.foodsEaten,
      elapsedMs: chosen.elapsedMs,
      tickMs: chosen.tickMs,
      starvationRemainingMs: nextStarv,
      poisonRemainingMs: chosen.poisonRemainingMs,
      obstacleWarningRemainingMs: chosen.obstacleWarningRemainingMs,
      isPaused: pauseAfterRewind,
      isGameOver: false,
      isWon: false,
      clearDeathReason: true,
      clearCrashPoint: true,
      canPracticeUndo: _practiceHistory.isNotEmpty,
    );
    _haptics.selection();
    notifyListeners();
    if (!pauseAfterRewind) {
      _startTimers();
    }
  }

  SnakeSpecialItem? _spawnSpecialItem() {
    final occupied = {..._state.snake, ..._state.obstacles, _state.apple};
    final pos = _randomFreeCell(_state.gridSize, occupied, const {});
    final roll = _rng.nextDouble();
    final SnakeSpecialKind kind;
    if (_state.difficulty.level >= 4 && roll < 0.28) {
      kind = SnakeSpecialKind.poison;
    } else if (roll < 0.62) {
      kind = SnakeSpecialKind.scissors;
    } else {
      kind = SnakeSpecialKind.golden;
    }
    return SnakeSpecialItem(
      point: pos,
      kind: kind,
      remainingMs: 7000,
      totalMs: 7000,
    );
  }

  Set<GridPoint> _buildStaticMaze(
    int size,
    int level,
    List<GridPoint> safeSnake,
  ) {
    if (level <= 1) return const {};
    final obs = <GridPoint>{};
    final safeSet = {
      ...safeSnake,
      GridPoint(safeSnake.first.x + 1, safeSnake.first.y),
      GridPoint(safeSnake.first.x + 2, safeSnake.first.y),
    };
    final margin = 4;
    if (level >= 2) {
      // Corner/pillar symmetry
      for (final p in [
        GridPoint(margin, margin),
        GridPoint(size - 1 - margin, margin),
        GridPoint(margin, size - 1 - margin),
        GridPoint(size - 1 - margin, size - 1 - margin),
      ]) {
        if (!safeSet.contains(p)) obs.add(p);
      }
    }
    if (level >= 3) {
      final c = size ~/ 2;
      for (var d = -2; d <= 2; d++) {
        if (d == 0) continue;
        final p1 = GridPoint(c + d, 3);
        final p2 = GridPoint(c + d, size - 4);
        if (!safeSet.contains(p1)) obs.add(p1);
        if (!safeSet.contains(p2)) obs.add(p2);
      }
    }
    if (level >= 4) {
      final c = size ~/ 2;
      for (var d = -2; d <= 2; d++) {
        if (d == 0) continue;
        final p1 = GridPoint(3, c + d);
        final p2 = GridPoint(size - 4, c + d);
        if (!safeSet.contains(p1)) obs.add(p1);
        if (!safeSet.contains(p2)) obs.add(p2);
      }
    }
    if (level >= 5) {
      for (var i = 0; i < 6; i++) {
        final p = _randomFreeCell(size, safeSet, obs);
        obs.add(p);
      }
    }
    return obs;
  }

  Set<GridPoint> _generateDynamicObstacles(
    int size,
    List<GridPoint> snake,
    GridPoint apple,
  ) {
    final head = snake.first;
    final forbidden = <GridPoint>{
      ...snake,
      apple,
      for (var dx = -2; dx <= 2; dx++)
        for (var dy = -2; dy <= 2; dy++) GridPoint(head.x + dx, head.y + dy),
    };
    final count = _state.difficulty.level == 7 ? 14 : 10;
    final obs = <GridPoint>{};
    for (var i = 0; i < count; i++) {
      obs.add(_randomFreeCell(size, forbidden, obs));
    }
    return obs;
  }

  GridPoint _randomFreeCell(
    int size,
    Set<GridPoint> occupied,
    Set<GridPoint> obstacles, {
    GridPoint? exclude,
  }) {
    for (var attempt = 0; attempt < 400; attempt++) {
      final p = GridPoint(_rng.nextInt(size), _rng.nextInt(size));
      if (!occupied.contains(p) &&
          !obstacles.contains(p) &&
          p != exclude) {
        return p;
      }
    }
    for (var y = 0; y < size; y++) {
      for (var x = 0; x < size; x++) {
        final p = GridPoint(x, y);
        if (!occupied.contains(p) && !obstacles.contains(p) && p != exclude) {
          return p;
        }
      }
    }
    return const GridPoint(0, 0);
  }

  void _endGame({
    required bool won,
    SnakeDeathReason? deathReason,
    GridPoint? crashPoint,
  }) {
    _stopTimers();
    _audio.playSfx(won ? ZetzySfx.gameWin : ZetzySfx.mineExplode);
    if (won) {
      _haptics.medium();
    } else {
      _haptics.heavy();
    }
    _state = _state.copyWith(
      isGameOver: true,
      isWon: won,
      deathReason: deathReason,
      clearDeathReason: deathReason == null,
      crashPoint: crashPoint,
      clearCrashPoint: crashPoint == null,
    );
    notifyListeners();
    onFinished(_state);
  }

  @override
  void dispose() {
    _stopTimers();
    super.dispose();
  }
}
