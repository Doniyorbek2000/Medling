import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import 'clinic_time.dart';
import 'l10n.dart';

/// Lokalga mos formatlash. `intl` o'zbek tilida oy nomlarini qo'llab-quvvatlaydi.
///
/// UTC belgili vaqtlar (qabullar, slotlar) Toshkent vaqtida, lokal vaqtlar
/// (masalan, tahlil qilingan payt) qurilma vaqtida ko'rsatiladi.
class Fmt {
  Fmt(this.context);
  final BuildContext context;

  String get _locale => Localizations.localeOf(context).languageCode;

  String money(int amount) =>
      context.l10n.priceUzs(NumberFormat.decimalPattern('ru').format(amount));

  String date(DateTime d) => DateFormat.MMMMd(_locale).format(_w(d));

  String weekdayShort(DateTime d) => DateFormat.E(_locale).format(_w(d));

  String time(DateTime d) => DateFormat.Hm(_locale).format(_w(d));

  String dateTime(DateTime d) => '${date(d)}, ${time(d)}';

  String fullDate(DateTime d) => DateFormat.yMMMMd(_locale).format(_w(d));

  DateTime _w(DateTime d) => d.isUtc ? clinicWall(d) : d;
}

extension FmtX on BuildContext {
  Fmt get fmt => Fmt(this);
}
