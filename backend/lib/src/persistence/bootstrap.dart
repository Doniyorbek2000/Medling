import '../ai/triage_service.dart';
import '../appointments/appointments.dart';
import '../auth/auth.dart';
import '../consent/consent.dart';
import '../consultations/chat.dart';
import '../doctors/doctors.dart';
import '../notifications/inbox.dart';
import '../notifications/notifications.dart';
import '../payments/click.dart';
import '../payments/orders.dart';
import '../payments/payme.dart';
import '../profile/medical_profile.dart';
import 'postgres_store.dart';

/// Ishga tushganda butun holatni bazadan servislarga yuklaydi (foreign key
/// tartibida). Qaytaradi: jadval -> qatorlar soni.
Future<Map<String, int>> restoreAll(
  PostgresStore store, {
  required AuthService auth,
  required ConsentService consents,
  required MedicalProfileService profiles,
  required TriageService triage,
  required DoctorService doctors,
  required AppointmentService appointments,
  required OrderRepository orders,
  required ClickMerchant click,
  required PaymeMerchant payme,
  required ChatService chat,
  required DeviceRegistry devices,
  NotificationInbox? inbox,
}) async {
  final restorers = <String, void Function(List<Map<String, dynamic>>)>{
    'users': auth.restoreUsers,
    'consents': consents.restore,
    'medical_profiles': profiles.restore,
    'triage_results': triage.restore,
    'doctors': doctors.restore,
    'appointments': appointments.restore,
    'payment_orders': orders.restore,
    'click_prepared': click.restore,
    'payme_transactions': payme.restore,
    'chat_messages': chat.restore,
    'devices': devices.restore,
    'notifications': ?inbox?.restore,
  };
  final counts = <String, int>{};
  for (final e in restorers.entries) {
    final rows = await store.load(e.key);
    e.value(rows);
    counts[e.key] = rows.length;
  }
  return counts;
}
