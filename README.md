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

## Imkoniyatlar

**Bemor uchun**
- Telefon raqami + SMS kod orqali kirish.
- Rozilik ekrani: har bir maqsad uchun alohida belgi, hech biri oldindan
  belgilanmagan, majburiylarisiz davom etib bo'lmaydi.
- AI alomatlar tahlili: shoshilinchlik darajasi, ehtimoliy sabablar, xavfli
  belgilar va qaysi mutaxassisga borish kerakligi. Shoshilinch holatda 103
  tugmasi chiqadi.
- Shifokorlar bazasi: mutaxassislik bo'yicha filtr, qidiruv, reyting, narx.
  Faqat moderatsiyadan o'tganlar ko'rinadi.
- Qabulga yozilish (30 daqiqalik slotlar, 15 daqiqalik to'lov broni), bekor
  qilish.
- To'lov: Click, Payme, Google Pay (Android) va Apple Pay (iOS).
- Profil: rozilikni qaytarib olish, ma'lumotlar nusxasini olish, AI tarixini
  o'chirish.

**Shifokor uchun**
- Ariza: F.I.Sh., mutaxassislik, litsenziya raqami, hujjatlar.
- Holat: `pending` → `approved` / `rejected` (sababi bilan) → `suspended`.
- Tasdiqlangandan keyin "Bemorlarim" bo'limi ochiladi.

**Admin uchun**
- Moderatsiya navbati: litsenziya va hujjatlarni ko'rish, tasdiqlash yoki rad
  etish. Har bir qaror audit jurnaliga yoziladi.

## Xavfsizlik va maxfiylik

| Talab | Amalga oshirilishi |
|---|---|
| Saqlashda shifrlash | AES-256-GCM, maydon darajasida (`FieldEncryption`). AAD yozuv ID'siga bog'langan, kalit rotatsiyasi bor |
| Uzatishda shifrlash | Faqat HTTPS (ilova HTTP manzilni rad etadi), HSTS, `cache-control: no-store` |
| Qurilmada | Token Keychain / Android Keystore'da. Tibbiy ma'lumot diskka yozilmaydi. `FLAG_SECURE`, zaxira nusxa o'chirilgan |
| Avtomatik chiqish | 10 daqiqa faolsizlikda sessiya yopiladi, JWT 15 daqiqa amal qiladi |
| Audit | Tibbiy ma'lumotga har bir murojaat qayd etiladi (kim, nima, qachon) |
| AI'ga minimal ma'lumot | Faqat alomatlar matni, yosh va jins yuboriladi. Telefon, e-mail, pasport va JShShIR avtomatik yashiriladi |
| Rozilik | 6 ta alohida, versiyalangan band. Tarix o'chirilmaydi. Rozilik bo'lmasa server `451` qaytaradi |
| Sub'ekt huquqlari | `GET /v1/me/export`, `DELETE /v1/me/health-data` |
| OTP | Xeshlangan, 5 daqiqa amal qiladi, 5 ta urinish, IP bo'yicha cheklov |
| To'lov xavfsizligi | Click imzosi (MD5) va Payme Basic auth konstant vaqtda tekshiriladi. Summa serverda olinadi. Karta ma'lumotlari serverga tushmaydi |

## Ishga tushirish

```bash
# Backend
cd backend
cp .env.example .env   # qiymatlarni to'ldiring
set -a; source .env; set +a
dart pub get && dart test
dart run bin/server.dart

# Mobil ilova
cd mobile
flutter pub get && flutter test
flutter run --dart-define=MEDLINK_API=https://api.medlink.uz
```

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
7. **Rozilik matnlari** (`mobile/lib/features/consent/consent_texts.dart`)
   namunaviy. Ularni yurist tekshirishi kerak.
