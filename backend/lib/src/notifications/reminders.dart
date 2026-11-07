import 'dart:async';

import '../appointments/appointments.dart';
import '../doctors/doctors.dart';
import 'notifications.dart';

/// Har daqiqada qabul boshlanishiga 1 soat qolganlarni topib, bemor va
/// shifokorga eslatma yuboradi. (Prod'da: Cloud Scheduler / navbat orqali.)
class ReminderScheduler {
  ReminderScheduler({
    required this.appointments,
    required this.doctors,
    required this.notifications,
    this.lead = const Duration(hours: 1),
  });

  final AppointmentService appointments;
  final DoctorService doctors;
  final NotificationService notifications;
  final Duration lead;
  Timer? _timer;

  void start({Duration every = const Duration(minutes: 1)}) {
    _timer?.cancel();
    _timer = Timer.periodic(every, (_) => tick(DateTime.now().toUtc()));
  }

  void stop() => _timer?.cancel();

  /// Bitta tekshiruv (testlarda to'g'ridan-to'g'ri chaqiriladi).
  Future<int> tick(DateTime now) async {
    final due = appointments.dueForReminder(now, lead);
    for (final a in due) {
      a.reminderSent = true;
      final data = {'type': 'appointment', 'appointmentId': a.id};
      await notifications.notify(
        a.patientId,
        PushKind.appointmentReminder,
        at: a.startsAt,
        data: data,
      );
      final doctorUser = doctors.byId(a.doctorId)?.userId;
      if (doctorUser != null) {
        await notifications.notify(
          doctorUser,
          PushKind.appointmentReminder,
          at: a.startsAt,
          data: data,
        );
      }
    }
    return due.length;
  }
}

/// Qabul hodisalarini bildirishnomalarga ulaydi.
void wireAppointmentNotifications({
  required AppointmentService appointments,
  required DoctorService doctors,
  required NotificationService notifications,
}) {
  appointments.onConfirmed = (a) {
    final data = {'type': 'appointment', 'appointmentId': a.id};
    notifications.notify(
      a.patientId,
      PushKind.paymentConfirmed,
      at: a.startsAt,
      data: data,
    );
    final doctorUser = doctors.byId(a.doctorId)?.userId;
    if (doctorUser != null) {
      notifications.notify(
        doctorUser,
        PushKind.newPatient,
        at: a.startsAt,
        data: data,
      );
    }
  };
  appointments.onCancelled = (a, actor) {
    final doctorUser = doctors.byId(a.doctorId)?.userId;
    // Bekor qilgan tomonga emas, ikkinchi tomonga xabar beramiz.
    final other = actor == a.patientId ? doctorUser : a.patientId;
    if (other != null) {
      notifications.notify(
        other,
        PushKind.appointmentCancelled,
        at: a.startsAt,
        data: {'type': 'appointment', 'appointmentId': a.id},
      );
    }
  };
}
