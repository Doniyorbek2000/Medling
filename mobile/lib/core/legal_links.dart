import 'package:flutter/widgets.dart';
import 'package:url_launcher/url_launcher.dart';

import 'config.dart';

/// Maxfiylik siyosati (`privacy`) yoki foydalanish shartlari (`terms`).
/// Matn serverda (do'kon sahifasidagi havola bilan bir xil), ilova tilida.
Uri legalUri(String kind, String lang) =>
    Uri.parse(AppConfig.apiBase)
        .replace(path: '/legal/$kind', queryParameters: {'lang': lang});

Future<void> openLegal(BuildContext context, String kind) => launchUrl(
  legalUri(kind, Localizations.localeOf(context).languageCode),
  mode: LaunchMode.inAppBrowserView,
);
