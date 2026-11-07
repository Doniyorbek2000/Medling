import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/session.dart';
import '../../core/theme.dart';
import '../../widgets/brand.dart';
import '../consent/consent_screen.dart';
import '../doctor_portal/doctor_apply_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _doctor;

  @override
  void initState() {
    super.initState();
    _loadDoctor();
  }

  Future<void> _loadDoctor() async {
    try {
      final res = await context.read<Session>().api.get('/v1/doctors/me');
      if (mounted) setState(() => _doctor = res);
    } on ApiError {
      if (mounted) setState(() => _doctor = null);
    }
  }

  Future<void> _export() async {
    try {
      final res = await context.read<Session>().api.get('/v1/me/export');
      await Clipboard.setData(
        ClipboardData(text: const JsonEncoder.withIndent('  ').convert(res)),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ma\'lumotlaringiz nusxasi buferga ko\'chirildi'),
          ),
        );
      }
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  Future<void> _deleteHealth() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Tibbiy ma\'lumotlarni o\'chirish'),
        content: const Text(
          'Barcha AI tahlillari tarixi qaytarib bo\'lmaydigan tarzda '
          'o\'chiriladi. Qabullar tarixi qonunda belgilangan muddat '
          'davomida saqlanadi.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Bekor'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text(
              'O\'chirish',
              style: TextStyle(color: Brand.danger),
            ),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await context.read<Session>().api.delete('/v1/me/health-data');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ma\'lumotlar o\'chirildi')),
        );
      }
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  static const _doctorStatus = {
    'pending': ('Ariza ko\'rib chiqilmoqda', Brand.warning),
    'approved': ('Tasdiqlangan shifokor', Brand.success),
    'rejected': ('Ariza rad etilgan', Brand.danger),
    'suspended': ('Profil to\'xtatilgan', Brand.danger),
  };

  @override
  Widget build(BuildContext context) {
    final session = context.watch<Session>();
    final doc = _doctor;
    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Center(child: MedLinkLogo(size: 72)),
          const SizedBox(height: 24),
          if (session.role != UserRole.admin)
            Card(
              child: doc == null
                  ? ListTile(
                      leading: const Icon(
                        Icons.medical_services_outlined,
                        color: Brand.blue,
                      ),
                      title: const Text('Shifokor sifatida qo\'shilish'),
                      subtitle: const Text(
                        'Ariza topshiring va moderatsiyadan o\'ting',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () async {
                        final sent = await Navigator.of(context).push<bool>(
                          MaterialPageRoute(
                            builder: (_) => const DoctorApplyScreen(),
                          ),
                        );
                        if (sent == true) _loadDoctor();
                      },
                    )
                  : Builder(
                      builder: (_) {
                        final (label, color) =
                            _doctorStatus[doc['status']] ?? ('', Colors.grey);
                        return ListTile(
                          leading: Icon(Icons.badge, color: color),
                          title: Text(label, style: TextStyle(color: color)),
                          subtitle: Text(
                            [
                              doc['fullName'],
                              if (doc['moderationNote'] != null)
                                'Izoh: ${doc['moderationNote']}',
                              if (doc['status'] == 'approved' &&
                                  session.role != UserRole.doctor)
                                'Shifokor panelini ochish uchun qayta kiring',
                            ].join('\n'),
                          ),
                        );
                      },
                    ),
            ),
          const SizedBox(height: 16),
          Text('Maxfiylik', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.fact_check_outlined),
                  title: const Text('Rozilik sozlamalari'),
                  subtitle: const Text('Berish yoki qaytarib olish'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ConsentScreen()),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.download_outlined),
                  title: const Text('Ma\'lumotlarim nusxasi'),
                  subtitle: const Text('Saqlangan barcha ma\'lumotlarni olish'),
                  onTap: _export,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline,
                    color: Brand.danger,
                  ),
                  title: const Text('AI tahlillari tarixini o\'chirish'),
                  onTap: _deleteHealth,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: session.logout,
            icon: const Icon(Icons.logout),
            label: const Text('Chiqish'),
          ),
        ],
      ),
    );
  }
}
