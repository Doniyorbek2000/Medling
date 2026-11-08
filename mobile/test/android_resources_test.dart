import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Android resurslari: manifest va XML fayllar havola qilgan `@color/...`
/// va `@drawable/...` resurslari mavjudligini tekshiradi. (Bir marta
/// colors.xml ustidan yozilib, release build "resource not found" bilan
/// yiqilgan edi — bu test uni lokal `flutter test` da ushlaydi.)
void main() {
  final res = Directory('android/app/src/main/res');

  Set<String> defined(String type) {
    final names = <String>{};
    for (final f in res.listSync(recursive: true).whereType<File>()) {
      final rel = f.path.substring(res.path.length + 1);
      final dir = rel.split(Platform.pathSeparator).first;
      if (type == 'color' && rel.endsWith('.xml') && dir.startsWith('values')) {
        for (final m in RegExp(
          r'<color name="([^"]+)"',
        ).allMatches(f.readAsStringSync())) {
          names.add(m.group(1)!);
        }
      }
      if (type == 'drawable' &&
          (dir.startsWith('drawable') || dir.startsWith('mipmap'))) {
        names.add(rel.split(Platform.pathSeparator).last.split('.').first);
      }
    }
    return names;
  }

  test('havola qilingan @color va @drawable resurslari mavjud', () {
    final colors = defined('color');
    final drawables = defined('drawable');
    final files = [
      File('android/app/src/main/AndroidManifest.xml'),
      ...res
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.xml')),
    ];
    final missing = <String>[];
    for (final f in files) {
      final text = f.readAsStringSync();
      for (final m in RegExp(r'@color/([A-Za-z0-9_]+)').allMatches(text)) {
        if (!colors.contains(m.group(1))) {
          missing.add('${f.path}: @color/${m.group(1)}');
        }
      }
      for (final m in RegExp(r'@drawable/([A-Za-z0-9_]+)').allMatches(text)) {
        if (!drawables.contains(m.group(1))) {
          missing.add('${f.path}: @drawable/${m.group(1)}');
        }
      }
    }
    expect(missing, isEmpty);
  });
}
