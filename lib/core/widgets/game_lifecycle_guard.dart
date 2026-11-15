import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zetzy/core/services/wakelock_service.dart';
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
  late final WakelockService _wakelock;

  @override
  void initState() {
    super.initState();
    _wakelock = ref.read(wakelockServiceProvider);
    WidgetsBinding.instance.addObserver(this);
    Future.microtask(() {
      if (mounted) _wakelock.enableIfAllowed();
    });
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
    _wakelock.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
