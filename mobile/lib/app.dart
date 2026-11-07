import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/app_lock.dart';
import 'core/config.dart';
import 'core/l10n.dart';
import 'core/session.dart';
import 'core/settings.dart';
import 'core/theme.dart';
import 'features/auth/phone_screen.dart';
import 'features/consent/consent_screen.dart';
import 'core/notifications.dart';
import 'data/repository.dart';
import 'features/appointments/appointment_detail_screen.dart';
import 'features/home/home_shell.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'widgets/brand.dart';

/// Bildirishnoma bosilganda sahifa ochish uchun.
final appNavigatorKey = GlobalKey<NavigatorState>();

/// Biometrik qulf holati: qulf ochilmaguncha bildirishnoma orqali tibbiy
/// sahifa ochilmaydi (aks holda qulfni chetlab o'tish mumkin bo'lardi).
final appLocked = ValueNotifier<bool>(false);

class MedLinkApp extends StatelessWidget {
  const MedLinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();
    return MaterialApp(
      navigatorKey: appNavigatorKey,
      onGenerateTitle: (c) => c.l10n.appName,
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: settings.themeMode,
      locale: settings.locale,
      supportedLocales: AppSettings.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // Tizim tili qo'llab-quvvatlanmasa — o'zbekcha.
      localeResolutionCallback: (device, supported) => supported.firstWhere(
        (l) => l.languageCode == device?.languageCode,
        orElse: () => const Locale('uz'),
      ),
      builder: (context, child) => MediaQuery.withClampedTextScaling(
        // Katta shrift sozlamasini qo'llab-quvvatlaymiz, lekin maket buzilmasin.
        maxScaleFactor: 1.4,
        child: _IdleGuard(child: child!),
      ),
      home: const _Root(),
    );
  }
}

class _Root extends StatelessWidget {
  const _Root();

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();
    final s = context.watch<Session>();
    final Widget page;
    if (!settings.onboardingDone) {
      page = const OnboardingScreen();
    } else if (s.loading) {
      page = const SplashScreen();
    } else if (!s.loggedIn) {
      page = const PhoneScreen();
    } else if (s.needsConsent) {
      page = const ConsentScreen(initial: true);
    } else {
      page = const NotificationRouter(child: LockGate(child: HomeShell()));
    }
    return AnimatedSwitcher(
      duration: context.motion(const Duration(milliseconds: 300)),
      child: KeyedSubtree(key: ValueKey(page.runtimeType), child: page),
    );
  }
}

/// Biometrik qulf: ilova ochilganda va fonda 30 soniyadan ko'p turganidan
/// keyin Face ID / barmoq izi so'raladi.
class LockGate extends StatefulWidget {
  const LockGate({super.key, required this.child});
  final Widget child;

  @override
  State<LockGate> createState() => _LockGateState();
}

class _LockGateState extends State<LockGate> with WidgetsBindingObserver {
  late bool _locked = context.read<AppSettings>().biometricLock;
  DateTime? _pausedAt;
  bool _prompting = false;

  @override
  void initState() {
    super.initState();
    appLocked.value = _locked;
    WidgetsBinding.instance.addObserver(this);
    if (_locked) WidgetsBinding.instance.addPostFrameCallback((_) => _unlock());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!context.read<AppSettings>().biometricLock || _prompting) return;
    if (state == AppLifecycleState.paused) {
      _pausedAt = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      final p = _pausedAt;
      _pausedAt = null;
      if (p != null &&
          DateTime.now().difference(p) > const Duration(seconds: 30)) {
        setState(() => _locked = true);
        appLocked.value = true;
        _unlock();
      }
    }
  }

  Future<void> _unlock() async {
    if (_prompting) return;
    _prompting = true;
    final ok = await context.read<AppLock>().unlock(
      context.l10n.biometricReason,
    );
    _prompting = false;
    if (ok && mounted) {
      setState(() => _locked = false);
      appLocked.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_locked) return widget.child;
    final l = context.l10n;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              const MedLinkLogo(size: 96),
              const SizedBox(height: 32),
              Text(l.lockedTitle, style: context.text.titleLarge),
              const Spacer(),
              FilledButton.icon(
                onPressed: _unlock,
                icon: const Icon(Icons.fingerprint),
                label: Text(l.unlock),
              ),
              TextButton(
                onPressed: () => context.read<Session>().logout(),
                child: Text(l.logout),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Faol bo'lmaslik vaqti tugasa yoki ilova uzoq vaqt fonda qolsa —
/// sessiya yopiladi (HIPAA §164.312(a)(2)(iii) "Automatic logoff").
/// Ilova qaytganda rol va rozilik holati yangilanadi.
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
      _pausedAt = null;
      if (p != null && DateTime.now().difference(p) > AppConfig.idleTimeout) {
        _expire();
      } else {
        final s = context.read<Session>();
        if (s.loggedIn) s.reloadMe().catchError((Object _) {});
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

/// Bildirishnoma bosilganda tegishli sahifani ochadi. Biometrik qulf ochiq
/// bo'lgandagina ishlaydi.
class NotificationRouter extends StatefulWidget {
  const NotificationRouter({super.key, required this.child});
  final Widget child;

  @override
  State<NotificationRouter> createState() => _NotificationRouterState();
}

class _NotificationRouterState extends State<NotificationRouter> {
  StreamSubscription<NotificationTap>? _sub;
  NotificationTap? _pending;

  @override
  void initState() {
    super.initState();
    _sub = context.read<NotificationsService?>()?.taps.listen((t) {
      _pending = t;
      _tryOpen();
    });
    appLocked.addListener(_tryOpen);
  }

  @override
  void dispose() {
    _sub?.cancel();
    appLocked.removeListener(_tryOpen);
    super.dispose();
  }

  Future<void> _tryOpen() async {
    final t = _pending;
    if (t == null || appLocked.value || !mounted) return;
    _pending = null;
    if (t.type == 'doctor_application') {
      HomeTabs.request.value = 'profile';
      return;
    }
    final id = t.appointmentId;
    if (id == null) return;
    try {
      final list = await context.read<MedLinkRepository>().appointments();
      final a = list.where((x) => x.id == id).firstOrNull;
      if (a == null) {
        // Shifokor uchun: bemorlar ro'yxati.
        HomeTabs.request.value = 'patients';
        return;
      }
      await appNavigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => AppointmentDetailScreen(appointment: a),
        ),
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
