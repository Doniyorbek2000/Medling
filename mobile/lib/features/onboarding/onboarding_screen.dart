import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/l10n.dart';
import '../../core/settings.dart';
import '../../core/theme.dart';
import '../../widgets/brand.dart';
import '../settings/language_picker.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pages = PageController();
  int _index = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final slides = [
      (Icons.auto_awesome_rounded, l.onb1Title, l.onb1Body),
      (Icons.verified_rounded, l.onb2Title, l.onb2Body),
      (Icons.lock_rounded, l.onb3Title, l.onb3Body),
    ];
    final last = _index == slides.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
              child: Row(
                children: [
                  const BrandName(fontSize: 20),
                  const Spacer(),
                  const LanguageButton(),
                  Flexible(
                    child: TextButton(
                      onPressed: () =>
                          context.read<AppSettings>().completeOnboarding(),
                      child: Text(
                        l.skip,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pages,
                onPageChanged: (i) => setState(() => _index = i),
                children: [
                  for (final (i, s) in slides.indexed)
                    _Slide(icon: s.$1, title: s.$2, body: s.$3, first: i == 0),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < slides.length; i++)
                  AnimatedContainer(
                    duration: context.motion(const Duration(milliseconds: 250)),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: i == _index ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i == _index
                          ? context.colors.primary
                          : context.colors.outlineVariant,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: FilledButton(
                onPressed: () => last
                    ? context.read<AppSettings>().completeOnboarding()
                    : _pages.nextPage(
                        duration: context.motion(
                          const Duration(milliseconds: 300),
                        ),
                        curve: Curves.easeOut,
                      ),
                child: Text(last ? l.getStarted : l.next),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Slide extends StatelessWidget {
  const _Slide({
    required this.icon,
    required this.title,
    required this.body,
    required this.first,
  });
  final IconData icon;
  final String title;
  final String body;
  final bool first;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 32),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (first)
          const MedLinkLogo(size: 140, showName: false)
        else
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              gradient: Brand.gradient,
              borderRadius: BorderRadius.circular(40),
            ),
            child: Icon(icon, size: 72, color: Colors.white),
          ),
        const SizedBox(height: 40),
        Text(
          title,
          textAlign: TextAlign.center,
          style: context.text.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          body,
          textAlign: TextAlign.center,
          style: context.text.bodyLarge?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
      ],
    ),
  );
}
