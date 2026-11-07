import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../core/config.dart';
import '../core/theme.dart';

import 'package:url_launcher/url_launcher.dart';

class MedLinkLogo extends StatelessWidget {
  const MedLinkLogo({super.key, this.size = 96, this.showName = true});
  final double size;
  final bool showName;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(size * 0.22),
          child: Image.asset(
            'assets/brand/medlink_icon.png',
            width: size,
            height: size,
          ),
        ),
        if (showName) ...[
          const SizedBox(height: 12),
          const BrandName(fontSize: 30),
        ],
      ],
    );
  }
}

/// "MED" ko'k, "LINK" yashil-moviy — logotipdagidek.
class BrandName extends StatelessWidget {
  const BrandName({super.key, this.fontSize = 22});
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w800,
      letterSpacing: 1.2,
    );
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: 'MED',
            style: style.copyWith(color: Brand.blue),
          ),
          TextSpan(
            text: 'LINK',
            style: style.copyWith(color: Brand.teal),
          ),
        ],
      ),
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(
    backgroundColor: Colors.white,
    body: Center(child: MedLinkLogo(size: 120)),
  );
}

class EmergencyBanner extends StatelessWidget {
  const EmergencyBanner({super.key, this.text});
  final String? text;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Brand.danger.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => launchUrl(Uri.parse('tel:${AppConfig.emergencyPhone}')),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              const Icon(Icons.emergency, color: Brand.danger),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text ??
                      'Hayot uchun xavfli holatda darhol '
                          '${AppConfig.emergencyPhone} ga qo\'ng\'iroq qiling',
                  style: const TextStyle(
                    color: Brand.danger,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Icon(Icons.call, color: Brand.danger),
            ],
          ),
        ),
      ),
    );
  }
}

void showError(BuildContext context, Object e) {
  final msg = e is ApiError ? e.userMessage : 'Xatolik yuz berdi';
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg)));
}
