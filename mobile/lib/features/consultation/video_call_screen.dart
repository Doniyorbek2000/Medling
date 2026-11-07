import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:livekit_client/livekit_client.dart' as lk;
import 'package:provider/provider.dart';

import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../data/repository.dart';
import '../../widgets/brand.dart';
import '../../widgets/states.dart';

enum _CallState { connecting, waiting, inCall, reconnecting, ended, failed }

/// Onlayn konsultatsiya: LiveKit (WebRTC) video qo'ng'iroq.
///
/// Token serverdan olinadi va faqat shu qabul ishtirokchilariga, faqat qabul
/// vaqtida beriladi. Media DTLS-SRTP bilan shifrlanadi, yozib olinmaydi.
class VideoCallScreen extends StatefulWidget {
  const VideoCallScreen({
    super.key,
    required this.appointmentId,
    required this.peerTitle,
  });

  final String appointmentId;

  /// Masalan, shifokor ismi (bemor ekranida) yoki "Bemor".
  final String peerTitle;

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  final _room = lk.Room(
    roomOptions: const lk.RoomOptions(adaptiveStream: true, dynacast: true),
  );
  lk.EventsListener<lk.RoomEvent>? _listener;
  _CallState _state = _CallState.connecting;
  Object? _error;
  bool _micOn = true;
  bool _camOn = true;
  bool _frontCamera = true;
  final _started = DateTime.now();
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _room.addListener(_onRoomChanged);
    _connect();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _state == _CallState.inCall) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _listener?.dispose();
    _room.removeListener(_onRoomChanged);
    _room.disconnect();
    _room.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    setState(() {
      _state = _CallState.connecting;
      _error = null;
    });
    try {
      final t = await context.read<MedLinkRepository>().videoToken(
        widget.appointmentId,
      );
      _listener = _room.createListener()
        ..on<lk.RoomDisconnectedEvent>((_) {
          if (mounted && _state != _CallState.ended) {
            setState(() => _state = _CallState.ended);
          }
        })
        ..on<lk.RoomReconnectingEvent>((_) {
          if (mounted) setState(() => _state = _CallState.reconnecting);
        })
        ..on<lk.RoomReconnectedEvent>((_) => _onRoomChanged())
        ..on<lk.ParticipantConnectedEvent>((_) {
          HapticFeedback.mediumImpact();
          _onRoomChanged();
        })
        ..on<lk.ParticipantDisconnectedEvent>((_) => _onRoomChanged());
      await _room.connect(t.url, t.token);
      // Kamera/mikrofon ruxsati shu yerda so'raladi (flutter_webrtc).
      await _room.localParticipant?.setMicrophoneEnabled(true);
      await _room.localParticipant?.setCameraEnabled(true);
      _onRoomChanged();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _state = _CallState.failed;
        _error = e;
      });
    }
  }

  void _onRoomChanged() {
    if (!mounted || _state == _CallState.ended) return;
    setState(() {
      _state = _room.remoteParticipants.isEmpty
          ? _CallState.waiting
          : _CallState.inCall;
      _micOn = _room.localParticipant?.isMicrophoneEnabled() ?? false;
      _camOn = _room.localParticipant?.isCameraEnabled() ?? false;
    });
  }

  lk.VideoTrack? get _remoteVideo {
    final p = _room.remoteParticipants.values.firstOrNull;
    for (final pub in p?.videoTrackPublications ?? const []) {
      if (pub.subscribed && !pub.muted && pub.track != null) {
        return pub.track as lk.VideoTrack;
      }
    }
    return null;
  }

  lk.LocalVideoTrack? get _localVideo {
    for (final pub in _room.localParticipant?.videoTrackPublications ?? []) {
      if (!pub.muted && pub.track != null) return pub.track;
    }
    return null;
  }

  Future<void> _toggleMic() async {
    HapticFeedback.selectionClick();
    await _room.localParticipant?.setMicrophoneEnabled(!_micOn);
    _onRoomChanged();
  }

  Future<void> _toggleCam() async {
    HapticFeedback.selectionClick();
    await _room.localParticipant?.setCameraEnabled(!_camOn);
    _onRoomChanged();
  }

  Future<void> _flipCamera() async {
    final t = _localVideo;
    if (t == null) return;
    _frontCamera = !_frontCamera;
    await t.setCameraPosition(
      _frontCamera ? lk.CameraPosition.front : lk.CameraPosition.back,
    );
  }

  Future<void> _hangUp() async {
    final l = context.l10n;
    if (_state == _CallState.inCall) {
      final ok = await confirmDialog(
        context,
        title: l.endCall,
        message: l.endCallConfirm,
        confirm: l.endCall,
        destructive: true,
      );
      if (!ok) return;
    }
    setState(() => _state = _CallState.ended);
    await _room.disconnect();
    if (mounted) Navigator.of(context).pop();
  }

  String get _duration {
    final d = DateTime.now().difference(_started);
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return d.inHours > 0 ? '${d.inHours}:$m:$s' : '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final remote = _remoteVideo;
    final local = _localVideo;
    return PopScope(
      canPop: _state == _CallState.failed || _state == _CallState.ended,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _hangUp();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0B1626),
        body: Stack(
          fit: StackFit.expand,
          children: [
            // Suhbatdosh (to'liq ekran)
            if (remote != null)
              lk.VideoTrackRenderer(remote, fit: lk.VideoViewFit.cover)
            else
              _Placeholder(
                title: widget.peerTitle,
                status: switch (_state) {
                  _CallState.connecting => l.callConnecting,
                  _CallState.reconnecting => l.callReconnecting,
                  _CallState.failed => errorTextForCall(context, _error),
                  _CallState.ended => l.callEnded,
                  _ => l.callWaiting,
                },
                busy:
                    _state == _CallState.connecting ||
                    _state == _CallState.reconnecting ||
                    _state == _CallState.waiting,
              ),
            // Yuqori panel
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(
                      Icons.lock_outline,
                      color: Colors.white70,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _state == _CallState.inCall
                            ? '${widget.peerTitle} · $_duration'
                            : l.callEncrypted,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // O'z kamerangiz (kichik oyna)
            if (local != null && _camOn)
              Positioned(
                right: 16,
                top: MediaQuery.paddingOf(context).top + 56,
                width: 110,
                height: 160,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: lk.VideoTrackRenderer(
                    local,
                    fit: lk.VideoViewFit.cover,
                    mirrorMode: _frontCamera
                        ? lk.VideoViewMirrorMode.mirror
                        : lk.VideoViewMirrorMode.off,
                  ),
                ),
              ),
            // Boshqaruv tugmalari
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: _state == _CallState.failed
                      ? Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: Text(l.close),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: FilledButton(
                                  onPressed: _connect,
                                  child: Text(l.retry),
                                ),
                              ),
                            ],
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _RoundButton(
                              icon: _micOn ? Icons.mic : Icons.mic_off,
                              label: _micOn ? l.mute : l.unmute,
                              active: _micOn,
                              onTap: _toggleMic,
                            ),
                            _RoundButton(
                              icon: _camOn
                                  ? Icons.videocam
                                  : Icons.videocam_off,
                              label: _camOn ? l.cameraOff : l.cameraOn,
                              active: _camOn,
                              onTap: _toggleCam,
                            ),
                            _RoundButton(
                              icon: Icons.cameraswitch_outlined,
                              label: l.switchCamera,
                              active: true,
                              onTap: _camOn ? _flipCamera : null,
                            ),
                            _RoundButton(
                              icon: Icons.call_end,
                              label: l.endCall,
                              color: Brand.danger,
                              active: true,
                              onTap: _hangUp,
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Video qo'ng'iroq xatolarini tushunarli matnga aylantiradi.
String errorTextForCall(BuildContext context, Object? e) {
  final l = context.l10n;
  final text = e.toString().toLowerCase();
  if (text.contains('permission') || text.contains('notallowed')) {
    return l.callPermissionDenied;
  }
  if (e != null) {
    final api = errorText(context, e);
    if (api != l.errorGeneric) return api;
  }
  return l.callFailed;
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({
    required this.title,
    required this.status,
    required this.busy,
  });
  final String title;
  final String status;
  final bool busy;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const MedLinkLogo(size: 88, showName: false),
          const SizedBox(height: 24),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            status,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70),
          ),
          if (busy) ...[
            const SizedBox(height: 24),
            const CircularProgressIndicator.adaptive(
              valueColor: AlwaysStoppedAnimation(Colors.white),
            ),
          ],
        ],
      ),
    ),
  );
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: color ?? (active ? Colors.white24 : Colors.white),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(
              width: 60,
              height: 60,
              child: Icon(
                icon,
                color: color != null || active ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        ExcludeSemantics(
          child: Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ),
      ],
    ),
  );
}
