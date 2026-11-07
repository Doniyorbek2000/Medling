/// Barcha klinikalar Toshkent vaqtida ishlaydi (Asia/Tashkent, UTC+5, yozgi
/// vaqt yo'q). Qabul vaqtlari qurilma qaysi vaqt zonasida bo'lishidan qat'i
/// nazar Toshkent vaqti bilan ko'rsatiladi — aks holda chet eldagi foydalanuvchi
/// 09:00 dagi qabulni 04:00 deb ko'radi.
const clinicOffset = Duration(hours: 5);

/// UTC vaqtni Toshkent "devor soati"ga aylantiradi (faqat ko'rsatish uchun).
DateTime clinicWall(DateTime instant) => instant.toUtc().add(clinicOffset);

/// Toshkent bo'yicha bugungi sana (00:00, UTC belgili).
DateTime clinicToday() {
  final w = clinicWall(DateTime.now());
  return DateTime.utc(w.year, w.month, w.day);
}

/// Qurilma vaqt zonasi Toshkentnikidan farq qiladimi.
bool get deviceOutsideClinicZone =>
    DateTime.now().timeZoneOffset != clinicOffset;
