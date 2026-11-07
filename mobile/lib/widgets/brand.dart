import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/config.dart';
import '../core/l10n.dart';
import '../core/theme.dart';

class MedLinkLogo extends StatelessWidget {
  const MedLinkLogo({super.key, this.size = 96, this.showName = true});
  final double size;
  final bool showName;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'MedLink',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(size * 0.24),
              boxShadow: [
                BoxShadow(
                  color: Brand.blue.withValues(alpha: 0.12),
                  blurRadius: size * 0.25,
                  offset: Offset(0, size * 0.06),
                ),
              ],
            ),
            padding: EdgeInsets.all(size * 0.04),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(size * 0.2),
              child: Image.asset('assets/brand/medlink_icon.png'),
            ),
          ),
          if (showName) ...[
            SizedBox(height: size * 0.14),
            BrandName(fontSize: size * 0.3),
          ],
        ],
      ),
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
      letterSpacing: fontSize * 0.05,
      height: 1.1,
    );
    return ExcludeSemantics(
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: 'MED',
              style: style.copyWith(
                color: context.isDark ? const Color(0xFF6FA8FF) : Brand.blue,
              ),
            ),
            TextSpan(
              text: 'LINK',
              style: style.copyWith(color: Brand.teal),
            ),
          ],
        ),
      ),
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: MedLinkLogo(size: 120)));
}

class EmergencyBanner extends StatelessWidget {
  const EmergencyBanner({super.key, this.text});
  final String? text;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Semantics(
      button: true,
      label: l.callEmergency(AppConfig.emergencyPhone),
      child: Material(
        color: Brand.danger.withValues(alpha: context.isDark ? 0.18 : 0.07),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => launchUrl(Uri.parse('tel:${AppConfig.emergencyPhone}')),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.emergency, color: Brand.danger),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    text ?? l.emergencyBanner(AppConfig.emergencyPhone),
                    style: const TextStyle(
                      color: Brand.danger,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const CircleAvatar(
                  radius: 18,
                  backgroundColor: Brand.danger,
                  child: Icon(Icons.call, color: Colors.white, size: 18),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class Avatar extends StatelessWidget {
  const Avatar({super.key, required this.initials, this.radius = 28});
  final String initials;
  final double radius;

  @override
  Widget build(BuildContext context) => Container(
    width: radius * 2,
    height: radius * 2,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
          Brand.blue.withValues(alpha: 0.16),
          Brand.teal.withValues(alpha: 0.16),
        ],
      ),
      borderRadius: BorderRadius.circular(radius * 0.6),
    ),
    child: Text(
      initials,
      style: TextStyle(
        color: context.colors.primary,
        fontWeight: FontWeight.w800,
        fontSize: radius * 0.6,
      ),
    ),
  );
}

class RatingStars extends StatelessWidget {
  const RatingStars({super.key, required this.rating, this.size = 16});
  final double rating;
  final double size;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (var i = 1; i <= 5; i++)
        Icon(
          rating >= i
              ? Icons.star_rounded
              : rating >= i - 0.5
              ? Icons.star_half_rounded
              : Icons.star_outline_rounded,
          color: const Color(0xFFFFB300),
          size: size,
        ),
    ],
  );
}
