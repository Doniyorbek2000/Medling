import 'package:flutter/material.dart';

import '../../core/l10n.dart';
import '../../core/theme.dart';

(String, Color) appointmentStatus(AppLocalizations l, String status) =>
    switch (status) {
      'awaitingPayment' => (l.statusAwaitingPayment, Brand.warning),
      'confirmed' => (l.statusConfirmed, Brand.success),
      'completed' => (l.statusCompleted, Brand.blue),
      'cancelled' => (l.statusCancelled, Colors.grey),
      _ => (status, Colors.grey),
    };
