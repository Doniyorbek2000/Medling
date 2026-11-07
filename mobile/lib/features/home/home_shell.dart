import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/l10n.dart';
import '../../core/session.dart';
import '../admin/moderation_screen.dart';
import '../appointments/appointments_screen.dart';
import '../doctor_portal/doctor_schedule_screen.dart';
import '../doctors/doctors_screen.dart';
import '../profile/profile_screen.dart';
import 'home_screen.dart';

/// Tablar orasida o'tish uchun (masalan, bosh sahifadan "Shifokorlar"ga).
class HomeTabs extends InheritedWidget {
  const HomeTabs({super.key, required this.select, required super.child});
  final void Function(String id) select;

  /// Tashqaridan tab ochish so'rovi (masalan, bildirishnoma bosilganda).
  static final request = ValueNotifier<String?>(null);

  static HomeTabs? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<HomeTabs>();

  @override
  bool updateShouldNotify(HomeTabs old) => false;
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  String _current = 'home';

  @override
  void initState() {
    super.initState();
    HomeTabs.request.addListener(_onRequest);
  }

  @override
  void dispose() {
    HomeTabs.request.removeListener(_onRequest);
    super.dispose();
  }

  void _onRequest() {
    final id = HomeTabs.request.value;
    if (id == null) return;
    HomeTabs.request.value = null;
    if (mounted) setState(() => _current = id);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final role = context.watch<Session>().role;
    final tabs = <(String, Widget, IconData, IconData, String)>[
      (
        'home',
        const HomeScreen(),
        Icons.home_outlined,
        Icons.home_rounded,
        l.tabHome,
      ),
      (
        'doctors',
        const DoctorsScreen(),
        Icons.medical_services_outlined,
        Icons.medical_services_rounded,
        l.tabDoctors,
      ),
      (
        'appointments',
        const AppointmentsScreen(),
        Icons.event_note_outlined,
        Icons.event_note_rounded,
        l.tabAppointments,
      ),
      if (role == UserRole.doctor)
        (
          'patients',
          const DoctorScheduleScreen(),
          Icons.badge_outlined,
          Icons.badge_rounded,
          l.tabPatients,
        ),
      if (role == UserRole.admin)
        (
          'moderation',
          const ModerationScreen(),
          Icons.verified_user_outlined,
          Icons.verified_user_rounded,
          l.tabModeration,
        ),
      (
        'profile',
        const ProfileScreen(),
        Icons.person_outline_rounded,
        Icons.person_rounded,
        l.tabProfile,
      ),
    ];
    var index = tabs.indexWhere((t) => t.$1 == _current);
    if (index < 0) index = 0;

    return HomeTabs(
      select: (id) => setState(() => _current = id),
      child: Scaffold(
        body: IndexedStack(
          index: index,
          children: [
            for (final t in tabs)
              KeyedSubtree(key: ValueKey(t.$1), child: t.$2),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: (i) => setState(() => _current = tabs[i].$1),
          destinations: [
            for (final t in tabs)
              NavigationDestination(
                icon: Icon(t.$3),
                selectedIcon: Icon(t.$4),
                label: t.$5,
              ),
          ],
        ),
      ),
    );
  }
}
