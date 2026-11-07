import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/api_client.dart';
import 'core/app_lock.dart';
import 'core/deep_links.dart';
import 'core/notifications.dart';
import 'core/notifications_controller.dart';
import 'core/session.dart';
import 'core/settings.dart';
import 'data/repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  } on MissingPluginException {
    // Testlar / qo'llab-quvvatlanmaydigan platforma.
  }

  // Shrift litsenziyalari (SIL OFL 1.1) "Litsenziyalar" sahifasida ko'rinadi.
  LicenseRegistry.addLicense(() async* {
    for (final (pkg, file) in [
      ('Figtree', 'OFL-Figtree.txt'),
      ('Noto Sans', 'OFL-NotoSans.txt'),
    ]) {
      yield LicenseEntryWithLineBreaks([
        pkg,
      ], await rootBundle.loadString('assets/fonts/$file'));
    }
  });

  final api = ApiClient();
  final settings = AppSettings();
  await settings.load();
  final session = Session(api);
  final repository = MedLinkRepository(api);
  final notifications = NotificationsService();
  await notifications.init();
  final notificationsController = NotificationsController(
    service: notifications,
    settings: settings,
    repo: repository,
    session: session,
  );
  session.restore();
  final links = DeepLinks()..start();

  runApp(
    MedLinkProviders(
      settings: settings,
      session: session,
      repository: repository,
      deepLinks: links,
      appLock: AppLock(),
      notifications: notifications,
      notificationsController: notificationsController,
      child: const MedLinkApp(),
    ),
  );
}

class MedLinkProviders extends StatelessWidget {
  const MedLinkProviders({
    super.key,
    required this.settings,
    required this.session,
    required this.repository,
    required this.deepLinks,
    required this.appLock,
    required this.child,
    this.notifications,
    this.notificationsController,
  });

  final AppSettings settings;
  final Session session;
  final MedLinkRepository repository;
  final DeepLinks deepLinks;
  final AppLock appLock;
  final Widget child;
  final NotificationsService? notifications;
  final NotificationsController? notificationsController;

  @override
  Widget build(BuildContext context) => MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: settings),
      ChangeNotifierProvider.value(value: session),
      Provider.value(value: repository),
      Provider.value(value: deepLinks),
      Provider.value(value: appLock),
      Provider<NotificationsService?>.value(value: notifications),
      Provider<NotificationsController?>.value(value: notificationsController),
    ],
    child: child,
  );
}
