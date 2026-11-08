import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../core/l10n.dart';
import '../core/theme.dart';

/// Server xatosini foydalanuvchi tilidagi matnga aylantiradi.
String errorText(BuildContext context, Object e) {
  final l = context.l10n;
  if (e is! ApiError) return l.errorGeneric;
  return switch (e.code) {
    'network' => l.errorNetwork,
    'otp_invalid' => l.errorOtpInvalid,
    'otp_expired' => l.errorOtpExpired,
    'otp_attempts_exceeded' => l.errorOtpAttempts,
    'rate_limited' => l.errorRateLimited,
    'consent_required' => l.errorConsentRequired,
    'slot_unavailable' => l.errorSlotUnavailable,
    'already_applied' => l.errorAlreadyApplied,
    'not_payable' => l.errorNotPayable,
    'not_started' => l.errorNotStarted,
    'already_reviewed' => l.errorAlreadyReviewed,
    'chat_closed' => l.errorChatClosed,
    'file_too_large' => l.errorFileTooLarge,
    'unsupported_file_type' => l.errorUnsupportedFile,
    'too_early' => l.errorTooEarly,
    'too_late' => l.errorTooLate,
    'video_unavailable' => l.errorVideoUnavailable,
    'consultation_type_unavailable' => l.errorTypeUnavailable,
    'invalid_schedule' || 'invalid_price' => l.errorInvalidSchedule,
    'too_late_to_reschedule' => l.errorTooLateToReschedule,
    'reschedule_limit' => l.errorRescheduleLimit,
    'doctor_unavailable' => l.errorDoctorUnavailable,
    'refund_failed' => l.errorRefundFailed,
    _ => l.errorGeneric,
  };
}

void showError(BuildContext context, Object e) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(errorText(context, e))));
}

void showMessage(BuildContext context, String text) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));
}

/// iOS'da Cupertino, Android'da Material uslubidagi tasdiqlash oynasi.
Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirm,
  bool destructive = false,
}) async {
  final l = context.l10n;
  final ok = await showAdaptiveDialog<bool>(
    context: context,
    builder: (c) => AlertDialog.adaptive(
      title: Text(title),
      content: Text(message),
      actions: [
        adaptiveAction(c, l.cancel, () => Navigator.pop(c, false)),
        adaptiveAction(
          c,
          confirm,
          () => Navigator.pop(c, true),
          destructive: destructive,
        ),
      ],
    ),
  );
  return ok ?? false;
}

Widget adaptiveAction(
  BuildContext context,
  String label,
  VoidCallback onPressed, {
  bool destructive = false,
}) {
  final style = destructive ? const TextStyle(color: Brand.danger) : null;
  return switch (Theme.of(context).platform) {
    TargetPlatform.iOS || TargetPlatform.macOS => CupertinoDialogAction(
      onPressed: onPressed,
      isDestructiveAction: destructive,
      child: Text(label),
    ),
    _ => TextButton(
      onPressed: onPressed,
      child: Text(label, style: style),
    ),
  };
}

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.error, required this.onRetry});
  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final offline = error is ApiError && (error as ApiError).isNetwork;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              offline ? Icons.wifi_off_rounded : Icons.error_outline_rounded,
              size: 56,
              color: context.colors.outline,
            ),
            const SizedBox(height: 16),
            Text(
              errorText(context, error),
              textAlign: TextAlign.center,
              style: context.text.titleMedium,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(context.l10n.retry),
            ),
          ],
        ),
      ),
    );
  }
}

class EmptyView extends StatelessWidget {
  const EmptyView({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Brand.teal.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 40, color: Brand.teal),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: context.text.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: context.text.bodyMedium?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ],
          if (action != null) ...[const SizedBox(height: 20), action!],
        ],
      ),
    ),
  );
}

/// Yuklanish paytida kontent shaklini ko'rsatuvchi skelet.
class SkeletonList extends StatefulWidget {
  const SkeletonList({super.key, this.count = 5, this.height = 92});
  final int count;
  final double height;

  @override
  State<SkeletonList> createState() => _SkeletonListState();
}

class _SkeletonListState extends State<SkeletonList>
    with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // "Animatsiyani kamaytirish" yoqilgan bo'lsa — skelet pulsatsiyasiz.
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = context.colors.onSurface;
    return Semantics(
      label: context.l10n.loading,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, _) => ListView.separated(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          itemCount: widget.count,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (_, _) => Container(
            height: widget.height,
            decoration: BoxDecoration(
              color: base.withValues(alpha: 0.04 + 0.04 * _c.value),
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),
      ),
    );
  }
}

/// Kelajakdagi ma'lumotni yuklaydi va holatlarni (yuklanmoqda / xato / bo'sh /
/// tayyor) bir xil ko'rinishda chiqaradi. `RefreshIndicator` bilan.
class AsyncList<T> extends StatefulWidget {
  const AsyncList({
    super.key,
    required this.load,
    required this.itemBuilder,
    required this.empty,
    this.header,
    this.padding = const EdgeInsets.all(16),
    this.separator = 12,
  });

  final Future<List<T>> Function() load;
  final Widget Function(BuildContext, T, VoidCallback reload) itemBuilder;
  final Widget empty;
  final Widget? header;
  final EdgeInsets padding;
  final double separator;

  @override
  State<AsyncList<T>> createState() => AsyncListState<T>();
}

class AsyncListState<T> extends State<AsyncList<T>> {
  List<T>? _items;
  Object? _error;

  @override
  void initState() {
    super.initState();
    reload();
  }

  Future<void> reload() async {
    try {
      final items = await widget.load();
      if (mounted) {
        setState(() {
          _items = items;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null && _items == null) {
      return ErrorView(
        error: _error!,
        onRetry: () {
          setState(() => _error = null);
          reload();
        },
      );
    }
    final items = _items;
    if (items == null) return const SkeletonList();
    return RefreshIndicator.adaptive(
      onRefresh: reload,
      child: items.isEmpty
          ? LayoutBuilder(
              builder: (_, c) => SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: c.maxHeight),
                  child: Column(
                    children: [
                      ?widget.header,
                      SizedBox(height: c.maxHeight * 0.12),
                      widget.empty,
                    ],
                  ),
                ),
              ),
            )
          : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: widget.padding,
              itemCount: items.length + (widget.header == null ? 0 : 1),
              separatorBuilder: (_, _) => SizedBox(height: widget.separator),
              itemBuilder: (c, i) {
                if (widget.header != null) {
                  if (i == 0) return widget.header!;
                  i--;
                }
                return widget.itemBuilder(c, items[i], reload);
              },
            ),
    );
  }
}

class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    this.title,
    required this.child,
    this.icon,
    this.padding = const EdgeInsets.all(16),
  });
  final String? title;
  final IconData? icon;
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 20, color: context.colors.primary),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    title!,
                    style: context.text.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
          child,
        ],
      ),
    ),
  );
}

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      style: TextStyle(
        color: context.inkOnTint(color, 0.12),
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class ProgressButton extends StatelessWidget {
  const ProgressButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.busy = false,
    this.icon,
  });
  final String label;
  final VoidCallback? onPressed;
  final bool busy;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => FilledButton(
    onPressed: busy ? null : onPressed,
    child: busy
        ? const SizedBox.square(
            dimension: 22,
            child: CircularProgressIndicator.adaptive(strokeWidth: 2.4),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20),
                const SizedBox(width: 8),
              ],
              Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
            ],
          ),
  );
}
