import 'package:shelf/shelf.dart';

import '../consent/consent.dart';

/// Maxfiylik siyosati va foydalanish shartlari (uz/ru/en).
///
/// App Store va Google Play ilova sahifasida ochiq havola talab qiladi:
/// `https://<api>/legal/privacy?lang=uz`, `.../legal/terms?lang=ru`.
/// Ilova ham shu sahifalarni ochadi — matn bitta joyda.
///
/// MUHIM: bu matnlar texnik jihatdan tizim qanday ishlashiga mos yozilgan,
/// lekin ishga chiqarishdan oldin yurist tomonidan tekshirilishi shart
/// (operator rekvizitlari, saqlash muddatlari, vakolatli organ).
class LegalInfo {
  const LegalInfo({
    this.operatorName = 'MedLink',
    this.operatorAddress = '',
    this.contactEmail = '',
    this.contactPhone = '',
  });

  final String operatorName;
  final String operatorAddress;
  final String contactEmail;
  final String contactPhone;

  String get _contacts => [
    if (operatorAddress.isNotEmpty) operatorAddress,
    if (contactEmail.isNotEmpty) contactEmail,
    if (contactPhone.isNotEmpty) contactPhone,
  ].join(' · ');
}

typedef _Section = (String title, List<String> paragraphs);

class LegalPages {
  LegalPages(this.info);
  final LegalInfo info;

  static const languages = ['uz', 'ru', 'en'];

  String get privacyVersion =>
      currentConsentVersions[ConsentScope.personalData]!;
  String get termsVersion => currentConsentVersions[ConsentScope.terms]!;

  Response privacy(Request req) => _page(req, 'privacy');
  Response terms(Request req) => _page(req, 'terms');

  Response _page(Request req, String kind) {
    var lang = req.url.queryParameters['lang'] ?? 'uz';
    if (!languages.contains(lang)) lang = 'uz';
    final privacy = kind == 'privacy';
    final title = privacy ? _privacyTitle[lang]! : _termsTitle[lang]!;
    final sections = privacy ? _privacy(lang) : _terms(lang);
    final version = privacy ? privacyVersion : termsVersion;
    return Response.ok(
      _html(lang, kind, title, version, sections),
      headers: {
        'content-type': 'text/html; charset=utf-8',
        // Ommaviy hujjat — keshlash mumkin (no-store faqat API uchun).
        'cache-control': 'public, max-age=3600',
        'content-security-policy':
            "default-src 'none'; style-src 'unsafe-inline'",
      },
    );
  }

  static const _privacyTitle = {
    'uz': 'Maxfiylik siyosati',
    'ru': 'Политика конфиденциальности',
    'en': 'Privacy Policy',
  };
  static const _termsTitle = {
    'uz': 'Foydalanish shartlari',
    'ru': 'Условия использования',
    'en': 'Terms of Use',
  };
  static const _versionLabel = {
    'uz': 'Tahrir',
    'ru': 'Редакция от',
    'en': 'Version',
  };

  static String _esc(String s) => s
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;');

  String _html(
    String lang,
    String kind,
    String title,
    String version,
    List<_Section> sections,
  ) {
    final b = StringBuffer()
      ..write('<!doctype html><html lang="$lang"><head><meta charset="utf-8">')
      ..write(
        '<meta name="viewport" content="width=device-width,initial-scale=1">',
      )
      ..write('<title>${_esc(title)} — MedLink</title><style>')
      ..write(
        ':root{color-scheme:light dark;--fg:#0f172a;--muted:#475569;'
        '--bg:#fff;--accent:#055DBE;--line:#e2e8f0}'
        '@media(prefers-color-scheme:dark){:root{--fg:#e2e8f0;'
        '--muted:#94a3b8;--bg:#0b1220;--accent:#5aa2f0;--line:#1e293b}}'
        'body{margin:0;background:var(--bg);color:var(--fg);'
        'font:16px/1.6 system-ui,-apple-system,"Segoe UI",Roboto,sans-serif}'
        'main{max-width:720px;margin:0 auto;padding:24px 16px 48px}'
        'h1{font-size:26px;line-height:1.25;margin:8px 0 4px}'
        'h2{font-size:18px;margin:28px 0 8px}'
        'p{margin:0 0 10px}.muted{color:var(--muted);font-size:14px}'
        'nav{display:flex;gap:12px;font-size:14px}'
        'nav a{color:var(--accent);text-decoration:none}'
        'nav a[aria-current]{font-weight:700;text-decoration:underline}'
        'hr{border:0;border-top:1px solid var(--line);margin:24px 0}',
      )
      ..write('</style></head><body><main><nav aria-label="Language">');
    for (final l in languages) {
      b.write(
        '<a href="/legal/$kind?lang=$l"'
        '${l == lang ? ' aria-current="page"' : ''}>${l.toUpperCase()}</a>',
      );
    }
    b
      ..write('</nav><h1>${_esc(title)}</h1>')
      ..write('<p class="muted">MedLink · ${_versionLabel[lang]} $version</p>');
    for (final (h, ps) in sections) {
      b.write('<h2>${_esc(h)}</h2>');
      for (final p in ps) {
        b.write('<p>${_esc(p)}</p>');
      }
    }
    b.write('<hr><p class="muted">${_esc(info.operatorName)}');
    if (info._contacts.isNotEmpty) b.write(' · ${_esc(info._contacts)}');
    b.write('</p></main></body></html>');
    return b.toString();
  }

  String _contactLine(String lang) {
    final c = info._contacts;
    if (c.isEmpty) {
      return switch (lang) {
        'ru' => 'Связаться с нами можно через раздел «Профиль» в приложении.',
        'en' => 'You can contact us from the Profile section of the app.',
        _ =>
          "Biz bilan ilovadagi «Profil» bo'limi orqali bog'lanishingiz mumkin.",
      };
    }
    return switch (lang) {
      'ru' => 'Контакты: $c.',
      'en' => 'Contact: $c.',
      _ => 'Aloqa: $c.',
    };
  }

  // ---------------------------------------------------------------------------
  // Maxfiylik siyosati
  // ---------------------------------------------------------------------------
  List<_Section> _privacy(String lang) {
    final op = info.operatorName;
    return switch (lang) {
      'ru' => [
        (
          '1. Кто обрабатывает ваши данные',
          [
            'Оператор персональных данных — $op («мы»). Политика описывает, '
                'какие данные собирает приложение MedLink, зачем, где они '
                'хранятся и как вы можете ими управлять.',
          ],
        ),
        (
          '2. Какие данные мы собираем',
          [
            'Номер телефона — для входа по SMS-коду. В базе он хранится в '
                'зашифрованном виде.',
            'Медицинский профиль, который вы заполняете сами: ФИО, дата '
                'рождения, пол, группа крови, рост и вес, аллергии, '
                'хронические заболевания, принимаемые лекарства.',
            'Описание симптомов и результаты AI-анализа.',
            'Записи на приём, сообщения и фотографии в чате с врачом, '
                'заключения и рецепты врача, ваши отзывы.',
            'Сведения об оплате: сумма, способ и статус. Номер карты к нам '
                'не попадает — его обрабатывает платёжная система.',
            'Идентификатор устройства для push-уведомлений.',
            'Журнал безопасности: кто и когда открывал медицинские данные.',
          ],
        ),
        (
          '3. Цели и основания обработки',
          [
            'Мы обрабатываем данные только с вашего явного согласия, '
                'отдельно по каждой цели: условия использования, '
                'персональные данные, данные о здоровье, AI-анализ, передача '
                'за рубеж, рассылки. Обязательны только первые три — без них '
                'сервис не может работать.',
            'Данные используются для записи к врачу, проведения консультации, '
                'оплаты, напоминаний и защиты аккаунта. Мы не продаём данные '
                'и не используем медицинские сведения для рекламы.',
          ],
        ),
        (
          '4. AI-анализ симптомов',
          [
            'Только при отдельном согласии описание симптомов отправляется в '
                'медицинскую модель Google Cloud Vertex AI. Перед отправкой '
                'из текста удаляются имя, телефон и другие идентификаторы. '
                'Результат — справочная информация, а не диагноз.',
          ],
        ),
        (
          '5. Кому передаются данные',
          [
            'Выбранному вами врачу — только по вашей записи и только после '
                'оплаты. Каждый просмотр записывается в журнал.',
            'Поставщикам услуг в объёме, необходимом для их работы: Click, '
                'Payme и Stripe (оплата), Eskiz (SMS), Google Firebase и '
                'Apple (уведомления — без медицинского содержания), LiveKit '
                '(видеосвязь). Видео не записывается.',
            'Государственным органам — только в случаях, прямо '
                'предусмотренных законом.',
          ],
        ),
        (
          '6. Где и сколько хранятся данные',
          [
            'Персональные данные граждан Узбекистана хранятся на серверах на '
                'территории Республики Узбекистан в соответствии с Законом '
                '«О персональных данных» (ЗРУ-547).',
            'Данные хранятся, пока у вас есть аккаунт. После удаления '
                'аккаунта медицинский профиль, AI-анализы, номер телефона и '
                'устройства удаляются сразу. Сведения об оплатах, заключения '
                'врачей и журнал безопасности хранятся в сроки, установленные '
                'законодательством, без возможности установить вашу личность '
                'по номеру телефона.',
          ],
        ),
        (
          '7. Как мы защищаем данные',
          [
            'Медицинские сведения, сообщения и файлы шифруются алгоритмом '
                'AES-256-GCM, соединение — по TLS. Доступ к записи есть '
                'только у её участников. В приложении — блокировка по Face '
                'ID или отпечатку пальца и автоматический выход при '
                'бездействии.',
          ],
        ),
        (
          '8. Ваши права',
          [
            'В приложении в любой момент можно: посмотреть и выгрузить свои '
                'данные, исправить профиль, отозвать любое согласие, удалить '
                'медицинские данные или весь аккаунт (Профиль → '
                'Конфиденциальность).',
            'Вы можете обратиться к нам по контактам ниже или подать жалобу '
                'в уполномоченный государственный орган по защите '
                'персональных данных.',
          ],
        ),
        (
          '9. Дети',
          [
            'Пользоваться сервисом могут лица старше 18 лет. За ребёнка '
                'аккаунт ведёт родитель или законный представитель.',
          ],
        ),
        (
          '10. Экстренные случаи',
          ['MedLink не заменяет скорую помощь. При угрозе жизни звоните 103.'],
        ),
        (
          '11. Изменения политики',
          [
            'При существенных изменениях мы обновим дату редакции и снова '
                'попросим ваше согласие в приложении.',
            _contactLine(lang),
          ],
        ),
      ],
      'en' => [
        (
          '1. Who processes your data',
          [
            'The data controller is $op ("we"). This policy explains what '
                'data the MedLink app collects, why, where it is stored and '
                'how you control it.',
          ],
        ),
        (
          '2. What we collect',
          [
            'Your phone number, to sign in with an SMS code. It is stored '
                'encrypted.',
            'The medical profile you fill in: full name, date of birth, sex, '
                'blood type, height and weight, allergies, chronic '
                'conditions, current medications.',
            'Symptom descriptions and AI analysis results.',
            'Appointments, chat messages and photos exchanged with your '
                "doctor, the doctor's conclusions and prescriptions, and your "
                'reviews.',
            'Payment details: amount, method and status. Your card number '
                'never reaches us; the payment provider handles it.',
            'A device identifier for push notifications.',
            'A security log of who opened medical data and when.',
          ],
        ),
        (
          '3. Purposes and legal basis',
          [
            'We process data only with your explicit consent, given '
                'separately for each purpose: terms of use, personal data, '
                'health data, AI analysis, cross-border transfer and '
                'marketing. Only the first three are required for the '
                'service to work.',
            'Data is used to book visits, hold consultations, take payments, '
                'send reminders and protect your account. We never sell '
                'data or use health information for advertising.',
          ],
        ),
        (
          '4. AI symptom analysis',
          [
            'Only with separate consent, your symptom description is sent to '
                'a medical model on Google Cloud Vertex AI. Names, phone '
                'numbers and other identifiers are removed first. The result '
                'is information, not a diagnosis.',
          ],
        ),
        (
          '5. Who receives data',
          [
            'The doctor you choose: only for your appointment and only after '
                'payment. Every view is logged.',
            'Service providers, only as needed for their function: Click, '
                'Payme and Stripe (payments), Eskiz (SMS), Google Firebase '
                'and Apple (notifications, with no medical content), LiveKit '
                '(video). Video is never recorded.',
            'Public authorities, only where the law expressly requires it.',
          ],
        ),
        (
          '6. Where and how long data is stored',
          [
            'Personal data of citizens of Uzbekistan is stored on servers '
                'located in the Republic of Uzbekistan, as required by the '
                'Law on Personal Data (ZRU-547).',
            'Data is kept while you have an account. When you delete your '
                'account, your medical profile, AI analyses, phone number and '
                "devices are deleted immediately. Payment records, doctors' "
                'conclusions and the security log are kept for the periods '
                'required by law, without your phone number.',
          ],
        ),
        (
          '7. How we protect data',
          [
            'Medical data, messages and files are encrypted with AES-256-GCM '
                'and sent over TLS. Only the participants of an appointment '
                'can access it. The app supports Face ID or fingerprint lock '
                'and signs you out after inactivity.',
          ],
        ),
        (
          '8. Your rights',
          [
            'At any time in the app you can view and export your data, '
                'correct your profile, withdraw any consent, and delete your '
                'health data or your whole account (Profile → Privacy).',
            'You can contact us using the details below or complain to the '
                'competent authority for personal data protection.',
          ],
        ),
        (
          '9. Children',
          [
            'The service is for people aged 18 and over. A parent or legal '
                'guardian manages the account on behalf of a child.',
          ],
        ),
        (
          '10. Emergencies',
          [
            'MedLink does not replace emergency services. If a life is at '
                'risk, call 103.',
          ],
        ),
        (
          '11. Changes',
          [
            'If we make material changes, we will update the version date '
                'and ask for your consent again in the app.',
            _contactLine(lang),
          ],
        ),
      ],
      _ => [
        (
          "1. Ma'lumotlaringizni kim qayta ishlaydi",
          [
            "Shaxsga doir ma'lumotlar operatori — $op («biz»). Ushbu "
                "siyosat MedLink ilovasi qanday ma'lumot yig'ishini, nima "
                "uchun, qayerda saqlashini va siz ularni qanday "
                'boshqarishingizni tushuntiradi.',
          ],
        ),
        (
          "2. Qanday ma'lumotlar yig'iladi",
          [
            'Telefon raqami — SMS kod orqali kirish uchun. Bazada shifrlangan '
                'holda saqlanadi.',
            "O'zingiz to'ldiradigan tibbiy profil: F.I.Sh., tug'ilgan sana, "
                "jins, qon guruhi, bo'y va vazn, allergiyalar, surunkali "
                "kasalliklar, qabul qilayotgan dorilar.",
            'Alomatlar tavsifi va AI tahlili natijalari.',
            'Qabullar, shifokor bilan chatdagi xabarlar va rasmlar, shifokor '
                'xulosalari va retseptlar, sharhlaringiz.',
            "To'lov ma'lumotlari: summa, usul va holat. Karta raqami bizga "
                "tushmaydi — uni to'lov tizimi qayta ishlaydi.",
            'Push-bildirishnomalar uchun qurilma identifikatori.',
            "Xavfsizlik jurnali: tibbiy ma'lumotlarni kim va qachon ochgani.",
          ],
        ),
        (
          '3. Maqsadlar va asos',
          [
            "Ma'lumotlar faqat sizning aniq roziligingiz bilan, har bir maqsad "
                "uchun alohida qayta ishlanadi: foydalanish shartlari, shaxsga "
                "doir ma'lumotlar, sog'liq haqidagi ma'lumotlar, AI tahlili, "
                "chet elga uzatish, xabarnomalar. Faqat dastlabki uchtasi "
                'majburiy — ularsiz xizmat ishlay olmaydi.',
            "Ma'lumotlar shifokorga yozilish, konsultatsiya o'tkazish, to'lov, "
                'eslatmalar va hisobni himoya qilish uchun ishlatiladi. Biz '
                "ma'lumot sotmaymiz va tibbiy ma'lumotdan reklama uchun "
                'foydalanmaymiz.',
          ],
        ),
        (
          '4. Alomatlarni AI orqali tahlil qilish',
          [
            'Faqat alohida rozilik berilsa, alomatlar tavsifi Google Cloud '
                'Vertex AI tibbiy modeliga yuboriladi. Yuborishdan oldin '
                'matndan ism, telefon va boshqa identifikatorlar olib '
                "tashlanadi. Natija — tashxis emas, ma'lumot uchun.",
          ],
        ),
        (
          "5. Ma'lumotlar kimga beriladi",
          [
            "Siz tanlagan shifokorga — faqat sizning qabulingiz bo'yicha va "
                "to'lovdan keyin. Har bir ko'rish jurnalga yoziladi.",
            'Xizmat yetkazib beruvchilarga — faqat ularning ishi uchun zarur '
                "hajmda: Click, Payme va Stripe (to'lov), Eskiz (SMS), "
                'Google Firebase va Apple (bildirishnomalar — tibbiy '
                "mazmunsiz), LiveKit (video aloqa). Video yozib olinmaydi.",
            "Davlat organlariga — faqat qonunda to'g'ridan-to'g'ri nazarda "
                'tutilgan hollarda.',
          ],
        ),
        (
          "6. Ma'lumotlar qayerda va qancha saqlanadi",
          [
            "O'zbekiston fuqarolarining shaxsga doir ma'lumotlari «Shaxsga "
                "doir ma'lumotlar to'g'risida»gi Qonun (O'RQ-547) talabiga "
                "ko'ra O'zbekiston Respublikasi hududidagi serverlarda "
                'saqlanadi.',
            "Ma'lumotlar hisobingiz mavjud bo'lguncha saqlanadi. Hisob "
                "o'chirilganda tibbiy profil, AI tahlillari, telefon raqami "
                "va qurilmalar darhol o'chiriladi. To'lov yozuvlari, shifokor "
                'xulosalari va xavfsizlik jurnali qonunda belgilangan '
                "muddatlarda, telefon raqamingizsiz saqlanadi.",
          ],
        ),
        (
          '7. Himoya choralari',
          [
            "Tibbiy ma'lumotlar, xabarlar va fayllar AES-256-GCM bilan "
                'shifrlanadi, aloqa TLS orqali. Qabulga faqat uning '
                "ishtirokchilari kira oladi. Ilovada Face ID yoki barmoq izi "
                'bilan qulf va faolsizlikda avtomatik chiqish bor.',
          ],
        ),
        (
          '8. Huquqlaringiz',
          [
            "Ilovada istalgan vaqtda: ma'lumotlaringizni ko'rish va yuklab "
                "olish, profilni tuzatish, istalgan rozilikni qaytarib olish, "
                "tibbiy ma'lumotlarni yoki butun hisobni o'chirish mumkin "
                "(Profil → Maxfiylik).",
            "Quyidagi kontaktlar orqali bizga yoki shaxsga doir ma'lumotlarni "
                'himoya qilish bo\'yicha vakolatli davlat organiga shikoyat '
                'bilan murojaat qilishingiz mumkin.',
          ],
        ),
        (
          '9. Bolalar',
          [
            "Xizmatdan 18 yoshdan oshganlar foydalanadi. Bola uchun hisobni "
                'ota-ona yoki qonuniy vakil yuritadi.',
          ],
        ),
        (
          '10. Shoshilinch holatlar',
          [
            "MedLink tez yordam o'rnini bosmaydi. Hayotga xavf bo'lsa, 103 "
                "raqamiga qo'ng'iroq qiling.",
          ],
        ),
        (
          "11. Siyosatdagi o'zgarishlar",
          [
            "Muhim o'zgarishlar bo'lsa, tahrir sanasini yangilaymiz va "
                "ilovada roziligingizni qayta so'raymiz.",
            _contactLine(lang),
          ],
        ),
      ],
    };
  }

  // ---------------------------------------------------------------------------
  // Foydalanish shartlari
  // ---------------------------------------------------------------------------
  List<_Section> _terms(String lang) => switch (lang) {
    'ru' => [
      (
        '1. Сервис',
        [
          'MedLink — платформа для записи к врачам, онлайн-консультаций и '
              'справочного AI-анализа симптомов. Врачи оказывают услуги '
              'самостоятельно и несут профессиональную ответственность за '
              'свои рекомендации.',
          'AI-анализ не является диагнозом и не заменяет осмотр врача.',
        ],
      ),
      (
        '2. Экстренные случаи',
        [
          'Сервис не предназначен для экстренной помощи. При угрозе жизни '
              'звоните 103.',
        ],
      ),
      (
        '3. Аккаунт',
        [
          'Для входа нужен номер телефона Узбекистана. Вы отвечаете за '
              'достоверность данных профиля и за доступ к своему телефону. '
              'Пользоваться сервисом могут лица старше 18 лет.',
        ],
      ),
      (
        '4. Врачи',
        [
          'Каждый врач проходит модерацию: мы проверяем лицензию и '
              'документы перед публикацией профиля. Врач обязан соблюдать '
              'врачебную тайну и законодательство о здравоохранении.',
        ],
      ),
      (
        '5. Запись, оплата и отмена',
        [
          'Время приёма резервируется на 15 минут до оплаты. Оплата — через '
              'Click, Payme, Google Pay или Apple Pay.',
          'Если врач отменяет приём, деньги возвращаются полностью. Если '
              'пациент отменяет приём не позднее чем за 24 часа, деньги '
              'возвращаются полностью; при более поздней отмене — не '
              'возвращаются.',
          'Перенести приём на другое свободное время можно не позднее чем за '
              '24 часа и не более двух раз.',
          'Возврат на Google Pay и Apple Pay выполняется автоматически, на '
              'Click и Payme — администратором. Срок зачисления зависит от '
              'банка.',
        ],
      ),
      (
        '6. Онлайн-консультации',
        [
          'Видеосвязь доступна за 10 минут до начала приёма. Видео не '
              'записывается. Чат с врачом открыт с подтверждения приёма до '
              '7 дней после заключения.',
          'Для консультации нужны стабильный интернет, камера и микрофон.',
        ],
      ),
      (
        '7. Запрещено',
        [
          'Указывать чужие или ложные данные, выдавать себя за врача, '
              'оскорблять участников, отправлять в чат материалы, не '
              'относящиеся к лечению, и пытаться получить доступ к чужим '
              'данным.',
        ],
      ),
      (
        '8. Ответственность',
        [
          'Мы обеспечиваем работу платформы, но не отвечаем за медицинские '
              'решения врачей и за последствия самолечения по результатам '
              'AI-анализа.',
        ],
      ),
      (
        '9. Удаление аккаунта',
        [
          'Аккаунт можно удалить в приложении: Профиль → Конфиденциальность → '
              'Удалить аккаунт. Будущие приёмы отменяются по правилам пункта '
              '5.',
        ],
      ),
      (
        '10. Применимое право',
        [
          'К условиям применяется законодательство Республики Узбекистан.',
          'При изменении условий мы обновим дату редакции и снова попросим '
              'согласие.',
          _contactLine(lang),
        ],
      ),
    ],
    'en' => [
      (
        '1. The service',
        [
          'MedLink is a platform for booking doctors, online consultations '
              'and informational AI symptom analysis. Doctors provide their '
              'services independently and are professionally responsible '
              'for their advice.',
          'AI analysis is not a diagnosis and does not replace a medical '
              'examination.',
        ],
      ),
      (
        '2. Emergencies',
        [
          'The service is not for emergencies. If a life is at risk, call '
              '103.',
        ],
      ),
      (
        '3. Your account',
        [
          'You sign in with an Uzbek phone number. You are responsible for '
              'the accuracy of your profile and for access to your phone. '
              'The service is for people aged 18 and over.',
        ],
      ),
      (
        '4. Doctors',
        [
          'Every doctor is moderated: we check the licence and documents '
              'before the profile is published. Doctors must keep medical '
              'confidentiality and follow healthcare law.',
        ],
      ),
      (
        '5. Booking, payment and cancellation',
        [
          'A time slot is held for 15 minutes until payment. You can pay with '
              'Click, Payme, Google Pay or Apple Pay.',
          'If the doctor cancels, you get a full refund. If you cancel at '
              'least 24 hours before the visit, you get a full refund; later '
              'cancellations are not refunded.',
          'You can move a visit to another free time at least 24 hours in '
              'advance, up to two times.',
          'Google Pay and Apple Pay refunds are automatic; Click and Payme '
              'refunds are processed by an administrator. When the money '
              'arrives depends on your bank.',
        ],
      ),
      (
        '6. Online consultations',
        [
          'Video opens 10 minutes before the visit and is never recorded. '
              'Chat with the doctor is open from confirmation until 7 days '
              'after the conclusion.',
          'You need a stable internet connection, a camera and a microphone.',
        ],
      ),
      (
        '7. Not allowed',
        [
          "Using someone else's or false details, impersonating a doctor, "
              'abusing other users, sending content unrelated to treatment, '
              "or trying to access other people's data.",
        ],
      ),
      (
        '8. Liability',
        [
          "We operate the platform but are not responsible for doctors' "
              'medical decisions or for self-treatment based on AI analysis.',
        ],
      ),
      (
        '9. Deleting your account',
        [
          'You can delete your account in the app: Profile → Privacy → '
              'Delete account. Upcoming visits are cancelled under section 5.',
        ],
      ),
      (
        '10. Governing law',
        [
          'These terms are governed by the laws of the Republic of '
              'Uzbekistan.',
          'If the terms change, we will update the version date and ask for '
              'your consent again.',
          _contactLine(lang),
        ],
      ),
    ],
    _ => [
      (
        '1. Xizmat',
        [
          "MedLink — shifokorlarga yozilish, onlayn konsultatsiya va "
              "alomatlarni ma'lumot uchun AI orqali tahlil qilish "
              "platformasi. Shifokorlar xizmatni mustaqil ko'rsatadi va "
              "tavsiyalari uchun kasbiy javobgar.",
          "AI tahlili tashxis emas va shifokor ko'rigining o'rnini "
              'bosmaydi.',
        ],
      ),
      (
        '2. Shoshilinch holatlar',
        [
          "Xizmat shoshilinch yordam uchun mo'ljallanmagan. Hayotga xavf "
              "bo'lsa, 103 raqamiga qo'ng'iroq qiling.",
        ],
      ),
      (
        '3. Hisob',
        [
          "Kirish uchun O'zbekiston telefon raqami kerak. Profil "
              "ma'lumotlarining to'g'riligi va telefoningizga kirish uchun "
              "o'zingiz javobgarsiz. Xizmatdan 18 yoshdan oshganlar "
              'foydalanadi.',
        ],
      ),
      (
        '4. Shifokorlar',
        [
          "Har bir shifokor moderatsiyadan o'tadi: profil e'lon qilinishidan "
              'oldin litsenziya va hujjatlar tekshiriladi. Shifokor tibbiy '
              "sirni saqlashi va sog'liqni saqlash qonunchiligiga amal "
              'qilishi shart.',
        ],
      ),
      (
        "5. Bron, to'lov va bekor qilish",
        [
          "Qabul vaqti to'lovgacha 15 daqiqa band qilib turiladi. To'lov — "
              'Click, Payme, Google Pay yoki Apple Pay orqali.',
          "Shifokor bekor qilsa, pul to'liq qaytariladi. Bemor qabulgacha "
              "kamida 24 soat qolganda bekor qilsa, pul to'liq qaytariladi; "
              'kechroq bekor qilinsa — qaytarilmaydi.',
          "Qabulni boshqa bo'sh vaqtga kamida 24 soat oldin va ko'pi bilan "
              "ikki marta ko'chirish mumkin.",
          'Google Pay va Apple Pay uchun qaytarish avtomatik, Click va Payme '
              "uchun — administrator orqali. Pul kelish muddati bankka "
              "bog'liq.",
        ],
      ),
      (
        '6. Onlayn konsultatsiya',
        [
          "Video aloqa qabuldan 10 daqiqa oldin ochiladi va yozib olinmaydi. "
              "Shifokor bilan chat qabul tasdiqlangandan to xulosadan 7 kun "
              "keyingacha ochiq.",
          'Konsultatsiya uchun barqaror internet, kamera va mikrofon kerak.',
        ],
      ),
      (
        '7. Taqiqlanadi',
        [
          "Boshqa shaxs yoki yolg'on ma'lumotlarini ko'rsatish, o'zini "
              "shifokor deb tanishtirish, ishtirokchilarni haqorat qilish, "
              "chatga davolanishga aloqasiz materiallar yuborish va boshqalar "
              "ma'lumotiga kirishga urinish.",
        ],
      ),
      (
        '8. Javobgarlik',
        [
          'Biz platforma ishini taʼminlaymiz, lekin shifokorlarning tibbiy '
              "qarorlari va AI tahlili asosida o'z-o'zini davolash "
              'oqibatlari uchun javobgar emasmiz.',
        ],
      ),
      (
        "9. Hisobni o'chirish",
        [
          "Hisobni ilovada o'chirish mumkin: Profil → Maxfiylik → Hisobni "
              "o'chirish. Kelgusi qabullar 5-band qoidalari bo'yicha bekor "
              'qilinadi.',
        ],
      ),
      (
        '10. Qonunchilik',
        [
          "Shartlarga O'zbekiston Respublikasi qonunchiligi qo'llaniladi.",
          "Shartlar o'zgarsa, tahrir sanasini yangilaymiz va roziligingizni "
              "qayta so'raymiz.",
          _contactLine(lang),
        ],
      ),
    ],
  };
}
