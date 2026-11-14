import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:zetzy/core/constants/app_constants.dart';
import 'package:zetzy/core/constants/supabase_schema.dart';
import 'package:zetzy/core/theme/zetzy_theme.dart';
import 'package:zetzy/core/widgets/tactile_card.dart';
import 'package:zetzy/l10n/app_localizations.dart';
import 'package:zetzy/providers/app_providers.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  Future<void> _pickAndUploadAvatar(AppLocalizations l10n) async {
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(source: ImageSource.gallery);
      if (file == null) return;
      final bytes = await file.readAsBytes();
      await ref.read(authProvider.notifier).uploadAvatar(bytes);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  void _showAuthSheet({required bool isRegister}) {
    final userCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final recoveryCtrl = TextEditingController();
    final l10n = AppLocalizations.of(context)!;
    String? errorMsg;
    var loading = false;

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(isRegister ? l10n.profileRegister : l10n.profileSignIn),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: userCtrl,
                  decoration: InputDecoration(labelText: l10n.profileUsername),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: passCtrl,
                  obscureText: true,
                  decoration: InputDecoration(labelText: l10n.profilePassword),
                ),
                if (isRegister) ...[
                  const SizedBox(height: 10),
                  TextField(
                    controller: recoveryCtrl,
                    decoration: InputDecoration(
                      labelText: '${l10n.profileRecoveryPhrase} (Optional)',
                    ),
                  ),
                ],
                if (errorMsg != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    errorMsg!,
                    style: TextStyle(color: context.palette.danger, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            if (!isRegister)
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _showForgotPasswordDialog();
                },
                child: Text(l10n.profileForgotPassword),
              ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: loading
                  ? null
                  : () async {
                      final u = userCtrl.text.trim();
                      final pw = passCtrl.text;
                      if (!ValidationRules.isValidUsername(u)) {
                        setDialogState(() => errorMsg = l10n.invalidUsername);
                        return;
                      }
                      if (!ValidationRules.isValidPassword(pw)) {
                        setDialogState(() => errorMsg = l10n.invalidPassword);
                        return;
                      }
                      setDialogState(() {
                        loading = true;
                        errorMsg = null;
                      });
                      try {
                        if (isRegister) {
                          await ref.read(authProvider.notifier).register(
                                username: u,
                                password: pw,
                                recoveryPhrase: recoveryCtrl.text.trim(),
                              );
                        } else {
                          await ref.read(authProvider.notifier).signIn(u, pw);
                        }
                        if (ctx.mounted) Navigator.pop(ctx);
                      } catch (e) {
                        setDialogState(() {
                          loading = false;
                          errorMsg = e.toString();
                        });
                      }
                    },
              child: loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(isRegister ? l10n.profileRegister : l10n.profileSignIn),
            ),
          ],
        ),
      ),
    );
  }

  void _showForgotPasswordDialog() {
    final userCtrl = TextEditingController();
    final phraseCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    final l10n = AppLocalizations.of(context)!;
    String? msg;

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(l10n.profileForgotPassword),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: userCtrl,
                decoration: InputDecoration(labelText: l10n.profileUsername),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: phraseCtrl,
                decoration: InputDecoration(
                  labelText: l10n.profileRecoveryPhrase,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: newPassCtrl,
                obscureText: true,
                decoration: InputDecoration(labelText: l10n.profileNewPassword),
              ),
              if (msg != null) ...[
                const SizedBox(height: 8),
                Text(msg!, style: const TextStyle(fontSize: 12)),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () async {
                if (!ValidationRules.isValidPassword(newPassCtrl.text)) {
                  setDialogState(() => msg = l10n.invalidPassword);
                  return;
                }
                try {
                  final ok = await ref
                      .read(supabaseServiceProvider)
                      .resetPasswordWithRecovery(
                        username: userCtrl.text.trim(),
                        recoveryPhrase: phraseCtrl.text.trim(),
                        newPassword: newPassCtrl.text,
                      );
                  if (ok && ctx.mounted) {
                    Navigator.pop(ctx);
                  } else {
                    setDialogState(() => msg = 'Invalid username or phrase');
                  }
                } catch (e) {
                  setDialogState(() => msg = '$e');
                }
              },
              child: Text(l10n.confirm),
            ),
          ],
        ),
      ),
    );
  }

  void _showChangeUsernameDialog() {
    final ctrl = TextEditingController(text: ref.read(authProvider).username);
    final l10n = AppLocalizations.of(context)!;
    String? err;

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(l10n.profileChangeUsername),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: ctrl,
                decoration: InputDecoration(labelText: l10n.profileUsername),
              ),
              if (err != null) ...[
                const SizedBox(height: 8),
                Text(err!, style: TextStyle(color: context.palette.danger, fontSize: 12)),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () async {
                final v = ctrl.text.trim();
                if (!ValidationRules.isValidUsername(v)) {
                  setDialogState(() => err = l10n.invalidUsername);
                  return;
                }
                try {
                  await ref.read(authProvider.notifier).updateUsername(v);
                  if (ctx.mounted) Navigator.pop(ctx);
                } catch (e) {
                  setDialogState(() => err = '$e');
                }
              },
              child: Text(l10n.save),
            ),
          ],
        ),
      ),
    );
  }

  void _showChangePasswordDialog() {
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    final l10n = AppLocalizations.of(context)!;
    String? err;

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(l10n.profileChangePassword),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: oldCtrl,
                obscureText: true,
                decoration: InputDecoration(labelText: l10n.profileOldPassword),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: newCtrl,
                obscureText: true,
                decoration: InputDecoration(labelText: l10n.profileNewPassword),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: confirmCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: l10n.profileConfirmPassword,
                ),
              ),
              if (err != null) ...[
                const SizedBox(height: 8),
                Text(err!, style: TextStyle(color: context.palette.danger, fontSize: 12)),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () async {
                if (newCtrl.text != confirmCtrl.text) {
                  setDialogState(() => err = 'Passwords do not match');
                  return;
                }
                if (!ValidationRules.isValidPassword(newCtrl.text)) {
                  setDialogState(() => err = l10n.invalidPassword);
                  return;
                }
                try {
                  await ref.read(authProvider.notifier).changePassword(
                        oldPassword: oldCtrl.text,
                        newPassword: newCtrl.text,
                      );
                  if (ctx.mounted) Navigator.pop(ctx);
                } catch (e) {
                  setDialogState(() => err = '$e');
                }
              },
              child: Text(l10n.save),
            ),
          ],
        ),
      ),
    );
  }

  void _showSqlSchemaDialog(AppLocalizations l10n) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.settingsViewSql),
        content: SizedBox(
          width: 560,
          height: 360,
          child: SingleChildScrollView(
            child: SelectableText(
              SupabaseConfig.sqlSetupGuide,
              style: ZetzyThemes.monoStyle(fontSize: 11),
            ),
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Clipboard.setData(
                const ClipboardData(text: SupabaseConfig.sqlSetupGuide),
              );
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(l10n.copied)));
            },
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: const Text('Copy SQL'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.close),
          ),
        ],
      ),
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
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              // Account Card
              TactileCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: p.surfaceElevated,
                          backgroundImage: user.avatarUrl != null
                              ? NetworkImage(user.avatarUrl!)
                              : null,
                          child: user.avatarUrl == null
                              ? Text(
                                  user.username.substring(0, 1).toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                  ),
                                )
                              : null,
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
                            onPressed: () => _pickAndUploadAvatar(l10n),
                            icon: const Icon(Icons.camera_alt_outlined),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (user.isGuest)
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
                      )
                    else
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
                          style: TextStyle(fontSize: 12, color: p.textSecondary),
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
                            ButtonSegment(value: 'id', label: Text('Indonesia')),
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
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: () => _showSqlSchemaDialog(l10n),
                      icon: const Icon(Icons.storage_rounded, size: 18),
                      label: Text(l10n.settingsViewSql),
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
