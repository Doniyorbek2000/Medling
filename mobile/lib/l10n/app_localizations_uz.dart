// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Uzbek (`uz`).
class AppLocalizationsUz extends AppLocalizations {
  AppLocalizationsUz([String locale = 'uz']) : super(locale);

  @override
  String get appName => 'MedLink';

  @override
  String get tagline => 'Sun\'iy intellekt yordamidagi tibbiy platforma';

  @override
  String get onb1Title => 'Alomatlaringizni AI tahlil qiladi';

  @override
  String get onb1Body =>
      'Nima bezovta qilayotganini yozing — Google Med-PaLM 2 qanchalik shoshilinchligini va qaysi shifokorga borishni aytadi.';

  @override
  String get onb2Title => 'Faqat tekshirilgan shifokorlar';

  @override
  String get onb2Body =>
      'Har bir shifokorning diplomi va litsenziyasi moderatorlar tomonidan tekshiriladi. Qabulga bir necha bosishda yoziling.';

  @override
  String get onb3Title => 'Ma\'lumotlaringiz himoyalangan';

  @override
  String get onb3Body =>
      'Tibbiy ma\'lumotlar shifrlanadi, faqat sizning roziligingiz bilan ishlatiladi va istalgan vaqtda o\'chiriladi.';

  @override
  String get skip => 'O\'tkazish';

  @override
  String get next => 'Keyingi';

  @override
  String get getStarted => 'Boshlash';

  @override
  String get phoneTitle => 'Telefon raqamingiz';

  @override
  String get phoneSubtitle => 'Kirish uchun SMS orqali kod yuboramiz';

  @override
  String get getCode => 'Kod olish';

  @override
  String get loginLegal =>
      'Davom etish orqali siz foydalanish shartlari va maxfiylik siyosati bilan tanishishga rozilik bildirasiz.';

  @override
  String get otpTitle => 'Kodni kiriting';

  @override
  String otpSubtitle(String phone) {
    return '$phone raqamiga 6 xonali kod yuborildi';
  }

  @override
  String get login => 'Kirish';

  @override
  String get resendCode => 'Kodni qayta yuborish';

  @override
  String resendIn(int seconds) {
    return 'Qayta yuborish: $seconds s';
  }

  @override
  String get cancel => 'Bekor qilish';

  @override
  String get save => 'Saqlash';

  @override
  String get saved => 'Saqlandi';

  @override
  String get delete => 'O\'chirish';

  @override
  String get deleted => 'O\'chirildi';

  @override
  String get retry => 'Qayta urinish';

  @override
  String get loading => 'Yuklanmoqda';

  @override
  String get submit => 'Yuborish';

  @override
  String get add => 'Qo\'shish';

  @override
  String get clear => 'Tozalash';

  @override
  String get all => 'Barchasi';

  @override
  String get seeAll => 'Barchasi';

  @override
  String get required => 'majburiy';

  @override
  String get requiredField => 'Majburiy maydon';

  @override
  String get logout => 'Chiqish';

  @override
  String get logoutConfirm => 'Hisobingizdan chiqmoqchimisiz?';

  @override
  String get systemDefault => 'Tizim bo\'yicha';

  @override
  String get today => 'Bugun';

  @override
  String get errorGeneric => 'Xatolik yuz berdi. Qayta urinib ko\'ring';

  @override
  String get errorNetwork => 'Internet aloqasi yo\'q';

  @override
  String get errorOtpInvalid => 'Kod noto\'g\'ri';

  @override
  String get errorOtpExpired => 'Kod muddati o\'tgan. Qayta so\'rang';

  @override
  String get errorOtpAttempts => 'Urinishlar soni tugadi. Yangi kod so\'rang';

  @override
  String get errorRateLimited =>
      'Juda ko\'p so\'rov. Birozdan so\'ng urinib ko\'ring';

  @override
  String get errorConsentRequired => 'Buning uchun rozilik kerak';

  @override
  String get errorSlotUnavailable => 'Bu vaqt band. Boshqa vaqtni tanlang';

  @override
  String get errorAlreadyApplied => 'Siz allaqachon ariza topshirgansiz';

  @override
  String get errorNotPayable => 'Bu qabulni to\'lab bo\'lmaydi';

  @override
  String get errorNotStarted => 'Qabul hali boshlanmagan';

  @override
  String get errorAlreadyReviewed => 'Siz allaqachon baho qoldirgansiz';

  @override
  String get consentScreenTitle => 'Rozilik va maxfiylik';

  @override
  String get consentIntro =>
      'Ma\'lumotlaringiz qanday ishlatilishini o\'qib chiqing va har bir band bo\'yicha alohida qaror qabul qiling. Majburiy bandlarsiz xizmat ishlamaydi.';

  @override
  String consentFooter(String version) {
    return 'Versiya: $version. Qaroringiz vaqti va qurilma ma\'lumoti dalil sifatida saqlanadi.';
  }

  @override
  String get agreeContinue => 'Roziman, davom etish';

  @override
  String get consentSettings => 'Rozilik sozlamalari';

  @override
  String get withdrawTitle => 'Rozilikni qaytarib olish';

  @override
  String get withdrawMessage =>
      'Majburiy rozilikni qaytarib olsangiz, xizmatdan foydalana olmaysiz. Davom etasizmi?';

  @override
  String get withdrawConfirm => 'Ha, qaytarib olaman';

  @override
  String get consentTermsTitle => 'Foydalanish shartlari';

  @override
  String get consentTermsSummary => 'MedLink xizmatidan foydalanish qoidalari.';

  @override
  String get consentTermsBody =>
      'MedLink — bemorlarni litsenziyaga ega shifokorlar bilan bog\'lovchi axborot platformasi. Platforma tibbiy yordam ko\'rsatmaydi va shoshilinch tibbiy yordam o\'rnini bosmaydi. Hayot uchun xavfli holatlarda 103 raqamiga qo\'ng\'iroq qiling. Shifokorlarning diplomi va litsenziyasi moderatorlar tomonidan tekshiriladi.';

  @override
  String get consentPersonalTitle => 'Shaxsga doir ma\'lumotlar';

  @override
  String get consentPersonalSummary =>
      'Telefon raqamingiz va profil ma\'lumotlaringizni saqlash.';

  @override
  String get consentPersonalBody =>
      '\"Shaxsga doir ma\'lumotlar to\'g\'risida\"gi Qonunga muvofiq telefon raqamingiz, ism-familiyangiz va qabullar tarixi xizmat ko\'rsatish maqsadida qayta ishlanadi va shifrlangan holda saqlanadi. Siz istalgan vaqtda ma\'lumotlaringiz nusxasini olishingiz, ularni o\'zgartirish yoki o\'chirishni talab qilishingiz mumkin.';

  @override
  String get consentHealthTitle => 'Sog\'liq haqidagi ma\'lumotlar';

  @override
  String get consentHealthSummary =>
      'Alomatlar, qabul sababi va tibbiy profilni saqlash.';

  @override
  String get consentHealthBody =>
      'Sog\'lig\'ingiz haqidagi ma\'lumotlar alohida toifadagi ma\'lumot hisoblanadi. Ular AES-256 bilan shifrlanadi, faqat siz va siz tanlagan shifokor ko\'ra oladi. Har bir murojaat audit jurnalida qayd etiladi. Ma\'lumotlar reklama maqsadida uchinchi shaxslarga berilmaydi.';

  @override
  String get consentAiTitle => 'Sun\'iy intellekt tahlili';

  @override
  String get consentAiSummary =>
      'Alomatlaringizni Google Med-PaLM 2 orqali tahlil qilish.';

  @override
  String get consentAiBody =>
      'AI tahlilidan foydalansangiz, kiritgan matningiz, yoshingiz va jinsingiz modelga yuboriladi. Ism, telefon va boshqa identifikatorlar yuborilmaydi. Natija tashxis emas. Rozilikni qaytarib olsangiz, AI tahlillari tarixi o\'chiriladi. Bu rozilik ixtiyoriy.';

  @override
  String get consentTransferTitle => 'Ma\'lumotni xorijga uzatish';

  @override
  String get consentTransferSummary =>
      'AI tahlili uchun shaxssizlashtirilgan matn Google Cloud\'ga uzatiladi.';

  @override
  String get consentTransferBody =>
      'AI modeli O\'zbekistondan tashqaridagi Google Cloud serverlarida ishlaydi. Tahlil uchun shaxssizlashtirilgan alomatlar matni shifrlangan kanal (TLS) orqali uzatiladi. AI tahlilidan foydalanish uchun bu rozilik zarur.';

  @override
  String get consentMarketingTitle => 'Xabarnomalar va aksiyalar';

  @override
  String get consentMarketingSummary =>
      'Yangiliklar va maxsus takliflar haqida xabarlar.';

  @override
  String get consentMarketingBody =>
      'Ixtiyoriy. Istalgan vaqtda sozlamalarda o\'chirishingiz mumkin.';

  @override
  String get tabHome => 'Asosiy';

  @override
  String get tabDoctors => 'Shifokorlar';

  @override
  String get tabAppointments => 'Qabullarim';

  @override
  String get tabPatients => 'Bemorlarim';

  @override
  String get tabModeration => 'Moderatsiya';

  @override
  String get tabProfile => 'Profil';

  @override
  String get goodMorning => 'Xayrli tong!';

  @override
  String get goodAfternoon => 'Xayrli kun!';

  @override
  String get goodEvening => 'Xayrli kech!';

  @override
  String get homeSubtitle => 'Bugun sog\'lig\'ingiz uchun nima qila olamiz?';

  @override
  String get aiCardTitle => 'Alomatlarni tahlil qilish';

  @override
  String get aiCardBody =>
      'Nima bezovta qilayotganini yozing — AI qaysi shifokorga borishni aytadi.';

  @override
  String get nextAppointment => 'Navbatdagi qabul';

  @override
  String get specialists => 'Mutaxassislar';

  @override
  String emergencyBanner(String phone) {
    return 'Hayot uchun xavfli holatda darhol $phone ga qo\'ng\'iroq qiling';
  }

  @override
  String callEmergency(String phone) {
    return '$phone ga qo\'ng\'iroq qilish';
  }

  @override
  String get triageTitle => 'AI alomatlar tahlili';

  @override
  String get triageHistory => 'Tahlillar tarixi';

  @override
  String get triageHistoryEmpty => 'Hali tahlil o\'tkazilmagan';

  @override
  String get aiConsentNeededTitle => 'AI tahlili uchun rozilik kerak';

  @override
  String get aiConsentNeededBody =>
      '\"Sun\'iy intellekt tahlili\" va \"Ma\'lumotni xorijga uzatish\" bandlariga rozilik bering. Bu ixtiyoriy — usiz ham shifokorga yozilishingiz mumkin.';

  @override
  String get symptomsQuestion => 'Nima bezovta qilyapti?';

  @override
  String get symptomsHint =>
      'Masalan: 3 kundan beri harorat 38.5, tomoq og\'riyapti, yutishda og\'riq bor...';

  @override
  String get noPiiHint => 'Ism, telefon yoki pasport ma\'lumotlarini yozmang.';

  @override
  String get age => 'Yosh';

  @override
  String get durationDays => 'Davomiyligi (kun)';

  @override
  String get female => 'Ayol';

  @override
  String get male => 'Erkak';

  @override
  String get prefilledFromProfile =>
      'Ma\'lumotlar tibbiy profilingizdan olindi';

  @override
  String chronicIncluded(String list) {
    return 'Hisobga olinadi: $list';
  }

  @override
  String get analyze => 'Tahlil qilish';

  @override
  String get analyzing => 'Tahlil qilinmoqda...';

  @override
  String get triagePoweredBy =>
      'Tahlil Google Med-PaLM 2 yordamida bajariladi va tashxis hisoblanmaydi.';

  @override
  String get resultTitle => 'Tahlil natijasi';

  @override
  String get urgencyEmergency => 'Shoshilinch yordam kerak';

  @override
  String urgencyEmergencyBody(String phone) {
    return 'Darhol $phone ga qo\'ng\'iroq qiling yoki eng yaqin shifoxonaga boring.';
  }

  @override
  String get urgencyUrgent => 'Tez orada shifokorga ko\'rining';

  @override
  String get urgencyUrgentBody =>
      'Bugun yoki ertaga shifokor qabuliga yoziling.';

  @override
  String get urgencyRoutine => 'Rejali qabul';

  @override
  String get urgencyRoutineBody =>
      'Yaqin kunlarda shifokor ko\'rigidan o\'ting.';

  @override
  String get urgencySelfCare => 'Uyda kuzatish';

  @override
  String get urgencySelfCareBody =>
      'Holat yomonlashsa, shifokorga murojaat qiling.';

  @override
  String get redFlags => 'Xavfli belgilar';

  @override
  String get possibleCauses => 'Ehtimoliy sabablar';

  @override
  String get likelihoodHigh => 'Yuqori';

  @override
  String get likelihoodMedium => 'O\'rtacha';

  @override
  String get likelihoodLow => 'Past';

  @override
  String get advice => 'Tavsiya';

  @override
  String get whichDoctor => 'Qaysi shifokorga borish kerak';

  @override
  String findSpecialist(String specialty) {
    return '$specialty topish';
  }

  @override
  String get disclaimer =>
      'Bu tahlil tashxis emas va shifokor ko\'rigining o\'rnini bosmaydi.';

  @override
  String get searchDoctors => 'Shifokor yoki klinika';

  @override
  String get noDoctorsFound => 'Shifokorlar topilmadi';

  @override
  String get noDoctorsFoundHint =>
      'Boshqa mutaxassislik yoki so\'rovni sinab ko\'ring';

  @override
  String get verifiedLicense => 'Litsenziya tekshirilgan';

  @override
  String yearsExperience(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count yil tajriba',
    );
    return '$_temp0';
  }

  @override
  String get experienceLabel => 'Yil tajriba';

  @override
  String get rating => 'Reyting';

  @override
  String get reviews => 'Sharhlar';

  @override
  String get about => 'Haqida';

  @override
  String consultationPrice(String price) {
    return 'Qabul narxi: $price';
  }

  @override
  String get patientReviews => 'Bemorlar sharhlari';

  @override
  String get chooseDay => 'Kunni tanlang';

  @override
  String get chooseTime => 'Vaqtni tanlang';

  @override
  String get morning => 'Ertalab';

  @override
  String get afternoon => 'Tushdan keyin';

  @override
  String get noSlots => 'Bu kunda bo\'sh vaqt yo\'q';

  @override
  String get visitReason => 'Murojaat sababi';

  @override
  String get visitReasonHint => 'Faqat shifokor ko\'radi';

  @override
  String bookFor(String when, String price) {
    return 'Yozilish · $when · $price';
  }

  @override
  String get holdNotice =>
      'Vaqt 15 daqiqa band qilinadi — shu muddatda to\'lang.';

  @override
  String priceUzs(String amount) {
    return '$amount so\'m';
  }

  @override
  String get payment => 'To\'lov';

  @override
  String get paymentMethod => 'To\'lov usuli';

  @override
  String get localCards => 'Uzcard, Humo';

  @override
  String get intlCards => 'Visa, Mastercard';

  @override
  String payAmount(String price) {
    return 'To\'lash · $price';
  }

  @override
  String get pay => 'To\'lash';

  @override
  String get checkPayment => 'To\'lovni tekshirish';

  @override
  String get paymentNotYet =>
      'To\'lov hali tasdiqlanmadi. Birozdan so\'ng tekshiring.';

  @override
  String get paymentFailed => 'To\'lov amalga oshmadi';

  @override
  String get cardSafety =>
      'Karta ma\'lumotlari MedLink serverlarida saqlanmaydi.';

  @override
  String holdLeft(String time) {
    return 'Bron muddati: $time';
  }

  @override
  String get holdExpired => 'Bron muddati tugadi. Vaqtni qayta tanlang.';

  @override
  String get appointmentConfirmed => 'Qabul tasdiqlandi!';

  @override
  String get backToHome => 'Bosh sahifaga';

  @override
  String get upcoming => 'Kelgusi';

  @override
  String get past => 'O\'tgan';

  @override
  String get noUpcoming => 'Kelgusi qabullar yo\'q';

  @override
  String get noPast => 'O\'tgan qabullar yo\'q';

  @override
  String get findDoctor => 'Shifokor topish';

  @override
  String get statusAwaitingPayment => 'To\'lov kutilmoqda';

  @override
  String get statusConfirmed => 'Tasdiqlangan';

  @override
  String get statusCompleted => 'Yakunlangan';

  @override
  String get statusCancelled => 'Bekor qilingan';

  @override
  String get appointmentDetails => 'Qabul tafsilotlari';

  @override
  String get dateLabel => 'Sana';

  @override
  String get timeLabel => 'Vaqt';

  @override
  String get clinicLabel => 'Klinika';

  @override
  String get priceLabel => 'Narx';

  @override
  String get cancelAppointment => 'Qabulni bekor qilish';

  @override
  String get cancelAppointmentConfirm =>
      'Haqiqatan ham qabulni bekor qilmoqchimisiz?';

  @override
  String get rateDoctor => 'Shifokorni baholash';

  @override
  String get reviewHint => 'Tajribangiz haqida yozing (ixtiyoriy)';

  @override
  String get yourReview => 'Sizning bahoyingiz';

  @override
  String get doctorApplication => 'Shifokor arizasi';

  @override
  String get moderationHowTitle => 'Moderatsiya qanday o\'tadi';

  @override
  String get moderationHowBody =>
      'Diplom, litsenziya (Sog\'liqni saqlash vazirligi reyestri) va shaxsni tasdiqlovchi hujjat tekshiriladi. Tasdiqlangandan so\'ng profilingiz \"tekshirilgan\" belgisi bilan bemorlarga ko\'rinadi. Odatda 1–3 ish kuni.';

  @override
  String get fullName => 'F.I.Sh.';

  @override
  String get fullNameInvalid => 'To\'liq F.I.Sh. kiriting';

  @override
  String get specialty => 'Mutaxassislik';

  @override
  String get licenseNumber => 'Litsenziya raqami';

  @override
  String get city => 'Shahar';

  @override
  String get experienceYearsLabel => 'Tajriba (yil)';

  @override
  String get priceUzsLabel => 'Narx (so\'m)';

  @override
  String get aboutYou => 'O\'zingiz haqingizda';

  @override
  String get documents => 'Hujjatlar';

  @override
  String get documentsHint =>
      'Diplom, litsenziya, pasport nusxalariga havolalar (har qatorda bittadan)';

  @override
  String get applicationConfirm =>
      'Ma\'lumotlar to\'g\'riligini tasdiqlayman va ular tekshirilishiga roziman';

  @override
  String get sendApplication => 'Arizani yuborish';

  @override
  String get applicationSent =>
      'Ariza yuborildi. Moderatsiya 1–3 ish kuni davom etadi.';

  @override
  String get noPatients => 'Hozircha yozilgan bemorlar yo\'q';

  @override
  String get noReason => 'Sabab ko\'rsatilmagan';

  @override
  String get completeVisit => 'Qabulni yakunlash';

  @override
  String get completeVisitConfirm =>
      'Qabul o\'tkazilganini tasdiqlaysizmi? Shundan so\'ng bemor baho qoldira oladi.';

  @override
  String get noPending => 'Tekshirilishi kerak bo\'lgan arizalar yo\'q';

  @override
  String get approve => 'Tasdiqlash';

  @override
  String approveConfirm(String name) {
    return '$name arizasini tasdiqlaysizmi? Profil bemorlarga ko\'rinadi.';
  }

  @override
  String get reject => 'Rad etish';

  @override
  String get rejectReason => 'Rad etish sababi';

  @override
  String get rejectReasonHint => 'Masalan: litsenziya reyestrda topilmadi';

  @override
  String get patient => 'Bemor';

  @override
  String get rolePatient => 'Bemor';

  @override
  String get roleDoctor => 'Shifokor';

  @override
  String get roleAdmin => 'Administrator';

  @override
  String get health => 'Sog\'liq';

  @override
  String get medicalProfile => 'Tibbiy profil';

  @override
  String get medicalProfileSubtitle =>
      'Allergiyalar, surunkali kasalliklar, dorilar';

  @override
  String get medicalProfileNote =>
      'Ma\'lumotlar shifrlangan holda saqlanadi va AI tahliliga avtomatik qo\'shiladi.';

  @override
  String get birthDate => 'Tug\'ilgan sana';

  @override
  String get bloodType => 'Qon guruhi';

  @override
  String get heightCm => 'Bo\'y (sm)';

  @override
  String get weightKg => 'Vazn (kg)';

  @override
  String get allergies => 'Allergiyalar';

  @override
  String get allergiesHint => 'Masalan: penitsillin';

  @override
  String get chronicConditions => 'Surunkali kasalliklar';

  @override
  String get chronicHint => 'Masalan: qandli diabet 2-tur';

  @override
  String get medications => 'Doimiy dorilar';

  @override
  String get medicationsHint => 'Masalan: metformin 500 mg';

  @override
  String get forDoctors => 'Shifokorlar uchun';

  @override
  String get becomeDoctor => 'Shifokor sifatida qo\'shilish';

  @override
  String get becomeDoctorSubtitle =>
      'Ariza topshiring va moderatsiyadan o\'ting';

  @override
  String get applicationPending => 'Ariza ko\'rib chiqilmoqda';

  @override
  String get applicationApproved => 'Tasdiqlangan shifokor';

  @override
  String get applicationRejected => 'Ariza rad etilgan';

  @override
  String get applicationSuspended => 'Profil to\'xtatilgan';

  @override
  String moderatorNote(String note) {
    return 'Moderator izohi: $note';
  }

  @override
  String get reapply => 'Qayta ariza topshirish';

  @override
  String get settings => 'Sozlamalar';

  @override
  String get language => 'Til';

  @override
  String get theme => 'Mavzu';

  @override
  String get themeLight => 'Yorug\'';

  @override
  String get themeDark => 'Qorong\'i';

  @override
  String get biometricLock => 'Biometrik qulf';

  @override
  String get biometricLockSubtitle => 'Face ID / barmoq izi bilan ochish';

  @override
  String get biometricReason =>
      'MedLink\'ni ochish uchun shaxsingizni tasdiqlang';

  @override
  String get lockedTitle => 'MedLink qulflangan';

  @override
  String get unlock => 'Ochish';

  @override
  String get privacy => 'Maxfiylik';

  @override
  String get exportData => 'Ma\'lumotlarim nusxasi';

  @override
  String get exportDataSubtitle => 'Saqlangan barcha ma\'lumotlarni olish';

  @override
  String get exportCopied => 'Ma\'lumotlaringiz nusxasi buferga ko\'chirildi';

  @override
  String get deleteHealthData => 'Tibbiy ma\'lumotlarni o\'chirish';

  @override
  String get deleteHealthDataConfirm =>
      'AI tahlillari va tibbiy profil qaytarib bo\'lmaydigan tarzda o\'chiriladi. Qabullar tarixi qonunda belgilangan muddat saqlanadi.';

  @override
  String get emergencyNumber => 'Tez yordam';

  @override
  String get version => 'Versiya';

  @override
  String get specTherapist => 'Terapevt';

  @override
  String get specPediatrician => 'Pediatr';

  @override
  String get specCardiologist => 'Kardiolog';

  @override
  String get specNeurologist => 'Nevrolog';

  @override
  String get specGastroenterologist => 'Gastroenterolog';

  @override
  String get specPulmonologist => 'Pulmonolog';

  @override
  String get specEndocrinologist => 'Endokrinolog';

  @override
  String get specDermatologist => 'Dermatolog';

  @override
  String get specEnt => 'LOR';

  @override
  String get specOphthalmologist => 'Oftalmolog';

  @override
  String get specGynecologist => 'Ginekolog';

  @override
  String get specUrologist => 'Urolog';

  @override
  String get specTraumatologist => 'Travmatolog';

  @override
  String get specPsychiatrist => 'Psixiatr';

  @override
  String get tashkentTime => 'Toshkent vaqti bilan (UTC+5)';

  @override
  String get completeProfile => 'Profilni to\'ldiring';

  @override
  String get licenses => 'Litsenziyalar';

  @override
  String get reminderTitle => 'MedLink: qabul eslatmasi';

  @override
  String reminderDayBefore(String time) {
    return 'Ertaga soat $time da qabulingiz bor.';
  }

  @override
  String reminderHourBefore(String time) {
    return 'Qabulingiz 1 soatdan keyin, soat $time da.';
  }

  @override
  String get notifications => 'Bildirishnomalar';

  @override
  String get notificationsSubtitle =>
      'Qabul eslatmalari va holat o\'zgarishlari';

  @override
  String get notificationsDenied =>
      'Ruxsat berilmadi. Telefon sozlamalaridan MedLink uchun bildirishnomalarni yoqing.';

  @override
  String get enableRemindersTitle => 'Qabulni unutmang';

  @override
  String get enableRemindersBody =>
      'Qabuldan 1 kun va 1 soat oldin eslatma yuboramiz. Matnda tibbiy ma\'lumot ko\'rsatilmaydi.';

  @override
  String get enableReminders => 'Eslatmalarni yoqish';

  @override
  String get remindersEnabled => 'Eslatmalar yoqildi';

  @override
  String get online => 'Onlayn';

  @override
  String get inClinic => 'Klinikada';

  @override
  String get onlineAvailable => 'Onlayn qabul bor';

  @override
  String get onlineOnly => 'Faqat onlayn qabul';

  @override
  String get consultationType => 'Qabul turi';

  @override
  String get consultationTypes => 'Qabul turlari';

  @override
  String get onlineHowItWorks =>
      'Qabul vaqtida ilovada video qo\'ng\'iroq ochiladi. Barqaror internet va tinch joy tayyorlang.';

  @override
  String onlinePriceLabel(String price) {
    return 'Onlayn qabul: $price';
  }

  @override
  String get onlineConsultation => 'Onlayn konsultatsiya';

  @override
  String get joinVideo => 'Video qo\'ng\'iroqqa kirish';

  @override
  String get videoReady =>
      'Xona ochiq. Shifokor bilan bog\'lanish uchun kiring.';

  @override
  String get videoReadyShort => 'Video tayyor';

  @override
  String videoOpensAt(String time) {
    return 'Video soat $time da ochiladi (qabuldan 10 daqiqa oldin).';
  }

  @override
  String get videoClosed =>
      'Video qabul vaqti tugadi. Savollarni chatda yozing.';

  @override
  String get videoNotConfigured =>
      'Video xizmati hozircha ulanmagan. Shifokor bilan chat orqali bog\'laning.';

  @override
  String get videoTips =>
      'Maslahat: quloqchin ishlating, yorug\' joyda o\'tiring.';

  @override
  String get callConnecting => 'Ulanmoqda...';

  @override
  String get callWaiting => 'Suhbatdosh hali kirmadi. Kuting...';

  @override
  String get callReconnecting => 'Aloqa uzildi, qayta ulanmoqda...';

  @override
  String get callEnded => 'Qo\'ng\'iroq tugadi';

  @override
  String get callFailed =>
      'Ulanib bo\'lmadi. Internetni tekshirib, qayta urinib ko\'ring.';

  @override
  String get callPermissionDenied =>
      'Kamera yoki mikrofonga ruxsat berilmagan. Telefon sozlamalaridan MedLink uchun ruxsat bering.';

  @override
  String get callEncrypted => 'Shifrlangan aloqa · yozib olinmaydi';

  @override
  String get mute => 'Ovozni o\'chirish';

  @override
  String get unmute => 'Ovozni yoqish';

  @override
  String get cameraOff => 'Kamerani o\'chirish';

  @override
  String get cameraOn => 'Kamerani yoqish';

  @override
  String get switchCamera => 'Almashtirish';

  @override
  String get endCall => 'Tugatish';

  @override
  String get endCallConfirm => 'Qo\'ng\'iroqni tugatmoqchimisiz?';

  @override
  String get close => 'Yopish';

  @override
  String get chat => 'Chat';

  @override
  String get chatSubtitle => 'Shifokorga savol bering';

  @override
  String get chatSubtitleDoctor => 'Bemor bilan yozishma';

  @override
  String get chatHint => 'Xabar yozing...';

  @override
  String get send => 'Yuborish';

  @override
  String get sending => 'Yuborilmoqda';

  @override
  String get chatEmptyTitle => 'Hali xabarlar yo\'q';

  @override
  String get chatEmptyBody =>
      'Qabul bo\'yicha savolingizni yozing. Shifokor ish vaqtida javob beradi.';

  @override
  String get chatClosed => 'Chat yopilgan: qabuldan keyin 7 kun o\'tdi.';

  @override
  String get chatEmergencyNote =>
      'Chat shoshilinch yordam uchun emas — xavfli holatda 103 ga qo\'ng\'iroq qiling';

  @override
  String get patientInfo => 'Bemor ma\'lumotlari';

  @override
  String get patientInfoSubtitle => 'Tibbiy profil va AI tahlili';

  @override
  String get aiPreTriage => 'Qabul oldidan AI tahlili';

  @override
  String get viewDetails => 'Batafsil ko\'rish';

  @override
  String get sex => 'Jins';

  @override
  String get heightWeight => 'Bo\'y / vazn';

  @override
  String get patientReview => 'Bemor bahosi';

  @override
  String get conclusion => 'Shifokor xulosasi';

  @override
  String get writeConclusion => 'Xulosa yozish';

  @override
  String get editConclusion => 'Xulosani tahrirlash';

  @override
  String get saveConclusion => 'Xulosani saqlash';

  @override
  String get saveConclusionConfirm =>
      'Xulosa bemorga yuboriladi va qabul yakunlanadi. Davom etasizmi?';

  @override
  String get conclusionSaved => 'Xulosa saqlandi va bemorga yuborildi';

  @override
  String get diagnosis => 'Tashxis';

  @override
  String get diagnosisHint => 'Masalan: O\'tkir respirator infeksiya (J06.9)';

  @override
  String get recommendations => 'Tavsiyalar';

  @override
  String get prescription => 'Retsept';

  @override
  String get addMedication => 'Dori qo\'shish';

  @override
  String get noPrescription => 'Dori tayinlanmagan';

  @override
  String get medication => 'Dori';

  @override
  String get drugName => 'Dori nomi';

  @override
  String get dose => 'Doza';

  @override
  String get frequency => 'Qabul qilish tartibi';

  @override
  String get frequencyHint => 'Masalan: kuniga 2 marta, ovqatdan keyin';

  @override
  String get notes => 'Izoh';

  @override
  String get followUp => 'Qayta ko\'rik';

  @override
  String get followUpNone => 'Shart emas';

  @override
  String inDays(int days) {
    return '$days kundan keyin';
  }

  @override
  String forDays(int days) {
    return '$days kun';
  }

  @override
  String followUpIn(int days) {
    return 'Qayta ko\'rik: $days kundan keyin';
  }

  @override
  String get conclusionPrivacy =>
      'Xulosa shifrlangan holda saqlanadi va faqat bemorga ko\'rinadi.';

  @override
  String get conclusionDisclaimer =>
      'Dorilarni faqat shifokor ko\'rsatmasiga ko\'ra qabul qiling. Ahvolingiz yomonlashsa — 103.';

  @override
  String get scheduleAndPrices => 'Jadval va narxlar';

  @override
  String get scheduleAndPricesSubtitle => 'Ish kunlari, soatlar, onlayn qabul';

  @override
  String get workDays => 'Ish kunlari';

  @override
  String get workHours => 'Ish vaqti (Toshkent vaqti)';

  @override
  String get from => 'Boshlanishi';

  @override
  String get to => 'Tugashi';

  @override
  String slotsPerDay(int count) {
    return 'Kuniga $count ta 30 daqiqalik qabul';
  }

  @override
  String get clinicPrice => 'Klinikadagi qabul narxi';

  @override
  String get onlinePrice => 'Onlayn qabul narxi';

  @override
  String get onlineSubtitle => 'Video qo\'ng\'iroq va chat orqali';

  @override
  String get scheduleNote =>
      'O\'zgarishlar faqat yangi bronlarga ta\'sir qiladi. Mavjud qabullar saqlanadi.';

  @override
  String get chooseConsultationType => 'Kamida bitta qabul turini yoqing';

  @override
  String get onlinePriceRequired => 'Onlayn qabul narxini kiriting';

  @override
  String get errorChatClosed => 'Chat yopilgan';

  @override
  String get errorTooEarly =>
      'Video hali ochilmagan — qabuldan 10 daqiqa oldin ochiladi';

  @override
  String get errorTooLate => 'Video qabul vaqti tugagan';

  @override
  String get errorVideoUnavailable => 'Video xizmati vaqtincha ishlamayapti';

  @override
  String get errorTypeUnavailable => 'Shifokor bu turdagi qabulni o\'tkazmaydi';

  @override
  String get errorInvalidSchedule =>
      'Jadval noto\'g\'ri: ish vaqti va kunlarini tekshiring';

  @override
  String get videoNotConfiguredDoctor =>
      'Video xizmati hozircha ulanmagan. Bemor bilan chat orqali bog\'laning.';

  @override
  String get tabAdmin => 'Boshqaruv';

  @override
  String get statistics => 'Statistika';

  @override
  String get applications => 'Arizalar';

  @override
  String get refunds => 'Qaytarishlar';

  @override
  String get statUsers => 'Foydalanuvchilar';

  @override
  String get statDoctors => 'Faol shifokorlar';

  @override
  String get statPendingApplications => 'Kutilayotgan arizalar';

  @override
  String get statToday => 'Bugungi qabullar';

  @override
  String get statRevenue30d => '30 kunlik tushum';

  @override
  String get statOnlineShare => 'Onlayn ulushi';

  @override
  String get statRefundsPending => 'Qaytarilishi kerak';

  @override
  String get statAppointments => 'Qabullar holati';

  @override
  String get noRefunds => 'Qaytariladigan to\'lovlar yo\'q';

  @override
  String get refundReasonDoctor => 'Shifokor bekor qildi';

  @override
  String get refundReasonPatient => 'Bemor 24 soatdan oldin bekor qildi';

  @override
  String get markRefunded => 'Qaytarildi deb belgilash';

  @override
  String markRefundedConfirm(String provider) {
    return 'Avval $provider kabinetida to\'lovni qaytaring. Bemorga xabar yuboriladi. Davom etasizmi?';
  }

  @override
  String requestedAt(String time) {
    return 'So\'ralgan: $time';
  }

  @override
  String transactionId(String id) {
    return 'Tranzaksiya: $id';
  }

  @override
  String get copied => 'Nusxa olindi';

  @override
  String get cancelPolicyRefund =>
      'Qabulgacha 24 soatdan ko\'proq vaqt bor — to\'lov to\'liq qaytariladi. Bekor qilasizmi?';

  @override
  String get cancelPolicyNoRefund =>
      'Qabulgacha 24 soatdan kam qoldi — to\'lov qaytarilmaydi. Baribir bekor qilasizmi?';

  @override
  String get cancelPolicyDoctor =>
      'Bemorga to\'lov to\'liq qaytariladi va xabar yuboriladi. Bekor qilasizmi?';

  @override
  String get refundRequested =>
      'Qabul bekor qilindi. To\'lov 3–5 ish kuni ichida qaytariladi.';

  @override
  String get refundRequestedShort => 'To\'lov qaytarilmoqda';

  @override
  String get refundDone => 'To\'lov qaytarildi';

  @override
  String get attachPhoto => 'Rasm qo\'shish';

  @override
  String get takePhoto => 'Suratga olish';

  @override
  String get chooseFromGallery => 'Galereyadan tanlash';

  @override
  String get attachmentHint =>
      'Tahlil natijasi, retsept yoki teri o\'zgarishi rasmini yuborishingiz mumkin. Rasm shifrlanadi, joylashuv ma\'lumoti olib tashlanadi.';

  @override
  String get uploadingPhoto => 'Rasm yuborilmoqda...';

  @override
  String get errorFileTooLarge => 'Fayl juda katta (5 MB gacha)';

  @override
  String get errorUnsupportedFile => 'Faqat JPEG yoki PNG rasm yuborish mumkin';

  @override
  String get aboutApp => 'Ilova haqida';

  @override
  String get privacyPolicy => 'Maxfiylik siyosati';

  @override
  String get termsOfUse => 'Foydalanish shartlari';

  @override
  String get deleteAccount => 'Hisobni o\'chirish';

  @override
  String get deleteAccountSubtitle =>
      'Hisob va tibbiy ma\'lumotlar butunlay o\'chiriladi';

  @override
  String get deleteAccountConfirm =>
      'Hisobingiz butunlay o\'chiriladi:\n• tibbiy profil, AI tahlillari va telefon raqamingiz o\'chiriladi;\n• kelgusi qabullar bekor qilinadi, to\'lov qaytarish qoidalari bo\'yicha qaytariladi;\n• to\'lovlar, shifokor xulosalari va xavfsizlik jurnali qonun talabiga ko\'ra telefon raqamingizsiz saqlanadi.\n\nBu amalni ortga qaytarib bo\'lmaydi.';

  @override
  String get deleteAccountFinal =>
      'Haqiqatan ham hisobingizni o\'chirmoqchimisiz?';

  @override
  String get accountDeleted => 'Hisobingiz o\'chirildi';

  @override
  String get continueAction => 'Davom etish';

  @override
  String get reschedule => 'Vaqtini o\'zgartirish';

  @override
  String get rescheduleTitle => 'Yangi vaqtni tanlang';

  @override
  String rescheduleHint(int count) {
    return 'To\'lov saqlanadi. Yana $count marta ko\'chirish mumkin.';
  }

  @override
  String rescheduleConfirm(String time) {
    return 'Qabulni $time ga ko\'chirasizmi?';
  }

  @override
  String get rescheduled => 'Qabul vaqti o\'zgartirildi';

  @override
  String get currentTime => 'Hozirgi vaqt';

  @override
  String get errorTooLateToReschedule =>
      'Qabulgacha 24 soatdan kam qolgani uchun vaqtni o\'zgartirib bo\'lmaydi';

  @override
  String get errorRescheduleLimit =>
      'Qabulni ko\'pi bilan 2 marta ko\'chirish mumkin';

  @override
  String get errorDoctorUnavailable =>
      'Shifokor hozir bu turdagi qabulni olib bormayapti';

  @override
  String get errorRefundFailed =>
      'To\'lov tizimi pulni qaytarmadi. Keyinroq qayta urinib ko\'ring';

  @override
  String get refundCompletedNow =>
      'Qabul bekor qilindi. Pul kartangizga qaytarildi — bank odatda 5–10 kunda o\'tkazadi.';

  @override
  String get liveConnected => 'Jonli aloqa';
}
