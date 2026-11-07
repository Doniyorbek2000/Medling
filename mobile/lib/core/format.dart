import 'package:intl/intl.dart';

final _money = NumberFormat.decimalPattern('ru');

String formatUzs(int amount) => '${_money.format(amount)} so\'m';

const _months = [
  'yanvar',
  'fevral',
  'mart',
  'aprel',
  'may',
  'iyun',
  'iyul',
  'avgust',
  'sentabr',
  'oktabr',
  'noyabr',
  'dekabr',
];

String formatDate(DateTime d) => '${d.day}-${_months[d.month - 1]}';

String formatTime(DateTime d) =>
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

String formatDateTime(DateTime d) => '${formatDate(d)}, ${formatTime(d)}';
