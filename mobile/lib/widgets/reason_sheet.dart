import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Sabab so'raydigan pastki oyna (rad etish, to'xtatish, bloklash).
/// Bo'sh sabab qabul qilinmaydi. Bekor qilinsa — null.
Future<String?> askReason(
  BuildContext context, {
  required String title,
  required String hint,
  required String confirm,
  String? warning,
}) => showModalBottomSheet<String>(
  context: context,
  isScrollControlled: true,
  builder: (_) => _ReasonSheet(
    title: title,
    hint: hint,
    confirm: confirm,
    warning: warning,
  ),
);

class _ReasonSheet extends StatefulWidget {
  const _ReasonSheet({
    required this.title,
    required this.hint,
    required this.confirm,
    this.warning,
  });
  final String title;
  final String hint;
  final String confirm;
  final String? warning;

  @override
  State<_ReasonSheet> createState() => _ReasonSheetState();
}

class _ReasonSheetState extends State<_ReasonSheet> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      20,
      0,
      20,
      MediaQuery.viewInsetsOf(context).bottom + 20,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.title,
          style: context.text.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        if (widget.warning != null) ...[
          const SizedBox(height: 8),
          Text(
            widget.warning!,
            style: context.text.bodyMedium?.copyWith(
              color: context.ink(Brand.danger),
            ),
          ),
        ],
        const SizedBox(height: 12),
        TextField(
          controller: _ctrl,
          autofocus: true,
          maxLines: 3,
          maxLength: 500,
          decoration: InputDecoration(hintText: widget.hint),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 8),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Brand.danger),
          onPressed: _ctrl.text.trim().isEmpty
              ? null
              : () => Navigator.pop(context, _ctrl.text.trim()),
          child: Text(widget.confirm),
        ),
      ],
    ),
  );
}
