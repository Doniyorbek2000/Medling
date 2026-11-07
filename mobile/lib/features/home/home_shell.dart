import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/session.dart';
import '../admin/moderation_screen.dart';
import '../appointments/appointments_screen.dart';
import '../doctor_portal/doctor_schedule_screen.dart';
import '../doctors/doctors_screen.dart';
import '../profile/profile_screen.dart';
import 'home_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final role = context.watch<Session>().role;
    final tabs = <(Widget, NavigationDestination)>[
      (
        HomeScreen(onOpenDoctors: () => setState(() => _index = 1)),
        const NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Asosiy',
        ),
      ),
      (
        const DoctorsScreen(),
        const NavigationDestination(
          icon: Icon(Icons.medical_services_outlined),
          selectedIcon: Icon(Icons.medical_services),
          label: 'Shifokorlar',
        ),
      ),
      (
        const AppointmentsScreen(),
        const NavigationDestination(
          icon: Icon(Icons.event_note_outlined),
          selectedIcon: Icon(Icons.event_note),
          label: 'Qabullarim',
        ),
      ),
      if (role == UserRole.doctor)
        (
          const DoctorScheduleScreen(),
          const NavigationDestination(
            icon: Icon(Icons.badge_outlined),
            selectedIcon: Icon(Icons.badge),
            label: 'Bemorlarim',
          ),
        ),
      if (role == UserRole.admin)
        (
          const ModerationScreen(),
          const NavigationDestination(
            icon: Icon(Icons.verified_user_outlined),
            selectedIcon: Icon(Icons.verified_user),
            label: 'Moderatsiya',
          ),
        ),
      (
        const ProfileScreen(),
        const NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Profil',
        ),
      ),
    ];
    final i = _index.clamp(0, tabs.length - 1);
    return Scaffold(
      body: IndexedStack(index: i, children: [for (final t in tabs) t.$1]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: i,
        onDestinationSelected: (v) => setState(() => _index = v),
        destinations: [for (final t in tabs) t.$2],
      ),
    );
  }
}
