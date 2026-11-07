import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_uz.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ru'),
    Locale('uz'),
  ];

  /// No description provided for @appName.
  ///
  /// In uz, this message translates to:
  /// **'MedLink'**
  String get appName;

  /// No description provided for @tagline.
  ///
  /// In uz, this message translates to:
  /// **'Sun\'iy intellekt yordamidagi tibbiy platforma'**
  String get tagline;

  /// No description provided for @onb1Title.
  ///
  /// In uz, this message translates to:
  /// **'Alomatlaringizni AI tahlil qiladi'**
  String get onb1Title;

  /// No description provided for @onb1Body.
  ///
  /// In uz, this message translates to:
  /// **'Nima bezovta qilayotganini yozing — Google Med-PaLM 2 qanchalik shoshilinchligini va qaysi shifokorga borishni aytadi.'**
  String get onb1Body;

  /// No description provided for @onb2Title.
  ///
  /// In uz, this message translates to:
  /// **'Faqat tekshirilgan shifokorlar'**
  String get onb2Title;

  /// No description provided for @onb2Body.
  ///
  /// In uz, this message translates to:
  /// **'Har bir shifokorning diplomi va litsenziyasi moderatorlar tomonidan tekshiriladi. Qabulga bir necha bosishda yoziling.'**
  String get onb2Body;

  /// No description provided for @onb3Title.
  ///
  /// In uz, this message translates to:
  /// **'Ma\'lumotlaringiz himoyalangan'**
  String get onb3Title;

  /// No description provided for @onb3Body.
  ///
  /// In uz, this message translates to:
  /// **'Tibbiy ma\'lumotlar shifrlanadi, faqat sizning roziligingiz bilan ishlatiladi va istalgan vaqtda o\'chiriladi.'**
  String get onb3Body;

  /// No description provided for @skip.
  ///
  /// In uz, this message translates to:
  /// **'O\'tkazish'**
  String get skip;

  /// No description provided for @next.
  ///
  /// In uz, this message translates to:
  /// **'Keyingi'**
  String get next;

  /// No description provided for @getStarted.
  ///
  /// In uz, this message translates to:
  /// **'Boshlash'**
  String get getStarted;

  /// No description provided for @phoneTitle.
  ///
  /// In uz, this message translates to:
  /// **'Telefon raqamingiz'**
  String get phoneTitle;

  /// No description provided for @phoneSubtitle.
  ///
  /// In uz, this message translates to:
  /// **'Kirish uchun SMS orqali kod yuboramiz'**
  String get phoneSubtitle;

  /// No description provided for @getCode.
  ///
  /// In uz, this message translates to:
  /// **'Kod olish'**
  String get getCode;

  /// No description provided for @loginLegal.
  ///
  /// In uz, this message translates to:
  /// **'Davom etish orqali siz foydalanish shartlari va maxfiylik siyosati bilan tanishishga rozilik bildirasiz.'**
  String get loginLegal;

  /// No description provided for @otpTitle.
  ///
  /// In uz, this message translates to:
  /// **'Kodni kiriting'**
  String get otpTitle;

  /// No description provided for @otpSubtitle.
  ///
  /// In uz, this message translates to:
  /// **'{phone} raqamiga 6 xonali kod yuborildi'**
  String otpSubtitle(String phone);

  /// No description provided for @login.
  ///
  /// In uz, this message translates to:
  /// **'Kirish'**
  String get login;

  /// No description provided for @resendCode.
  ///
  /// In uz, this message translates to:
  /// **'Kodni qayta yuborish'**
  String get resendCode;

  /// No description provided for @resendIn.
  ///
  /// In uz, this message translates to:
  /// **'Qayta yuborish: {seconds} s'**
  String resendIn(int seconds);

  /// No description provided for @cancel.
  ///
  /// In uz, this message translates to:
  /// **'Bekor qilish'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In uz, this message translates to:
  /// **'Saqlash'**
  String get save;

  /// No description provided for @saved.
  ///
  /// In uz, this message translates to:
  /// **'Saqlandi'**
  String get saved;

  /// No description provided for @delete.
  ///
  /// In uz, this message translates to:
  /// **'O\'chirish'**
  String get delete;

  /// No description provided for @deleted.
  ///
  /// In uz, this message translates to:
  /// **'O\'chirildi'**
  String get deleted;

  /// No description provided for @retry.
  ///
  /// In uz, this message translates to:
  /// **'Qayta urinish'**
  String get retry;

  /// No description provided for @loading.
  ///
  /// In uz, this message translates to:
  /// **'Yuklanmoqda'**
  String get loading;

  /// No description provided for @submit.
  ///
  /// In uz, this message translates to:
  /// **'Yuborish'**
  String get submit;

  /// No description provided for @add.
  ///
  /// In uz, this message translates to:
  /// **'Qo\'shish'**
  String get add;

  /// No description provided for @clear.
  ///
  /// In uz, this message translates to:
  /// **'Tozalash'**
  String get clear;

  /// No description provided for @all.
  ///
  /// In uz, this message translates to:
  /// **'Barchasi'**
  String get all;

  /// No description provided for @seeAll.
  ///
  /// In uz, this message translates to:
  /// **'Barchasi'**
  String get seeAll;

  /// No description provided for @required.
  ///
  /// In uz, this message translates to:
  /// **'majburiy'**
  String get required;

  /// No description provided for @requiredField.
  ///
  /// In uz, this message translates to:
  /// **'Majburiy maydon'**
  String get requiredField;

  /// No description provided for @logout.
  ///
  /// In uz, this message translates to:
  /// **'Chiqish'**
  String get logout;

  /// No description provided for @logoutConfirm.
  ///
  /// In uz, this message translates to:
  /// **'Hisobingizdan chiqmoqchimisiz?'**
  String get logoutConfirm;

  /// No description provided for @systemDefault.
  ///
  /// In uz, this message translates to:
  /// **'Tizim bo\'yicha'**
  String get systemDefault;

  /// No description provided for @today.
  ///
  /// In uz, this message translates to:
  /// **'Bugun'**
  String get today;

  /// No description provided for @errorGeneric.
  ///
  /// In uz, this message translates to:
  /// **'Xatolik yuz berdi. Qayta urinib ko\'ring'**
  String get errorGeneric;

  /// No description provided for @errorNetwork.
  ///
  /// In uz, this message translates to:
  /// **'Internet aloqasi yo\'q'**
  String get errorNetwork;

  /// No description provided for @errorOtpInvalid.
  ///
  /// In uz, this message translates to:
  /// **'Kod noto\'g\'ri'**
  String get errorOtpInvalid;

  /// No description provided for @errorOtpExpired.
  ///
  /// In uz, this message translates to:
  /// **'Kod muddati o\'tgan. Qayta so\'rang'**
  String get errorOtpExpired;

  /// No description provided for @errorOtpAttempts.
  ///
  /// In uz, this message translates to:
  /// **'Urinishlar soni tugadi. Yangi kod so\'rang'**
  String get errorOtpAttempts;

  /// No description provided for @errorRateLimited.
  ///
  /// In uz, this message translates to:
  /// **'Juda ko\'p so\'rov. Birozdan so\'ng urinib ko\'ring'**
  String get errorRateLimited;

  /// No description provided for @errorConsentRequired.
  ///
  /// In uz, this message translates to:
  /// **'Buning uchun rozilik kerak'**
  String get errorConsentRequired;

  /// No description provided for @errorSlotUnavailable.
  ///
  /// In uz, this message translates to:
  /// **'Bu vaqt band. Boshqa vaqtni tanlang'**
  String get errorSlotUnavailable;

  /// No description provided for @errorAlreadyApplied.
  ///
  /// In uz, this message translates to:
  /// **'Siz allaqachon ariza topshirgansiz'**
  String get errorAlreadyApplied;

  /// No description provided for @errorNotPayable.
  ///
  /// In uz, this message translates to:
  /// **'Bu qabulni to\'lab bo\'lmaydi'**
  String get errorNotPayable;

  /// No description provided for @errorNotStarted.
  ///
  /// In uz, this message translates to:
  /// **'Qabul hali boshlanmagan'**
  String get errorNotStarted;

  /// No description provided for @errorAlreadyReviewed.
  ///
  /// In uz, this message translates to:
  /// **'Siz allaqachon baho qoldirgansiz'**
  String get errorAlreadyReviewed;

  /// No description provided for @consentScreenTitle.
  ///
  /// In uz, this message translates to:
  /// **'Rozilik va maxfiylik'**
  String get consentScreenTitle;

  /// No description provided for @consentIntro.
  ///
  /// In uz, this message translates to:
  /// **'Ma\'lumotlaringiz qanday ishlatilishini o\'qib chiqing va har bir band bo\'yicha alohida qaror qabul qiling. Majburiy bandlarsiz xizmat ishlamaydi.'**
  String get consentIntro;

  /// No description provided for @consentFooter.
  ///
  /// In uz, this message translates to:
  /// **'Versiya: {version}. Qaroringiz vaqti va qurilma ma\'lumoti dalil sifatida saqlanadi.'**
  String consentFooter(String version);

  /// No description provided for @agreeContinue.
  ///
  /// In uz, this message translates to:
  /// **'Roziman, davom etish'**
  String get agreeContinue;

  /// No description provided for @consentSettings.
  ///
  /// In uz, this message translates to:
  /// **'Rozilik sozlamalari'**
  String get consentSettings;

  /// No description provided for @withdrawTitle.
  ///
  /// In uz, this message translates to:
  /// **'Rozilikni qaytarib olish'**
  String get withdrawTitle;

  /// No description provided for @withdrawMessage.
  ///
  /// In uz, this message translates to:
  /// **'Majburiy rozilikni qaytarib olsangiz, xizmatdan foydalana olmaysiz. Davom etasizmi?'**
  String get withdrawMessage;

  /// No description provided for @withdrawConfirm.
  ///
  /// In uz, this message translates to:
  /// **'Ha, qaytarib olaman'**
  String get withdrawConfirm;

  /// No description provided for @consentTermsTitle.
  ///
  /// In uz, this message translates to:
  /// **'Foydalanish shartlari'**
  String get consentTermsTitle;

  /// No description provided for @consentTermsSummary.
  ///
  /// In uz, this message translates to:
  /// **'MedLink xizmatidan foydalanish qoidalari.'**
  String get consentTermsSummary;

  /// No description provided for @consentTermsBody.
  ///
  /// In uz, this message translates to:
  /// **'MedLink — bemorlarni litsenziyaga ega shifokorlar bilan bog\'lovchi axborot platformasi. Platforma tibbiy yordam ko\'rsatmaydi va shoshilinch tibbiy yordam o\'rnini bosmaydi. Hayot uchun xavfli holatlarda 103 raqamiga qo\'ng\'iroq qiling. Shifokorlarning diplomi va litsenziyasi moderatorlar tomonidan tekshiriladi.'**
  String get consentTermsBody;

  /// No description provided for @consentPersonalTitle.
  ///
  /// In uz, this message translates to:
  /// **'Shaxsga doir ma\'lumotlar'**
  String get consentPersonalTitle;

  /// No description provided for @consentPersonalSummary.
  ///
  /// In uz, this message translates to:
  /// **'Telefon raqamingiz va profil ma\'lumotlaringizni saqlash.'**
  String get consentPersonalSummary;

  /// No description provided for @consentPersonalBody.
  ///
  /// In uz, this message translates to:
  /// **'\"Shaxsga doir ma\'lumotlar to\'g\'risida\"gi Qonunga muvofiq telefon raqamingiz, ism-familiyangiz va qabullar tarixi xizmat ko\'rsatish maqsadida qayta ishlanadi va shifrlangan holda saqlanadi. Siz istalgan vaqtda ma\'lumotlaringiz nusxasini olishingiz, ularni o\'zgartirish yoki o\'chirishni talab qilishingiz mumkin.'**
  String get consentPersonalBody;

  /// No description provided for @consentHealthTitle.
  ///
  /// In uz, this message translates to:
  /// **'Sog\'liq haqidagi ma\'lumotlar'**
  String get consentHealthTitle;

  /// No description provided for @consentHealthSummary.
  ///
  /// In uz, this message translates to:
  /// **'Alomatlar, qabul sababi va tibbiy profilni saqlash.'**
  String get consentHealthSummary;

  /// No description provided for @consentHealthBody.
  ///
  /// In uz, this message translates to:
  /// **'Sog\'lig\'ingiz haqidagi ma\'lumotlar alohida toifadagi ma\'lumot hisoblanadi. Ular AES-256 bilan shifrlanadi, faqat siz va siz tanlagan shifokor ko\'ra oladi. Har bir murojaat audit jurnalida qayd etiladi. Ma\'lumotlar reklama maqsadida uchinchi shaxslarga berilmaydi.'**
  String get consentHealthBody;

  /// No description provided for @consentAiTitle.
  ///
  /// In uz, this message translates to:
  /// **'Sun\'iy intellekt tahlili'**
  String get consentAiTitle;

  /// No description provided for @consentAiSummary.
  ///
  /// In uz, this message translates to:
  /// **'Alomatlaringizni Google Med-PaLM 2 orqali tahlil qilish.'**
  String get consentAiSummary;

  /// No description provided for @consentAiBody.
  ///
  /// In uz, this message translates to:
  /// **'AI tahlilidan foydalansangiz, kiritgan matningiz, yoshingiz va jinsingiz modelga yuboriladi. Ism, telefon va boshqa identifikatorlar yuborilmaydi. Natija tashxis emas. Rozilikni qaytarib olsangiz, AI tahlillari tarixi o\'chiriladi. Bu rozilik ixtiyoriy.'**
  String get consentAiBody;

  /// No description provided for @consentTransferTitle.
  ///
  /// In uz, this message translates to:
  /// **'Ma\'lumotni xorijga uzatish'**
  String get consentTransferTitle;

  /// No description provided for @consentTransferSummary.
  ///
  /// In uz, this message translates to:
  /// **'AI tahlili uchun shaxssizlashtirilgan matn Google Cloud\'ga uzatiladi.'**
  String get consentTransferSummary;

  /// No description provided for @consentTransferBody.
  ///
  /// In uz, this message translates to:
  /// **'AI modeli O\'zbekistondan tashqaridagi Google Cloud serverlarida ishlaydi. Tahlil uchun shaxssizlashtirilgan alomatlar matni shifrlangan kanal (TLS) orqali uzatiladi. AI tahlilidan foydalanish uchun bu rozilik zarur.'**
  String get consentTransferBody;

  /// No description provided for @consentMarketingTitle.
  ///
  /// In uz, this message translates to:
  /// **'Xabarnomalar va aksiyalar'**
  String get consentMarketingTitle;

  /// No description provided for @consentMarketingSummary.
  ///
  /// In uz, this message translates to:
  /// **'Yangiliklar va maxsus takliflar haqida xabarlar.'**
  String get consentMarketingSummary;

  /// No description provided for @consentMarketingBody.
  ///
  /// In uz, this message translates to:
  /// **'Ixtiyoriy. Istalgan vaqtda sozlamalarda o\'chirishingiz mumkin.'**
  String get consentMarketingBody;

  /// No description provided for @tabHome.
  ///
  /// In uz, this message translates to:
  /// **'Asosiy'**
  String get tabHome;

  /// No description provided for @tabDoctors.
  ///
  /// In uz, this message translates to:
  /// **'Shifokorlar'**
  String get tabDoctors;

  /// No description provided for @tabAppointments.
  ///
  /// In uz, this message translates to:
  /// **'Qabullarim'**
  String get tabAppointments;

  /// No description provided for @tabPatients.
  ///
  /// In uz, this message translates to:
  /// **'Bemorlarim'**
  String get tabPatients;

  /// No description provided for @tabModeration.
  ///
  /// In uz, this message translates to:
  /// **'Moderatsiya'**
  String get tabModeration;

  /// No description provided for @tabProfile.
  ///
  /// In uz, this message translates to:
  /// **'Profil'**
  String get tabProfile;

  /// No description provided for @goodMorning.
  ///
  /// In uz, this message translates to:
  /// **'Xayrli tong!'**
  String get goodMorning;

  /// No description provided for @goodAfternoon.
  ///
  /// In uz, this message translates to:
  /// **'Xayrli kun!'**
  String get goodAfternoon;

  /// No description provided for @goodEvening.
  ///
  /// In uz, this message translates to:
  /// **'Xayrli kech!'**
  String get goodEvening;

  /// No description provided for @homeSubtitle.
  ///
  /// In uz, this message translates to:
  /// **'Bugun sog\'lig\'ingiz uchun nima qila olamiz?'**
  String get homeSubtitle;

  /// No description provided for @aiCardTitle.
  ///
  /// In uz, this message translates to:
  /// **'Alomatlarni tahlil qilish'**
  String get aiCardTitle;

  /// No description provided for @aiCardBody.
  ///
  /// In uz, this message translates to:
  /// **'Nima bezovta qilayotganini yozing — AI qaysi shifokorga borishni aytadi.'**
  String get aiCardBody;

  /// No description provided for @nextAppointment.
  ///
  /// In uz, this message translates to:
  /// **'Navbatdagi qabul'**
  String get nextAppointment;

  /// No description provided for @specialists.
  ///
  /// In uz, this message translates to:
  /// **'Mutaxassislar'**
  String get specialists;

  /// No description provided for @emergencyBanner.
  ///
  /// In uz, this message translates to:
  /// **'Hayot uchun xavfli holatda darhol {phone} ga qo\'ng\'iroq qiling'**
  String emergencyBanner(String phone);

  /// No description provided for @callEmergency.
  ///
  /// In uz, this message translates to:
  /// **'{phone} ga qo\'ng\'iroq qilish'**
  String callEmergency(String phone);

  /// No description provided for @triageTitle.
  ///
  /// In uz, this message translates to:
  /// **'AI alomatlar tahlili'**
  String get triageTitle;

  /// No description provided for @triageHistory.
  ///
  /// In uz, this message translates to:
  /// **'Tahlillar tarixi'**
  String get triageHistory;

  /// No description provided for @triageHistoryEmpty.
  ///
  /// In uz, this message translates to:
  /// **'Hali tahlil o\'tkazilmagan'**
  String get triageHistoryEmpty;

  /// No description provided for @aiConsentNeededTitle.
  ///
  /// In uz, this message translates to:
  /// **'AI tahlili uchun rozilik kerak'**
  String get aiConsentNeededTitle;

  /// No description provided for @aiConsentNeededBody.
  ///
  /// In uz, this message translates to:
  /// **'\"Sun\'iy intellekt tahlili\" va \"Ma\'lumotni xorijga uzatish\" bandlariga rozilik bering. Bu ixtiyoriy — usiz ham shifokorga yozilishingiz mumkin.'**
  String get aiConsentNeededBody;

  /// No description provided for @symptomsQuestion.
  ///
  /// In uz, this message translates to:
  /// **'Nima bezovta qilyapti?'**
  String get symptomsQuestion;

  /// No description provided for @symptomsHint.
  ///
  /// In uz, this message translates to:
  /// **'Masalan: 3 kundan beri harorat 38.5, tomoq og\'riyapti, yutishda og\'riq bor...'**
  String get symptomsHint;

  /// No description provided for @noPiiHint.
  ///
  /// In uz, this message translates to:
  /// **'Ism, telefon yoki pasport ma\'lumotlarini yozmang.'**
  String get noPiiHint;

  /// No description provided for @age.
  ///
  /// In uz, this message translates to:
  /// **'Yosh'**
  String get age;

  /// No description provided for @durationDays.
  ///
  /// In uz, this message translates to:
  /// **'Davomiyligi (kun)'**
  String get durationDays;

  /// No description provided for @female.
  ///
  /// In uz, this message translates to:
  /// **'Ayol'**
  String get female;

  /// No description provided for @male.
  ///
  /// In uz, this message translates to:
  /// **'Erkak'**
  String get male;

  /// No description provided for @prefilledFromProfile.
  ///
  /// In uz, this message translates to:
  /// **'Ma\'lumotlar tibbiy profilingizdan olindi'**
  String get prefilledFromProfile;

  /// No description provided for @chronicIncluded.
  ///
  /// In uz, this message translates to:
  /// **'Hisobga olinadi: {list}'**
  String chronicIncluded(String list);

  /// No description provided for @analyze.
  ///
  /// In uz, this message translates to:
  /// **'Tahlil qilish'**
  String get analyze;

  /// No description provided for @analyzing.
  ///
  /// In uz, this message translates to:
  /// **'Tahlil qilinmoqda...'**
  String get analyzing;

  /// No description provided for @triagePoweredBy.
  ///
  /// In uz, this message translates to:
  /// **'Tahlil Google Med-PaLM 2 yordamida bajariladi va tashxis hisoblanmaydi.'**
  String get triagePoweredBy;

  /// No description provided for @resultTitle.
  ///
  /// In uz, this message translates to:
  /// **'Tahlil natijasi'**
  String get resultTitle;

  /// No description provided for @urgencyEmergency.
  ///
  /// In uz, this message translates to:
  /// **'Shoshilinch yordam kerak'**
  String get urgencyEmergency;

  /// No description provided for @urgencyEmergencyBody.
  ///
  /// In uz, this message translates to:
  /// **'Darhol {phone} ga qo\'ng\'iroq qiling yoki eng yaqin shifoxonaga boring.'**
  String urgencyEmergencyBody(String phone);

  /// No description provided for @urgencyUrgent.
  ///
  /// In uz, this message translates to:
  /// **'Tez orada shifokorga ko\'rining'**
  String get urgencyUrgent;

  /// No description provided for @urgencyUrgentBody.
  ///
  /// In uz, this message translates to:
  /// **'Bugun yoki ertaga shifokor qabuliga yoziling.'**
  String get urgencyUrgentBody;

  /// No description provided for @urgencyRoutine.
  ///
  /// In uz, this message translates to:
  /// **'Rejali qabul'**
  String get urgencyRoutine;

  /// No description provided for @urgencyRoutineBody.
  ///
  /// In uz, this message translates to:
  /// **'Yaqin kunlarda shifokor ko\'rigidan o\'ting.'**
  String get urgencyRoutineBody;

  /// No description provided for @urgencySelfCare.
  ///
  /// In uz, this message translates to:
  /// **'Uyda kuzatish'**
  String get urgencySelfCare;

  /// No description provided for @urgencySelfCareBody.
  ///
  /// In uz, this message translates to:
  /// **'Holat yomonlashsa, shifokorga murojaat qiling.'**
  String get urgencySelfCareBody;

  /// No description provided for @redFlags.
  ///
  /// In uz, this message translates to:
  /// **'Xavfli belgilar'**
  String get redFlags;

  /// No description provided for @possibleCauses.
  ///
  /// In uz, this message translates to:
  /// **'Ehtimoliy sabablar'**
  String get possibleCauses;

  /// No description provided for @likelihoodHigh.
  ///
  /// In uz, this message translates to:
  /// **'Yuqori'**
  String get likelihoodHigh;

  /// No description provided for @likelihoodMedium.
  ///
  /// In uz, this message translates to:
  /// **'O\'rtacha'**
  String get likelihoodMedium;

  /// No description provided for @likelihoodLow.
  ///
  /// In uz, this message translates to:
  /// **'Past'**
  String get likelihoodLow;

  /// No description provided for @advice.
  ///
  /// In uz, this message translates to:
  /// **'Tavsiya'**
  String get advice;

  /// No description provided for @whichDoctor.
  ///
  /// In uz, this message translates to:
  /// **'Qaysi shifokorga borish kerak'**
  String get whichDoctor;

  /// No description provided for @findSpecialist.
  ///
  /// In uz, this message translates to:
  /// **'{specialty} topish'**
  String findSpecialist(String specialty);

  /// No description provided for @disclaimer.
  ///
  /// In uz, this message translates to:
  /// **'Bu tahlil tashxis emas va shifokor ko\'rigining o\'rnini bosmaydi.'**
  String get disclaimer;

  /// No description provided for @searchDoctors.
  ///
  /// In uz, this message translates to:
  /// **'Shifokor yoki klinika'**
  String get searchDoctors;

  /// No description provided for @noDoctorsFound.
  ///
  /// In uz, this message translates to:
  /// **'Shifokorlar topilmadi'**
  String get noDoctorsFound;

  /// No description provided for @noDoctorsFoundHint.
  ///
  /// In uz, this message translates to:
  /// **'Boshqa mutaxassislik yoki so\'rovni sinab ko\'ring'**
  String get noDoctorsFoundHint;

  /// No description provided for @verifiedLicense.
  ///
  /// In uz, this message translates to:
  /// **'Litsenziya tekshirilgan'**
  String get verifiedLicense;

  /// No description provided for @yearsExperience.
  ///
  /// In uz, this message translates to:
  /// **'{count, plural, other{{count} yil tajriba}}'**
  String yearsExperience(int count);

  /// No description provided for @experienceLabel.
  ///
  /// In uz, this message translates to:
  /// **'Yil tajriba'**
  String get experienceLabel;

  /// No description provided for @rating.
  ///
  /// In uz, this message translates to:
  /// **'Reyting'**
  String get rating;

  /// No description provided for @reviews.
  ///
  /// In uz, this message translates to:
  /// **'Sharhlar'**
  String get reviews;

  /// No description provided for @about.
  ///
  /// In uz, this message translates to:
  /// **'Haqida'**
  String get about;

  /// No description provided for @consultationPrice.
  ///
  /// In uz, this message translates to:
  /// **'Qabul narxi: {price}'**
  String consultationPrice(String price);

  /// No description provided for @patientReviews.
  ///
  /// In uz, this message translates to:
  /// **'Bemorlar sharhlari'**
  String get patientReviews;

  /// No description provided for @chooseDay.
  ///
  /// In uz, this message translates to:
  /// **'Kunni tanlang'**
  String get chooseDay;

  /// No description provided for @chooseTime.
  ///
  /// In uz, this message translates to:
  /// **'Vaqtni tanlang'**
  String get chooseTime;

  /// No description provided for @morning.
  ///
  /// In uz, this message translates to:
  /// **'Ertalab'**
  String get morning;

  /// No description provided for @afternoon.
  ///
  /// In uz, this message translates to:
  /// **'Tushdan keyin'**
  String get afternoon;

  /// No description provided for @noSlots.
  ///
  /// In uz, this message translates to:
  /// **'Bu kunda bo\'sh vaqt yo\'q'**
  String get noSlots;

  /// No description provided for @visitReason.
  ///
  /// In uz, this message translates to:
  /// **'Murojaat sababi'**
  String get visitReason;

  /// No description provided for @visitReasonHint.
  ///
  /// In uz, this message translates to:
  /// **'Faqat shifokor ko\'radi'**
  String get visitReasonHint;

  /// No description provided for @bookFor.
  ///
  /// In uz, this message translates to:
  /// **'Yozilish · {when} · {price}'**
  String bookFor(String when, String price);

  /// No description provided for @holdNotice.
  ///
  /// In uz, this message translates to:
  /// **'Vaqt 15 daqiqa band qilinadi — shu muddatda to\'lang.'**
  String get holdNotice;

  /// No description provided for @priceUzs.
  ///
  /// In uz, this message translates to:
  /// **'{amount} so\'m'**
  String priceUzs(String amount);

  /// No description provided for @payment.
  ///
  /// In uz, this message translates to:
  /// **'To\'lov'**
  String get payment;

  /// No description provided for @paymentMethod.
  ///
  /// In uz, this message translates to:
  /// **'To\'lov usuli'**
  String get paymentMethod;

  /// No description provided for @localCards.
  ///
  /// In uz, this message translates to:
  /// **'Uzcard, Humo'**
  String get localCards;

  /// No description provided for @intlCards.
  ///
  /// In uz, this message translates to:
  /// **'Visa, Mastercard'**
  String get intlCards;

  /// No description provided for @payAmount.
  ///
  /// In uz, this message translates to:
  /// **'To\'lash · {price}'**
  String payAmount(String price);

  /// No description provided for @pay.
  ///
  /// In uz, this message translates to:
  /// **'To\'lash'**
  String get pay;

  /// No description provided for @checkPayment.
  ///
  /// In uz, this message translates to:
  /// **'To\'lovni tekshirish'**
  String get checkPayment;

  /// No description provided for @paymentNotYet.
  ///
  /// In uz, this message translates to:
  /// **'To\'lov hali tasdiqlanmadi. Birozdan so\'ng tekshiring.'**
  String get paymentNotYet;

  /// No description provided for @paymentFailed.
  ///
  /// In uz, this message translates to:
  /// **'To\'lov amalga oshmadi'**
  String get paymentFailed;

  /// No description provided for @cardSafety.
  ///
  /// In uz, this message translates to:
  /// **'Karta ma\'lumotlari MedLink serverlarida saqlanmaydi.'**
  String get cardSafety;

  /// No description provided for @holdLeft.
  ///
  /// In uz, this message translates to:
  /// **'Bron muddati: {time}'**
  String holdLeft(String time);

  /// No description provided for @holdExpired.
  ///
  /// In uz, this message translates to:
  /// **'Bron muddati tugadi. Vaqtni qayta tanlang.'**
  String get holdExpired;

  /// No description provided for @appointmentConfirmed.
  ///
  /// In uz, this message translates to:
  /// **'Qabul tasdiqlandi!'**
  String get appointmentConfirmed;

  /// No description provided for @backToHome.
  ///
  /// In uz, this message translates to:
  /// **'Bosh sahifaga'**
  String get backToHome;

  /// No description provided for @upcoming.
  ///
  /// In uz, this message translates to:
  /// **'Kelgusi'**
  String get upcoming;

  /// No description provided for @past.
  ///
  /// In uz, this message translates to:
  /// **'O\'tgan'**
  String get past;

  /// No description provided for @noUpcoming.
  ///
  /// In uz, this message translates to:
  /// **'Kelgusi qabullar yo\'q'**
  String get noUpcoming;

  /// No description provided for @noPast.
  ///
  /// In uz, this message translates to:
  /// **'O\'tgan qabullar yo\'q'**
  String get noPast;

  /// No description provided for @findDoctor.
  ///
  /// In uz, this message translates to:
  /// **'Shifokor topish'**
  String get findDoctor;

  /// No description provided for @statusAwaitingPayment.
  ///
  /// In uz, this message translates to:
  /// **'To\'lov kutilmoqda'**
  String get statusAwaitingPayment;

  /// No description provided for @statusConfirmed.
  ///
  /// In uz, this message translates to:
  /// **'Tasdiqlangan'**
  String get statusConfirmed;

  /// No description provided for @statusCompleted.
  ///
  /// In uz, this message translates to:
  /// **'Yakunlangan'**
  String get statusCompleted;

  /// No description provided for @statusCancelled.
  ///
  /// In uz, this message translates to:
  /// **'Bekor qilingan'**
  String get statusCancelled;

  /// No description provided for @appointmentDetails.
  ///
  /// In uz, this message translates to:
  /// **'Qabul tafsilotlari'**
  String get appointmentDetails;

  /// No description provided for @dateLabel.
  ///
  /// In uz, this message translates to:
  /// **'Sana'**
  String get dateLabel;

  /// No description provided for @timeLabel.
  ///
  /// In uz, this message translates to:
  /// **'Vaqt'**
  String get timeLabel;

  /// No description provided for @clinicLabel.
  ///
  /// In uz, this message translates to:
  /// **'Klinika'**
  String get clinicLabel;

  /// No description provided for @priceLabel.
  ///
  /// In uz, this message translates to:
  /// **'Narx'**
  String get priceLabel;

  /// No description provided for @cancelAppointment.
  ///
  /// In uz, this message translates to:
  /// **'Qabulni bekor qilish'**
  String get cancelAppointment;

  /// No description provided for @cancelAppointmentConfirm.
  ///
  /// In uz, this message translates to:
  /// **'Haqiqatan ham qabulni bekor qilmoqchimisiz?'**
  String get cancelAppointmentConfirm;

  /// No description provided for @rateDoctor.
  ///
  /// In uz, this message translates to:
  /// **'Shifokorni baholash'**
  String get rateDoctor;

  /// No description provided for @reviewHint.
  ///
  /// In uz, this message translates to:
  /// **'Tajribangiz haqida yozing (ixtiyoriy)'**
  String get reviewHint;

  /// No description provided for @yourReview.
  ///
  /// In uz, this message translates to:
  /// **'Sizning bahoyingiz'**
  String get yourReview;

  /// No description provided for @doctorApplication.
  ///
  /// In uz, this message translates to:
  /// **'Shifokor arizasi'**
  String get doctorApplication;

  /// No description provided for @moderationHowTitle.
  ///
  /// In uz, this message translates to:
  /// **'Moderatsiya qanday o\'tadi'**
  String get moderationHowTitle;

  /// No description provided for @moderationHowBody.
  ///
  /// In uz, this message translates to:
  /// **'Diplom, litsenziya (Sog\'liqni saqlash vazirligi reyestri) va shaxsni tasdiqlovchi hujjat tekshiriladi. Tasdiqlangandan so\'ng profilingiz \"tekshirilgan\" belgisi bilan bemorlarga ko\'rinadi. Odatda 1–3 ish kuni.'**
  String get moderationHowBody;

  /// No description provided for @fullName.
  ///
  /// In uz, this message translates to:
  /// **'F.I.Sh.'**
  String get fullName;

  /// No description provided for @fullNameInvalid.
  ///
  /// In uz, this message translates to:
  /// **'To\'liq F.I.Sh. kiriting'**
  String get fullNameInvalid;

  /// No description provided for @specialty.
  ///
  /// In uz, this message translates to:
  /// **'Mutaxassislik'**
  String get specialty;

  /// No description provided for @licenseNumber.
  ///
  /// In uz, this message translates to:
  /// **'Litsenziya raqami'**
  String get licenseNumber;

  /// No description provided for @city.
  ///
  /// In uz, this message translates to:
  /// **'Shahar'**
  String get city;

  /// No description provided for @experienceYearsLabel.
  ///
  /// In uz, this message translates to:
  /// **'Tajriba (yil)'**
  String get experienceYearsLabel;

  /// No description provided for @priceUzsLabel.
  ///
  /// In uz, this message translates to:
  /// **'Narx (so\'m)'**
  String get priceUzsLabel;

  /// No description provided for @aboutYou.
  ///
  /// In uz, this message translates to:
  /// **'O\'zingiz haqingizda'**
  String get aboutYou;

  /// No description provided for @documents.
  ///
  /// In uz, this message translates to:
  /// **'Hujjatlar'**
  String get documents;

  /// No description provided for @documentsHint.
  ///
  /// In uz, this message translates to:
  /// **'Diplom, litsenziya, pasport nusxalariga havolalar (har qatorda bittadan)'**
  String get documentsHint;

  /// No description provided for @applicationConfirm.
  ///
  /// In uz, this message translates to:
  /// **'Ma\'lumotlar to\'g\'riligini tasdiqlayman va ular tekshirilishiga roziman'**
  String get applicationConfirm;

  /// No description provided for @sendApplication.
  ///
  /// In uz, this message translates to:
  /// **'Arizani yuborish'**
  String get sendApplication;

  /// No description provided for @applicationSent.
  ///
  /// In uz, this message translates to:
  /// **'Ariza yuborildi. Moderatsiya 1–3 ish kuni davom etadi.'**
  String get applicationSent;

  /// No description provided for @noPatients.
  ///
  /// In uz, this message translates to:
  /// **'Hozircha yozilgan bemorlar yo\'q'**
  String get noPatients;

  /// No description provided for @noReason.
  ///
  /// In uz, this message translates to:
  /// **'Sabab ko\'rsatilmagan'**
  String get noReason;

  /// No description provided for @completeVisit.
  ///
  /// In uz, this message translates to:
  /// **'Qabulni yakunlash'**
  String get completeVisit;

  /// No description provided for @completeVisitConfirm.
  ///
  /// In uz, this message translates to:
  /// **'Qabul o\'tkazilganini tasdiqlaysizmi? Shundan so\'ng bemor baho qoldira oladi.'**
  String get completeVisitConfirm;

  /// No description provided for @noPending.
  ///
  /// In uz, this message translates to:
  /// **'Tekshirilishi kerak bo\'lgan arizalar yo\'q'**
  String get noPending;

  /// No description provided for @approve.
  ///
  /// In uz, this message translates to:
  /// **'Tasdiqlash'**
  String get approve;

  /// No description provided for @approveConfirm.
  ///
  /// In uz, this message translates to:
  /// **'{name} arizasini tasdiqlaysizmi? Profil bemorlarga ko\'rinadi.'**
  String approveConfirm(String name);

  /// No description provided for @reject.
  ///
  /// In uz, this message translates to:
  /// **'Rad etish'**
  String get reject;

  /// No description provided for @rejectReason.
  ///
  /// In uz, this message translates to:
  /// **'Rad etish sababi'**
  String get rejectReason;

  /// No description provided for @rejectReasonHint.
  ///
  /// In uz, this message translates to:
  /// **'Masalan: litsenziya reyestrda topilmadi'**
  String get rejectReasonHint;

  /// No description provided for @patient.
  ///
  /// In uz, this message translates to:
  /// **'Bemor'**
  String get patient;

  /// No description provided for @rolePatient.
  ///
  /// In uz, this message translates to:
  /// **'Bemor'**
  String get rolePatient;

  /// No description provided for @roleDoctor.
  ///
  /// In uz, this message translates to:
  /// **'Shifokor'**
  String get roleDoctor;

  /// No description provided for @roleAdmin.
  ///
  /// In uz, this message translates to:
  /// **'Administrator'**
  String get roleAdmin;

  /// No description provided for @health.
  ///
  /// In uz, this message translates to:
  /// **'Sog\'liq'**
  String get health;

  /// No description provided for @medicalProfile.
  ///
  /// In uz, this message translates to:
  /// **'Tibbiy profil'**
  String get medicalProfile;

  /// No description provided for @medicalProfileSubtitle.
  ///
  /// In uz, this message translates to:
  /// **'Allergiyalar, surunkali kasalliklar, dorilar'**
  String get medicalProfileSubtitle;

  /// No description provided for @medicalProfileNote.
  ///
  /// In uz, this message translates to:
  /// **'Ma\'lumotlar shifrlangan holda saqlanadi va AI tahliliga avtomatik qo\'shiladi.'**
  String get medicalProfileNote;

  /// No description provided for @birthDate.
  ///
  /// In uz, this message translates to:
  /// **'Tug\'ilgan sana'**
  String get birthDate;

  /// No description provided for @bloodType.
  ///
  /// In uz, this message translates to:
  /// **'Qon guruhi'**
  String get bloodType;

  /// No description provided for @heightCm.
  ///
  /// In uz, this message translates to:
  /// **'Bo\'y (sm)'**
  String get heightCm;

  /// No description provided for @weightKg.
  ///
  /// In uz, this message translates to:
  /// **'Vazn (kg)'**
  String get weightKg;

  /// No description provided for @allergies.
  ///
  /// In uz, this message translates to:
  /// **'Allergiyalar'**
  String get allergies;

  /// No description provided for @allergiesHint.
  ///
  /// In uz, this message translates to:
  /// **'Masalan: penitsillin'**
  String get allergiesHint;

  /// No description provided for @chronicConditions.
  ///
  /// In uz, this message translates to:
  /// **'Surunkali kasalliklar'**
  String get chronicConditions;

  /// No description provided for @chronicHint.
  ///
  /// In uz, this message translates to:
  /// **'Masalan: qandli diabet 2-tur'**
  String get chronicHint;

  /// No description provided for @medications.
  ///
  /// In uz, this message translates to:
  /// **'Doimiy dorilar'**
  String get medications;

  /// No description provided for @medicationsHint.
  ///
  /// In uz, this message translates to:
  /// **'Masalan: metformin 500 mg'**
  String get medicationsHint;

  /// No description provided for @forDoctors.
  ///
  /// In uz, this message translates to:
  /// **'Shifokorlar uchun'**
  String get forDoctors;

  /// No description provided for @becomeDoctor.
  ///
  /// In uz, this message translates to:
  /// **'Shifokor sifatida qo\'shilish'**
  String get becomeDoctor;

  /// No description provided for @becomeDoctorSubtitle.
  ///
  /// In uz, this message translates to:
  /// **'Ariza topshiring va moderatsiyadan o\'ting'**
  String get becomeDoctorSubtitle;

  /// No description provided for @applicationPending.
  ///
  /// In uz, this message translates to:
  /// **'Ariza ko\'rib chiqilmoqda'**
  String get applicationPending;

  /// No description provided for @applicationApproved.
  ///
  /// In uz, this message translates to:
  /// **'Tasdiqlangan shifokor'**
  String get applicationApproved;

  /// No description provided for @applicationRejected.
  ///
  /// In uz, this message translates to:
  /// **'Ariza rad etilgan'**
  String get applicationRejected;

  /// No description provided for @applicationSuspended.
  ///
  /// In uz, this message translates to:
  /// **'Profil to\'xtatilgan'**
  String get applicationSuspended;

  /// No description provided for @moderatorNote.
  ///
  /// In uz, this message translates to:
  /// **'Moderator izohi: {note}'**
  String moderatorNote(String note);

  /// No description provided for @reapply.
  ///
  /// In uz, this message translates to:
  /// **'Qayta ariza topshirish'**
  String get reapply;

  /// No description provided for @settings.
  ///
  /// In uz, this message translates to:
  /// **'Sozlamalar'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In uz, this message translates to:
  /// **'Til'**
  String get language;

  /// No description provided for @theme.
  ///
  /// In uz, this message translates to:
  /// **'Mavzu'**
  String get theme;

  /// No description provided for @themeLight.
  ///
  /// In uz, this message translates to:
  /// **'Yorug\''**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In uz, this message translates to:
  /// **'Qorong\'i'**
  String get themeDark;

  /// No description provided for @biometricLock.
  ///
  /// In uz, this message translates to:
  /// **'Biometrik qulf'**
  String get biometricLock;

  /// No description provided for @biometricLockSubtitle.
  ///
  /// In uz, this message translates to:
  /// **'Face ID / barmoq izi bilan ochish'**
  String get biometricLockSubtitle;

  /// No description provided for @biometricReason.
  ///
  /// In uz, this message translates to:
  /// **'MedLink\'ni ochish uchun shaxsingizni tasdiqlang'**
  String get biometricReason;

  /// No description provided for @lockedTitle.
  ///
  /// In uz, this message translates to:
  /// **'MedLink qulflangan'**
  String get lockedTitle;

  /// No description provided for @unlock.
  ///
  /// In uz, this message translates to:
  /// **'Ochish'**
  String get unlock;

  /// No description provided for @privacy.
  ///
  /// In uz, this message translates to:
  /// **'Maxfiylik'**
  String get privacy;

  /// No description provided for @exportData.
  ///
  /// In uz, this message translates to:
  /// **'Ma\'lumotlarim nusxasi'**
  String get exportData;

  /// No description provided for @exportDataSubtitle.
  ///
  /// In uz, this message translates to:
  /// **'Saqlangan barcha ma\'lumotlarni olish'**
  String get exportDataSubtitle;

  /// No description provided for @exportCopied.
  ///
  /// In uz, this message translates to:
  /// **'Ma\'lumotlaringiz nusxasi buferga ko\'chirildi'**
  String get exportCopied;

  /// No description provided for @deleteHealthData.
  ///
  /// In uz, this message translates to:
  /// **'Tibbiy ma\'lumotlarni o\'chirish'**
  String get deleteHealthData;

  /// No description provided for @deleteHealthDataConfirm.
  ///
  /// In uz, this message translates to:
  /// **'AI tahlillari va tibbiy profil qaytarib bo\'lmaydigan tarzda o\'chiriladi. Qabullar tarixi qonunda belgilangan muddat saqlanadi.'**
  String get deleteHealthDataConfirm;

  /// No description provided for @emergencyNumber.
  ///
  /// In uz, this message translates to:
  /// **'Tez yordam'**
  String get emergencyNumber;

  /// No description provided for @version.
  ///
  /// In uz, this message translates to:
  /// **'Versiya'**
  String get version;

  /// No description provided for @specTherapist.
  ///
  /// In uz, this message translates to:
  /// **'Terapevt'**
  String get specTherapist;

  /// No description provided for @specPediatrician.
  ///
  /// In uz, this message translates to:
  /// **'Pediatr'**
  String get specPediatrician;

  /// No description provided for @specCardiologist.
  ///
  /// In uz, this message translates to:
  /// **'Kardiolog'**
  String get specCardiologist;

  /// No description provided for @specNeurologist.
  ///
  /// In uz, this message translates to:
  /// **'Nevrolog'**
  String get specNeurologist;

  /// No description provided for @specGastroenterologist.
  ///
  /// In uz, this message translates to:
  /// **'Gastroenterolog'**
  String get specGastroenterologist;

  /// No description provided for @specPulmonologist.
  ///
  /// In uz, this message translates to:
  /// **'Pulmonolog'**
  String get specPulmonologist;

  /// No description provided for @specEndocrinologist.
  ///
  /// In uz, this message translates to:
  /// **'Endokrinolog'**
  String get specEndocrinologist;

  /// No description provided for @specDermatologist.
  ///
  /// In uz, this message translates to:
  /// **'Dermatolog'**
  String get specDermatologist;

  /// No description provided for @specEnt.
  ///
  /// In uz, this message translates to:
  /// **'LOR'**
  String get specEnt;

  /// No description provided for @specOphthalmologist.
  ///
  /// In uz, this message translates to:
  /// **'Oftalmolog'**
  String get specOphthalmologist;

  /// No description provided for @specGynecologist.
  ///
  /// In uz, this message translates to:
  /// **'Ginekolog'**
  String get specGynecologist;

  /// No description provided for @specUrologist.
  ///
  /// In uz, this message translates to:
  /// **'Urolog'**
  String get specUrologist;

  /// No description provided for @specTraumatologist.
  ///
  /// In uz, this message translates to:
  /// **'Travmatolog'**
  String get specTraumatologist;

  /// No description provided for @specPsychiatrist.
  ///
  /// In uz, this message translates to:
  /// **'Psixiatr'**
  String get specPsychiatrist;

  /// No description provided for @tashkentTime.
  ///
  /// In uz, this message translates to:
  /// **'Toshkent vaqti bilan (UTC+5)'**
  String get tashkentTime;

  /// No description provided for @completeProfile.
  ///
  /// In uz, this message translates to:
  /// **'Profilni to\'ldiring'**
  String get completeProfile;

  /// No description provided for @licenses.
  ///
  /// In uz, this message translates to:
  /// **'Litsenziyalar'**
  String get licenses;

  /// No description provided for @reminderTitle.
  ///
  /// In uz, this message translates to:
  /// **'MedLink: qabul eslatmasi'**
  String get reminderTitle;

  /// No description provided for @reminderDayBefore.
  ///
  /// In uz, this message translates to:
  /// **'Ertaga soat {time} da qabulingiz bor.'**
  String reminderDayBefore(String time);

  /// No description provided for @reminderHourBefore.
  ///
  /// In uz, this message translates to:
  /// **'Qabulingiz 1 soatdan keyin, soat {time} da.'**
  String reminderHourBefore(String time);

  /// No description provided for @notifications.
  ///
  /// In uz, this message translates to:
  /// **'Bildirishnomalar'**
  String get notifications;

  /// No description provided for @notificationsSubtitle.
  ///
  /// In uz, this message translates to:
  /// **'Qabul eslatmalari va holat o\'zgarishlari'**
  String get notificationsSubtitle;

  /// No description provided for @notificationsDenied.
  ///
  /// In uz, this message translates to:
  /// **'Ruxsat berilmadi. Telefon sozlamalaridan MedLink uchun bildirishnomalarni yoqing.'**
  String get notificationsDenied;

  /// No description provided for @enableRemindersTitle.
  ///
  /// In uz, this message translates to:
  /// **'Qabulni unutmang'**
  String get enableRemindersTitle;

  /// No description provided for @enableRemindersBody.
  ///
  /// In uz, this message translates to:
  /// **'Qabuldan 1 kun va 1 soat oldin eslatma yuboramiz. Matnda tibbiy ma\'lumot ko\'rsatilmaydi.'**
  String get enableRemindersBody;

  /// No description provided for @enableReminders.
  ///
  /// In uz, this message translates to:
  /// **'Eslatmalarni yoqish'**
  String get enableReminders;

  /// No description provided for @remindersEnabled.
  ///
  /// In uz, this message translates to:
  /// **'Eslatmalar yoqildi'**
  String get remindersEnabled;

  /// No description provided for @online.
  ///
  /// In uz, this message translates to:
  /// **'Onlayn'**
  String get online;

  /// No description provided for @inClinic.
  ///
  /// In uz, this message translates to:
  /// **'Klinikada'**
  String get inClinic;

  /// No description provided for @onlineAvailable.
  ///
  /// In uz, this message translates to:
  /// **'Onlayn qabul bor'**
  String get onlineAvailable;

  /// No description provided for @onlineOnly.
  ///
  /// In uz, this message translates to:
  /// **'Faqat onlayn qabul'**
  String get onlineOnly;

  /// No description provided for @consultationType.
  ///
  /// In uz, this message translates to:
  /// **'Qabul turi'**
  String get consultationType;

  /// No description provided for @consultationTypes.
  ///
  /// In uz, this message translates to:
  /// **'Qabul turlari'**
  String get consultationTypes;

  /// No description provided for @onlineHowItWorks.
  ///
  /// In uz, this message translates to:
  /// **'Qabul vaqtida ilovada video qo\'ng\'iroq ochiladi. Barqaror internet va tinch joy tayyorlang.'**
  String get onlineHowItWorks;

  /// No description provided for @onlinePriceLabel.
  ///
  /// In uz, this message translates to:
  /// **'Onlayn qabul: {price}'**
  String onlinePriceLabel(String price);

  /// No description provided for @onlineConsultation.
  ///
  /// In uz, this message translates to:
  /// **'Onlayn konsultatsiya'**
  String get onlineConsultation;

  /// No description provided for @joinVideo.
  ///
  /// In uz, this message translates to:
  /// **'Video qo\'ng\'iroqqa kirish'**
  String get joinVideo;

  /// No description provided for @videoReady.
  ///
  /// In uz, this message translates to:
  /// **'Xona ochiq. Shifokor bilan bog\'lanish uchun kiring.'**
  String get videoReady;

  /// No description provided for @videoReadyShort.
  ///
  /// In uz, this message translates to:
  /// **'Video tayyor'**
  String get videoReadyShort;

  /// No description provided for @videoOpensAt.
  ///
  /// In uz, this message translates to:
  /// **'Video soat {time} da ochiladi (qabuldan 10 daqiqa oldin).'**
  String videoOpensAt(String time);

  /// No description provided for @videoClosed.
  ///
  /// In uz, this message translates to:
  /// **'Video qabul vaqti tugadi. Savollarni chatda yozing.'**
  String get videoClosed;

  /// No description provided for @videoNotConfigured.
  ///
  /// In uz, this message translates to:
  /// **'Video xizmati hozircha ulanmagan. Shifokor bilan chat orqali bog\'laning.'**
  String get videoNotConfigured;

  /// No description provided for @videoTips.
  ///
  /// In uz, this message translates to:
  /// **'Maslahat: quloqchin ishlating, yorug\' joyda o\'tiring.'**
  String get videoTips;

  /// No description provided for @callConnecting.
  ///
  /// In uz, this message translates to:
  /// **'Ulanmoqda...'**
  String get callConnecting;

  /// No description provided for @callWaiting.
  ///
  /// In uz, this message translates to:
  /// **'Suhbatdosh hali kirmadi. Kuting...'**
  String get callWaiting;

  /// No description provided for @callReconnecting.
  ///
  /// In uz, this message translates to:
  /// **'Aloqa uzildi, qayta ulanmoqda...'**
  String get callReconnecting;

  /// No description provided for @callEnded.
  ///
  /// In uz, this message translates to:
  /// **'Qo\'ng\'iroq tugadi'**
  String get callEnded;

  /// No description provided for @callFailed.
  ///
  /// In uz, this message translates to:
  /// **'Ulanib bo\'lmadi. Internetni tekshirib, qayta urinib ko\'ring.'**
  String get callFailed;

  /// No description provided for @callPermissionDenied.
  ///
  /// In uz, this message translates to:
  /// **'Kamera yoki mikrofonga ruxsat berilmagan. Telefon sozlamalaridan MedLink uchun ruxsat bering.'**
  String get callPermissionDenied;

  /// No description provided for @callEncrypted.
  ///
  /// In uz, this message translates to:
  /// **'Shifrlangan aloqa · yozib olinmaydi'**
  String get callEncrypted;

  /// No description provided for @mute.
  ///
  /// In uz, this message translates to:
  /// **'Ovozni o\'chirish'**
  String get mute;

  /// No description provided for @unmute.
  ///
  /// In uz, this message translates to:
  /// **'Ovozni yoqish'**
  String get unmute;

  /// No description provided for @cameraOff.
  ///
  /// In uz, this message translates to:
  /// **'Kamerani o\'chirish'**
  String get cameraOff;

  /// No description provided for @cameraOn.
  ///
  /// In uz, this message translates to:
  /// **'Kamerani yoqish'**
  String get cameraOn;

  /// No description provided for @switchCamera.
  ///
  /// In uz, this message translates to:
  /// **'Almashtirish'**
  String get switchCamera;

  /// No description provided for @endCall.
  ///
  /// In uz, this message translates to:
  /// **'Tugatish'**
  String get endCall;

  /// No description provided for @endCallConfirm.
  ///
  /// In uz, this message translates to:
  /// **'Qo\'ng\'iroqni tugatmoqchimisiz?'**
  String get endCallConfirm;

  /// No description provided for @close.
  ///
  /// In uz, this message translates to:
  /// **'Yopish'**
  String get close;

  /// No description provided for @chat.
  ///
  /// In uz, this message translates to:
  /// **'Chat'**
  String get chat;

  /// No description provided for @chatSubtitle.
  ///
  /// In uz, this message translates to:
  /// **'Shifokorga savol bering'**
  String get chatSubtitle;

  /// No description provided for @chatSubtitleDoctor.
  ///
  /// In uz, this message translates to:
  /// **'Bemor bilan yozishma'**
  String get chatSubtitleDoctor;

  /// No description provided for @chatHint.
  ///
  /// In uz, this message translates to:
  /// **'Xabar yozing...'**
  String get chatHint;

  /// No description provided for @send.
  ///
  /// In uz, this message translates to:
  /// **'Yuborish'**
  String get send;

  /// No description provided for @sending.
  ///
  /// In uz, this message translates to:
  /// **'Yuborilmoqda'**
  String get sending;

  /// No description provided for @chatEmptyTitle.
  ///
  /// In uz, this message translates to:
  /// **'Hali xabarlar yo\'q'**
  String get chatEmptyTitle;

  /// No description provided for @chatEmptyBody.
  ///
  /// In uz, this message translates to:
  /// **'Qabul bo\'yicha savolingizni yozing. Shifokor ish vaqtida javob beradi.'**
  String get chatEmptyBody;

  /// No description provided for @chatClosed.
  ///
  /// In uz, this message translates to:
  /// **'Chat yopilgan: qabuldan keyin 7 kun o\'tdi.'**
  String get chatClosed;

  /// No description provided for @chatEmergencyNote.
  ///
  /// In uz, this message translates to:
  /// **'Chat shoshilinch yordam uchun emas — xavfli holatda 103 ga qo\'ng\'iroq qiling'**
  String get chatEmergencyNote;

  /// No description provided for @patientInfo.
  ///
  /// In uz, this message translates to:
  /// **'Bemor ma\'lumotlari'**
  String get patientInfo;

  /// No description provided for @patientInfoSubtitle.
  ///
  /// In uz, this message translates to:
  /// **'Tibbiy profil va AI tahlili'**
  String get patientInfoSubtitle;

  /// No description provided for @aiPreTriage.
  ///
  /// In uz, this message translates to:
  /// **'Qabul oldidan AI tahlili'**
  String get aiPreTriage;

  /// No description provided for @viewDetails.
  ///
  /// In uz, this message translates to:
  /// **'Batafsil ko\'rish'**
  String get viewDetails;

  /// No description provided for @sex.
  ///
  /// In uz, this message translates to:
  /// **'Jins'**
  String get sex;

  /// No description provided for @heightWeight.
  ///
  /// In uz, this message translates to:
  /// **'Bo\'y / vazn'**
  String get heightWeight;

  /// No description provided for @patientReview.
  ///
  /// In uz, this message translates to:
  /// **'Bemor bahosi'**
  String get patientReview;

  /// No description provided for @conclusion.
  ///
  /// In uz, this message translates to:
  /// **'Shifokor xulosasi'**
  String get conclusion;

  /// No description provided for @writeConclusion.
  ///
  /// In uz, this message translates to:
  /// **'Xulosa yozish'**
  String get writeConclusion;

  /// No description provided for @editConclusion.
  ///
  /// In uz, this message translates to:
  /// **'Xulosani tahrirlash'**
  String get editConclusion;

  /// No description provided for @saveConclusion.
  ///
  /// In uz, this message translates to:
  /// **'Xulosani saqlash'**
  String get saveConclusion;

  /// No description provided for @saveConclusionConfirm.
  ///
  /// In uz, this message translates to:
  /// **'Xulosa bemorga yuboriladi va qabul yakunlanadi. Davom etasizmi?'**
  String get saveConclusionConfirm;

  /// No description provided for @conclusionSaved.
  ///
  /// In uz, this message translates to:
  /// **'Xulosa saqlandi va bemorga yuborildi'**
  String get conclusionSaved;

  /// No description provided for @diagnosis.
  ///
  /// In uz, this message translates to:
  /// **'Tashxis'**
  String get diagnosis;

  /// No description provided for @diagnosisHint.
  ///
  /// In uz, this message translates to:
  /// **'Masalan: O\'tkir respirator infeksiya (J06.9)'**
  String get diagnosisHint;

  /// No description provided for @recommendations.
  ///
  /// In uz, this message translates to:
  /// **'Tavsiyalar'**
  String get recommendations;

  /// No description provided for @prescription.
  ///
  /// In uz, this message translates to:
  /// **'Retsept'**
  String get prescription;

  /// No description provided for @addMedication.
  ///
  /// In uz, this message translates to:
  /// **'Dori qo\'shish'**
  String get addMedication;

  /// No description provided for @noPrescription.
  ///
  /// In uz, this message translates to:
  /// **'Dori tayinlanmagan'**
  String get noPrescription;

  /// No description provided for @medication.
  ///
  /// In uz, this message translates to:
  /// **'Dori'**
  String get medication;

  /// No description provided for @drugName.
  ///
  /// In uz, this message translates to:
  /// **'Dori nomi'**
  String get drugName;

  /// No description provided for @dose.
  ///
  /// In uz, this message translates to:
  /// **'Doza'**
  String get dose;

  /// No description provided for @frequency.
  ///
  /// In uz, this message translates to:
  /// **'Qabul qilish tartibi'**
  String get frequency;

  /// No description provided for @frequencyHint.
  ///
  /// In uz, this message translates to:
  /// **'Masalan: kuniga 2 marta, ovqatdan keyin'**
  String get frequencyHint;

  /// No description provided for @notes.
  ///
  /// In uz, this message translates to:
  /// **'Izoh'**
  String get notes;

  /// No description provided for @followUp.
  ///
  /// In uz, this message translates to:
  /// **'Qayta ko\'rik'**
  String get followUp;

  /// No description provided for @followUpNone.
  ///
  /// In uz, this message translates to:
  /// **'Shart emas'**
  String get followUpNone;

  /// No description provided for @inDays.
  ///
  /// In uz, this message translates to:
  /// **'{days} kundan keyin'**
  String inDays(int days);

  /// No description provided for @forDays.
  ///
  /// In uz, this message translates to:
  /// **'{days} kun'**
  String forDays(int days);

  /// No description provided for @followUpIn.
  ///
  /// In uz, this message translates to:
  /// **'Qayta ko\'rik: {days} kundan keyin'**
  String followUpIn(int days);

  /// No description provided for @conclusionPrivacy.
  ///
  /// In uz, this message translates to:
  /// **'Xulosa shifrlangan holda saqlanadi va faqat bemorga ko\'rinadi.'**
  String get conclusionPrivacy;

  /// No description provided for @conclusionDisclaimer.
  ///
  /// In uz, this message translates to:
  /// **'Dorilarni faqat shifokor ko\'rsatmasiga ko\'ra qabul qiling. Ahvolingiz yomonlashsa — 103.'**
  String get conclusionDisclaimer;

  /// No description provided for @scheduleAndPrices.
  ///
  /// In uz, this message translates to:
  /// **'Jadval va narxlar'**
  String get scheduleAndPrices;

  /// No description provided for @scheduleAndPricesSubtitle.
  ///
  /// In uz, this message translates to:
  /// **'Ish kunlari, soatlar, onlayn qabul'**
  String get scheduleAndPricesSubtitle;

  /// No description provided for @workDays.
  ///
  /// In uz, this message translates to:
  /// **'Ish kunlari'**
  String get workDays;

  /// No description provided for @workHours.
  ///
  /// In uz, this message translates to:
  /// **'Ish vaqti (Toshkent vaqti)'**
  String get workHours;

  /// No description provided for @from.
  ///
  /// In uz, this message translates to:
  /// **'Boshlanishi'**
  String get from;

  /// No description provided for @to.
  ///
  /// In uz, this message translates to:
  /// **'Tugashi'**
  String get to;

  /// No description provided for @slotsPerDay.
  ///
  /// In uz, this message translates to:
  /// **'Kuniga {count} ta 30 daqiqalik qabul'**
  String slotsPerDay(int count);

  /// No description provided for @clinicPrice.
  ///
  /// In uz, this message translates to:
  /// **'Klinikadagi qabul narxi'**
  String get clinicPrice;

  /// No description provided for @onlinePrice.
  ///
  /// In uz, this message translates to:
  /// **'Onlayn qabul narxi'**
  String get onlinePrice;

  /// No description provided for @onlineSubtitle.
  ///
  /// In uz, this message translates to:
  /// **'Video qo\'ng\'iroq va chat orqali'**
  String get onlineSubtitle;

  /// No description provided for @scheduleNote.
  ///
  /// In uz, this message translates to:
  /// **'O\'zgarishlar faqat yangi bronlarga ta\'sir qiladi. Mavjud qabullar saqlanadi.'**
  String get scheduleNote;

  /// No description provided for @chooseConsultationType.
  ///
  /// In uz, this message translates to:
  /// **'Kamida bitta qabul turini yoqing'**
  String get chooseConsultationType;

  /// No description provided for @onlinePriceRequired.
  ///
  /// In uz, this message translates to:
  /// **'Onlayn qabul narxini kiriting'**
  String get onlinePriceRequired;

  /// No description provided for @errorChatClosed.
  ///
  /// In uz, this message translates to:
  /// **'Chat yopilgan'**
  String get errorChatClosed;

  /// No description provided for @errorTooEarly.
  ///
  /// In uz, this message translates to:
  /// **'Video hali ochilmagan — qabuldan 10 daqiqa oldin ochiladi'**
  String get errorTooEarly;

  /// No description provided for @errorTooLate.
  ///
  /// In uz, this message translates to:
  /// **'Video qabul vaqti tugagan'**
  String get errorTooLate;

  /// No description provided for @errorVideoUnavailable.
  ///
  /// In uz, this message translates to:
  /// **'Video xizmati vaqtincha ishlamayapti'**
  String get errorVideoUnavailable;

  /// No description provided for @errorTypeUnavailable.
  ///
  /// In uz, this message translates to:
  /// **'Shifokor bu turdagi qabulni o\'tkazmaydi'**
  String get errorTypeUnavailable;

  /// No description provided for @errorInvalidSchedule.
  ///
  /// In uz, this message translates to:
  /// **'Jadval noto\'g\'ri: ish vaqti va kunlarini tekshiring'**
  String get errorInvalidSchedule;

  /// No description provided for @videoNotConfiguredDoctor.
  ///
  /// In uz, this message translates to:
  /// **'Video xizmati hozircha ulanmagan. Bemor bilan chat orqali bog\'laning.'**
  String get videoNotConfiguredDoctor;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ru', 'uz'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
    case 'uz':
      return AppLocalizationsUz();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
