import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:medlink_backend/medlink_backend.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;

/// Faqat ishlab chiqish uchun: kodni server logiga chiqaradi.
class DevOtpSender implements OtpSender {
  @override
  Future<void> send(String phone, String code) async {
    stdout.writeln('[DEV OTP] ${phone.substring(0, 6)}***: $code');
  }
}

void log(String severity, String message) =>
    stdout.writeln(jsonEncode({'severity': severity, 'message': message}));

Future<void> main() async {
  final env = Platform.environment;
  final cfg = AppConfig.fromEnvironment();
  final dev = env['MEDLINK_ENV'] == 'dev';
  final databaseUrl = env['DATABASE_URL'] ?? '';
  final eskizEmail = env['ESKIZ_EMAIL'] ?? '';

  // Prod: ma'lumotlar bazasi va haqiqiy SMS shart.
  if (!dev && (databaseUrl.isEmpty || eskizEmail.isEmpty)) {
    stderr.writeln(
      'Prod rejimi uchun DATABASE_URL va ESKIZ_EMAIL/ESKIZ_PASSWORD kerak. '
      'Sinov uchun MEDLINK_ENV=dev bilan ishga tushiring.',
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

  // ---------------- Servislar ----------------
  final auth = AuthService(
    jwtSecret: cfg.jwtSecret,
    encryption: enc,
    // ESKIZ_EMAIL berilsa — haqiqiy SMS, aks holda kod logga chiqadi (dev).
    otpSender: eskizEmail.isEmpty
        ? DevOtpSender()
        : EskizOtpSender(
            client: httpClient,
            email: eskizEmail,
            password: env['ESKIZ_PASSWORD'] ?? '',
            from: env['ESKIZ_FROM'] ?? '4546',
          ),
    adminPhones: (env['MEDLINK_ADMIN_PHONES'] ?? '')
        .split(',')
        .where((p) => p.isNotEmpty)
        .toSet(),
  );
  final consents = ConsentService();
  final profiles = MedicalProfileService(enc);
  final triage = TriageService(model: model, encryption: enc);
  final doctors = DoctorService(enc);
  final appointments = AppointmentService(doctors, enc);
  final orders = OrderRepository();
  final chat = ChatService(appointments, enc);
  final devices = DeviceRegistry();
  final inbox = NotificationInbox();

  // To'lov bekor qilingan qabul uchun kelsa (masalan, bron muddati o'tgach),
  // pul avtomatik qaytarish navbatiga qo'yiladi.
  void paid(PaymentOrder o) {
    appointments.markPaid(o.appointmentId);
    if (appointments.byId(o.appointmentId)?.status ==
        AppointmentStatus.cancelled) {
      orders.requestRefund(o, 'late_payment');
    }
  }

  void refunded(PaymentOrder o) {
    final a = appointments.byId(o.appointmentId);
    if (a == null) return;
    a.status = AppointmentStatus.cancelled;
    appointments.persist(a);
  }

  final click = ClickMerchant(
    serviceId: cfg.clickServiceId,
    merchantId: cfg.clickMerchantId,
    secretKey: cfg.clickSecretKey,
    orders: orders,
    onPaid: paid,
  );
  final payme = PaymeMerchant(
    merchantId: cfg.paymeMerchantId,
    key: cfg.paymeKey,
    orders: orders,
    onPaid: paid,
    onRefunded: refunded,
    testMode: cfg.paymeTestMode,
  );

  // ---------------- PostgreSQL ----------------
  PostgresStore? store;
  AuditLog audit = InMemoryAuditLog();
  if (databaseUrl.isNotEmpty) {
    store = await PostgresStore.open(databaseUrl);
    final counts = await restoreAll(
      store,
      auth: auth,
      consents: consents,
      profiles: profiles,
      triage: triage,
      doctors: doctors,
      appointments: appointments,
      orders: orders,
      click: click,
      payme: payme,
      chat: chat,
      devices: devices,
      inbox: inbox,
    );
    log('INFO', 'PostgreSQL: holat yuklandi $counts');
    audit = PostgresAuditLog(store.pool);
    changes.enabled = true;
  } else {
    log('WARNING', 'DATABASE_URL yo\'q — ma\'lumotlar faqat xotirada (dev).');
  }

  // Demo shifokorlar: faqat dev va baza bo'sh bo'lsa (har qayta ishga
  // tushishda takrorlanmaydi).
  if (dev && env['MEDLINK_SEED_DEMO'] != 'false' && doctors.all.isEmpty) {
    await doctors.seedDemo();
  }
  await store?.flush(changes.drain());

  // ---------------- Bildirishnomalar ----------------
  // FCM_PROJECT_ID berilsa — Firebase, aks holda faqat log (dev).
  final fcmProject = env['FCM_PROJECT_ID'] ?? '';
  final notifications = NotificationService(
    devices: devices,
    inbox: inbox,
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
  wireConsultationNotifications(
    appointments: appointments,
    doctors: doctors,
    chat: chat,
    notifications: notifications,
  );
  final reminders =
      ReminderScheduler(
          appointments: appointments,
          doctors: doctors,
          notifications: notifications,
        )
        ..onExpired = ((a) => orders.cancelPendingFor(a.id))
        ..start();

  final api = MedLinkApi(
    auth: auth,
    consents: consents,
    triage: triage,
    doctors: doctors,
    appointments: appointments,
    orders: orders,
    click: click,
    payme: payme,
    wallet: StripeWalletGateway(httpClient, cfg.stripeSecretKey),
    audit: audit,
    profiles: profiles,
    devices: devices,
    notifications: notifications,
    chat: chat,
    attachments: AttachmentService(
      appointments: appointments,
      chat: chat,
      encryption: enc,
      store: store == null
          ? MemoryAttachmentStore()
          : PostgresAttachmentStore(store.pool),
    ),
    video: VideoTokenIssuer(
      url: env['LIVEKIT_URL'] ?? '',
      apiKey: env['LIVEKIT_API_KEY'] ?? '',
      apiSecret: env['LIVEKIT_API_SECRET'] ?? '',
    ),
    publicBaseUrl: cfg.publicBaseUrl,
    legal: LegalInfo(
      operatorName: env['MEDLINK_OPERATOR_NAME'] ?? 'MedLink',
      operatorAddress: env['MEDLINK_OPERATOR_ADDRESS'] ?? '',
      contactEmail: env['MEDLINK_CONTACT_EMAIL'] ?? '',
      contactPhone: env['MEDLINK_CONTACT_PHONE'] ?? '',
    ),
    // Cloud Run / load balancer ortida: true.
    trustProxy: env['MEDLINK_TRUST_PROXY'] == 'true',
  );

  // Har bir so'rovdagi o'zgarishlar javobdan oldin bazaga yoziladi.
  var handler = api.handler;
  Timer? backgroundFlush;
  if (store != null) {
    void onError(Object e) => log('ERROR', 'PostgreSQL yozish xatosi: $e');
    handler = const Pipeline()
        .addMiddleware(persistenceMiddleware(store, onError: onError))
        .addHandler(handler);
    backgroundFlush = startBackgroundFlush(store, onError: onError);
  }

  final server = await io.serve(handler, InternetAddress.anyIPv4, cfg.port);
  log('INFO', 'MedLink API: http://${server.address.host}:${server.port}');

  // To'xtash (Cloud Run SIGTERM yuboradi): yangi so'rovlar qabul qilinmaydi,
  // qolgan o'zgarishlar yoziladi, ulanishlar yopiladi.
  Future<void> shutdown(ProcessSignal s) async {
    log('INFO', 'To\'xtatilmoqda ($s)...');
    await server.close();
    reminders.stop();
    backgroundFlush?.cancel();
    final st = store;
    if (st != null) {
      await st.flush(changes.drain());
      await st.close();
    }
    exit(0);
  }

  ProcessSignal.sigterm.watch().listen(shutdown);
  ProcessSignal.sigint.watch().listen(shutdown);
}
