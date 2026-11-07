import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/config.dart';
import 'core/session.dart';
import 'core/theme.dart';
import 'features/auth/phone_screen.dart';
import 'features/consent/consent_screen.dart';
import 'features/home/home_shell.dart';
import 'widgets/brand.dart';

class MedLinkApp extends StatelessWidget {
  const MedLinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MedLink',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: const _IdleGuard(child: _Root()),
    );
  }
}

class _Root extends StatelessWidget {
  const _Root();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<Session>();
    if (s.loading) return const SplashScreen();
    if (!s.loggedIn) return const PhoneScreen();
    if (s.needsConsent) return const ConsentScreen(initial: true);
    return const HomeShell();
  }
}

/// Faol bo'lmaslik vaqti tugasa yoki ilova uzoq vaqt fonda qolsa —
/// sessiya yopiladi (HIPAA §164.312(a)(2)(iii) "Automatic logoff").
class _IdleGuard extends StatefulWidget {
  const _IdleGuard({required this.child});
  final Widget child;

  @override
  State<_IdleGuard> createState() => _IdleGuardState();
}

class _IdleGuardState extends State<_IdleGuard> with WidgetsBindingObserver {
  Timer? _timer;
  DateTime? _pausedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _reset();
  }

  void _reset() {
    _timer?.cancel();
    _timer = Timer(AppConfig.idleTimeout, _expire);
  }

  void _expire() {
    final s = context.read<Session>();
    if (s.loggedIn) s.logout();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _pausedAt = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      final p = _pausedAt;
      if (p != null && DateTime.now().difference(p) > AppConfig.idleTimeout) {
        _expire();
      }
      _reset();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Listener(
    behavior: HitTestBehavior.translucent,
    onPointerDown: (_) => _reset(),
    child: widget.child,
  );
}
