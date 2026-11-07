import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/api_client.dart';
import 'core/app_lock.dart';
import 'core/deep_links.dart';
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

  final api = ApiClient();
  final settings = AppSettings();
  await settings.load();
  final session = Session(api)..restore();
  final links = DeepLinks()..start();

  runApp(
    MedLinkProviders(
      settings: settings,
      session: session,
      repository: MedLinkRepository(api),
      deepLinks: links,
      appLock: AppLock(),
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
  });

  final AppSettings settings;
  final Session session;
  final MedLinkRepository repository;
  final DeepLinks deepLinks;
  final AppLock appLock;
  final Widget child;

  @override
  Widget build(BuildContext context) => MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: settings),
      ChangeNotifierProvider.value(value: session),
      Provider.value(value: repository),
      Provider.value(value: deepLinks),
      Provider.value(value: appLock),
    ],
    child: child,
  );
}
