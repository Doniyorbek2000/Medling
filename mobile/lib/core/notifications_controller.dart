import 'dart:ui';

import 'package:flutter/foundation.dart';

import '../data/repository.dart';
import '../l10n/app_localizations.dart';
import '../models/models.dart';
import 'clinic_time.dart';
import 'notifications.dart';
import 'session.dart';
import 'settings.dart';

/// Bildirishnomalarni yoqish/o'chirish, kirish/chiqishda qurilmani
/// ro'yxatga olish va mahalliy eslatmalarni sinxronlash.
class NotificationsController {
  NotificationsController({
    required this.service,
    required this.settings,
    required this.repo,
    required this.session,
  }) {
    repo.onAppointments = sync;
    session.onLoggedIn = onLogin;
    session.beforeLogout = onLogout;
  }

  final NotificationsService service;
  final AppSettings settings;
  final MedLinkRepository repo;
  final Session session;

  String get localeCode {
    final l = settings.locale ?? PlatformDispatcher.instance.locale;
    return AppSettings.supportedLocales.any(
          (s) => s.languageCode == l.languageCode,
        )
        ? l.languageCode
        : 'uz';
  }

  /// Foydalanuvchi o'zi yoqqanda: tizim ruxsati so'raladi.
  Future<bool> enable() async {
    final granted = await service.requestPermission();
    if (!granted) return false;
    await settings.setNotifications(true);
    await onLogin();
    return true;
  }

  Future<void> disable() async {
    await settings.setNotifications(false);
    await service.unregisterDevice(repo);
    await service.cancelReminders();
  }

  Future<void> onLogin() async {
    if (!settings.notificationsEnabled || !session.loggedIn) return;
    await service.registerDevice(repo, localeCode);
    try {
      await repo.appointments(); // onAppointments -> sync
    } catch (_) {}
  }

  Future<void> onLogout() async {
    repo.clearCache(); // tibbiy rasmlar xotirada qolmasin
    await service.unregisterDevice(repo);
    await service.cancelReminders();
  }

  /// Qabullar ro'yxati yuklanganda chaqiriladi.
  void sync(List<Appointment> appointments) {
    if (!settings.notificationsEnabled) return;
    final l = lookupAppLocalizations(Locale(localeCode));
    service
        .syncReminders(
          appointments,
          ReminderTexts(
            title: l.reminderTitle,
            dayBefore: l.reminderDayBefore,
            hourBefore: l.reminderHourBefore,
          ),
          reminderTime,
        )
        .catchError((Object _) => 0);
  }

  /// Eslatmadagi vaqt — Toshkent vaqtida, "09:00".
  @visibleForTesting
  static String reminderTime(DateTime utc) {
    final w = clinicWall(utc);
    return '${w.hour.toString().padLeft(2, '0')}:'
        '${w.minute.toString().padLeft(2, '0')}';
  }
}
