import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// iOS sozlamalari App Store tekshiruvidan o'tishi uchun: privacy manifest
/// ilovaga qo'shilgan, ruxsat so'rovlari uchun tavsiflar bor.
void main() {
  test('PrivacyInfo.xcprivacy mavjud va Resources bosqichida', () {
    final manifest = File('ios/Runner/PrivacyInfo.xcprivacy');
    expect(manifest.existsSync(), isTrue);
    final xml = manifest.readAsStringSync();
    expect(xml, contains('<key>NSPrivacyTracking</key>\n\t<false/>'));
    expect(xml, contains('NSPrivacyCollectedDataTypeHealth'));

    final pbx = File('ios/Runner.xcodeproj/project.pbxproj').readAsStringSync();
    expect(
      RegExp('PrivacyInfo.xcprivacy in Resources').allMatches(pbx).length,
      2, // PBXBuildFile + Resources ro'yxati
    );
  });

  test('Info.plist: har bir ruxsat uchun tushuntirish bor', () {
    final plist = File('ios/Runner/Info.plist').readAsStringSync();
    for (final key in [
      'NSFaceIDUsageDescription',
      'NSCameraUsageDescription',
      'NSMicrophoneUsageDescription',
      'NSPhotoLibraryUsageDescription',
    ]) {
      expect(plist, contains(key), reason: key);
    }
  });
}
