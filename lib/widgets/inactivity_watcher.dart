import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../main.dart';

class InactivityWatcher extends StatefulWidget {
  final Duration timeout;
  final Duration warningTime;
  final Future<void> Function() onTimeout;
  final Widget child;

  const InactivityWatcher({
    super.key,
    required this.timeout,
    required this.warningTime,
    required this.onTimeout,
    required this.child,
  });

  @override
  State<InactivityWatcher> createState() => _InactivityWatcherState();
}

class _InactivityWatcherState extends State<InactivityWatcher> {
  Timer? _timer;
  bool _isWarningShown = false;

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_onKey);
    _restart();
  }

  bool _onKey(KeyEvent event) {
    _restart();
    return false;
  }

  void _restart() {
    if (_isWarningShown) return;
    _timer?.cancel();
    final warningDelay = widget.timeout - widget.warningTime;
    _timer = Timer(warningDelay, _showWarning);
  }

  void _showWarning() {
    if (!mounted) return;
    _isWarningShown = true;
    rootNavigatorKey.currentState?.push(
      DialogRoute(
        context: rootNavigatorKey.currentContext!,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('Вы всё еще здесь?'),
          content: Text('Ваша сессия будет завершена через ${widget.warningTime.inSeconds} секунд из-за неактивности.'),
          actions: [
            FilledButton(
              onPressed: () {
                rootNavigatorKey.currentState?.pop();
                _isWarningShown = false;
                _restart();
              },
              child: const Text('Продолжить работу'),
            ),
          ],
        ),
      ),
    );

    _timer = Timer(widget.warningTime, () async {
      if (mounted) {
        if (rootNavigatorKey.currentState?.canPop() == true) {
          rootNavigatorKey.currentState?.pop();
        }
        await widget.onTimeout();
      }
    });
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _restart(),
      onPointerMove: (_) => _restart(),
      onPointerSignal: (_) => _restart(),
      child: widget.child,
    );
  }
}