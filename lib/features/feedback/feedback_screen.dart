import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:zetzy/core/theme/zetzy_theme.dart';
import 'package:zetzy/core/widgets/tactile_card.dart';
import 'package:zetzy/core/widgets/user_avatar.dart';
import 'package:zetzy/data/models/feedback_entry.dart';
import 'package:zetzy/data/models/user_profile.dart';
import 'package:zetzy/l10n/app_localizations.dart';
import 'package:zetzy/providers/app_providers.dart';

/// Dedicated Player & Admin Feedback page:
/// - Players submit up to 5 pending items tagged with app version, edit within
///   6 hours, delete anytime, and see 1× Admin approval/rejection + reply.
/// - Admins see all players' feedback in 20-item pages (Load More) and can
///   approve (✓) or reject (✕) with an optional 1× message.
class FeedbackScreen extends ConsumerStatefulWidget {
  const FeedbackScreen({super.key});

  @override
  ConsumerState<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends ConsumerState<FeedbackScreen> {
  static const int _pageSize = 20;

  final TextEditingController _composerCtrl = TextEditingController();

  int _selectedTab = 0; // 0 = Admin Inbox (when admin), 1 = My Feedback
  bool _submitting = false;

  // Player list state
  bool _loadingMine = false;
  String? _mineError;
  List<FeedbackEntry> _myItems = const [];

  // Admin inbox paginated state (20 per page)
  bool _loadingAdminInitial = false;
  bool _loadingAdminMore = false;
  bool _adminHasMore = false;
  String? _adminError;
  List<FeedbackEntry> _adminItems = const [];

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadInitialData);
  }

  @override
  void dispose() {
    _composerCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    final user = ref.read(authProvider);
    final supa = ref.read(supabaseServiceProvider);
    if (!supa.isAvailable || user.isGuest) return;

    await Future.wait([
      _refreshMine(),
      if (user.isAdmin) _loadAdmin(reset: true),
    ]);
  }

  Future<void> _refreshMine() async {
    final supa = ref.read(supabaseServiceProvider);
    if (!supa.isAvailable || ref.read(authProvider).isGuest) return;
    setState(() {
      _loadingMine = true;
      _mineError = null;
    });
    try {
      final list = await supa.fetchMyFeedbacks();
      if (!mounted) return;
      setState(() {
        _myItems = list;
        _loadingMine = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _mineError = e.toString();
        _loadingMine = false;
      });
    }
  }

  Future<void> _loadAdmin({required bool reset}) async {
    final supa = ref.read(supabaseServiceProvider);
    final user = ref.read(authProvider);
    if (!supa.isAvailable || !user.isAdmin) return;
    if (!reset && (_loadingAdminInitial || _loadingAdminMore || !_adminHasMore)) {
      return;
    }

    final offset = reset ? 0 : _adminItems.length;
    setState(() {
      if (reset) {
        _loadingAdminInitial = true;
      } else {
        _loadingAdminMore = true;
      }
      _adminError = null;
    });

    try {
      final page = await supa.fetchAllFeedbacks(
        limit: _pageSize,
        offset: offset,
      );
      if (!mounted) return;
      final merged = reset ? page : _mergeUnique(_adminItems, page);
      setState(() {
        _adminItems = merged;
        _adminHasMore = page.length >= _pageSize;
        _loadingAdminInitial = false;
        _loadingAdminMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _adminError = e.toString();
        _loadingAdminInitial = false;
        _loadingAdminMore = false;
      });
    }
  }

  List<FeedbackEntry> _mergeUnique(
    List<FeedbackEntry> existing,
    List<FeedbackEntry> incoming,
  ) {
    final seen = existing.map((e) => e.id).toSet();
    return [...existing, ...incoming.where((e) => seen.add(e.id))];
  }

  Future<void> _submitFeedback(String appVersion) async {
    final text = _composerCtrl.text.trim();
    if (text.length < 3 || _submitting) return;
    setState(() => _submitting = true);
    try {
      final created = await ref
          .read(supabaseServiceProvider)
          .createFeedback(message: text, appVersion: appVersion);
      if (!mounted) return;
      _composerCtrl.clear();
      setState(() {
        _myItems = [created, ..._myItems];
        if (ref.read(authProvider).isAdmin) {
          _adminItems = [
            created,
            ..._adminItems.where((e) => e.id != created.id),
          ];
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _editFeedback(FeedbackEntry entry, AppLocalizations l10n) async {
    final savedText = await showDialog<String>(
      context: context,
      builder: (_) => _EditFeedbackDialog(initialText: entry.message),
    );
    if (savedText == null || savedText == entry.message) return;

    try {
      final updated = await ref
          .read(supabaseServiceProvider)
          .updateFeedbackMessage(feedbackId: entry.id, message: savedText);
      if (!mounted) return;
      _replaceEntryInLists(updated);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  Future<void> _deleteFeedback(
    FeedbackEntry entry,
    AppLocalizations l10n,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          l10n.feedbackDeleteConfirmTitle,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        content: Text(l10n.feedbackDeleteConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: context.palette.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.feedbackDeleteAction),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(supabaseServiceProvider).deleteFeedback(entry.id);
      if (!mounted) return;
      setState(() {
        _myItems = _myItems.where((e) => e.id != entry.id).toList();
        _adminItems = _adminItems.where((e) => e.id != entry.id).toList();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  Future<void> _reviewFeedback(
    FeedbackEntry entry,
    FeedbackStatus initialDecision,
    AppLocalizations l10n,
  ) async {
    final result =
        await showDialog<({FeedbackStatus decision, String reply})>(
          context: context,
          builder: (_) => _ReviewFeedbackDialog(
            entry: entry,
            initialDecision: initialDecision,
          ),
        );
    if (result == null) return;

    try {
      final updated = await ref
          .read(supabaseServiceProvider)
          .reviewFeedback(
            feedbackId: entry.id,
            decision: result.decision,
            adminReply: result.reply,
          );
      if (!mounted) return;
      _replaceEntryInLists(updated);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  void _replaceEntryInLists(FeedbackEntry updated) {
    setState(() {
      _myItems = [
        for (final item in _myItems) item.id == updated.id ? updated : item,
      ];
      _adminItems = [
        for (final item in _adminItems) item.id == updated.id ? updated : item,
      ];
    });
  }

  String _formatShortDuration(Duration duration) {
    if (duration.inDays >= 1) {
      final hours = duration.inHours % 24;
      return '${duration.inDays}d ${hours}h';
    }
    if (duration.inHours >= 1) {
      final mins = duration.inMinutes % 60;
      return '${duration.inHours}h ${mins}m';
    }
    return '${duration.inMinutes.clamp(1, 59)}m';
  }

  String _formatTimestamp(DateTime utc) {
    final local = utc.toLocal();
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $hh:$mm';
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(authProvider);
    final supa = ref.watch(supabaseServiceProvider);
    final appVersion = ref.watch(appVersionProvider).value ?? '0.0.3';
    final showingAdminInbox = user.isAdmin && _selectedTab == 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          user.isAdmin ? l10n.feedbackAdminInboxTitle : l10n.feedbackTitle,
        ),
        actions: [
          if (supa.isAvailable && !user.isGuest)
            IconButton(
              tooltip: 'Refresh',
              onPressed: () {
                if (showingAdminInbox) {
                  _loadAdmin(reset: true);
                } else {
                  _refreshMine();
                }
              },
              icon: const Icon(Icons.refresh_rounded),
            ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _PrivacyNoticeBanner(text: l10n.feedbackPrivacyNote),
                const SizedBox(height: 14),
                if (!supa.isAvailable || user.isGuest)
                  TactileCard(
                    child: Column(
                      children: [
                        Icon(
                          Icons.lock_person_outlined,
                          size: 40,
                          color: p.textSecondary,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          !supa.isAvailable
                              ? l10n.settingsSupabaseLocalOnly
                              : l10n.feedbackSignInRequired,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: p.textSecondary,
                            fontSize: 13.5,
                          ),
                        ),
                      ],
                    ),
                  )
                else ...[
                  if (user.isAdmin) ...[
                    SegmentedButton<int>(
                      expandedInsets: EdgeInsets.zero,
                      selected: {_selectedTab},
                      onSelectionChanged: (sel) =>
                          setState(() => _selectedTab = sel.first),
                      segments: [
                        ButtonSegment(
                          value: 0,
                          icon: const Icon(Icons.inbox_rounded, size: 17),
                          label: Text(l10n.feedbackTabInbox),
                        ),
                        ButtonSegment(
                          value: 1,
                          icon: const Icon(Icons.rate_review_outlined, size: 17),
                          label: Text(l10n.feedbackTabMine),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                  ],
                  if (showingAdminInbox)
                    ..._buildAdminInboxSection(user, p, l10n)
                  else
                    ..._buildMyFeedbackSection(p, l10n, appVersion),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildMyFeedbackSection(
    ZetzyPalette p,
    AppLocalizations l10n,
    String appVersion,
  ) {
    final pendingCount = _myItems
        .where((e) => e.status == FeedbackStatus.pending)
        .length;
    final limitReached = pendingCount >= FeedbackEntry.maxPendingPerUser;

    return [
      TactileCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: (limitReached ? p.warning : p.accent).withValues(
                      alpha: 0.14,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: (limitReached ? p.warning : p.accent).withValues(
                        alpha: 0.4,
                      ),
                    ),
                  ),
                  child: Text(
                    l10n.feedbackPendingCount(
                      pendingCount,
                      FeedbackEntry.maxPendingPerUser,
                    ),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: limitReached ? p.warning : p.accent,
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: p.surfaceElevated,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: p.border),
                  ),
                  child: Text(
                    'v$appVersion',
                    style: ZetzyThemes.monoStyle(
                      fontSize: 11.5,
                      color: p.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _composerCtrl,
              enabled: !limitReached && !_submitting,
              minLines: 3,
              maxLines: 5,
              maxLength: 1000,
              decoration: InputDecoration(
                hintText: l10n.feedbackPlaceholder,
              ),
            ),
            if (limitReached) ...[
              const SizedBox(height: 6),
              Text(
                l10n.feedbackLimitReached(FeedbackEntry.maxPendingPerUser),
                style: TextStyle(fontSize: 12, color: p.warning),
              ),
            ],
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: limitReached || _submitting
                  ? null
                  : () => _submitFeedback(appVersion),
              icon: _submitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_rounded, size: 17),
              label: Text(l10n.feedbackSubmit),
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      if (_loadingMine && _myItems.isEmpty)
        const Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        )
      else if (_mineError != null)
        TactileCard(
          child: Text(_mineError!, style: TextStyle(color: p.danger)),
        )
      else if (_myItems.isEmpty)
        TactileCard(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: Text(
                l10n.feedbackEmptyMine,
                style: TextStyle(color: p.textSecondary),
              ),
            ),
          ),
        )
      else
        for (final entry in _myItems) ...[
          _buildFeedbackCard(
            entry: entry,
            isAdminView: false,
            isOwner: true,
            p: p,
            l10n: l10n,
          ),
          const SizedBox(height: 12),
        ],
    ];
  }

  List<Widget> _buildAdminInboxSection(
    UserProfile currentUser,
    ZetzyPalette p,
    AppLocalizations l10n,
  ) {
    if (_loadingAdminInitial && _adminItems.isEmpty) {
      return [
        const Padding(
          padding: EdgeInsets.all(28),
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }
    if (_adminError != null && _adminItems.isEmpty) {
      return [
        TactileCard(
          child: Text(_adminError!, style: TextStyle(color: p.danger)),
        ),
      ];
    }
    if (_adminItems.isEmpty) {
      return [
        TactileCard(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Center(
              child: Text(
                l10n.feedbackEmptyInbox,
                style: TextStyle(color: p.textSecondary),
              ),
            ),
          ),
        ),
      ];
    }

    return [
      for (final entry in _adminItems) ...[
        _buildFeedbackCard(
          entry: entry,
          isAdminView: true,
          isOwner: entry.userId == currentUser.id,
          p: p,
          l10n: l10n,
        ),
        const SizedBox(height: 12),
      ],
      if (_adminHasMore)
        OutlinedButton.icon(
          onPressed: _loadingAdminMore ? null : () => _loadAdmin(reset: false),
          icon: _loadingAdminMore
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.expand_more_rounded),
          label: Text(l10n.feedbackLoadMore),
        ),
    ];
  }

  Widget _buildFeedbackCard({
    required FeedbackEntry entry,
    required bool isAdminView,
    required bool isOwner,
    required ZetzyPalette p,
    required AppLocalizations l10n,
  }) {
    final canEdit = isOwner && entry.canEdit();
    final expiryRemaining = entry.expiryRemaining();

    return TactileCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              UserAvatar(
                avatarUrl: entry.avatarUrl,
                username: entry.username,
                radius: 16,
                fontSize: 13,
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
                            '@${entry.username}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13.5,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: p.surfaceElevated,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: p.border),
                          ),
                          child: Text(
                            'v${entry.appVersion}',
                            style: ZetzyThemes.monoStyle(
                              fontSize: 10.5,
                              color: p.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatTimestamp(entry.createdAt),
                      style: TextStyle(fontSize: 11, color: p.textSecondary),
                    ),
                  ],
                ),
              ),
              _StatusBadge(status: entry.status, l10n: l10n),
            ],
          ),
          const SizedBox(height: 10),
          Text(entry.message, style: const TextStyle(fontSize: 14, height: 1.4)),
          if (entry.adminReply != null && entry.adminReply!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: p.accent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: p.accent.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.feedbackAdminReplyLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: p.accent,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    entry.adminReply!,
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (!entry.status.isResolved && isOwner)
                Text(
                  canEdit
                      ? l10n.feedbackEditWindow(
                          _formatShortDuration(entry.editRemaining()),
                        )
                      : l10n.feedbackEditLocked,
                  style: TextStyle(fontSize: 11.5, color: p.textSecondary),
                ),
              if (expiryRemaining != null)
                Text(
                  l10n.feedbackAutoDeleteNotice(
                    _formatShortDuration(expiryRemaining),
                  ),
                  style: TextStyle(fontSize: 11.5, color: p.textSecondary),
                ),
            ],
          ),
          if (isOwner || (isAdminView && !entry.status.isResolved)) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                if (isAdminView && !entry.status.isResolved) ...[
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: p.success,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => _reviewFeedback(
                        entry,
                        FeedbackStatus.approved,
                        l10n,
                      ),
                      icon: const Icon(Icons.check_rounded, size: 17),
                      label: Text(l10n.feedbackReviewActionApprove),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: p.danger,
                        side: BorderSide(color: p.danger.withValues(alpha: 0.5)),
                      ),
                      onPressed: () => _reviewFeedback(
                        entry,
                        FeedbackStatus.rejected,
                        l10n,
                      ),
                      icon: const Icon(Icons.close_rounded, size: 17),
                      label: Text(l10n.feedbackReviewActionReject),
                    ),
                  ),
                ] else if (isOwner) ...[
                  if (canEdit) ...[
                    OutlinedButton.icon(
                      onPressed: () => _editFeedback(entry, l10n),
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: Text(l10n.feedbackEditAction),
                    ),
                    const SizedBox(width: 8),
                  ],
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: p.danger,
                      side: BorderSide(color: p.danger.withValues(alpha: 0.45)),
                    ),
                    onPressed: () => _deleteFeedback(entry, l10n),
                    icon: const Icon(Icons.delete_outline_rounded, size: 16),
                    label: Text(l10n.feedbackDeleteAction),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _PrivacyNoticeBanner extends StatelessWidget {
  const _PrivacyNoticeBanner({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: p.accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: p.accent.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(Icons.lock_outline_rounded, size: 16, color: p.accent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: p.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status, required this.l10n});
  final FeedbackStatus status;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final (label, color, icon) = switch (status) {
      FeedbackStatus.pending => (
        l10n.feedbackStatusPending,
        p.warning,
        Icons.schedule_rounded,
      ),
      FeedbackStatus.approved => (
        l10n.feedbackStatusApproved,
        p.success,
        Icons.check_circle_rounded,
      ),
      FeedbackStatus.rejected => (
        l10n.feedbackStatusRejected,
        p.danger,
        Icons.cancel_rounded,
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _EditFeedbackDialog extends StatefulWidget {
  const _EditFeedbackDialog({required this.initialText});
  final String initialText;

  @override
  State<_EditFeedbackDialog> createState() => _EditFeedbackDialogState();
}

class _EditFeedbackDialogState extends State<_EditFeedbackDialog> {
  late final TextEditingController _ctrl = TextEditingController(
    text: widget.initialText,
  );
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(
        l10n.feedbackEditDialogTitle,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          child: TextField(
            controller: _ctrl,
            maxLines: 5,
            minLines: 3,
            maxLength: 1000,
            decoration: InputDecoration(
              hintText: l10n.feedbackPlaceholder,
              errorText: _error,
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () {
            final val = _ctrl.text.trim();
            if (val.length < 3) {
              setState(() => _error = 'Min 3 characters');
              return;
            }
            Navigator.of(context).pop(val);
          },
          child: Text(l10n.save),
        ),
      ],
    );
  }
}

class _ReviewFeedbackDialog extends StatefulWidget {
  const _ReviewFeedbackDialog({
    required this.entry,
    required this.initialDecision,
  });

  final FeedbackEntry entry;
  final FeedbackStatus initialDecision;

  @override
  State<_ReviewFeedbackDialog> createState() => _ReviewFeedbackDialogState();
}

class _ReviewFeedbackDialogState extends State<_ReviewFeedbackDialog> {
  final TextEditingController _replyCtrl = TextEditingController();
  late FeedbackStatus _decision = widget.initialDecision;

  @override
  void dispose() {
    _replyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final p = context.palette;
    return AlertDialog(
      title: Text(
        l10n.feedbackReviewDialogTitle,
        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '@${widget.entry.username} • v${widget.entry.appVersion}',
                style: ZetzyThemes.monoStyle(fontSize: 12, color: p.accent),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: p.surfaceElevated,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: p.border),
                ),
                child: Text(
                  widget.entry.message,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              const SizedBox(height: 12),
              SegmentedButton<FeedbackStatus>(
                expandedInsets: EdgeInsets.zero,
                selected: {_decision},
                onSelectionChanged: (sel) =>
                    setState(() => _decision = sel.first),
                segments: [
                  ButtonSegment(
                    value: FeedbackStatus.approved,
                    icon: const Icon(Icons.check_rounded, size: 16),
                    label: Text(l10n.feedbackReviewActionApprove),
                  ),
                  ButtonSegment(
                    value: FeedbackStatus.rejected,
                    icon: const Icon(Icons.close_rounded, size: 16),
                    label: Text(l10n.feedbackReviewActionReject),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _replyCtrl,
                maxLines: 3,
                minLines: 2,
                maxLength: 500,
                decoration: InputDecoration(
                  labelText: l10n.feedbackAdminReplyLabel,
                  hintText: l10n.feedbackReviewReplyHint,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: _decision == FeedbackStatus.approved
                ? p.success
                : p.danger,
            foregroundColor: Colors.white,
          ),
          onPressed: () => Navigator.of(context).pop((
            decision: _decision,
            reply: _replyCtrl.text.trim(),
          )),
          child: Text(l10n.confirm),
        ),
      ],
    );
  }
}
