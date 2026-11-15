import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zetzy/core/constants/app_constants.dart';
import 'package:zetzy/core/services/avatar_picker_service.dart';
import 'package:zetzy/core/theme/zetzy_theme.dart';
import 'package:zetzy/core/widgets/tactile_card.dart';
import 'package:zetzy/l10n/app_localizations.dart';
import 'package:zetzy/providers/app_providers.dart';

String _formatAuthError(Object error) {
  if (error is AuthException) return error.message;
  if (error is PostgrestException) return error.message;
  if (error is StorageException) return error.message;
  if (error is ArgumentError) return '${error.message}';
  if (error is StateError) return error.message;
  return error.toString();
}

InputDecoration _dialogInputDecoration({
  required String label,
  String? helperText,
  Widget? suffixIcon,
}) => InputDecoration(
  labelText: label,
  helperText: helperText,
  helperMaxLines: 2,
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
  suffixIcon: suffixIcon,
);

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _uploadingAvatar = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_recoverLostAndroidAvatar);
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _recoverLostAndroidAvatar() async {
    try {
      final bytes = await ref
          .read(avatarPickerServiceProvider)
          .retrieveLostAndroidBytes();
      if (!mounted || bytes == null || ref.read(authProvider).isGuest) return;
      await _uploadAvatarBytes(bytes);
    } catch (e) {
      _showSnack(_formatAuthError(e));
    }
  }

  Future<void> _handleAvatarTap(AppLocalizations l10n) async {
    if (_uploadingAvatar) return;
    if (ref.read(authProvider).isGuest) {
      _showSnack(l10n.profileAvatarSignInRequired);
      return;
    }

    final picker = ref.read(avatarPickerServiceProvider);
    if (!picker.supportsCameraChoice) {
      await _pickAndUploadFromSource(AvatarPickSource.gallery, l10n);
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(l10n.profileAvatarSourceGallery),
              onTap: () {
                Navigator.of(sheetCtx).pop();
                _pickAndUploadFromSource(AvatarPickSource.gallery, l10n);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(l10n.profileAvatarSourceCamera),
              onTap: () {
                Navigator.of(sheetCtx).pop();
                _pickAndUploadFromSource(AvatarPickSource.camera, l10n);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUploadFromSource(
    AvatarPickSource source,
    AppLocalizations l10n,
  ) async {
    try {
      final bytes = await ref
          .read(avatarPickerServiceProvider)
          .pickImageBytes(source: source);
      if (bytes == null || !mounted) return;
      await _uploadAvatarBytes(bytes, successMessage: l10n.profileAvatarUpdated);
    } catch (e) {
      _showSnack(_formatAuthError(e));
    }
  }

  Future<void> _uploadAvatarBytes(
    Uint8List bytes, {
    String? successMessage,
  }) async {
    setState(() => _uploadingAvatar = true);
    try {
      await ref.read(authProvider.notifier).uploadAvatar(bytes);
      if (successMessage != null) {
        _showSnack(successMessage);
      }
    } catch (e) {
      _showSnack(_formatAuthError(e));
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  void _showAuthSheet({required bool isRegister}) {
    showDialog<void>(
      context: context,
      builder: (_) => _AuthDialog(
        isRegister: isRegister,
        onOpenForgotPassword: _showForgotPasswordDialog,
      ),
    );
  }

  void _showForgotPasswordDialog() {
    showDialog<void>(
      context: context,
      builder: (_) => const _ForgotPasswordDialog(),
    );
  }

  void _showChangeUsernameDialog() {
    showDialog<void>(
      context: context,
      builder: (_) => _ChangeUsernameDialog(
        initialUsername: ref.read(authProvider).username,
      ),
    );
  }

  void _showChangePasswordDialog() {
    showDialog<void>(
      context: context,
      builder: (_) => const _ChangePasswordDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(authProvider);
    final settings = ref.watch(settingsProvider);
    final settingsCtrl = ref.read(settingsProvider.notifier);
    final supa = ref.watch(supabaseServiceProvider);
    final hasAudio = ref.watch(audioServiceProvider).hasAudioAssets;

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                l10n.navProfile,
                style: Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 14),
              // Account Card
              TactileCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        InkWell(
                          borderRadius: BorderRadius.circular(32),
                          onTap: _uploadingAvatar
                              ? null
                              : () => _handleAvatarTap(l10n),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CircleAvatar(
                                radius: 28,
                                backgroundColor: p.surfaceElevated,
                                backgroundImage: user.avatarUrl != null
                                    ? NetworkImage(user.avatarUrl!)
                                    : null,
                                onBackgroundImageError: user.avatarUrl != null
                                    ? (_, _) {}
                                    : null,
                                child: user.avatarUrl == null
                                    ? Text(
                                        user.username
                                            .substring(0, 1)
                                            .toUpperCase(),
                                        style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      )
                                    : null,
                              ),
                              if (_uploadingAvatar)
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  padding: const EdgeInsets.all(16),
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              else if (!user.isGuest)
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: p.accent,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: p.surface,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.camera_alt_rounded,
                                      size: 11,
                                      color: p.surface,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.isGuest
                                    ? l10n.profileGuest
                                    : '@${user.username}',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              Text(
                                'Chess ELO: ${user.chessElo}',
                                style: ZetzyThemes.monoStyle(
                                  fontSize: 13,
                                  color: p.accent,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!user.isGuest)
                          IconButton(
                            tooltip: l10n.profileUploadAvatar,
                            onPressed: _uploadingAvatar
                                ? null
                                : () => _handleAvatarTap(l10n),
                            icon: _uploadingAvatar
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.camera_alt_outlined),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (user.isGuest) ...[
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton(
                              onPressed: supa.isAvailable
                                  ? () => _showAuthSheet(isRegister: false)
                                  : null,
                              child: Text(l10n.profileSignIn),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: supa.isAvailable
                                  ? () => _showAuthSheet(isRegister: true)
                                  : null,
                              child: Text(l10n.profileRegister),
                            ),
                          ),
                        ],
                      ),
                      if (!supa.isAvailable) ...[
                        const SizedBox(height: 8),
                        Text(
                          l10n.settingsSupabaseLocalOnly,
                          style: TextStyle(
                            fontSize: 12,
                            color: p.textSecondary,
                          ),
                        ),
                      ],
                    ] else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OutlinedButton(
                            onPressed: _showChangeUsernameDialog,
                            child: Text(l10n.profileChangeUsername),
                          ),
                          OutlinedButton(
                            onPressed: _showChangePasswordDialog,
                            child: Text(l10n.profileChangePassword),
                          ),
                          OutlinedButton(
                            onPressed: () =>
                                ref.read(authProvider.notifier).signOut(),
                            child: Text(l10n.profileSignOut),
                          ),
                        ],
                      ),
                    if (!user.isGuest) ...[
                      const Divider(height: 22),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        value: user.hasRecoveryCode,
                        title: Text(l10n.profileRecoveryToggle),
                        subtitle: Text(
                          l10n.profileRecoveryDesc,
                          style: TextStyle(
                            fontSize: 12,
                            color: p.textSecondary,
                          ),
                        ),
                        onChanged: (enabled) async {
                          if (!enabled) {
                            await ref
                                .read(authProvider.notifier)
                                .setRecoveryPhrase(null);
                            return;
                          }
                          final ctrl = TextEditingController();
                          final phrase = await showDialog<String>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: Text(l10n.profileRecoveryPhrase),
                              content: TextField(controller: ctrl),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: Text(l10n.cancel),
                                ),
                                FilledButton(
                                  onPressed: () =>
                                      Navigator.pop(ctx, ctrl.text.trim()),
                                  child: Text(l10n.save),
                                ),
                              ],
                            ),
                          );
                          if (phrase != null && phrase.isNotEmpty) {
                            await ref
                                .read(authProvider.notifier)
                                .setRecoveryPhrase(phrase);
                          }
                        },
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),
              // Appearance & Language
              TactileCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.settingsAppearance,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      l10n.settingsTheme,
                      style: TextStyle(fontSize: 12, color: p.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final mode in ZetzyThemeMode.values)
                          ChoiceChip(
                            selected: settings.themeMode == mode,
                            onSelected: (_) => settingsCtrl.setTheme(mode),
                            label: Text(mode.localizedName(l10n)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(l10n.settingsLanguage),
                        SegmentedButton<String>(
                          selected: {settings.localeCode},
                          onSelectionChanged: (s) =>
                              settingsCtrl.setLocale(s.first),
                          segments: const [
                            ButtonSegment(value: 'en', label: Text('English')),
                            ButtonSegment(
                              value: 'id',
                              label: Text('Indonesia'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              // Gameplay & Controls
              TactileCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.settingsGameplay,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      value: settings.sfxEnabled,
                      onChanged: settingsCtrl.setSfx,
                      title: Text(l10n.settingsAudioSfx),
                      subtitle: hasAudio
                          ? null
                          : Text(
                              l10n.settingsAudioPending,
                              style: TextStyle(
                                fontSize: 11,
                                color: p.textSecondary,
                              ),
                            ),
                    ),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      value: settings.bgmEnabled,
                      onChanged: settingsCtrl.setBgm,
                      title: Text(l10n.settingsAudioBgm),
                    ),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      value: settings.hapticsEnabled,
                      onChanged: settingsCtrl.setHaptics,
                      title: Text(l10n.settingsHaptics),
                    ),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      value: settings.wakelockEnabled,
                      onChanged: settingsCtrl.setWakelock,
                      title: Text(l10n.settingsWakelock),
                    ),
                    const Divider(),
                    Text(
                      l10n.settingsSnakeControl,
                      style: TextStyle(fontSize: 12, color: p.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    SegmentedButton<SnakeControlMode>(
                      selected: {settings.snakeControlMode},
                      onSelectionChanged: (s) =>
                          settingsCtrl.setSnakeControl(s.first),
                      segments: [
                        ButtonSegment(
                          value: SnakeControlMode.swipe,
                          label: Text(l10n.settingsSnakeSwipe),
                        ),
                        ButtonSegment(
                          value: SnakeControlMode.dpad,
                          label: Text(l10n.settingsSnakeDpad),
                        ),
                        ButtonSegment(
                          value: SnakeControlMode.splitTap,
                          label: Text(l10n.settingsSnakeSplit),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      l10n.settingsChessPieces,
                      style: TextStyle(fontSize: 12, color: p.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final set in ChessPieceSet.values)
                          ChoiceChip(
                            selected: settings.chessPieceSet == set,
                            onSelected: (_) =>
                                settingsCtrl.setChessPieceSet(set),
                            label: Text(set.label),
                          ),
                      ],
                    ),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      value: settings.chessAutoQueen,
                      onChanged: settingsCtrl.setChessAutoQueen,
                      title: Text(l10n.settingsChessAutoQueen),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              // Cloud & Danger Zone
              TactileCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.settingsCloudStatus,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      supa.isAvailable
                          ? l10n.settingsSupabaseConfigured
                          : l10n.settingsSupabaseLocalOnly,
                      style: TextStyle(
                        color: supa.isAvailable ? p.success : p.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const Divider(height: 24),
                    Text(
                      l10n.profileDangerZone,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: p.danger,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        OutlinedButton(
                          onPressed: () =>
                              ref.read(authProvider.notifier).resetAllStats(),
                          child: Text(l10n.profileResetStats),
                        ),
                        if (!user.isGuest)
                          FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: p.danger,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () =>
                                ref.read(authProvider.notifier).deleteAccount(),
                            child: Text(l10n.profileDeleteAccount),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DialogErrorBanner extends StatelessWidget {
  const _DialogErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final danger = context.palette.danger;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: danger.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: danger.withValues(alpha: 0.4)),
      ),
      child: Text(message, style: TextStyle(color: danger, fontSize: 12.5)),
    );
  }
}

class _AuthDialog extends ConsumerStatefulWidget {
  const _AuthDialog({
    required this.isRegister,
    required this.onOpenForgotPassword,
  });

  final bool isRegister;
  final VoidCallback onOpenForgotPassword;

  @override
  ConsumerState<_AuthDialog> createState() => _AuthDialogState();
}

class _AuthDialogState extends ConsumerState<_AuthDialog> {
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _recoveryCtrl = TextEditingController();

  String? _errorMsg;
  bool _loading = false;
  bool _obscurePass = true;

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    _recoveryCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit(AppLocalizations l10n) async {
    final u = _userCtrl.text.trim();
    final pw = _passCtrl.text;

    if (!ValidationRules.isValidUsername(u)) {
      setState(() => _errorMsg = l10n.invalidUsername);
      return;
    }
    if (!ValidationRules.isValidPassword(pw)) {
      setState(() => _errorMsg = l10n.invalidPassword);
      return;
    }

    setState(() {
      _loading = true;
      _errorMsg = null;
    });

    try {
      if (widget.isRegister) {
        await ref
            .read(authProvider.notifier)
            .register(
              username: u,
              password: pw,
              recoveryPhrase: _recoveryCtrl.text.trim(),
            );
      } else {
        await ref.read(authProvider.notifier).signIn(u, pw);
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMsg = _formatAuthError(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final p = context.palette;

    return PopScope(
      canPop: !_loading,
      child: AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        title: Text(
          widget.isRegister ? l10n.profileRegister : l10n.profileSignIn,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        content: SizedBox(
          width: 440,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.requiredHint,
                  style: TextStyle(fontSize: 12, color: p.textSecondary),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _userCtrl,
                  enabled: !_loading,
                  textInputAction: TextInputAction.next,
                  decoration: _dialogInputDecoration(
                    label: '${l10n.profileUsername} *',
                    helperText: l10n.invalidUsername,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _passCtrl,
                  enabled: !_loading,
                  obscureText: _obscurePass,
                  textInputAction: widget.isRegister
                      ? TextInputAction.next
                      : TextInputAction.done,
                  onSubmitted: widget.isRegister ? null : (_) => _submit(l10n),
                  decoration: _dialogInputDecoration(
                    label: '${l10n.profilePassword} *',
                    helperText: l10n.invalidPassword,
                    suffixIcon: IconButton(
                      onPressed: () =>
                          setState(() => _obscurePass = !_obscurePass),
                      icon: Icon(
                        _obscurePass
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
                ),
                if (widget.isRegister) ...[
                  const SizedBox(height: 14),
                  TextField(
                    controller: _recoveryCtrl,
                    enabled: !_loading,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _submit(l10n),
                    decoration: _dialogInputDecoration(
                      label:
                          '${l10n.profileRecoveryPhrase} (${l10n.optionalLabel})',
                      helperText: l10n.profileRecoveryDesc,
                    ),
                  ),
                ],
                if (_errorMsg != null) ...[
                  const SizedBox(height: 14),
                  _DialogErrorBanner(message: _errorMsg!),
                ],
              ],
            ),
          ),
        ),
        actions: [
          if (!widget.isRegister)
            TextButton(
              onPressed: _loading
                  ? null
                  : () {
                      Navigator.of(context).pop();
                      widget.onOpenForgotPassword();
                    },
              child: Text(l10n.profileForgotPassword),
            ),
          TextButton(
            onPressed: _loading ? null : () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: _loading ? null : () => _submit(l10n),
            child: _loading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    widget.isRegister
                        ? l10n.profileRegister
                        : l10n.profileSignIn,
                  ),
          ),
        ],
      ),
    );
  }
}

class _ForgotPasswordDialog extends ConsumerStatefulWidget {
  const _ForgotPasswordDialog();

  @override
  ConsumerState<_ForgotPasswordDialog> createState() =>
      _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends ConsumerState<_ForgotPasswordDialog> {
  final _userCtrl = TextEditingController();
  final _phraseCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();

  String? _msg;
  bool _loading = false;

  @override
  void dispose() {
    _userCtrl.dispose();
    _phraseCtrl.dispose();
    _newPassCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return PopScope(
      canPop: !_loading,
      child: AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        title: Text(
          l10n.profileForgotPassword,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        content: SizedBox(
          width: 440,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.requiredHint,
                  style: TextStyle(
                    fontSize: 12,
                    color: context.palette.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _userCtrl,
                  enabled: !_loading,
                  decoration: _dialogInputDecoration(
                    label: '${l10n.profileUsername} *',
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _phraseCtrl,
                  enabled: !_loading,
                  decoration: _dialogInputDecoration(
                    label: '${l10n.profileRecoveryPhrase} *',
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _newPassCtrl,
                  enabled: !_loading,
                  obscureText: true,
                  decoration: _dialogInputDecoration(
                    label: '${l10n.profileNewPassword} *',
                    helperText: l10n.invalidPassword,
                  ),
                ),
                if (_msg != null) ...[
                  const SizedBox(height: 14),
                  _DialogErrorBanner(message: _msg!),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _loading ? null : () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: _loading
                ? null
                : () async {
                    if (!ValidationRules.isValidPassword(_newPassCtrl.text)) {
                      setState(() => _msg = l10n.invalidPassword);
                      return;
                    }
                    setState(() {
                      _loading = true;
                      _msg = null;
                    });
                    try {
                      final ok = await ref
                          .read(supabaseServiceProvider)
                          .resetPasswordWithRecovery(
                            username: _userCtrl.text.trim(),
                            recoveryPhrase: _phraseCtrl.text.trim(),
                            newPassword: _newPassCtrl.text,
                          );
                      if (!context.mounted) return;
                      if (ok) {
                        Navigator.of(context).pop();
                      } else {
                        setState(() {
                          _loading = false;
                          _msg = 'Invalid username or phrase';
                        });
                      }
                    } catch (e) {
                      if (!mounted) return;
                      setState(() {
                        _loading = false;
                        _msg = _formatAuthError(e);
                      });
                    }
                  },
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );
  }
}

class _ChangeUsernameDialog extends ConsumerStatefulWidget {
  const _ChangeUsernameDialog({required this.initialUsername});

  final String initialUsername;

  @override
  ConsumerState<_ChangeUsernameDialog> createState() =>
      _ChangeUsernameDialogState();
}

class _ChangeUsernameDialogState extends ConsumerState<_ChangeUsernameDialog> {
  late final TextEditingController _ctrl;
  String? _err;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialUsername);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return PopScope(
      canPop: !_loading,
      child: AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        title: Text(
          l10n.profileChangeUsername,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _ctrl,
                  enabled: !_loading,
                  decoration: _dialogInputDecoration(
                    label: '${l10n.profileUsername} *',
                    helperText: l10n.invalidUsername,
                  ),
                ),
                if (_err != null) ...[
                  const SizedBox(height: 14),
                  _DialogErrorBanner(message: _err!),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _loading ? null : () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: _loading
                ? null
                : () async {
                    final v = _ctrl.text.trim();
                    if (!ValidationRules.isValidUsername(v)) {
                      setState(() => _err = l10n.invalidUsername);
                      return;
                    }
                    setState(() {
                      _loading = true;
                      _err = null;
                    });
                    try {
                      await ref.read(authProvider.notifier).updateUsername(v);
                      if (context.mounted) Navigator.of(context).pop();
                    } catch (e) {
                      if (!mounted) return;
                      setState(() {
                        _loading = false;
                        _err = _formatAuthError(e);
                      });
                    }
                  },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }
}

class _ChangePasswordDialog extends ConsumerStatefulWidget {
  const _ChangePasswordDialog();

  @override
  ConsumerState<_ChangePasswordDialog> createState() =>
      _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends ConsumerState<_ChangePasswordDialog> {
  final _oldCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  String? _err;
  bool _loading = false;

  @override
  void dispose() {
    _oldCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return PopScope(
      canPop: !_loading,
      child: AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        title: Text(
          l10n.profileChangePassword,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        content: SizedBox(
          width: 440,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _oldCtrl,
                  enabled: !_loading,
                  obscureText: true,
                  decoration: _dialogInputDecoration(
                    label: '${l10n.profileOldPassword} *',
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _newCtrl,
                  enabled: !_loading,
                  obscureText: true,
                  decoration: _dialogInputDecoration(
                    label: '${l10n.profileNewPassword} *',
                    helperText: l10n.invalidPassword,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _confirmCtrl,
                  enabled: !_loading,
                  obscureText: true,
                  decoration: _dialogInputDecoration(
                    label: '${l10n.profileConfirmPassword} *',
                  ),
                ),
                if (_err != null) ...[
                  const SizedBox(height: 14),
                  _DialogErrorBanner(message: _err!),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _loading ? null : () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: _loading
                ? null
                : () async {
                    if (_newCtrl.text != _confirmCtrl.text) {
                      setState(() => _err = 'Passwords do not match');
                      return;
                    }
                    if (!ValidationRules.isValidPassword(_newCtrl.text)) {
                      setState(() => _err = l10n.invalidPassword);
                      return;
                    }
                    setState(() {
                      _loading = true;
                      _err = null;
                    });
                    try {
                      await ref
                          .read(authProvider.notifier)
                          .changePassword(
                            oldPassword: _oldCtrl.text,
                            newPassword: _newCtrl.text,
                          );
                      if (context.mounted) Navigator.of(context).pop();
                    } catch (e) {
                      if (!mounted) return;
                      setState(() {
                        _loading = false;
                        _err = _formatAuthError(e);
                      });
                    }
                  },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }
}
