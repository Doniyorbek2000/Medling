import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../data/repository.dart';
import '../../models/models.dart';
import '../../widgets/reason_sheet.dart';
import '../../widgets/states.dart';
import '../appointments/appointment_status.dart';
import '../doctors/specialty.dart';
import 'admin_doctor_screen.dart';

/// Gorizontal filtr chiplari (bitta tanlov).
class FilterChips<T> extends StatelessWidget {
  const FilterChips({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  final List<(T, String)> options;
  final T value;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 48,
    child: ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      scrollDirection: Axis.horizontal,
      itemCount: options.length,
      separatorBuilder: (_, _) => const SizedBox(width: 8),
      itemBuilder: (_, i) {
        final (v, label) = options[i];
        return ChoiceChip(
          label: Text(label),
          selected: v == value,
          showCheckmark: false,
          onSelected: (_) => onChanged(v),
        );
      },
    ),
  );
}

(String, Color) doctorStatus(AppLocalizations l, String s) => switch (s) {
  'approved' => (l.statusApproved, Brand.success),
  'suspended' => (l.statusSuspended, Brand.danger),
  'rejected' => (l.statusRejected, Colors.grey),
  _ => (l.statusPending, Brand.warning),
};

String _shortId(String id) => id.length > 8 ? id.substring(0, 8) : id;

// ---------------------------------------------------------------------------
// Shifokorlar
// ---------------------------------------------------------------------------
class AdminDoctorsTab extends StatefulWidget {
  const AdminDoctorsTab({super.key});

  @override
  State<AdminDoctorsTab> createState() => _AdminDoctorsTabState();
}

class _AdminDoctorsTabState extends State<AdminDoctorsTab> {
  String? _status = 'approved';
  String _q = '';
  int _version = 0;
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final repo = context.read<MedLinkRepository>();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: TextField(
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search_rounded),
              hintText: l.searchDoctors,
            ),
            onChanged: (v) {
              _debounce?.cancel();
              _debounce = Timer(const Duration(milliseconds: 350), () {
                if (mounted) setState(() => _q = v.trim());
              });
            },
          ),
        ),
        FilterChips<String?>(
          value: _status,
          onChanged: (v) => setState(() => _status = v),
          options: [
            ('approved', l.statusApproved),
            ('suspended', l.statusSuspended),
            ('pending', l.statusPending),
            ('rejected', l.statusRejected),
            (null, l.all),
          ],
        ),
        Expanded(
          child: AsyncList<Map<String, dynamic>>(
            key: ValueKey('$_status|$_q|$_version'),
            load: () => repo.adminDoctors(status: _status, q: _q),
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            separator: 8,
            empty: EmptyView(
              icon: Icons.search_off_rounded,
              title: l.noResults,
            ),
            itemBuilder: (context, d, _) {
              final (label, color) = doctorStatus(l, d['status'] as String);
              return Card(
                child: ListTile(
                  title: Text(d['fullName'] as String),
                  subtitle: Text(
                    '${specialtyName(l, d['specialty'] as String)} · '
                    '${d['clinic']}\n'
                    '★ ${(d['rating'] as num).toStringAsFixed(1)} · '
                    '${l.upcoming}: ${d['upcoming']}',
                  ),
                  isThreeLine: true,
                  trailing: StatusChip(label: label, color: color),
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            AdminDoctorScreen(doctorId: d['id'] as String),
                      ),
                    );
                    if (mounted) setState(() => _version++);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Foydalanuvchilar
// ---------------------------------------------------------------------------
class AdminUsersTab extends StatefulWidget {
  const AdminUsersTab({super.key});

  @override
  State<AdminUsersTab> createState() => _AdminUsersTabState();
}

class _AdminUsersTabState extends State<AdminUsersTab> {
  String _filter = 'all';
  String _q = '';
  int _version = 0;
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String _role(AppLocalizations l, String r) => switch (r) {
    'doctor' => l.roleDoctor,
    'admin' => l.roleAdmin,
    _ => l.rolePatient,
  };

  Future<void> _toggleBlock(AdminUser u) async {
    final l = context.l10n;
    final repo = context.read<MedLinkRepository>();
    String? reason;
    if (!u.blocked) {
      reason = await askReason(
        context,
        title: l.blockUser,
        hint: l.blockReasonHint,
        confirm: l.blockUser,
        warning: l.blockWarning,
      );
      if (reason == null) return;
    } else {
      final ok = await confirmDialog(
        context,
        title: l.unblockUser,
        message: l.unblockConfirm,
        confirm: l.unblockUser,
      );
      if (!ok) return;
    }
    try {
      await repo.setUserBlocked(u.id, blocked: !u.blocked, reason: reason);
      if (mounted) setState(() => _version++);
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final repo = context.read<MedLinkRepository>();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: TextField(
            controller: _ctrl,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
            ],
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.phone_rounded),
              hintText: l.searchByPhone,
              suffixIcon: IconButton(
                tooltip: l.findDoctor,
                icon: const Icon(Icons.search_rounded),
                onPressed: () => setState(() => _q = _ctrl.text.trim()),
              ),
            ),
            onSubmitted: (v) => setState(() => _q = v.trim()),
          ),
        ),
        FilterChips<String>(
          value: _filter,
          onChanged: (v) => setState(() => _filter = v),
          options: [
            ('all', l.all),
            ('patient', l.rolePatient),
            ('doctor', l.roleDoctor),
            ('blocked', l.blocked),
          ],
        ),
        Expanded(
          child: AsyncList<AdminUser>(
            key: ValueKey('$_filter|$_q|$_version'),
            load: () => repo.adminUsers(
              q: _q,
              role: _filter == 'patient' || _filter == 'doctor'
                  ? _filter
                  : null,
              blockedOnly: _filter == 'blocked',
            ),
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            separator: 8,
            empty: EmptyView(
              icon: Icons.person_search_rounded,
              title: l.noResults,
            ),
            itemBuilder: (context, u, _) => Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            u.phone,
                            style: context.text.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (u.blocked)
                          StatusChip(label: l.blocked, color: Brand.danger)
                        else
                          StatusChip(
                            label: _role(l, u.role),
                            color: u.role == 'doctor' ? Brand.teal : Brand.blue,
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${l.registeredAt(context.fmt.date(u.createdAt))} · '
                      '${l.appointmentsCount(u.appointments)}',
                      style: context.text.bodySmall?.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      'ID ${_shortId(u.id)}',
                      style: context.text.bodySmall?.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                    if (u.blocked && u.blockReason != null) ...[
                      const SizedBox(height: 4),
                      Text('${l.reason}: ${u.blockReason}'),
                    ],
                    if (u.role != 'admin') ...[
                      const SizedBox(height: 8),
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: u.blocked
                            ? OutlinedButton(
                                onPressed: () => _toggleBlock(u),
                                child: Text(l.unblockUser),
                              )
                            : OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: context.ink(Brand.danger),
                                ),
                                onPressed: () => _toggleBlock(u),
                                child: Text(l.blockUser),
                              ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Qabullar (tibbiy mazmunsiz)
// ---------------------------------------------------------------------------
class AdminAppointmentsTab extends StatefulWidget {
  const AdminAppointmentsTab({super.key});

  @override
  State<AdminAppointmentsTab> createState() => _AdminAppointmentsTabState();
}

class _AdminAppointmentsTabState extends State<AdminAppointmentsTab> {
  String? _status = 'confirmed';

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final repo = context.read<MedLinkRepository>();
    return Column(
      children: [
        FilterChips<String?>(
          value: _status,
          onChanged: (v) => setState(() => _status = v),
          options: [
            ('confirmed', l.statusConfirmed),
            ('awaitingPayment', l.statusAwaitingPayment),
            ('completed', l.statusCompleted),
            ('cancelled', l.statusCancelled),
            (null, l.all),
          ],
        ),
        Expanded(
          child: AsyncList<AdminAppointment>(
            key: ValueKey(_status),
            load: () => repo.adminAppointments(status: _status),
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            separator: 8,
            empty: EmptyView(
              icon: Icons.event_busy_rounded,
              title: l.noResults,
            ),
            itemBuilder: (context, a, _) {
              final (label, color) = appointmentStatus(l, a.status);
              return Card(
                child: ListTile(
                  leading: Icon(
                    a.type == 'online'
                        ? Icons.videocam_outlined
                        : Icons.local_hospital_outlined,
                  ),
                  title: Text(a.doctorName ?? '—'),
                  subtitle: Text(
                    '${context.fmt.dateTime(a.startsAt)} · '
                    '${context.fmt.money(a.priceUzs)}\n'
                    '${a.paid ? l.paidLabel : l.unpaidLabel}'
                    '${a.refundStatus == 'none' ? '' : ' · ${l.refunds}: ${a.refundStatus == 'refunded' ? l.orderRefunded : l.orderPending}'}',
                  ),
                  isThreeLine: true,
                  trailing: StatusChip(label: label, color: color),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// To'lovlar
// ---------------------------------------------------------------------------
class AdminPaymentsTab extends StatefulWidget {
  const AdminPaymentsTab({super.key});

  @override
  State<AdminPaymentsTab> createState() => _AdminPaymentsTabState();
}

class _AdminPaymentsTabState extends State<AdminPaymentsTab> {
  String? _provider;
  int? _sum;

  static String providerName(String p) => switch (p) {
    'click' => 'Click',
    'payme' => 'Payme',
    'googlePay' => 'Google Pay',
    'applePay' => 'Apple Pay',
    _ => p,
  };

  (String, Color) _status(AppLocalizations l, String s) => switch (s) {
    'paid' => (l.paidLabel, Brand.success),
    'processing' => (l.orderProcessing, Brand.warning),
    'cancelled' => (l.orderCancelled, Colors.grey),
    'refunded' => (l.orderRefunded, Brand.blue),
    _ => (l.orderPending, Brand.warning),
  };

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final repo = context.read<MedLinkRepository>();
    return Column(
      children: [
        FilterChips<String?>(
          value: _provider,
          onChanged: (v) => setState(() {
            _provider = v;
            _sum = null;
          }),
          options: [
            (null, l.all),
            for (final p in ['click', 'payme', 'googlePay', 'applePay'])
              (p, providerName(p)),
          ],
        ),
        if (_sum != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                l.totalPaid(context.fmt.money(_sum!)),
                style: context.text.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        Expanded(
          child: AsyncList<AdminPayment>(
            key: ValueKey(_provider),
            load: () async {
              final r = await repo.adminPayments(provider: _provider);
              if (mounted && _sum != r.sumPaidUzs) {
                WidgetsBinding.instance.addPostFrameCallback(
                  (_) => mounted ? setState(() => _sum = r.sumPaidUzs) : null,
                );
              }
              return r.items;
            },
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            separator: 8,
            empty: EmptyView(
              icon: Icons.receipt_long_outlined,
              title: l.noResults,
            ),
            itemBuilder: (context, o, _) {
              final (label, color) = _status(l, o.status);
              return Card(
                child: ListTile(
                  title: Text(
                    context.fmt.money(o.amountUzs),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    '${providerName(o.provider)} · '
                    '${context.fmt.dateTime(o.createdAt)}'
                    '${o.providerTxnId == null ? '' : '\n${o.providerTxnId}'}',
                  ),
                  isThreeLine: o.providerTxnId != null,
                  trailing: StatusChip(label: label, color: color),
                  onLongPress: o.providerTxnId == null
                      ? null
                      : () {
                          Clipboard.setData(
                            ClipboardData(text: o.providerTxnId!),
                          );
                          showMessage(context, l.copied);
                        },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Audit jurnali
// ---------------------------------------------------------------------------
class AdminAuditTab extends StatefulWidget {
  const AdminAuditTab({super.key});

  @override
  State<AdminAuditTab> createState() => _AdminAuditTabState();
}

class _AdminAuditTabState extends State<AdminAuditTab> {
  String? _action;

  IconData _icon(String action) => switch (action.split('.').first) {
    'user' || 'me' => Icons.person_outline_rounded,
    'doctor' => Icons.medical_services_outlined,
    'refund' || 'payment' => Icons.payments_outlined,
    'patient' || 'triage' || 'conclusion' => Icons.health_and_safety_outlined,
    'review' => Icons.rate_review_outlined,
    _ => Icons.history_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final repo = context.read<MedLinkRepository>();
    return Column(
      children: [
        FilterChips<String?>(
          value: _action,
          onChanged: (v) => setState(() => _action = v),
          options: [
            (null, l.all),
            ('user.', l.users),
            ('doctor.', l.tabDoctors),
            ('refund.', l.refunds),
            ('patient.', l.medicalData),
            ('review.', l.reviews),
          ],
        ),
        Expanded(
          child: AsyncList<AuditEntry>(
            key: ValueKey(_action),
            load: () => repo.auditLog(action: _action),
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            separator: 4,
            empty: EmptyView(icon: Icons.history_rounded, title: l.noResults),
            itemBuilder: (context, e, _) => ListTile(
              dense: true,
              leading: Icon(_icon(e.action)),
              title: Text(
                e.action,
                style: const TextStyle(fontFamily: 'monospace'),
              ),
              subtitle: Text(
                '${context.fmt.dateTime(e.at)} · '
                '${l.actorLabel(_shortId(e.actorId))}'
                '${e.resourceId == null ? '' : ' · ${e.resource} ${_shortId(e.resourceId!)}'}',
              ),
            ),
          ),
        ),
      ],
    );
  }
}
