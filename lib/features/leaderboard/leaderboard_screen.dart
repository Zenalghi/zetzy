import 'dart:math';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zetzy/core/constants/app_constants.dart';
import 'package:zetzy/core/theme/zetzy_theme.dart';
import 'package:zetzy/core/utils/time_formatter.dart';
import 'package:zetzy/core/widgets/game_type_icon.dart';
import 'package:zetzy/core/widgets/platform_badge.dart';
import 'package:zetzy/core/widgets/tactile_card.dart';
import 'package:zetzy/core/widgets/user_avatar.dart';
import 'package:zetzy/data/models/game_record.dart';
import 'package:zetzy/data/models/user_profile.dart';
import 'package:zetzy/l10n/app_localizations.dart';
import 'package:zetzy/providers/app_providers.dart';

class _PagedListState<T> {
  const _PagedListState({
    this.items = const [],
    this.offset = 0,
    this.loadingInitial = false,
    this.loadingMore = false,
    this.hasMore = false,
    this.error = false,
  });

  final List<T> items;
  final int offset;
  final bool loadingInitial;
  final bool loadingMore;
  final bool hasMore;
  final bool error;

  _PagedListState<T> copyWith({
    List<T>? items,
    int? offset,
    bool? loadingInitial,
    bool? loadingMore,
    bool? hasMore,
    bool? error,
  }) {
    return _PagedListState<T>(
      items: items ?? this.items,
      offset: offset ?? this.offset,
      loadingInitial: loadingInitial ?? this.loadingInitial,
      loadingMore: loadingMore ?? this.loadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: error ?? this.error,
    );
  }
}

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  static const int _initialPageSize = 20;
  static const int _loadMoreStep = 10;
  static const int _maxEntries = 100;

  GameType _game = GameType.sudoku;
  DifficultyLevel _difficulty = DifficultyLevel.normal;
  int _tabIndex = 0; // 0: Global, 1: My Best, 2: Chess ELO

  _PagedListState<GameRecord> _globalState = const _PagedListState();
  _PagedListState<UserProfile> _eloState = const _PagedListState();
  int _myBestLimit = _initialPageSize;

  String? _loadedGlobalFilterKey;
  bool _eloInitialized = false;
  int _globalReqGen = 0;
  int _eloReqGen = 0;
  final ScrollController _scrollCtrl = ScrollController();

  String get _currentGlobalFilterKey => '${_game.id}_${_difficulty.level}';

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      if (ref.read(supabaseServiceProvider).isAvailable) {
        _loadGlobal(reset: true);
      }
    });
  }

  Future<void> _loadGlobal({required bool reset}) async {
    final supa = ref.read(supabaseServiceProvider);
    if (!supa.isAvailable) return;
    if (!reset &&
        (_globalState.loadingMore ||
            _globalState.loadingInitial ||
            !_globalState.hasMore ||
            _globalState.items.length >= _maxEntries)) {
      return;
    }

    final reqGen = ++_globalReqGen;
    final game = _game;
    final diff = _difficulty.level;
    final filterKey = _currentGlobalFilterKey;
    final offset = reset ? 0 : _globalState.offset;
    final limit = reset
        ? _initialPageSize
        : min(_loadMoreStep, _maxEntries - _globalState.items.length);
    if (limit <= 0) return;

    setState(() {
      _loadedGlobalFilterKey = filterKey;
      _globalState = reset
          ? const _PagedListState(loadingInitial: true)
          : _globalState.copyWith(loadingMore: true, error: false);
    });

    try {
      final page = await supa.fetchGlobalLeaderboard(
        gameType: game,
        difficulty: diff,
        limit: limit,
        offset: offset,
      );
      if (!mounted || reqGen != _globalReqGen) return;

      final merged = reset
          ? page
          : _mergeUnique<GameRecord>(_globalState.items, page, (r) => r.id);
      setState(() {
        _globalState = _PagedListState(
          items: merged,
          offset: offset + page.length,
          loadingInitial: false,
          loadingMore: false,
          hasMore: page.length == limit && merged.length < _maxEntries,
          error: false,
        );
      });
      if (reset && _scrollCtrl.hasClients) {
        _scrollCtrl.jumpTo(0);
      }
    } catch (_) {
      if (!mounted || reqGen != _globalReqGen) return;
      setState(() {
        _globalState = _globalState.copyWith(
          loadingInitial: false,
          loadingMore: false,
          error: reset,
        );
      });
    }
  }

  Future<void> _loadElo({required bool reset}) async {
    final supa = ref.read(supabaseServiceProvider);
    if (!supa.isAvailable) return;
    if (!reset &&
        (_eloState.loadingMore ||
            _eloState.loadingInitial ||
            !_eloState.hasMore ||
            _eloState.items.length >= _maxEntries)) {
      return;
    }

    final reqGen = ++_eloReqGen;
    final offset = reset ? 0 : _eloState.offset;
    final limit = reset
        ? _initialPageSize
        : min(_loadMoreStep, _maxEntries - _eloState.items.length);
    if (limit <= 0) return;

    setState(() {
      _eloInitialized = true;
      _eloState = reset
          ? const _PagedListState(loadingInitial: true)
          : _eloState.copyWith(loadingMore: true, error: false);
    });

    try {
      final page = await supa.fetchChessEloLeaderboard(
        limit: limit,
        offset: offset,
      );
      if (!mounted || reqGen != _eloReqGen) return;

      final merged = reset
          ? page
          : _mergeUnique<UserProfile>(_eloState.items, page, (u) => u.id);
      setState(() {
        _eloState = _PagedListState(
          items: merged,
          offset: offset + page.length,
          loadingInitial: false,
          loadingMore: false,
          hasMore: page.length == limit && merged.length < _maxEntries,
          error: false,
        );
      });
      if (reset && _scrollCtrl.hasClients) {
        _scrollCtrl.jumpTo(0);
      }
    } catch (_) {
      if (!mounted || reqGen != _eloReqGen) return;
      setState(() {
        _eloState = _eloState.copyWith(
          loadingInitial: false,
          loadingMore: false,
          error: reset,
        );
      });
    }
  }

  List<T> _mergeUnique<T>(
    List<T> existing,
    List<T> incoming,
    String Function(T item) idOf,
  ) {
    final seen = existing.map(idOf).toSet();
    return [
      ...existing,
      ...incoming.where((item) => seen.add(idOf(item))),
    ];
  }

  void _onTabChanged(int nextTab) {
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.jumpTo(0);
    }
    setState(() => _tabIndex = nextTab);
    if (nextTab == 0 && _loadedGlobalFilterKey != _currentGlobalFilterKey) {
      _loadGlobal(reset: true);
    } else if (nextTab == 2 && !_eloInitialized) {
      _loadElo(reset: true);
    }
  }

  void _onFilterChanged({GameType? game, DifficultyLevel? difficulty}) {
    setState(() {
      if (game != null) _game = game;
      if (difficulty != null) _difficulty = difficulty;
      _myBestLimit = _initialPageSize;
    });
    if (_tabIndex == 0) {
      _loadGlobal(reset: true);
    }
  }

  Future<void> _refreshCurrentRemoteTab() async {
    if (_tabIndex == 0) {
      await _loadGlobal(reset: true);
    } else if (_tabIndex == 2) {
      await _loadElo(reset: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l10n = AppLocalizations.of(context)!;
    final supa = ref.watch(supabaseServiceProvider);
    final isRemoteLoading =
        (_tabIndex == 0 && _globalState.loadingInitial) ||
        (_tabIndex == 2 && _eloState.loadingInitial);

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 920),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.navLeaderboard,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                    if (supa.isAvailable && _tabIndex != 1)
                      IconButton(
                        key: const ValueKey('leaderboard_refresh_btn'),
                        tooltip: l10n.leaderboardRefresh,
                        onPressed:
                            isRemoteLoading ? null : _refreshCurrentRemoteTab,
                        icon: isRemoteLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.refresh_rounded),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                SegmentedButton<int>(
                  selected: {_tabIndex},
                  onSelectionChanged: (s) => _onTabChanged(s.first),
                  segments: [
                    ButtonSegment(
                      value: 0,
                      label: Text(l10n.leaderboardGlobal),
                      icon: const Icon(Icons.public_rounded, size: 18),
                    ),
                    ButtonSegment(
                      value: 1,
                      label: Text(l10n.leaderboardMyBest),
                      icon: const Icon(Icons.person_outline_rounded, size: 18),
                    ),
                    ButtonSegment(
                      value: 2,
                      label: Text(l10n.leaderboardChessElo),
                      icon: const GameTypeIcon(game: GameType.chess, size: 18),
                    ),
                  ],
                ),
                if (_tabIndex != 2) ...[
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final g in GameType.values)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              selected: _game == g,
                              onSelected: (_) => _onFilterChanged(game: g),
                              avatar: GameTypeIcon(game: g, size: 16),
                              label: Text(g.localizedTitle(l10n)),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final d in DifficultyLevel.values)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              selected: _difficulty == d,
                              onSelected: (_) =>
                                  _onFilterChanged(difficulty: d),
                              avatar: Image.asset(
                                d.badgeAsset,
                                width: 18,
                                height: 18,
                                errorBuilder: (_, _, _) => const SizedBox(),
                              ),
                              label: Text('${d.level}. ${d.localizedLabel(l10n)}'),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Expanded(
                  child: _tabIndex == 2
                      ? _buildChessEloList(supa.isAvailable, p, l10n)
                      : _tabIndex == 0
                      ? _buildGlobalRecordsList(supa.isAvailable, p, l10n)
                      : _buildMyBestList(p, l10n),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMyBestList(ZetzyPalette p, AppLocalizations l10n) {
    final asyncRecords = ref.watch(localRecordsProvider);
    return asyncRecords.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (all) {
        final filtered = all
            .where(
              (r) => r.gameType == _game && r.difficulty == _difficulty.level,
            )
            .where((r) => _game == GameType.snake || r.isWon)
            .where(
              (r) =>
                  _game != GameType.chess ||
                  r.metadata['mode'] == null ||
                  r.metadata['mode'] == 'vsAi',
            )
            .toList();
        filtered.sort((a, b) {
          if (_game == GameType.snake || _game == GameType.chess) {
            final cmp = b.score.compareTo(a.score);
            return cmp != 0 ? cmp : a.durationMs.compareTo(b.durationMs);
          }
          return a.durationMs.compareTo(b.durationMs);
        });

        final cappedTotal = min(filtered.length, _maxEntries);
        final visibleCount = min(_myBestLimit, cappedTotal);
        final visible = filtered.take(visibleCount).toList();
        final hasMore = visibleCount < cappedTotal;

        return _renderRecordList(
          visible,
          p,
          l10n,
          hasMore: hasMore,
          loadingMore: false,
          onLoadMore: () => setState(
            () => _myBestLimit = min(_maxEntries, _myBestLimit + _loadMoreStep),
          ),
        );
      },
    );
  }

  Widget _buildGlobalRecordsList(
    bool supaReady,
    ZetzyPalette p,
    AppLocalizations l10n,
  ) {
    if (!supaReady) {
      return _OfflineNotice(
        message: l10n.settingsSupabaseLocalOnly,
        fallback: _buildMyBestList(p, l10n),
      );
    }

    if (_globalState.loadingInitial && _globalState.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_globalState.error && _globalState.items.isEmpty) {
      return _buildMyBestList(p, l10n);
    }

    return RefreshIndicator(
      onRefresh: () => _loadGlobal(reset: true),
      child: _renderRecordList(
        _globalState.items,
        p,
        l10n,
        hasMore: _globalState.hasMore,
        loadingMore: _globalState.loadingMore,
        onLoadMore: () => _loadGlobal(reset: false),
      ),
    );
  }

  Widget _buildChessEloList(
    bool supaReady,
    ZetzyPalette p,
    AppLocalizations l10n,
  ) {
    final user = ref.watch(authProvider);
    if (!supaReady) {
      return ListView(
        children: [
          TactileCard(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: p.accent.withValues(alpha: 0.2),
                child: Text('#1', style: TextStyle(color: p.accent)),
              ),
              title: Text('@${user.username}'),
              subtitle: Text(l10n.settingsSupabaseLocalOnly),
              trailing: Text(
                '${user.chessElo} ELO',
                style: ZetzyThemes.monoStyle(fontSize: 16, color: p.accent),
              ),
            ),
          ),
        ],
      );
    }

    if (_eloState.loadingInitial && _eloState.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final list = _eloState.items;
    if (list.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => _loadElo(reset: true),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 80),
            Center(
              child: Text(
                l10n.leaderboardEmpty,
                style: TextStyle(color: p.textSecondary),
              ),
            ),
          ],
        ),
      );
    }

    final showFooter = _eloState.hasMore;
    return RefreshIndicator(
      onRefresh: () => _loadElo(reset: true),
      child: ListView.separated(
        key: const ValueKey('leaderboard_elo_list'),
        controller: _scrollCtrl,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: list.length + (showFooter ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          if (i >= list.length) {
            return _buildLoadMoreFooter(
              p: p,
              l10n: l10n,
              shownCount: list.length,
              hasMore: _eloState.hasMore,
              loadingMore: _eloState.loadingMore,
              onLoadMore: () => _loadElo(reset: false),
            );
          }

          final prof = list[i];
          return TactileCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                SizedBox(
                  width: 34,
                  child: Text(
                    '#${i + 1}',
                    style: ZetzyThemes.monoStyle(
                      fontSize: 14,
                      color: i < 3 ? p.accent : p.textSecondary,
                    ),
                  ),
                ),
                UserAvatar(
                  avatarUrl: prof.avatarUrl,
                  username: prof.username,
                  radius: 16,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '@${prof.username}',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                Text(
                  '${prof.chessElo}',
                  style: ZetzyThemes.monoStyle(
                    fontSize: 15,
                    color: p.accent,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _renderRecordList(
    List<GameRecord> records,
    ZetzyPalette p,
    AppLocalizations l10n, {
    required bool hasMore,
    required bool loadingMore,
    required VoidCallback onLoadMore,
  }) {
    if (records.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 80),
          Center(
            child: Text(
              l10n.leaderboardEmpty,
              style: TextStyle(color: p.textSecondary),
            ),
          ),
        ],
      );
    }

    final currentUser = ref.watch(authProvider);
    final showFooter = hasMore;

    return ListView.separated(
      key: ValueKey('leaderboard_records_list_$_tabIndex'),
      controller: _scrollCtrl,
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: records.length + (showFooter ? 1 : 0),
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, idx) {
        if (idx >= records.length) {
          return _buildLoadMoreFooter(
            p: p,
            l10n: l10n,
            shownCount: records.length,
            hasMore: hasMore,
            loadingMore: loadingMore,
            onLoadMore: onLoadMore,
          );
        }

        final r = records[idx];
        final isCurrentUser =
            r.userId == currentUser.id ||
            (!currentUser.isGuest && r.username == currentUser.username);
        final resolvedAvatarUrl =
            (r.avatarUrl != null && r.avatarUrl!.isNotEmpty)
            ? r.avatarUrl
            : (isCurrentUser ? currentUser.avatarUrl : null);

        return TactileCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              SizedBox(
                width: 34,
                child: Text(
                  '#${idx + 1}',
                  style: ZetzyThemes.monoStyle(
                    fontSize: 14,
                    color: idx < 3 ? p.accent : p.textSecondary,
                  ),
                ),
              ),
              UserAvatar(
                avatarUrl: resolvedAvatarUrl,
                username: r.username,
                radius: 16,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            '@${r.username}',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(width: 6),
                        PlatformBadge(platform: r.platform, size: 14),
                      ],
                    ),
                    Text(
                      '${l10n.scoreLabel}: ${r.score}',
                      style: TextStyle(fontSize: 12, color: p.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                TimeFormatter.formatMs(r.durationMs),
                style: ZetzyThemes.monoStyle(
                  fontSize: 14,
                  color: p.textPrimary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoadMoreFooter({
    required ZetzyPalette p,
    required AppLocalizations l10n,
    required int shownCount,
    required bool hasMore,
    required bool loadingMore,
    required VoidCallback onLoadMore,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 12),
      child: Column(
        children: [
          Text(
            l10n.leaderboardShowingCount(shownCount),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11.5, color: p.textSecondary),
          ),
          if (hasMore) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              key: const ValueKey('leaderboard_load_more_btn'),
              onPressed: loadingMore ? null : onLoadMore,
              icon: loadingMore
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.expand_more_rounded, size: 18),
              label: Text(l10n.leaderboardLoadMore(_loadMoreStep)),
            ),
          ],
        ],
      ),
    );
  }
}

class _OfflineNotice extends StatelessWidget {
  const _OfflineNotice({required this.message, required this.fallback});
  final String message;
  final Widget fallback;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: p.surfaceElevated,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: p.border),
          ),
          child: Text(
            message,
            style: TextStyle(fontSize: 12, color: p.textSecondary),
          ),
        ),
        Expanded(child: fallback),
      ],
    );
  }
}
