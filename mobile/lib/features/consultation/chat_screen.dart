import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../data/repository.dart';
import '../../models/models.dart';
import '../../widgets/brand.dart';
import '../../widgets/states.dart';

/// Qabul chati (bemor ↔ shifokor). Xabarlar serverda shifrlangan; ekran
/// ochiq paytda har 4 soniyada yangilanadi, fonda — to'xtaydi.
class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    required this.appointmentId,
    required this.title,
    this.subtitle,
  });

  final String appointmentId;
  final String title;
  final String? subtitle;

  static const pollEvery = Duration(seconds: 4);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _messages = <ChatMessage>[];
  final _pending = <String>[];
  bool _loading = true;
  bool _canWrite = true;
  bool _sending = false;
  bool _uploading = false;
  Object? _error;
  Timer? _poll;

  MedLinkRepository get _repo => context.read<MedLinkRepository>();
  int get _lastSeq => _messages.isEmpty ? 0 : _messages.last.seq;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh(initial: true);
    _startPolling();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _poll?.cancel();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refresh();
      _startPolling();
    } else if (state == AppLifecycleState.paused) {
      _poll?.cancel();
    }
  }

  void _startPolling() {
    _poll?.cancel();
    _poll = Timer.periodic(ChatScreen.pollEvery, (_) => _refresh());
  }

  Future<void> _refresh({bool initial = false}) async {
    try {
      final res = await _repo.messages(widget.appointmentId, after: _lastSeq);
      if (!mounted) return;
      final known = _messages.map((m) => m.id).toSet();
      final fresh = res.items.where((m) => !known.contains(m.id)).toList();
      setState(() {
        _messages.addAll(fresh);
        _canWrite = res.canWrite;
        _loading = false;
        _error = null;
      });
      if (fresh.isNotEmpty || initial) _scrollToEnd();
    } catch (e) {
      if (mounted && initial) {
        setState(() {
          _loading = false;
          _error = e;
        });
      }
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: context.motion(const Duration(milliseconds: 250)),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() {
      _sending = true;
      _pending.add(text);
    });
    _input.clear();
    _scrollToEnd();
    try {
      final m = await _repo.sendMessage(widget.appointmentId, text);
      HapticFeedback.lightImpact();
      if (!mounted) return;
      setState(() {
        _pending.remove(text);
        if (!_messages.any((x) => x.id == m.id)) _messages.add(m);
        _messages.sort((a, b) => a.seq.compareTo(b.seq));
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _pending.remove(text));
      _input.text = text; // matn yo'qolmasin
      showError(context, e);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _attach() async {
    final l = context.l10n;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (c) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(l.takePhoto),
              onTap: () => Navigator.pop(c, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(l.chooseFromGallery),
              onTap: () => Navigator.pop(c, ImageSource.gallery),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Text(
                l.attachmentHint,
                style: Theme.of(c).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;
    XFile? file;
    try {
      // Qayta kodlash (maxWidth/imageQuality) joylashuv kabi EXIF
      // metama'lumotlarini olib tashlaydi; to'liq metadata so'ralmaydi.
      file = await ImagePicker().pickImage(
        source: source,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 85,
        requestFullMetadata: false,
      );
    } catch (_) {
      if (mounted) showMessage(context, l.callPermissionDenied);
      return;
    }
    if (file == null || !mounted) return;
    setState(() => _uploading = true);
    _scrollToEnd();
    try {
      final bytes = await file.readAsBytes();
      final m = await _repo.uploadAttachment(
        widget.appointmentId,
        bytes,
        file.name,
      );
      HapticFeedback.lightImpact();
      if (!mounted) return;
      setState(() {
        if (!_messages.any((x) => x.id == m.id)) _messages.add(m);
        _messages.sort((a, b) => a.seq.compareTo(b.seq));
      });
      _scrollToEnd();
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title, overflow: TextOverflow.ellipsis),
            if (widget.subtitle != null)
              Text(
                widget.subtitle!,
                style: context.text.bodySmall?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
            child: EmergencyBanner(text: l.chatEmergencyNote, compact: true),
          ),
          Expanded(child: _body(context)),
          _composer(context),
        ],
      ),
    );
  }

  Widget _body(BuildContext context) {
    final l = context.l10n;
    if (_loading) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }
    if (_error != null) {
      return ErrorView(
        error: _error!,
        onRetry: () {
          setState(() {
            _loading = true;
            _error = null;
          });
          _refresh(initial: true);
        },
      );
    }
    if (_messages.isEmpty && _pending.isEmpty) {
      return EmptyView(
        icon: Icons.forum_outlined,
        title: l.chatEmptyTitle,
        subtitle: l.chatEmptyBody,
      );
    }
    final items = <Widget>[];
    DateTime? lastDay;
    for (final m in _messages) {
      final day = DateTime(m.at.year, m.at.month, m.at.day);
      if (lastDay != day) {
        final today = DateTime.now();
        final isToday = day == DateTime(today.year, today.month, today.day);
        items.add(
          _DayChip(text: isToday ? l.today : context.fmt.fullDate(m.at)),
        );
        lastDay = day;
      }
      items.add(_Bubble(message: m, appointmentId: widget.appointmentId));
    }
    for (final p in _pending) {
      items.add(_Bubble.pending(text: p));
    }
    if (_uploading) items.add(_Bubble.pending(text: l.uploadingPhoto));
    return ListView(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      children: items,
    );
  }

  Widget _composer(BuildContext context) {
    final l = context.l10n;
    if (!_canWrite) {
      return SafeArea(
        top: false,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: context.colors.surface,
          child: Text(
            l.chatClosed,
            textAlign: TextAlign.center,
            style: TextStyle(color: context.colors.onSurfaceVariant),
          ),
        ),
      );
    }
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
        decoration: BoxDecoration(
          color: context.colors.surface,
          border: Border(top: BorderSide(color: context.colors.outlineVariant)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            IconButton(
              tooltip: l.attachPhoto,
              onPressed: _uploading ? null : _attach,
              icon: const Icon(Icons.add_photo_alternate_outlined),
            ),
            Expanded(
              child: TextField(
                controller: _input,
                minLines: 1,
                maxLines: 5,
                maxLength: 2000,
                textCapitalization: TextCapitalization.sentences,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: l.chatHint,
                  counterText: '',
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              tooltip: l.send,
              onPressed: _input.text.trim().isEmpty || _sending ? null : _send,
              icon: const Icon(Icons.send_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: context.colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(text, style: context.text.labelSmall),
      ),
    ),
  );
}

class _Bubble extends StatelessWidget {
  const _Bubble({required ChatMessage this.message, this.appointmentId})
    : pendingText = null;
  const _Bubble.pending({required String text})
    : message = null,
      appointmentId = null,
      pendingText = text;

  final ChatMessage? message;
  final String? pendingText;
  final String? appointmentId;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final m = message;
    final mine = m?.mine ?? true;
    final bg = mine
        ? context.colors.primary
        : context.colors.surfaceContainerHighest;
    final fg = mine ? context.colors.onPrimary : context.colors.onSurface;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 3),
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(mine ? 16 : 4),
              bottomRight: Radius.circular(mine ? 4 : 16),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (m != null && !mine)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    m.senderRole == 'doctor' ? l.roleDoctor : l.rolePatient,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: context.ink(Brand.teal),
                    ),
                  ),
                ),
              if (m?.attachment case final att? when att.isImage)
                _ImageAttachment(appointmentId: appointmentId!, attachment: att)
              else
                SelectableText(
                  m?.text ?? pendingText!,
                  style: TextStyle(color: fg, height: 1.35),
                ),
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    m == null ? l.sending : context.fmt.time(m.at),
                    style: TextStyle(
                      fontSize: 11,
                      color: fg.withValues(alpha: 0.75),
                    ),
                  ),
                  if (mine) ...[
                    const SizedBox(width: 4),
                    Icon(
                      m == null ? Icons.schedule : Icons.done_rounded,
                      size: 13,
                      color: fg.withValues(alpha: 0.75),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Chatdagi rasm: avtorizatsiya bilan yuklanadi, bosilsa to'liq ekranda.
class _ImageAttachment extends StatelessWidget {
  const _ImageAttachment({
    required this.appointmentId,
    required this.attachment,
  });

  final String appointmentId;
  final ChatAttachment attachment;

  @override
  Widget build(BuildContext context) {
    final future = context.read<MedLinkRepository>().attachmentBytes(
      appointmentId,
      attachment.id,
    );
    return FutureBuilder<Uint8List>(
      future: future,
      builder: (context, snap) {
        final bytes = snap.data;
        return Semantics(
          image: true,
          label: attachment.name,
          button: bytes != null,
          child: GestureDetector(
            onTap: bytes == null
                ? null
                : () => Navigator.of(context).push(
                    MaterialPageRoute(
                      fullscreenDialog: true,
                      builder: (_) =>
                          _ImageViewer(bytes: bytes, title: attachment.name),
                    ),
                  ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 220,
                height: 220,
                child: bytes != null
                    ? Image.memory(
                        bytes,
                        fit: BoxFit.cover,
                        gaplessPlayback: true,
                      )
                    : ColoredBox(
                        color: Colors.black12,
                        child: Center(
                          child: snap.hasError
                              ? const Icon(Icons.broken_image_outlined)
                              : const CircularProgressIndicator.adaptive(),
                        ),
                      ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ImageViewer extends StatelessWidget {
  const _ImageViewer({required this.bytes, required this.title});
  final Uint8List bytes;
  final String title;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    appBar: AppBar(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      title: Text(title, style: const TextStyle(color: Colors.white)),
    ),
    body: Center(
      child: InteractiveViewer(maxScale: 5, child: Image.memory(bytes)),
    ),
  );
}
