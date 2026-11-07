import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:medlink_backend/medlink_backend.dart';
import 'package:shelf/shelf_io.dart' as io;

/// Faqat ishlab chiqish uchun: kodni server logiga chiqaradi.
/// Prod'da Eskiz.uz / Play Mobile SMS shlyuzi implementatsiyasi ulanadi.
class DevOtpSender implements OtpSender {
  @override
  Future<void> send(String phone, String code) async {
    stdout.writeln('[DEV OTP] ${phone.substring(0, 6)}***: $code');
  }
}

Future<void> main() async {
  final env = Platform.environment;
  final cfg = AppConfig.fromEnvironment();
  if (env['MEDLINK_ENV'] != 'dev') {
    stderr.writeln(
      'Prod rejimi uchun haqiqiy OtpSender va doimiy (Postgres) '
      'repozitoriylarni ulang. Hozircha MEDLINK_ENV=dev bilan ishga tushiring.',
    );
    exit(1);
  }

  final httpClient = http.Client();
  final enc = FieldEncryption(cfg.dataKeys, cfg.activeKeyId);
  final tokens = GcpTokenProvider(
    httpClient,
    staticToken: env['GCP_ACCESS_TOKEN'],
  );

  final MedicalModel model = cfg.medModel.startsWith('medlm')
      ? VertexMedLmModel(
          client: httpClient,
          tokens: tokens,
          project: cfg.gcpProject,
          location: cfg.gcpLocation,
          model: cfg.medModel,
        )
      : VertexGenerateContentModel(
          client: httpClient,
          tokens: tokens,
          project: cfg.gcpProject,
          location: cfg.gcpLocation,
          model: cfg.medModel,
        );

  final doctors = DoctorService(enc);
  if (env['MEDLINK_SEED_DEMO'] != 'false') await doctors.seedDemo();
  final appointments = AppointmentService(doctors, enc);
  final orders = OrderRepository();

  // Push: FCM_PROJECT_ID berilsa — Firebase, aks holda faqat log (dev).
  final devices = DeviceRegistry();
  final fcmProject = env['FCM_PROJECT_ID'] ?? '';
  final notifications = NotificationService(
    devices: devices,
    sender: fcmProject.isEmpty
        ? LogPushSender()
        : FcmPushSender(
            client: httpClient,
            tokens: tokens,
            projectId: fcmProject,
          ),
  );
  wireAppointmentNotifications(
    appointments: appointments,
    doctors: doctors,
    notifications: notifications,
  );
  final chat = ChatService(appointments, enc);
  wireConsultationNotifications(
    appointments: appointments,
    doctors: doctors,
    chat: chat,
    notifications: notifications,
  );
  ReminderScheduler(
    appointments: appointments,
    doctors: doctors,
    notifications: notifications,
  ).start();
  void paid(PaymentOrder o) => appointments.markPaid(o.appointmentId);
  void refunded(PaymentOrder o) =>
      appointments.byId(o.appointmentId)?.status = AppointmentStatus.cancelled;

  final api = MedLinkApi(
    auth: AuthService(
      jwtSecret: cfg.jwtSecret,
      encryption: enc,
      // ESKIZ_EMAIL berilsa — haqiqiy SMS, aks holda kod logga chiqadi.
      otpSender: (env['ESKIZ_EMAIL'] ?? '').isEmpty
          ? DevOtpSender()
          : EskizOtpSender(
              client: httpClient,
              email: env['ESKIZ_EMAIL']!,
              password: env['ESKIZ_PASSWORD'] ?? '',
              from: env['ESKIZ_FROM'] ?? '4546',
            ),
      adminPhones: (env['MEDLINK_ADMIN_PHONES'] ?? '')
          .split(',')
          .where((p) => p.isNotEmpty)
          .toSet(),
    ),
    consents: ConsentService(),
    triage: TriageService(model: model, encryption: enc),
    doctors: doctors,
    appointments: appointments,
    orders: orders,
    click: ClickMerchant(
      serviceId: cfg.clickServiceId,
      merchantId: cfg.clickMerchantId,
      secretKey: cfg.clickSecretKey,
      orders: orders,
      onPaid: paid,
    ),
    payme: PaymeMerchant(
      merchantId: cfg.paymeMerchantId,
      key: cfg.paymeKey,
      orders: orders,
      onPaid: paid,
      onRefunded: refunded,
      testMode: cfg.paymeTestMode,
    ),
    wallet: StripeWalletGateway(httpClient, cfg.stripeSecretKey),
    audit: InMemoryAuditLog(),
    profiles: MedicalProfileService(enc),
    devices: devices,
    notifications: notifications,
    chat: chat,
    video: VideoTokenIssuer(
      url: env['LIVEKIT_URL'] ?? '',
      apiKey: env['LIVEKIT_API_KEY'] ?? '',
      apiSecret: env['LIVEKIT_API_SECRET'] ?? '',
    ),
    publicBaseUrl: cfg.publicBaseUrl,
  );

  final server = await io.serve(api.handler, InternetAddress.anyIPv4, cfg.port);
  stdout.writeln('MedLink API: http://${server.address.host}:${server.port}');
}
