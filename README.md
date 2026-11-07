<p align="center"><img src="mobile/assets/brand/medlink_logo.jpg" width="420" alt="MedLink"></p>

# MedLink

Sun'iy intellektga ega mobil tibbiy platforma: bemorlar alomatlarini AI orqali
tahlil qiladi, tekshirilgan shifokorni topadi, qabulga yoziladi va to'laydi.

| Qism | Texnologiya | Papka |
|---|---|---|
| Mobil ilova (Android, iOS) | Flutter 3.47 / Dart 3.13 | [`mobile/`](mobile) |
| API server | Dart + shelf | [`backend/`](backend) |
| AI diagnostika | Google Med-PaLM 2 (Vertex AI MedLM) | `backend/lib/src/ai` |
| To'lovlar | Click, Payme, Google Pay, Apple Pay | `backend/lib/src/payments` |

<p align="center"><img src="docs/screenshots.png" width="900" alt="MedLink ekranlari"></p>

## Imkoniyatlar

**Bemor uchun**
- Tanishtiruv ekranlari, telefon raqami va SMS kod orqali kirish (6 katakli
  kod, SMS'dan avtomatik to'ldirish, qayta yuborish taymeri).
- Rozilik ekrani: har bir maqsad uchun alohida belgi, hech biri oldindan
  belgilanmagan, majburiylarisiz davom etib bo'lmaydi.
- AI alomatlar tahlili: shoshilinchlik darajasi, ehtimoliy sabablar, xavfli
  belgilar va qaysi mutaxassisga borish kerakligi. Shoshilinch holatda 103
  tugmasi chiqadi. Tibbiy profildagi yosh, jins va surunkali kasalliklar
  avtomatik qo'shiladi. Tahlillar tarixi saqlanadi.
- Tibbiy profil: tug'ilgan sana, qon guruhi, bo'y, vazn, allergiyalar,
  surunkali kasalliklar, doimiy dorilar.
- Shifokorlar bazasi: mutaxassislik bo'yicha filtr, qidiruv, reyting, sharhlar.
  Faqat moderatsiyadan o'tganlar ko'rinadi.
- Qabulga yozilish: 14 kunlik kalendar, ertalab va tushdan keyingi slotlar
  (har doim Toshkent vaqtida), 15 daqiqalik to'lov broni taymer bilan.
- To'lov: Click, Payme (ilovaga deep link orqali qaytadi), Google Pay
  (Android) va Apple Pay (iOS).
- Qabullar: kelgusi va o'tgan qabullar, tafsilotlar, bekor qilish, yakunlangan
  qabuldan keyin shifokorni baholash.
- Bildirishnomalar: to'lov tasdiqlandi, qabul bekor qilindi, qabuldan 24 soat
  va 1 soat oldin eslatma. Ruxsat birinchi to'lovdan keyin yoki sozlamalarda
  so'raladi. Bildirishnoma bosilsa qabul sahifasi ochiladi (biometrik qulf
  ochilgandan keyin).
- Sozlamalar: til (o'zbek, rus, ingliz), mavzu (yorug', qorong'i, tizim
  bo'yicha), Face ID / barmoq izi bilan qulflash.
- Maxfiylik: rozilikni qaytarib olish, ma'lumotlar nusxasini olish, tibbiy
  ma'lumotlarni o'chirish.

**Shifokor uchun**
- Ariza: F.I.Sh., mutaxassislik, litsenziya, hujjatlar.
- Holat: `pending` → `approved` / `rejected` (sababi bilan) → `suspended`.
  Rad etilsa, qayta ariza topshirish mumkin.
- Push: yangi bemor yozildi, qabul bekor qilindi, qabul eslatmasi, ariza
  natijasi.
- Tasdiqlangandan keyin "Bemorlarim" bo'limi ochiladi (rol ilova qayta
  ochilganda avtomatik yangilanadi). Qabulni yakunlash.

**Admin uchun**
- Moderatsiya navbati: litsenziya va hujjatlarni ko'rish, tasdiqlash yoki
  sababini yozib rad etish. Har bir qaror audit jurnaliga yoziladi.

## iOS va Android

| | Android | iOS |
|---|---|---|
| Minimal versiya | Android 7.0 (API 24) | iOS 15 |
| Splash | Native, yorug'/qorong'i, Android 12+ API | Native LaunchScreen, yorug'/qorong'i |
| Biometrika | Barmoq izi / yuz (`USE_BIOMETRIC`) | Face ID / Touch ID (`NSFaceIDUsageDescription`) |
| Ekranni himoyalash | `FLAG_SECURE`: skrinshot va so'nggi ilovalarda ko'rinmaydi | Fonga o'tganda logotipli parda |
| Tarmoq | Faqat HTTPS, foydalanuvchi o'rnatgan CA'larga ishonilmaydi | ATS (faqat HTTPS) |
| Zaxira nusxa | O'chirilgan (`allowBackup=false`, data extraction rules) | Token Keychain'da |
| Til | Ilova tilini tizim sozlamalarida tanlash (Android 13+) | `CFBundleLocalizations` |
| Orqaga qaytish | Predictive back | Chetdan surib qaytish (Cupertino) |
| To'lov hamyoni | Google Pay | Apple Pay (entitlement) |
| Deep link | `medlink://payment-result` | `medlink://payment-result` |
| Release | R8 minify + shrink, imzo `key.properties` yoki CI secret'lari orqali | `--no-codesign` CI build, imzolash Xcode'da |

## Push-bildirishnomalar

| | |
|---|---|
| Server push | Firebase Cloud Messaging HTTP v1, qurilma FID (Firebase Installation ID) bo'yicha (`message.fid`) |
| Mahalliy eslatmalar | Qabuldan 24 soat va 1 soat oldin, telefonda rejalashtiriladi (Firebase'siz ham ishlaydi, qayta yonganda tiklanadi) |
| Server eslatmasi | Qabulga 1 soat qolganda bemor va shifokorga (`ReminderScheduler`) |
| Maxfiylik | Matnda shifokor ismi, mutaxassislik, sabab yo'q (testlar tekshiradi). Android qulf ekranida mazmun yashirin (`visibility: private`) |
| Ruxsat | Ilova ochilganda emas — to'lovdan keyin yoki sozlamalarda. Rad etilsa, telefon sozlamalariga yo'naltiriladi |
| Eskirgan qurilmalar | FCM `UNREGISTERED` qaytarsa, qurilma o'chiriladi. Chiqishda FID serverdan o'chiriladi |

**Firebase'ni ulash:**
1. Firebase Console'da loyiha yarating, unga Android (`uz.medlink.medlink`)
   va iOS (`uz.medlink.medlink`) ilovalarini qo'shing.
2. iOS: Apple Developer'da APNs kalitini (.p8) yarating va Firebase →
   Project settings → Cloud Messaging bo'limiga yuklang. App ID uchun Push
   Notifications imkoniyatini yoqing.
3. Ilovani quyidagi parametrlar bilan yig'ing (bular maxfiy emas, CI'da
   repozitoriy *Variables* sifatida beriladi):
   ```bash
   flutter build appbundle \
     --dart-define=FIREBASE_PROJECT_ID=... --dart-define=FIREBASE_SENDER_ID=... \
     --dart-define=FIREBASE_ANDROID_API_KEY=... --dart-define=FIREBASE_ANDROID_APP_ID=... \
     --dart-define=FIREBASE_IOS_API_KEY=... --dart-define=FIREBASE_IOS_APP_ID=...
   ```
4. Backend: `FCM_PROJECT_ID` ni bering. Xizmat hisobiga Firebase Cloud
   Messaging API'ga yuborish ruxsatini bering. `FCM_PROJECT_ID` bo'sh bo'lsa,
   push'lar faqat logga yoziladi.

## Arxitektura (mobil)

```
mobile/lib/
  core/        api_client, session (token avtomatik yangilanadi), settings,
               theme (yorug'/qorong'i), l10n, app_lock, deep_links, clinic_time
  data/        repository.dart: barcha server so'rovlari shu yerda
  models/      Doctor, Appointment, TriageResult, MedicalProfile, ...
  features/    onboarding, auth, consent, home, triage, doctors, appointments,
               payments, medical_profile, doctor_portal, admin, profile, settings
  widgets/     brand (logo, 103 banneri), states (skelet, xato, bo'sh holat)
  l10n/        app_uz.arb (asosiy), app_ru.arb, app_en.arb
```

## Xavfsizlik va maxfiylik

| Talab | Amalga oshirilishi |
|---|---|
| Saqlashda shifrlash | AES-256-GCM, maydon darajasida (`FieldEncryption`). AAD yozuv ID'siga bog'langan, kalit rotatsiyasi bor |
| Uzatishda shifrlash | Faqat HTTPS (ilova HTTP manzilni rad etadi), HSTS, `cache-control: no-store` |
| Qurilmada | Token Keychain / Android Keystore'da. Tibbiy ma'lumot diskka yozilmaydi |
| Avtomatik chiqish | 10 daqiqa faolsizlikda sessiya yopiladi. JWT 15 daqiqa amal qiladi va faol sessiyada yangilanib turadi |
| Audit | Tibbiy ma'lumotga har bir murojaat qayd etiladi (kim, nima, qachon) |
| AI'ga minimal ma'lumot | Faqat alomatlar matni, yosh, jins va surunkali kasalliklar yuboriladi. Telefon, e-mail, pasport va JShShIR avtomatik yashiriladi |
| Xavfli belgilar | AI'dan mustaqil lokal qoidalar. Apostrofning barcha variantlari, apostrofsiz va kirill yozuvdagi matn ham tekshiriladi |
| Rozilik | 6 ta alohida, versiyalangan band. Tarix o'chirilmaydi. Rozilik bo'lmasa server `451` qaytaradi |
| Sub'ekt huquqlari | `GET /v1/me/export`, `DELETE /v1/me/health-data` |
| OTP | Xeshlangan, 5 daqiqa amal qiladi, 5 ta urinish, IP bo'yicha cheklov |
| To'lov xavfsizligi | Click imzosi (MD5) va Payme Basic auth konstant vaqtda tekshiriladi. Summa serverda olinadi. Karta ma'lumotlari serverga tushmaydi |

## Ishga tushirish

```bash
# Backend (dev rejimida 8 ta demo shifokor yuklanadi, SMS kod logga chiqadi)
cd backend
cp .env.example .env   # qiymatlarni to'ldiring
set -a; source .env; set +a
dart pub get && dart test
dart run bin/server.dart

# Mobil ilova
cd mobile
flutter pub get && flutter test
flutter run --dart-define=MEDLINK_API=http://10.0.2.2:8080       # Android emulyator
flutter run --dart-define=MEDLINK_API=https://api.medlink.uz     # haqiqiy server
```

**Android release:** `android/key.properties.example` dan `key.properties`
yarating (u git'ga qo'shilmaydi), keyin `flutter build appbundle --release`.

**iOS release:** Xcode'da Team tanlang. Apple Developer kabinetida
`merchant.uz.medlink` Merchant ID'ni yarating va App ID uchun Apple Pay
imkoniyatini yoqing. So'ng `flutter build ipa`.

**Matnlar:** `lib/l10n/app_uz.arb` (asosiy), `app_ru.arb`, `app_en.arb`.
O'zgartirgandan keyin `flutter gen-l10n` ni ishga tushiring.

**CI** (`.github/workflows/ci.yml`): backend testlari, `flutter analyze` va
testlar, Android APK + AAB va iOS imzosiz build. Release kalit uchun
repozitoriy secret'lari: `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`,
`ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`. API manzili: `MEDLINK_API`
o'zgaruvchisi.

Webhook manzillarini to'lov kabinetlarida ko'rsating:
- Click Prepare: `POST /payments/click/prepare`, Complete: `POST /payments/click/complete`
- Payme: `POST /payments/payme`

## Ishga chiqarishdan oldin hal qilinishi kerak

Kod texnik asosni beradi. Quyidagilar esa kod bilan yopilmaydi va ishga
chiqarishdan oldin hal qilinishi shart:

1. **Ma'lumotlarni lokalizatsiya qilish (O'RQ-547, 27¹-modda).** O'zbekiston
   fuqarolarining shaxsga doir ma'lumotlari O'zbekiston hududidagi serverlarda
   saqlanishi kerak. Google Cloud'da O'zbekiston regioni yo'q, shuning uchun
   baza mahalliy data-markazda bo'lishi kerak. AI'ga yuboriladigan
   shaxssizlashtirilgan matn uchun alohida rozilik qo'shilgan
   (`crossBorderTransfer`), lekin bu sxema yurist tomonidan tasdiqlanishi kerak.
2. **Med-PaLM 2 ga kirish.** MedLM modellari Google'ning ruxsat ro'yxati orqali
   beriladi va Google ularni bosqichma-bosqich to'xtatishni e'lon qilgan.
   Loyihangiz uchun mavjudligini tekshiring. Kod boshqa modelga tayyor:
   `MEDLINK_MED_MODEL` qiymati `medlm-` bilan boshlanmasa, `generateContent`
   API ishlatiladi (masalan MedGemma yoki Gemini).
3. **HIPAA.** HIPAA AQSh qonuni. Unga moslik faqat kod bilan ta'minlanmaydi:
   Google Cloud bilan BAA (Business Associate Agreement) tuzish, xavflarni
   baholash, ichki siyosatlar va xodimlarni o'qitish kerak.
4. **Google Pay va Apple Pay.** Ular xalqaro ekvayer orqali ishlaydi (kodda
   Stripe). Stripe O'zbekistonda ro'yxatdan o'tgan kompaniyalarga xizmat
   ko'rsatmaydi, Uzcard va Humo esa bu hamyonlarda odatda yo'q. Xorijiy
   yuridik shaxs yoki Visa/Mastercard tokenlarini qabul qiladigan mahalliy
   ekvayer kerak. Apple Pay uchun Merchant ID va Xcode'da entitlement sozlang.
   `assets/pay/*.json` faylidagi `pk_test_REPLACE_ME` ni almashtiring.
5. **Tibbiy buyum sifatida ro'yxatdan o'tkazish.** AI triaj funksiyasi
   ko'p yurisdiksiyalarda tibbiy dasturiy ta'minot (SaMD) hisoblanishi mumkin.
   Ilova natijani "tashxis emas" deb aniq ko'rsatadi, lekin regulyator bilan
   maslahatlashing.
6. **Doimiy saqlash.** Hozircha repozitoriylar xotirada ishlaydi (server faqat
   `MEDLINK_ENV=dev` rejimida ishga tushadi). Prod uchun PostgreSQL, KMS orqali
   kalit boshqaruvi, faqat qo'shiladigan audit jurnali va haqiqiy SMS shlyuzi
   (Eskiz, Play Mobile) kerak.
7. **Rozilik matnlari** (`mobile/lib/l10n/app_*.arb`, `consent*` kalitlari)
   namunaviy, uchala tilda ham. Ularni yurist tekshirishi kerak.
8. **Firebase loyihasi.** Push kodi tayyor, lekin Firebase loyihasi, APNs
   kaliti va yuqoridagi parametrlar berilmaguncha faqat mahalliy eslatmalar
   ishlaydi.
9. **Qurilmada sinash.** APK, AAB va iOS build CI'da muvaffaqiyatli yig'iladi,
   lekin ilova haqiqiy telefonda ishga tushirib ko'rilmagan. Google Pay, Apple
   Pay, Face ID, push-bildirishnomalar va deep link'larni haqiqiy qurilmada
   sinab ko'ring.
