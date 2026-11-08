<p align="center"><img src="mobile/assets/brand/medlink_logo.jpg" width="420" alt="MedLink"></p>

# MedLink

Sun'iy intellektga ega mobil tibbiy platforma: bemorlar alomatlarini AI orqali
tahlil qiladi, tekshirilgan shifokorni topadi, qabulga yoziladi va to'laydi.

| Qism | Texnologiya | Papka |
|---|---|---|
| Mobil ilova (Android, iOS) | Flutter 3.47 / Dart 3.13 | [`mobile/`](mobile) |
| API server | Dart + shelf, PostgreSQL 16 | [`backend/`](backend) |
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
- **Onlayn konsultatsiya:** qabul turini tanlash (klinikada yoki onlayn),
  qabul vaqtida video qo'ng'iroq (LiveKit/WebRTC, shifrlangan, yozib
  olinmaydi), shifokor bilan chat (qabul tasdiqlangandan to xulosadan 7 kun
  keyingacha), shifokor xulosasi va retsept (tashxis, tavsiyalar, dorilar,
  qayta ko'rik muddati).
- Qabulga yozilish: 14 kunlik kalendar, ertalab va tushdan keyingi slotlar
  (har doim Toshkent vaqtida), 15 daqiqalik to'lov broni taymer bilan.
- To'lov: Click, Payme (ilovaga deep link orqali qaytadi), Google Pay
  (Android) va Apple Pay (iOS).
- Pul qaytarish siyosati bekor qilishdan oldin ko'rsatiladi: qabulgacha 24
  soatdan ko'p bo'lsa, to'liq qaytariladi; shifokor bekor qilsa, har doim
  qaytariladi. Google Pay va Apple Pay to'lovlari Stripe orqali darhol
  avtomatik qaytariladi; Click va Payme — admin navbati orqali.
- Qabul vaqtini ko'chirish: shu shifokorning boshqa bo'sh vaqtiga, qabulgacha
  kamida 24 soat qolganda va ko'pi bilan 2 marta. To'lov saqlanadi,
  shifokorga push boradi.
- Qabullar: kelgusi va o'tgan qabullar, tafsilotlar, bekor qilish, yakunlangan
  qabuldan keyin shifokorni baholash.
- Bildirishnomalar: to'lov tasdiqlandi, qabul bekor qilindi, qabuldan 24 soat
  va 1 soat oldin eslatma. Ruxsat birinchi to'lovdan keyin yoki sozlamalarda
  so'raladi. Bildirishnoma bosilsa qabul sahifasi ochiladi (biometrik qulf
  ochilgandan keyin).
- Sozlamalar: til (o'zbek, rus, ingliz), mavzu (yorug', qorong'i, tizim
  bo'yicha), Face ID / barmoq izi bilan qulflash.
- Maxfiylik: rozilikni qaytarib olish, ma'lumotlar nusxasini olish, tibbiy
  ma'lumotlarni o'chirish, hisobni butunlay o'chirish (App Store va Google
  Play talabi). Maxfiylik siyosati va foydalanish shartlari ilovada va
  serverda (`/legal/privacy`, `/legal/terms`, 3 tilda) — shu havolani do'kon
  sahifasiga qo'ying.

**Shifokor uchun**
- Ariza: F.I.Sh., mutaxassislik, litsenziya, hujjatlar.
- Holat: `pending` → `approved` / `rejected` (sababi bilan) → `suspended`.
  Rad etilsa, qayta ariza topshirish mumkin.
- Ish jadvali: ish kunlari, soatlari, klinika va onlayn qabul narxlari.
- Onlayn qabul: video qo'ng'iroq, chat, qabul oldidan bemorning tibbiy
  profili va AI tahlilini ko'rish (audit bilan), xulosa va retsept yozish.
- Push: yangi bemor yozildi, qabul bekor qilindi, qabul eslatmasi, ariza
  natijasi.
- Tasdiqlangandan keyin "Bemorlarim" bo'limi ochiladi (rol ilova qayta
  ochilganda avtomatik yangilanadi). Qabulni yakunlash.

**Admin uchun**
- Statistika: foydalanuvchilar, faol shifokorlar, kutilayotgan arizalar,
  bugungi qabullar, 30 kunlik tushum, onlayn ulushi, qabullar holati.
- Pul qaytarish navbati. Admin pulni Click yoki Payme kabinetida qaytaradi va
  ilovada "qaytarildi" deb belgilaydi, bemorga push yuboriladi. Payme
  `CancelTransaction` kelsa, qaytarish avtomatik belgilanadi.
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

## Onlayn konsultatsiya

| | |
|---|---|
| Video | LiveKit (open-source WebRTC SFU). Serverni O'zbekistondagi data-markazga o'rnatish mumkin, bu ma'lumotlarni lokalizatsiya qilish talabiga mos keladi. Media DTLS-SRTP bilan shifrlanadi, yozib olish o'chirilgan |
| Kirish | Token faqat shu qabulning bemori va shifokoriga beriladi. Qabul onlayn va to'langan bo'lishi kerak, vaqt oralig'i qabuldan 10 daqiqa oldindan 60 daqiqa keyingacha. Xona nomi va ko'rinadigan ismda shaxsiy ma'lumot yo'q |
| Rasmlar | Chatda tahlil natijasi yoki retsept rasmi (JPEG/PNG, 5 MB gacha). Turi fayl imzosi bo'yicha tekshiriladi. Rasm shifrlanib, PostgreSQL'da alohida jadvalda saqlanadi va xotiraga yuklanmaydi. Telefonda qayta kodlanadi, bu joylashuv (EXIF) ma'lumotini olib tashlaydi. Har bir ko'rish audit jurnaliga yoziladi |
| Chat | Xabarlar AES-256-GCM bilan shifrlanadi. Faqat ishtirokchilar ko'radi. Push'da matn ko'rsatilmaydi ("Yangi xabar"). Xabar yuborish daqiqasiga 30 ta bilan cheklangan |
| Real vaqt | Yangi xabarlar WebSocket (`/v1/appointments/{id}/live`) orqali darhol keladi. Token sarlavhada, ulanish 15 daqiqada yopiladi va yangi token bilan qayta ochiladi. Uzilsa, ilova 4 soniyalik so'rovga o'tadi va 2–30 soniyada qayta ulanadi |
| Xulosa | Tashxis, tavsiyalar, retsept (dori, doza, tartib, muddat), qayta ko'rik. Shifrlangan holda saqlanadi, bemorga push yuboriladi, qabul yakunlanadi |
| Shifokor uchun | Qabul oldidan bemorning tibbiy profili (allergiyalar alohida ajratilgan) va AI tahlili. Har bir ko'rish audit jurnaliga yoziladi |

Backend sozlamalari: `LIVEKIT_URL`, `LIVEKIT_API_KEY`, `LIVEKIT_API_SECRET`.
Ular berilmasa, video tugmasi o'rnida "video ulanmagan, chatdan foydalaning"
xabari chiqadi. LiveKit'ni o'rnatish: https://docs.livekit.io/home/self-hosting/

**SMS:** `ESKIZ_EMAIL` va `ESKIZ_PASSWORD` berilsa, OTP Eskiz.uz orqali
yuboriladi. SMS shablonini Eskiz kabinetida oldindan tasdiqlatish kerak.

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
| Sub'ekt huquqlari | `GET /v1/me/export`, `DELETE /v1/me/health-data`, `DELETE /v1/me` (hisobni o'chirish: telefon raqami, tibbiy profil, AI tahlillari va qurilmalar o'chadi, kelgusi qabullar bekor qilinib pul qaytariladi; to'lovlar, xulosalar va audit qonun bo'yicha raqamsiz saqlanadi) |
| App Store | `ios/Runner/PrivacyInfo.xcprivacy`: kuzatuv yo'q, yig'iladigan ma'lumotlar ro'yxati. App Store Connect'dagi "App Privacy" anketasini shu bilan bir xil to'ldiring |
| OTP | Xeshlangan, 5 daqiqa amal qiladi, 5 ta urinish, IP bo'yicha cheklov |
| To'lov xavfsizligi | Click imzosi (MD5) va Payme Basic auth konstant vaqtda tekshiriladi. Summa serverda olinadi. Karta ma'lumotlari serverga tushmaydi |

## PostgreSQL

| | |
|---|---|
| Ulash | `DATABASE_URL=postgresql://user:pass@host:5432/medlink?sslmode=require`. Prod'da majburiy. SSL standart holatda talab qilinadi |
| Sxema | `backend/lib/src/persistence/schema.dart`. Migratsiyalar ishga tushganda avtomatik, tartib bilan, har biri alohida tranzaksiyada qo'llanadi (`schema_migrations`) |
| Jadvallar | `users`, `consents` (faqat qo'shiladi), `medical_profiles`, `triage_results`, `doctors`, `appointments`, `payment_orders`, `click_prepared`, `payme_transactions`, `chat_messages`, `devices`, `audit_log` (faqat qo'shiladi). Foreign key va indekslar bor |
| Shifrlash | Tibbiy maydonlar ilova darajasida AES-256-GCM bilan shifrlanib keladi, bazada ochiq matn yo'q (integratsion test tekshiradi) |
| Yozish | Har bir HTTP so'rovdagi o'zgarishlar javobdan **oldin** bitta tranzaksiyada yoziladi. Masalan, Click/Payme "muvaffaqiyatli" javobini faqat yozuv bazaga tushgandan keyin oladi. Baza ishlamasa, mijoz `503` oladi, o'zgarishlar yo'qolmaydi va qayta urinib yoziladi |
| O'qish | Ishga tushganda butun holat bazadan xotiraga yuklanadi, so'rovlar xotiradan tez javob beradi |
| Cheklov | Bir vaqtda faqat **bitta** server nusxasi ishlaydi. Bu `pg_try_advisory_lock` bilan kafolatlanadi: ikkinchi nusxa ishga tushmaydi, shuning uchun ma'lumotlar ikkiga bo'linib ketmaydi. Cloud Run'da `max-instances=1` qo'ying |
| To'xtash | SIGTERM kelganda qolgan o'zgarishlar yoziladi va ulanishlar yopiladi |
| Testlar | `test/postgres_test.dart`: to'liq oqim, keyin "qayta ishga tushirish" va holatni tiklash; advisory lock; migratsiyalarni qayta qo'llash; shifrlash; o'chirish. CI'da PostgreSQL 16 xizmati bilan ishlaydi |

Lokal: `docker compose up --build` (PostgreSQL + API). Yoki mavjud bazaga
qarshi: `TEST_DATABASE_URL=postgresql://...?sslmode=disable dart test`.

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
6. **Operator rekvizitlari.** Maxfiylik siyosatida operator nomi va aloqa
   ma'lumotlari `MEDLINK_OPERATOR_NAME`, `MEDLINK_OPERATOR_ADDRESS`,
   `MEDLINK_CONTACT_EMAIL`, `MEDLINK_CONTACT_PHONE` orqali beriladi. Siyosat va
   shartlar matni (`backend/lib/src/legal/legal.dart`) tizim qanday ishlashiga
   mos yozilgan, lekin yurist tekshirishi kerak: saqlash muddatlari,
   vakolatli organ nomi.
7. **Click qaytarishlari.** Click Merchant API'da qaytarish (reversal)
   alohida shartnoma va kalitlar bilan ochiladi; hozir Click va Payme
   qaytarishlari kabinet orqali bajarilib, ilovada belgilanadi.
8. **Bitta server nusxasi.** PostgreSQL ulangan, lekin hozirgi arxitektura
   bitta yozuvchi nusxani talab qiladi (ikkinchisi ishga tushmaydi).
   Gorizontal masshtablash uchun servislarni "har so'rovda bazadan o'qish"
   rejimiga o'tkazish kerak (pastdagi "PostgreSQL" bo'limiga qarang).
   Shifrlash kalitlarini KMS / Secret Manager'da saqlang.
9. **Rozilik matnlari** (`mobile/lib/l10n/app_*.arb`, `consent*` kalitlari)
   namunaviy, uchala tilda ham. Ularni yurist tekshirishi kerak.
10. **Firebase loyihasi.** Push kodi tayyor, lekin Firebase loyihasi, APNs
   kaliti va yuqoridagi parametrlar berilmaguncha faqat mahalliy eslatmalar
   ishlaydi.
11. **Qurilmada sinash.** APK, AAB va iOS build CI'da muvaffaqiyatli yig'iladi,
   lekin ilova haqiqiy telefonda ishga tushirib ko'rilmagan. Google Pay, Apple
   Pay, Face ID, push-bildirishnomalar, video qo'ng'iroq va deep link'larni
   haqiqiy qurilmada sinab ko'ring.
