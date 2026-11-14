import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zetzy/providers/app_providers.dart';

/// Automatically pauses active games on background/focus loss and manages wakelock.
class GameLifecycleGuard extends ConsumerStatefulWidget {
  const GameLifecycleGuard({
    super.key,
    required this.onAutoPause,
    required this.child,
  });

  final VoidCallback onAutoPause;
  final Widget child;

  @override
  ConsumerState<GameLifecycleGuard> createState() => _GameLifecycleGuardState();
}

class _GameLifecycleGuardState extends ConsumerState<GameLifecycleGuard>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future.microtask(
      () => ref.read(wakelockServiceProvider).enableIfAllowed(),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      widget.onAutoPause();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ref.read(wakelockServiceProvider).disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
