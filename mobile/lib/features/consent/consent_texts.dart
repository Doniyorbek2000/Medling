/// Rozilik matnlari. DIQQAT: bular namunaviy matnlar — ishga tushirishdan
/// oldin yurist tomonidan tekshirilishi va backend'dagi versiya bilan
/// moslashtirilishi shart.
class ConsentText {
  const ConsentText(this.title, this.summary, this.body);
  final String title;
  final String summary;
  final String body;
}

const consentTexts = <String, ConsentText>{
  'terms': ConsentText(
    'Foydalanish shartlari',
    'MedLink xizmatidan foydalanish qoidalari.',
    'MedLink — bemorlarni litsenziyaga ega shifokorlar bilan bog\'lovchi '
        'axborot platformasi. Platforma tibbiy yordam ko\'rsatmaydi va '
        'shoshilinch tibbiy yordam xizmati o\'rnini bosmaydi. Hayot uchun '
        'xavfli holatlarda 103 raqamiga qo\'ng\'iroq qiling. Shifokorlar '
        'diplomi va litsenziyasi platforma moderatorlari tomonidan '
        'tekshiriladi.',
  ),
  'personalData': ConsentText(
    'Shaxsga doir ma\'lumotlarni qayta ishlash',
    'Telefon raqamingiz va profil ma\'lumotlaringizni saqlash.',
    '"Shaxsga doir ma\'lumotlar to\'g\'risida"gi O\'zbekiston Respublikasi '
        'Qonuniga muvofiq, telefon raqamingiz, ism-familiyangiz va qabul '
        'tarixingiz xizmat ko\'rsatish maqsadida qayta ishlanadi. '
        'Ma\'lumotlar shifrlangan holda saqlanadi. Siz istalgan vaqtda '
        'ma\'lumotlaringiz nusxasini olishingiz, ularni o\'zgartirish yoki '
        'o\'chirishni talab qilishingiz mumkin.',
  ),
  'healthData': ConsentText(
    'Sog\'liq haqidagi ma\'lumotlar',
    'Alomatlar, qabul sababi va shifokor xulosalarini saqlash.',
    'Sog\'lig\'ingiz haqidagi ma\'lumotlar alohida toifadagi ma\'lumot '
        'hisoblanadi. Ular AES-256 bilan shifrlanadi, faqat siz va siz '
        'tanlagan shifokor ko\'ra oladi. Har bir murojaat audit jurnalida '
        'qayd etiladi. Ma\'lumotlar uchinchi shaxslarga reklama maqsadida '
        'berilmaydi.',
  ),
  'aiProcessing': ConsentText(
    'Sun\'iy intellekt tahlili',
    'Alomatlaringizni AI modeli (Google Med-PaLM 2) orqali tahlil qilish.',
    'Alomatlar tahlili funksiyasidan foydalansangiz, kiritgan matningiz, '
        'yoshingiz va jinsingiz AI modeliga yuboriladi. Ism, telefon va '
        'boshqa identifikatorlar yuborilmaydi. AI natijasi tashxis emas — '
        'u faqat qaysi shifokorga murojaat qilishni tavsiya qiladi. '
        'Rozilikni qaytarib olsangiz, AI tahlillaringiz tarixi o\'chiriladi. '
        'Bu rozilik ixtiyoriy: usiz ham shifokorga yozilishingiz mumkin.',
  ),
  'crossBorderTransfer': ConsentText(
    'Ma\'lumotni xorijga uzatish',
    'AI tahlili uchun ma\'lumot Google Cloud serverlariga uzatiladi.',
    'AI modeli O\'zbekistondan tashqarida joylashgan Google Cloud '
        'serverlarida ishlaydi. Tahlil uchun shaxsiylashtirilmagan alomatlar '
        'matni shifrlangan kanal (TLS) orqali uzatiladi va model tomonidan '
        'saqlanmaydi. AI tahlilidan foydalanish uchun bu rozilik zarur.',
  ),
  'marketing': ConsentText(
    'Xabarnomalar va aksiyalar',
    'Yangiliklar va maxsus takliflar haqida SMS/push xabarlar.',
    'Ixtiyoriy. Istalgan vaqtda profil sozlamalarida o\'chirishingiz mumkin.',
  ),
};
