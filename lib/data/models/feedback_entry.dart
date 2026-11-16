/// Moderation state for a player feedback entry.
enum FeedbackStatus {
  pending('pending'),
  approved('approved'),
  rejected('rejected');

  const FeedbackStatus(this.id);
  final String id;

  bool get isResolved => this != FeedbackStatus.pending;

  static FeedbackStatus fromId(String? raw) => FeedbackStatus.values.firstWhere(
    (s) => s.id == raw,
    orElse: () => FeedbackStatus.pending,
  );
}

/// Player feedback record stored in Supabase `public.feedbacks` and readable
/// strictly by the authoring player and admins.
class FeedbackEntry {
  const FeedbackEntry({
    required this.id,
    required this.userId,
    required this.username,
    this.avatarUrl,
    required this.message,
    required this.appVersion,
    this.status = FeedbackStatus.pending,
    this.adminReply,
    this.reviewedBy,
    this.reviewedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  static const int maxPendingPerUser = 5;
  static const Duration editWindow = Duration(hours: 6);
  static const Duration resolvedRetention = Duration(days: 3);

  final String id;
  final String userId;
  final String username;
  final String? avatarUrl;
  final String message;
  final String appVersion;
  final FeedbackStatus status;
  final String? adminReply;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Players can edit their own pending feedback strictly within 6 hours of creation.
  bool canEdit({DateTime? now}) {
    if (status.isResolved) return false;
    final current = (now ?? DateTime.now()).toUtc();
    return current.difference(createdAt.toUtc()) < editWindow;
  }

  /// Remaining edit window before editing locks (zero if locked/resolved).
  Duration editRemaining({DateTime? now}) {
    if (status.isResolved) return Duration.zero;
    final current = (now ?? DateTime.now()).toUtc();
    final remaining = editWindow - current.difference(createdAt.toUtc());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Remaining time before an approved/rejected feedback is auto-purged (3 days).
  Duration? expiryRemaining({DateTime? now}) {
    final reviewed = reviewedAt;
    if (!status.isResolved || reviewed == null) return null;
    final current = (now ?? DateTime.now()).toUtc();
    final remaining = resolvedRetention - current.difference(reviewed.toUtc());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  bool isExpired({DateTime? now}) {
    final rem = expiryRemaining(now: now);
    return rem != null && rem == Duration.zero;
  }

  FeedbackEntry copyWith({
    String? message,
    FeedbackStatus? status,
    String? adminReply,
    String? reviewedBy,
    DateTime? reviewedAt,
    DateTime? updatedAt,
  }) {
    return FeedbackEntry(
      id: id,
      userId: userId,
      username: username,
      avatarUrl: avatarUrl,
      message: message ?? this.message,
      appVersion: appVersion,
      status: status ?? this.status,
      adminReply: adminReply ?? this.adminReply,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory FeedbackEntry.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>?;
    final createdRaw = json['created_at']?.toString();
    final updatedRaw = json['updated_at']?.toString();
    final reviewedRaw = json['reviewed_at']?.toString();
    final created = createdRaw != null
        ? DateTime.parse(createdRaw).toUtc()
        : DateTime.now().toUtc();

    return FeedbackEntry(
      id: json['id'].toString(),
      userId: (json['user_id'] ?? '').toString(),
      username:
          (profile?['username'] ?? json['username'] ?? 'player').toString(),
      avatarUrl: (profile?['avatar_url'] ?? json['avatar_url']) as String?,
      message: (json['message'] ?? '').toString(),
      appVersion: (json['app_version'] ?? '0.0.0').toString(),
      status: FeedbackStatus.fromId(json['status']?.toString()),
      adminReply: json['admin_reply'] as String?,
      reviewedBy: json['reviewed_by']?.toString(),
      reviewedAt: reviewedRaw != null ? DateTime.parse(reviewedRaw).toUtc() : null,
      createdAt: created,
      updatedAt: updatedRaw != null
          ? DateTime.parse(updatedRaw).toUtc()
          : created,
    );
  }
}
