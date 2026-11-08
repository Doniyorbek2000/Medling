import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/app_lock.dart';
import '../../core/config.dart';
import '../../core/l10n.dart';
import '../../core/legal_links.dart';
import '../../core/notifications_controller.dart';
import '../../core/session.dart';
import '../../core/settings.dart';
import '../../core/theme.dart';
import '../../data/repository.dart';
import '../../models/models.dart';
import '../../widgets/brand.dart';
import '../../widgets/states.dart';
import '../consent/consent_screen.dart';
import '../doctor_portal/doctor_apply_screen.dart';
import '../doctor_portal/doctor_settings_screen.dart';
import '../medical_profile/medical_profile_screen.dart';
import '../payments/my_payments_screen.dart';
import '../settings/language_picker.dart';
import '../triage/triage_history_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  DoctorApplication? _application;
  MedicalProfile? _profile;
  bool _biometricAvailable = false;

  MedLinkRepository get _repo => context.read<MedLinkRepository>();

  @override
  void initState() {
    super.initState();
    _load();
    context.read<AppLock>().available.then((v) {
      if (mounted) setState(() => _biometricAvailable = v);
    });
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        _repo.myApplication(),
        _repo.profile(),
      ]);
      if (!mounted) return;
      setState(() {
        _application = results[0] as DoctorApplication?;
        _profile = results[1] as MedicalProfile?;
      });
    } catch (_) {}
  }

  Future<void> _push(Widget page) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
    _load();
  }

  Future<void> _export() async {
    try {
      final data = await _repo.exportData();
      await Clipboard.setData(
        ClipboardData(text: const JsonEncoder.withIndent('  ').convert(data)),
      );
      if (mounted) showMessage(context, context.l10n.exportCopied);
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  Future<void> _deleteHealth() async {
    final l = context.l10n;
    final ok = await confirmDialog(
      context,
      title: l.deleteHealthData,
      message: l.deleteHealthDataConfirm,
      confirm: l.delete,
      destructive: true,
    );
    if (!ok || !mounted) return;
    try {
      await _repo.deleteHealthData();
      if (mounted) showMessage(context, l.deleted);
      _load();
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  /// Hisobni o'chirish: avval nima o'chishi va nima qonun bo'yicha
  /// saqlanishi tushuntiriladi, keyin yana bir bor tasdiq so'raladi.
  Future<void> _deleteAccount() async {
    final l = context.l10n;
    final first = await confirmDialog(
      context,
      title: l.deleteAccount,
      message: l.deleteAccountConfirm,
      confirm: l.continueAction,
      destructive: true,
    );
    if (!first || !mounted) return;
    final sure = await confirmDialog(
      context,
      title: l.deleteAccount,
      message: l.deleteAccountFinal,
      confirm: l.delete,
      destructive: true,
    );
    if (!sure || !mounted) return;
    final session = context.read<Session>();
    try {
      await _repo.deleteAccount();
      if (!mounted) return;
      showMessage(context, l.accountDeleted);
      await session.logout();
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  Future<void> _toggleBiometric(bool v) async {
    final settings = context.read<AppSettings>();
    if (v) {
      // Yoqishdan oldin foydalanuvchi o'zini tasdiqlashi kerak.
      final ok = await context.read<AppLock>().unlock(
        context.l10n.biometricReason,
      );
      if (!ok) return;
    }
    await settings.setBiometricLock(v);
  }

  Future<void> _toggleNotifications(bool v) async {
    final c = context.read<NotificationsController?>();
    if (c == null) return;
    if (!v) return c.disable();
    final ok = await c.enable();
    if (!ok && mounted) showMessage(context, context.l10n.notificationsDenied);
  }

  Future<void> _pickTheme() async {
    final l = context.l10n;
    final settings = context.read<AppSettings>();
    await showModalBottomSheet<void>(
      context: context,
      builder: (c) => SafeArea(
        child: RadioGroup<ThemeMode>(
          groupValue: settings.themeMode,
          onChanged: (m) {
            settings.setThemeMode(m!);
            Navigator.pop(c);
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l.theme, style: context.text.titleMedium),
              const SizedBox(height: 8),
              RadioListTile(
                value: ThemeMode.system,
                title: Text(l.systemDefault),
              ),
              RadioListTile(value: ThemeMode.light, title: Text(l.themeLight)),
              RadioListTile(value: ThemeMode.dark, title: Text(l.themeDark)),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final session = context.watch<Session>();
    final settings = context.watch<AppSettings>();
    final p = _profile;
    final hasName = p?.fullName.isNotEmpty ?? false;
    final name = hasName ? p!.fullName : l.completeProfile;
    final roleLabel = switch (session.role) {
      UserRole.admin => l.roleAdmin,
      UserRole.doctor => l.roleDoctor,
      UserRole.patient => l.rolePatient,
    };
    final themeLabel = switch (settings.themeMode) {
      ThemeMode.light => l.themeLight,
      ThemeMode.dark => l.themeDark,
      ThemeMode.system => l.systemDefault,
    };
    final langCode = Localizations.localeOf(context).languageCode;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.tabProfile),
        automaticallyImplyLeading: false,
      ),
      body: RefreshIndicator.adaptive(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: InkWell(
                onTap: () => _push(const MedicalProfileScreen()),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Avatar(
                        initials: !hasName
                            ? '+'
                            : name
                                  .split(' ')
                                  .where((s) => s.isNotEmpty)
                                  .take(2)
                                  .map((s) => s[0])
                                  .join(),
                        radius: 30,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: context.text.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            StatusChip(label: roleLabel, color: Brand.teal),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded),
                    ],
                  ),
                ),
              ),
            ),
            _group(l.health, [
              _tile(
                Icons.assignment_ind_outlined,
                l.medicalProfile,
                subtitle: l.medicalProfileSubtitle,
                onTap: () => _push(const MedicalProfileScreen()),
              ),
              _tile(
                Icons.history_rounded,
                l.triageHistory,
                onTap: () => _push(const TriageHistoryScreen()),
              ),
              _tile(
                Icons.receipt_long_outlined,
                l.myPayments,
                subtitle: l.myPaymentsSubtitle,
                onTap: () => _push(const MyPaymentsScreen()),
              ),
            ]),
            if (session.role != UserRole.admin) _doctorSection(l, session),
            _group(l.settings, [
              _tile(
                Icons.language_rounded,
                l.language,
                trailing: Text(
                  settings.locale == null
                      ? l.systemDefault
                      : languageNames[langCode] ?? langCode,
                ),
                onTap: () => showLanguagePicker(context),
              ),
              _tile(
                Icons.dark_mode_outlined,
                l.theme,
                trailing: Text(themeLabel),
                onTap: _pickTheme,
              ),
              if (context.read<NotificationsController?>() != null)
                SwitchListTile.adaptive(
                  secondary: const Icon(Icons.notifications_outlined),
                  title: Text(l.notifications),
                  subtitle: Text(l.notificationsSubtitle),
                  value: settings.notificationsEnabled,
                  onChanged: _toggleNotifications,
                ),
              if (_biometricAvailable)
                SwitchListTile.adaptive(
                  secondary: const Icon(Icons.fingerprint_rounded),
                  title: Text(l.biometricLock),
                  subtitle: Text(l.biometricLockSubtitle),
                  value: settings.biometricLock,
                  onChanged: _toggleBiometric,
                ),
            ]),
            _group(l.privacy, [
              _tile(
                Icons.fact_check_outlined,
                l.consentSettings,
                onTap: () => _push(const ConsentScreen()),
              ),
              _tile(
                Icons.download_outlined,
                l.exportData,
                subtitle: l.exportDataSubtitle,
                onTap: _export,
              ),
              _tile(
                Icons.delete_outline_rounded,
                l.deleteHealthData,
                color: Brand.danger,
                onTap: _deleteHealth,
              ),
              _tile(
                Icons.person_remove_outlined,
                l.deleteAccount,
                subtitle: l.deleteAccountSubtitle,
                color: Brand.danger,
                onTap: _deleteAccount,
              ),
            ]),
            _group(l.aboutApp, [
              _tile(
                Icons.policy_outlined,
                l.privacyPolicy,
                onTap: () => openLegal(context, 'privacy'),
              ),
              _tile(
                Icons.description_outlined,
                l.termsOfUse,
                onTap: () => openLegal(context, 'terms'),
              ),
              _tile(
                Icons.emergency_outlined,
                l.emergencyNumber,
                trailing: const Text(
                  AppConfig.emergencyPhone,
                  style: TextStyle(
                    color: Brand.danger,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _tile(
                Icons.gavel_outlined,
                l.licenses,
                onTap: () => showLicensePage(
                  context: context,
                  applicationName: 'MedLink',
                  applicationVersion: AppConfig.version,
                ),
              ),
              _tile(
                Icons.info_outline_rounded,
                l.version,
                trailing: const Text(AppConfig.version),
              ),
            ]),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () async {
                final ok = await confirmDialog(
                  context,
                  title: l.logout,
                  message: l.logoutConfirm,
                  confirm: l.logout,
                );
                if (ok && context.mounted) context.read<Session>().logout();
              },
              icon: const Icon(Icons.logout_rounded),
              label: Text(l.logout),
            ),
            const SizedBox(height: 24),
            const Center(child: MedLinkLogo(size: 40)),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _doctorSection(AppLocalizations l, Session session) {
    final app = _application;
    if (app == null) {
      return _group(l.forDoctors, [
        _tile(
          Icons.medical_services_outlined,
          l.becomeDoctor,
          subtitle: l.becomeDoctorSubtitle,
          onTap: () => _push(const DoctorApplyScreen()),
        ),
      ]);
    }
    final (label, color) = switch (app.status) {
      'pending' => (l.applicationPending, Brand.warning),
      'approved' => (l.applicationApproved, Brand.success),
      'rejected' => (l.applicationRejected, Brand.danger),
      _ => (l.applicationSuspended, Brand.danger),
    };
    return _group(l.forDoctors, [
      ListTile(
        leading: Icon(Icons.badge_outlined, color: color),
        title: Text(
          label,
          style: TextStyle(
            color: context.ink(color),
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(
          [
            app.doctor.fullName,
            if (app.moderationNote != null)
              l.moderatorNote(app.moderationNote!),
          ].join('\n'),
        ),
      ),
      if (app.status == 'approved' && session.role == UserRole.doctor)
        _tile(
          Icons.tune_rounded,
          l.scheduleAndPrices,
          subtitle: l.scheduleAndPricesSubtitle,
          onTap: () => _push(const DoctorSettingsScreen()),
        ),
      if (app.status == 'rejected')
        _tile(
          Icons.refresh_rounded,
          l.reapply,
          onTap: () => _push(const DoctorApplyScreen()),
        ),
    ]);
  }

  Widget _group(String title, List<Widget> children) => Padding(
    padding: const EdgeInsets.only(top: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: context.text.labelMedium?.copyWith(
              color: context.colors.onSurfaceVariant,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Card(
          child: Column(
            children: [
              for (final (i, c) in children.indexed) ...[
                if (i > 0) const Divider(indent: 56),
                c,
              ],
            ],
          ),
        ),
      ],
    ),
  );

  Widget _tile(
    IconData icon,
    String title, {
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    Color? color,
  }) => ListTile(
    leading: Icon(icon, color: color),
    title: Text(
      title,
      style: TextStyle(color: color == null ? null : context.ink(color)),
    ),
    subtitle: subtitle == null ? null : Text(subtitle),
    trailing:
        trailing ??
        (onTap == null ? null : const Icon(Icons.chevron_right_rounded)),
    onTap: onTap,
  );
}
