import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../data/repository.dart';
import '../../models/models.dart';
import '../../widgets/states.dart';
import '../appointments/appointment_detail_screen.dart';

/// Ilova ichidagi bildirishnomalar tarixi. Push o'chirilgan yoki yetib
/// kelmagan bo'lsa ham xabarlar shu yerda saqlanadi.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<InboxNotification>? _items;
  int _unread = 0;
  Object? _error;

  MedLinkRepository get _repo => context.read<MedLinkRepository>();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_items == null && _error == null) _load();
  }

  Future<void> _load() async {
    try {
      final lang = Localizations.localeOf(context).languageCode;
      final r = await _repo.notifications(lang);
      if (!mounted) return;
      setState(() {
        _items = r.items;
        _unread = r.unread;
        _error = null;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  Future<void> _markAll() async {
    try {
      await _repo.markNotificationsRead();
      if (!mounted) return;
      setState(() {
        for (final i in _items ?? const <InboxNotification>[]) {
          i.read = true;
        }
        _unread = 0;
      });
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  Future<void> _open(InboxNotification n) async {
    if (!n.read) {
      setState(() {
        n.read = true;
        _unread = (_unread - 1).clamp(0, 1 << 30);
      });
      _repo.markNotificationsRead([n.id]).catchError((Object _) => 0);
    }
    final id = n.appointmentId;
    if (id == null) return;
    try {
      final a = await _repo.appointment(id);
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AppointmentDetailScreen(appointment: a),
        ),
      );
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  IconData _icon(String kind) => switch (kind) {
    'paymentConfirmed' => Icons.check_circle_outline_rounded,
    'newPatient' => Icons.person_add_alt_outlined,
    'appointmentCancelled' => Icons.event_busy_outlined,
    'appointmentReminder' => Icons.alarm_rounded,
    'appointmentRescheduled' => Icons.edit_calendar_outlined,
    'newMessage' => Icons.chat_bubble_outline_rounded,
    'consultationStarted' => Icons.videocam_outlined,
    'conclusionReady' => Icons.assignment_outlined,
    'refundCompleted' => Icons.undo_rounded,
    'doctorApproved' => Icons.verified_outlined,
    'doctorRejected' || 'doctorSuspended' => Icons.report_outlined,
    _ => Icons.notifications_none_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final items = _items;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.notifications),
        actions: [
          if (_unread > 0)
            IconButton(
              tooltip: l.markAllRead,
              icon: const Icon(Icons.done_all_rounded),
              onPressed: _markAll,
            ),
        ],
      ),
      body: items == null
          ? (_error != null
                ? ErrorView(error: _error!, onRetry: _load)
                : const SkeletonList(count: 5, height: 72))
          : RefreshIndicator.adaptive(
              onRefresh: _load,
              child: items.isEmpty
                  ? ListView(
                      children: [
                        const SizedBox(height: 80),
                        EmptyView(
                          icon: Icons.notifications_none_rounded,
                          title: l.noNotifications,
                        ),
                      ],
                    )
                  : ListView.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final n = items[i];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: n.read
                                ? context.colors.surfaceContainerHighest
                                : context.colors.primaryContainer,
                            child: Icon(
                              _icon(n.kind),
                              color: n.read
                                  ? context.colors.onSurfaceVariant
                                  : context.colors.onPrimaryContainer,
                            ),
                          ),
                          title: Text(
                            n.title,
                            style: TextStyle(
                              fontWeight: n.read
                                  ? FontWeight.w500
                                  : FontWeight.w800,
                            ),
                          ),
                          subtitle: Text(
                            '${n.body}\n${context.fmt.dateTime(n.at)}',
                          ),
                          isThreeLine: true,
                          trailing: n.read
                              ? null
                              : Container(
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(
                                    color: Brand.blue,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                          onTap: () => _open(n),
                        );
                      },
                    ),
            ),
    );
  }
}

/// Qo'ng'iroqcha belgisi o'qilmaganlar soni bilan.
class NotificationBell extends StatefulWidget {
  const NotificationBell({super.key});

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell>
    with WidgetsBindingObserver {
  int _unread = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    try {
      final lang = Localizations.localeOf(context).languageCode;
      final r = await context.read<MedLinkRepository>().notifications(lang);
      if (mounted) setState(() => _unread = r.unread);
    } catch (_) {
      // Belgi ixtiyoriy — xato bo'lsa son ko'rsatilmaydi.
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return IconButton(
      tooltip: l.notifications,
      icon: Badge(
        isLabelVisible: _unread > 0,
        label: Text(_unread > 99 ? '99+' : '$_unread'),
        child: const Icon(Icons.notifications_none_rounded),
      ),
      onPressed: () async {
        await Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const NotificationsScreen()));
        _refresh();
      },
    );
  }
}
