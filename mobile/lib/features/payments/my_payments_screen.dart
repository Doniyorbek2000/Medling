import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../data/repository.dart';
import '../../models/models.dart';
import '../../widgets/states.dart';
import '../appointments/appointment_detail_screen.dart';

/// Bemorning to'lovlar tarixi: summa, usul, holat va qaytarish.
class MyPaymentsScreen extends StatelessWidget {
  const MyPaymentsScreen({super.key});

  static String providerName(String p) => switch (p) {
    'click' => 'Click',
    'payme' => 'Payme',
    'googlePay' => 'Google Pay',
    'applePay' => 'Apple Pay',
    _ => p,
  };

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final repo = context.read<MedLinkRepository>();
    return Scaffold(
      appBar: AppBar(title: Text(l.myPayments)),
      body: AsyncList<MyPayment>(
        load: repo.myPayments,
        separator: 8,
        empty: EmptyView(
          icon: Icons.receipt_long_outlined,
          title: l.noPayments,
        ),
        itemBuilder: (context, p, _) {
          final (label, color) = switch (p.refundStatus) {
            'refunded' => (l.orderRefunded, Brand.blue),
            'requested' => (l.refundRequestedShort, Brand.warning),
            _ => (l.paidLabel, Brand.success),
          };
          return Card(
            child: ListTile(
              title: Text(
                context.fmt.money(p.amountUzs),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text(
                [
                  if (p.doctorName != null) p.doctorName!,
                  if (p.appointmentStartsAt != null)
                    l.visitOn(context.fmt.dateTime(p.appointmentStartsAt!)),
                  [
                    providerName(p.provider),
                    if (p.paidAt != null) context.fmt.dateTime(p.paidAt!),
                  ].join(' · '),
                ].join('\n'),
              ),
              isThreeLine: true,
              trailing: StatusChip(label: label, color: color),
              onLongPress: p.providerTxnId == null
                  ? null
                  : () {
                      Clipboard.setData(ClipboardData(text: p.providerTxnId!));
                      showMessage(context, l.copied);
                    },
              onTap: () async {
                try {
                  final a = await repo.appointment(p.appointmentId);
                  if (!context.mounted) return;
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AppointmentDetailScreen(appointment: a),
                    ),
                  );
                } catch (e) {
                  if (context.mounted) showError(context, e);
                }
              },
            ),
          );
        },
      ),
    );
  }
}
