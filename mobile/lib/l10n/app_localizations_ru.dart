// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appName => 'MedLink';

  @override
  String get tagline => 'Медицинская платформа с искусственным интеллектом';

  @override
  String get onb1Title => 'ИИ анализирует ваши симптомы';

  @override
  String get onb1Body =>
      'Опишите, что вас беспокоит — Google Med-PaLM 2 подскажет срочность и нужного врача.';

  @override
  String get onb2Title => 'Только проверенные врачи';

  @override
  String get onb2Body =>
      'Диплом и лицензия каждого врача проверяются модераторами. Запись на приём — в пару касаний.';

  @override
  String get onb3Title => 'Ваши данные под защитой';

  @override
  String get onb3Body =>
      'Медицинские данные шифруются, используются только с вашего согласия и удаляются в любой момент.';

  @override
  String get skip => 'Пропустить';

  @override
  String get next => 'Далее';

  @override
  String get getStarted => 'Начать';

  @override
  String get phoneTitle => 'Ваш номер телефона';

  @override
  String get phoneSubtitle => 'Мы отправим код для входа по SMS';

  @override
  String get getCode => 'Получить код';

  @override
  String get loginLegal =>
      'Продолжая, вы соглашаетесь ознакомиться с условиями использования и политикой конфиденциальности.';

  @override
  String get otpTitle => 'Введите код';

  @override
  String otpSubtitle(String phone) {
    return 'Мы отправили 6-значный код на $phone';
  }

  @override
  String get login => 'Войти';

  @override
  String get resendCode => 'Отправить код повторно';

  @override
  String resendIn(int seconds) {
    return 'Повторно через $seconds с';
  }

  @override
  String get cancel => 'Отмена';

  @override
  String get save => 'Сохранить';

  @override
  String get saved => 'Сохранено';

  @override
  String get delete => 'Удалить';

  @override
  String get deleted => 'Удалено';

  @override
  String get retry => 'Повторить';

  @override
  String get loading => 'Загрузка';

  @override
  String get submit => 'Отправить';

  @override
  String get add => 'Добавить';

  @override
  String get clear => 'Очистить';

  @override
  String get all => 'Все';

  @override
  String get seeAll => 'Все';

  @override
  String get required => 'обязательно';

  @override
  String get requiredField => 'Обязательное поле';

  @override
  String get logout => 'Выйти';

  @override
  String get logoutConfirm => 'Выйти из аккаунта?';

  @override
  String get systemDefault => 'Как в системе';

  @override
  String get today => 'Сегодня';

  @override
  String get errorGeneric => 'Произошла ошибка. Попробуйте ещё раз';

  @override
  String get errorNetwork => 'Нет подключения к интернету';

  @override
  String get errorOtpInvalid => 'Неверный код';

  @override
  String get errorOtpExpired => 'Срок действия кода истёк. Запросите новый';

  @override
  String get errorOtpAttempts => 'Попытки исчерпаны. Запросите новый код';

  @override
  String get errorRateLimited => 'Слишком много запросов. Попробуйте позже';

  @override
  String get errorConsentRequired => 'Для этого нужно ваше согласие';

  @override
  String get errorSlotUnavailable => 'Это время занято. Выберите другое';

  @override
  String get errorAlreadyApplied => 'Вы уже подали заявку';

  @override
  String get errorNotPayable => 'Этот приём нельзя оплатить';

  @override
  String get errorNotStarted => 'Приём ещё не начался';

  @override
  String get errorAlreadyReviewed => 'Вы уже оставили отзыв';

  @override
  String get consentScreenTitle => 'Согласия и конфиденциальность';

  @override
  String get consentIntro =>
      'Прочитайте, как используются ваши данные, и примите решение по каждому пункту отдельно. Без обязательных пунктов сервис не работает.';

  @override
  String consentFooter(String version) {
    return 'Версия: $version. Время решения и данные устройства сохраняются как подтверждение.';
  }

  @override
  String get agreeContinue => 'Согласен, продолжить';

  @override
  String get consentSettings => 'Настройки согласий';

  @override
  String get withdrawTitle => 'Отзыв согласия';

  @override
  String get withdrawMessage =>
      'Если вы отзовёте обязательное согласие, вы не сможете пользоваться сервисом. Продолжить?';

  @override
  String get withdrawConfirm => 'Да, отозвать';

  @override
  String get consentTermsTitle => 'Условия использования';

  @override
  String get consentTermsSummary => 'Правила использования сервиса MedLink.';

  @override
  String get consentTermsBody =>
      'MedLink — информационная платформа, связывающая пациентов с лицензированными врачами. Платформа не оказывает медицинскую помощь и не заменяет скорую помощь. В угрожающих жизни ситуациях звоните 103. Дипломы и лицензии врачей проверяются модераторами.';

  @override
  String get consentPersonalTitle => 'Персональные данные';

  @override
  String get consentPersonalSummary =>
      'Хранение номера телефона и данных профиля.';

  @override
  String get consentPersonalBody =>
      'В соответствии с Законом «О персональных данных» ваш номер телефона, ФИО и история приёмов обрабатываются для оказания услуг и хранятся в зашифрованном виде. Вы можете в любой момент получить копию данных, потребовать их изменения или удаления.';

  @override
  String get consentHealthTitle => 'Данные о здоровье';

  @override
  String get consentHealthSummary =>
      'Хранение симптомов, причин обращения и медицинского профиля.';

  @override
  String get consentHealthBody =>
      'Данные о здоровье относятся к особой категории. Они шифруются AES-256 и доступны только вам и выбранному врачу. Каждое обращение фиксируется в журнале аудита. Данные не передаются третьим лицам в рекламных целях.';

  @override
  String get consentAiTitle => 'Анализ искусственным интеллектом';

  @override
  String get consentAiSummary =>
      'Анализ симптомов с помощью Google Med-PaLM 2.';

  @override
  String get consentAiBody =>
      'При использовании анализа ИИ модели передаются введённый текст, возраст и пол. Имя, телефон и другие идентификаторы не передаются. Результат не является диагнозом. При отзыве согласия история анализов удаляется. Согласие добровольное.';

  @override
  String get consentTransferTitle => 'Трансграничная передача';

  @override
  String get consentTransferSummary =>
      'Для анализа ИИ обезличенный текст передаётся в Google Cloud.';

  @override
  String get consentTransferBody =>
      'Модель ИИ работает на серверах Google Cloud за пределами Узбекистана. Обезличенный текст симптомов передаётся по защищённому каналу (TLS). Это согласие необходимо для анализа ИИ.';

  @override
  String get consentMarketingTitle => 'Новости и акции';

  @override
  String get consentMarketingSummary =>
      'Сообщения о новостях и специальных предложениях.';

  @override
  String get consentMarketingBody =>
      'Необязательно. Можно отключить в настройках в любой момент.';

  @override
  String get tabHome => 'Главная';

  @override
  String get tabDoctors => 'Врачи';

  @override
  String get tabAppointments => 'Мои приёмы';

  @override
  String get tabPatients => 'Пациенты';

  @override
  String get tabModeration => 'Модерация';

  @override
  String get tabProfile => 'Профиль';

  @override
  String get goodMorning => 'Доброе утро!';

  @override
  String get goodAfternoon => 'Добрый день!';

  @override
  String get goodEvening => 'Добрый вечер!';

  @override
  String get homeSubtitle => 'Чем мы можем помочь вашему здоровью сегодня?';

  @override
  String get aiCardTitle => 'Проверить симптомы';

  @override
  String get aiCardBody =>
      'Опишите, что беспокоит — ИИ подскажет, к какому врачу обратиться.';

  @override
  String get nextAppointment => 'Ближайший приём';

  @override
  String get specialists => 'Специалисты';

  @override
  String emergencyBanner(String phone) {
    return 'При угрозе жизни немедленно звоните $phone';
  }

  @override
  String callEmergency(String phone) {
    return 'Позвонить $phone';
  }

  @override
  String get triageTitle => 'Анализ симптомов ИИ';

  @override
  String get triageHistory => 'История анализов';

  @override
  String get triageHistoryEmpty => 'Анализов пока нет';

  @override
  String get aiConsentNeededTitle => 'Нужно согласие на анализ ИИ';

  @override
  String get aiConsentNeededBody =>
      'Дайте согласие на пункты «Анализ ИИ» и «Трансграничная передача». Это необязательно — записаться к врачу можно и без этого.';

  @override
  String get symptomsQuestion => 'Что вас беспокоит?';

  @override
  String get symptomsHint =>
      'Например: третий день температура 38,5, болит горло, больно глотать...';

  @override
  String get noPiiHint => 'Не указывайте имя, телефон и паспортные данные.';

  @override
  String get age => 'Возраст';

  @override
  String get durationDays => 'Длительность (дни)';

  @override
  String get female => 'Женский';

  @override
  String get male => 'Мужской';

  @override
  String get prefilledFromProfile => 'Данные взяты из медицинского профиля';

  @override
  String chronicIncluded(String list) {
    return 'Будет учтено: $list';
  }

  @override
  String get analyze => 'Анализировать';

  @override
  String get analyzing => 'Анализируем...';

  @override
  String get triagePoweredBy =>
      'Анализ выполняется с помощью Google Med-PaLM 2 и не является диагнозом.';

  @override
  String get resultTitle => 'Результат анализа';

  @override
  String get urgencyEmergency => 'Нужна экстренная помощь';

  @override
  String urgencyEmergencyBody(String phone) {
    return 'Немедленно позвоните $phone или обратитесь в ближайшую больницу.';
  }

  @override
  String get urgencyUrgent => 'Скоро обратитесь к врачу';

  @override
  String get urgencyUrgentBody => 'Запишитесь к врачу на сегодня или завтра.';

  @override
  String get urgencyRoutine => 'Плановый приём';

  @override
  String get urgencyRoutineBody => 'Пройдите осмотр в ближайшие дни.';

  @override
  String get urgencySelfCare => 'Наблюдение дома';

  @override
  String get urgencySelfCareBody => 'Если станет хуже — обратитесь к врачу.';

  @override
  String get redFlags => 'Тревожные признаки';

  @override
  String get possibleCauses => 'Возможные причины';

  @override
  String get likelihoodHigh => 'Высокая';

  @override
  String get likelihoodMedium => 'Средняя';

  @override
  String get likelihoodLow => 'Низкая';

  @override
  String get advice => 'Рекомендация';

  @override
  String get whichDoctor => 'К какому врачу обратиться';

  @override
  String findSpecialist(String specialty) {
    return 'Найти: $specialty';
  }

  @override
  String get disclaimer =>
      'Этот анализ не является диагнозом и не заменяет осмотр врача.';

  @override
  String get searchDoctors => 'Врач или клиника';

  @override
  String get noDoctorsFound => 'Врачи не найдены';

  @override
  String get noDoctorsFoundHint => 'Попробуйте другую специальность или запрос';

  @override
  String get verifiedLicense => 'Лицензия проверена';

  @override
  String yearsExperience(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count лет опыта',
      few: '$count года опыта',
      one: '$count год опыта',
    );
    return '$_temp0';
  }

  @override
  String get experienceLabel => 'Лет опыта';

  @override
  String get rating => 'Рейтинг';

  @override
  String get reviews => 'Отзывы';

  @override
  String get about => 'О враче';

  @override
  String consultationPrice(String price) {
    return 'Стоимость приёма: $price';
  }

  @override
  String get patientReviews => 'Отзывы пациентов';

  @override
  String get chooseDay => 'Выберите день';

  @override
  String get chooseTime => 'Выберите время';

  @override
  String get morning => 'Утро';

  @override
  String get afternoon => 'День';

  @override
  String get noSlots => 'На этот день нет свободного времени';

  @override
  String get visitReason => 'Причина обращения';

  @override
  String get visitReasonHint => 'Видит только врач';

  @override
  String bookFor(String when, String price) {
    return 'Записаться · $when · $price';
  }

  @override
  String get holdNotice =>
      'Время бронируется на 15 минут — оплатите в течение этого срока.';

  @override
  String priceUzs(String amount) {
    return '$amount сум';
  }

  @override
  String get payment => 'Оплата';

  @override
  String get paymentMethod => 'Способ оплаты';

  @override
  String get localCards => 'Uzcard, Humo';

  @override
  String get intlCards => 'Visa, Mastercard';

  @override
  String payAmount(String price) {
    return 'Оплатить · $price';
  }

  @override
  String get pay => 'Оплатить';

  @override
  String get checkPayment => 'Проверить оплату';

  @override
  String get paymentNotYet =>
      'Оплата ещё не подтверждена. Проверьте чуть позже.';

  @override
  String get paymentFailed => 'Оплата не прошла';

  @override
  String get cardSafety => 'Данные карты не хранятся на серверах MedLink.';

  @override
  String holdLeft(String time) {
    return 'Бронь действует: $time';
  }

  @override
  String get holdExpired => 'Бронь истекла. Выберите время заново.';

  @override
  String get appointmentConfirmed => 'Приём подтверждён!';

  @override
  String get backToHome => 'На главную';

  @override
  String get upcoming => 'Предстоящие';

  @override
  String get past => 'Прошедшие';

  @override
  String get noUpcoming => 'Нет предстоящих приёмов';

  @override
  String get noPast => 'Нет прошедших приёмов';

  @override
  String get findDoctor => 'Найти врача';

  @override
  String get statusAwaitingPayment => 'Ожидает оплаты';

  @override
  String get statusConfirmed => 'Подтверждён';

  @override
  String get statusCompleted => 'Завершён';

  @override
  String get statusCancelled => 'Отменён';

  @override
  String get appointmentDetails => 'Детали приёма';

  @override
  String get dateLabel => 'Дата';

  @override
  String get timeLabel => 'Время';

  @override
  String get clinicLabel => 'Клиника';

  @override
  String get priceLabel => 'Стоимость';

  @override
  String get cancelAppointment => 'Отменить приём';

  @override
  String get cancelAppointmentConfirm =>
      'Вы действительно хотите отменить приём?';

  @override
  String get rateDoctor => 'Оценить врача';

  @override
  String get reviewHint => 'Расскажите о приёме (необязательно)';

  @override
  String get yourReview => 'Ваша оценка';

  @override
  String get doctorApplication => 'Заявка врача';

  @override
  String get moderationHowTitle => 'Как проходит модерация';

  @override
  String get moderationHowBody =>
      'Проверяются диплом, лицензия (реестр Минздрава) и документ, удостоверяющий личность. После одобрения профиль станет виден пациентам с отметкой «проверен». Обычно 1–3 рабочих дня.';

  @override
  String get fullName => 'ФИО';

  @override
  String get fullNameInvalid => 'Введите полное ФИО';

  @override
  String get specialty => 'Специальность';

  @override
  String get licenseNumber => 'Номер лицензии';

  @override
  String get city => 'Город';

  @override
  String get experienceYearsLabel => 'Стаж (лет)';

  @override
  String get priceUzsLabel => 'Цена (сум)';

  @override
  String get aboutYou => 'О себе';

  @override
  String get documents => 'Документы';

  @override
  String get documentsHint =>
      'Ссылки на копии диплома, лицензии, паспорта (по одной в строке)';

  @override
  String get applicationConfirm =>
      'Подтверждаю достоверность данных и согласен на их проверку';

  @override
  String get sendApplication => 'Отправить заявку';

  @override
  String get applicationSent =>
      'Заявка отправлена. Модерация занимает 1–3 рабочих дня.';

  @override
  String get noPatients => 'Пока нет записанных пациентов';

  @override
  String get noReason => 'Причина не указана';

  @override
  String get completeVisit => 'Завершить приём';

  @override
  String get completeVisitConfirm =>
      'Подтвердить, что приём состоялся? После этого пациент сможет оставить отзыв.';

  @override
  String get noPending => 'Нет заявок на проверку';

  @override
  String get approve => 'Одобрить';

  @override
  String approveConfirm(String name) {
    return 'Одобрить заявку $name? Профиль станет виден пациентам.';
  }

  @override
  String get reject => 'Отклонить';

  @override
  String get rejectReason => 'Причина отказа';

  @override
  String get rejectReasonHint => 'Например: лицензия не найдена в реестре';

  @override
  String get patient => 'Пациент';

  @override
  String get rolePatient => 'Пациент';

  @override
  String get roleDoctor => 'Врач';

  @override
  String get roleAdmin => 'Администратор';

  @override
  String get health => 'Здоровье';

  @override
  String get medicalProfile => 'Медицинский профиль';

  @override
  String get medicalProfileSubtitle =>
      'Аллергии, хронические болезни, лекарства';

  @override
  String get medicalProfileNote =>
      'Данные хранятся в зашифрованном виде и автоматически учитываются при анализе ИИ.';

  @override
  String get birthDate => 'Дата рождения';

  @override
  String get bloodType => 'Группа крови';

  @override
  String get heightCm => 'Рост (см)';

  @override
  String get weightKg => 'Вес (кг)';

  @override
  String get allergies => 'Аллергии';

  @override
  String get allergiesHint => 'Например: пенициллин';

  @override
  String get chronicConditions => 'Хронические заболевания';

  @override
  String get chronicHint => 'Например: сахарный диабет 2 типа';

  @override
  String get medications => 'Постоянные лекарства';

  @override
  String get medicationsHint => 'Например: метформин 500 мг';

  @override
  String get forDoctors => 'Для врачей';

  @override
  String get becomeDoctor => 'Стать врачом MedLink';

  @override
  String get becomeDoctorSubtitle => 'Подайте заявку и пройдите модерацию';

  @override
  String get applicationPending => 'Заявка на рассмотрении';

  @override
  String get applicationApproved => 'Подтверждённый врач';

  @override
  String get applicationRejected => 'Заявка отклонена';

  @override
  String get applicationSuspended => 'Профиль приостановлен';

  @override
  String moderatorNote(String note) {
    return 'Комментарий модератора: $note';
  }

  @override
  String get reapply => 'Подать заявку снова';

  @override
  String get settings => 'Настройки';

  @override
  String get language => 'Язык';

  @override
  String get theme => 'Тема';

  @override
  String get themeLight => 'Светлая';

  @override
  String get themeDark => 'Тёмная';

  @override
  String get biometricLock => 'Биометрическая блокировка';

  @override
  String get biometricLockSubtitle => 'Вход по Face ID / отпечатку пальца';

  @override
  String get biometricReason => 'Подтвердите личность, чтобы открыть MedLink';

  @override
  String get lockedTitle => 'MedLink заблокирован';

  @override
  String get unlock => 'Разблокировать';

  @override
  String get privacy => 'Конфиденциальность';

  @override
  String get exportData => 'Копия моих данных';

  @override
  String get exportDataSubtitle => 'Получить все сохранённые данные';

  @override
  String get exportCopied => 'Копия данных скопирована в буфер обмена';

  @override
  String get deleteHealthData => 'Удалить медицинские данные';

  @override
  String get deleteHealthDataConfirm =>
      'Анализы ИИ и медицинский профиль будут безвозвратно удалены. История приёмов хранится в установленный законом срок.';

  @override
  String get emergencyNumber => 'Скорая помощь';

  @override
  String get version => 'Версия';

  @override
  String get specTherapist => 'Терапевт';

  @override
  String get specPediatrician => 'Педиатр';

  @override
  String get specCardiologist => 'Кардиолог';

  @override
  String get specNeurologist => 'Невролог';

  @override
  String get specGastroenterologist => 'Гастроэнтеролог';

  @override
  String get specPulmonologist => 'Пульмонолог';

  @override
  String get specEndocrinologist => 'Эндокринолог';

  @override
  String get specDermatologist => 'Дерматолог';

  @override
  String get specEnt => 'ЛОР';

  @override
  String get specOphthalmologist => 'Офтальмолог';

  @override
  String get specGynecologist => 'Гинеколог';

  @override
  String get specUrologist => 'Уролог';

  @override
  String get specTraumatologist => 'Травматолог';

  @override
  String get specPsychiatrist => 'Психиатр';

  @override
  String get tashkentTime => 'По времени Ташкента (UTC+5)';

  @override
  String get completeProfile => 'Заполните профиль';

  @override
  String get licenses => 'Лицензии';

  @override
  String get reminderTitle => 'MedLink: напоминание о приёме';

  @override
  String reminderDayBefore(String time) {
    return 'Завтра в $time у вас приём.';
  }

  @override
  String reminderHourBefore(String time) {
    return 'Ваш приём через час, в $time.';
  }

  @override
  String get notifications => 'Уведомления';

  @override
  String get notificationsSubtitle =>
      'Напоминания о приёмах и изменения статуса';

  @override
  String get notificationsDenied =>
      'Разрешение не выдано. Включите уведомления для MedLink в настройках телефона.';

  @override
  String get enableRemindersTitle => 'Не пропустите приём';

  @override
  String get enableRemindersBody =>
      'Напомним за день и за час до приёма. Медицинские данные в тексте не показываются.';

  @override
  String get enableReminders => 'Включить напоминания';

  @override
  String get remindersEnabled => 'Напоминания включены';

  @override
  String get online => 'Онлайн';

  @override
  String get inClinic => 'В клинике';

  @override
  String get onlineAvailable => 'Есть онлайн-приём';

  @override
  String get onlineOnly => 'Только онлайн-приём';

  @override
  String get consultationType => 'Тип приёма';

  @override
  String get consultationTypes => 'Типы приёма';

  @override
  String get onlineHowItWorks =>
      'Во время приёма в приложении откроется видеозвонок. Подготовьте стабильный интернет и тихое место.';

  @override
  String onlinePriceLabel(String price) {
    return 'Онлайн-приём: $price';
  }

  @override
  String get onlineConsultation => 'Онлайн-консультация';

  @override
  String get joinVideo => 'Войти в видеозвонок';

  @override
  String get videoReady =>
      'Комната открыта. Войдите, чтобы связаться с врачом.';

  @override
  String get videoReadyShort => 'Видео доступно';

  @override
  String videoOpensAt(String time) {
    return 'Видео откроется в $time (за 10 минут до приёма).';
  }

  @override
  String get videoClosed =>
      'Время видеоприёма истекло. Задайте вопросы в чате.';

  @override
  String get videoNotConfigured =>
      'Видеосвязь пока не подключена. Свяжитесь с врачом в чате.';

  @override
  String get videoTips =>
      'Совет: используйте наушники и сядьте в светлом месте.';

  @override
  String get callConnecting => 'Подключение...';

  @override
  String get callWaiting => 'Собеседник ещё не подключился. Подождите...';

  @override
  String get callReconnecting => 'Связь прервалась, переподключаемся...';

  @override
  String get callEnded => 'Звонок завершён';

  @override
  String get callFailed =>
      'Не удалось подключиться. Проверьте интернет и повторите.';

  @override
  String get callPermissionDenied =>
      'Нет доступа к камере или микрофону. Разрешите доступ для MedLink в настройках.';

  @override
  String get callEncrypted => 'Зашифрованная связь · без записи';

  @override
  String get mute => 'Выкл. микрофон';

  @override
  String get unmute => 'Вкл. микрофон';

  @override
  String get cameraOff => 'Выкл. камеру';

  @override
  String get cameraOn => 'Вкл. камеру';

  @override
  String get switchCamera => 'Сменить';

  @override
  String get endCall => 'Завершить';

  @override
  String get endCallConfirm => 'Завершить звонок?';

  @override
  String get close => 'Закрыть';

  @override
  String get chat => 'Чат';

  @override
  String get chatSubtitle => 'Задайте вопрос врачу';

  @override
  String get chatSubtitleDoctor => 'Переписка с пациентом';

  @override
  String get chatHint => 'Напишите сообщение...';

  @override
  String get send => 'Отправить';

  @override
  String get sending => 'Отправка';

  @override
  String get chatEmptyTitle => 'Сообщений пока нет';

  @override
  String get chatEmptyBody =>
      'Задайте вопрос по приёму. Врач ответит в рабочее время.';

  @override
  String get chatClosed => 'Чат закрыт: прошло 7 дней после приёма.';

  @override
  String get chatEmergencyNote =>
      'Чат не для экстренной помощи — при угрозе жизни звоните 103';

  @override
  String get patientInfo => 'Данные пациента';

  @override
  String get patientInfoSubtitle => 'Медицинский профиль и анализ ИИ';

  @override
  String get aiPreTriage => 'Анализ ИИ перед приёмом';

  @override
  String get viewDetails => 'Подробнее';

  @override
  String get sex => 'Пол';

  @override
  String get heightWeight => 'Рост / вес';

  @override
  String get patientReview => 'Оценка пациента';

  @override
  String get conclusion => 'Заключение врача';

  @override
  String get writeConclusion => 'Написать заключение';

  @override
  String get editConclusion => 'Изменить заключение';

  @override
  String get saveConclusion => 'Сохранить заключение';

  @override
  String get saveConclusionConfirm =>
      'Заключение будет отправлено пациенту, приём завершится. Продолжить?';

  @override
  String get conclusionSaved => 'Заключение сохранено и отправлено пациенту';

  @override
  String get diagnosis => 'Диагноз';

  @override
  String get diagnosisHint => 'Например: ОРВИ (J06.9)';

  @override
  String get recommendations => 'Рекомендации';

  @override
  String get prescription => 'Рецепт';

  @override
  String get addMedication => 'Добавить препарат';

  @override
  String get noPrescription => 'Препараты не назначены';

  @override
  String get medication => 'Препарат';

  @override
  String get drugName => 'Название препарата';

  @override
  String get dose => 'Доза';

  @override
  String get frequency => 'Схема приёма';

  @override
  String get frequencyHint => 'Например: 2 раза в день после еды';

  @override
  String get notes => 'Примечание';

  @override
  String get followUp => 'Повторный приём';

  @override
  String get followUpNone => 'Не требуется';

  @override
  String inDays(int days) {
    return 'через $days дн.';
  }

  @override
  String forDays(int days) {
    return '$days дн.';
  }

  @override
  String followUpIn(int days) {
    return 'Повторный приём: через $days дн.';
  }

  @override
  String get conclusionPrivacy =>
      'Заключение хранится в зашифрованном виде и доступно только пациенту.';

  @override
  String get conclusionDisclaimer =>
      'Принимайте препараты только по назначению врача. При ухудшении — 103.';

  @override
  String get scheduleAndPrices => 'График и цены';

  @override
  String get scheduleAndPricesSubtitle => 'Рабочие дни, часы, онлайн-приём';

  @override
  String get workDays => 'Рабочие дни';

  @override
  String get workHours => 'Рабочее время (Ташкент)';

  @override
  String get from => 'С';

  @override
  String get to => 'До';

  @override
  String slotsPerDay(int count) {
    return '$count приёмов по 30 минут в день';
  }

  @override
  String get clinicPrice => 'Цена приёма в клинике';

  @override
  String get onlinePrice => 'Цена онлайн-приёма';

  @override
  String get onlineSubtitle => 'По видеосвязи и в чате';

  @override
  String get scheduleNote =>
      'Изменения влияют только на новые записи. Существующие приёмы сохраняются.';

  @override
  String get chooseConsultationType => 'Включите хотя бы один тип приёма';

  @override
  String get onlinePriceRequired => 'Укажите цену онлайн-приёма';

  @override
  String get errorChatClosed => 'Чат закрыт';

  @override
  String get errorTooEarly =>
      'Видео ещё не доступно — откроется за 10 минут до приёма';

  @override
  String get errorTooLate => 'Время видеоприёма истекло';

  @override
  String get errorVideoUnavailable => 'Видеосвязь временно недоступна';

  @override
  String get errorTypeUnavailable => 'Врач не проводит такой тип приёма';

  @override
  String get errorInvalidSchedule => 'Неверный график: проверьте дни и часы';

  @override
  String get videoNotConfiguredDoctor =>
      'Видеосвязь пока не подключена. Свяжитесь с пациентом в чате.';

  @override
  String get tabAdmin => 'Управление';

  @override
  String get statistics => 'Статистика';

  @override
  String get applications => 'Заявки';

  @override
  String get refunds => 'Возвраты';

  @override
  String get statUsers => 'Пользователи';

  @override
  String get statDoctors => 'Активные врачи';

  @override
  String get statPendingApplications => 'Заявки на проверке';

  @override
  String get statToday => 'Приёмы сегодня';

  @override
  String get statRevenue30d => 'Выручка за 30 дней';

  @override
  String get statOnlineShare => 'Доля онлайн';

  @override
  String get statRefundsPending => 'Ожидают возврата';

  @override
  String get statAppointments => 'Статусы приёмов';

  @override
  String get noRefunds => 'Нет ожидающих возвратов';

  @override
  String get refundReasonDoctor => 'Отменено врачом';

  @override
  String get refundReasonPatient => 'Пациент отменил более чем за 24 часа';

  @override
  String get markRefunded => 'Отметить возврат';

  @override
  String markRefundedConfirm(String provider) {
    return 'Сначала выполните возврат в кабинете $provider. Пациент получит уведомление. Продолжить?';
  }

  @override
  String requestedAt(String time) {
    return 'Запрошен: $time';
  }

  @override
  String transactionId(String id) {
    return 'Транзакция: $id';
  }

  @override
  String get copied => 'Скопировано';

  @override
  String get cancelPolicyRefund =>
      'До приёма более 24 часов — оплата будет возвращена полностью. Отменить?';

  @override
  String get cancelPolicyNoRefund =>
      'До приёма меньше 24 часов — оплата не возвращается. Всё равно отменить?';

  @override
  String get cancelPolicyDoctor =>
      'Пациенту будет возвращена вся сумма и отправлено уведомление. Отменить?';

  @override
  String get refundRequested =>
      'Приём отменён. Оплата вернётся в течение 3–5 рабочих дней.';

  @override
  String get refundRequestedShort => 'Возврат в обработке';

  @override
  String get refundDone => 'Оплата возвращена';

  @override
  String get attachPhoto => 'Прикрепить фото';

  @override
  String get takePhoto => 'Сделать фото';

  @override
  String get chooseFromGallery => 'Выбрать из галереи';

  @override
  String get attachmentHint =>
      'Можно отправить фото анализов, рецепта или изменений кожи. Фото шифруется, данные о местоположении удаляются.';

  @override
  String get uploadingPhoto => 'Отправка фото...';

  @override
  String get errorFileTooLarge => 'Файл слишком большой (до 5 МБ)';

  @override
  String get errorUnsupportedFile =>
      'Можно отправлять только фото JPEG или PNG';

  @override
  String get aboutApp => 'О приложении';

  @override
  String get privacyPolicy => 'Политика конфиденциальности';

  @override
  String get termsOfUse => 'Условия использования';

  @override
  String get deleteAccount => 'Удалить аккаунт';

  @override
  String get deleteAccountSubtitle =>
      'Аккаунт и медицинские данные удаляются навсегда';

  @override
  String get deleteAccountConfirm =>
      'Ваш аккаунт будет удалён навсегда:\n• медицинский профиль, AI-анализы и номер телефона удаляются;\n• будущие приёмы отменяются, оплата возвращается по правилам возврата;\n• платежи, заключения врачей и журнал безопасности хранятся по закону без вашего номера телефона.\n\nЭто действие нельзя отменить.';

  @override
  String get deleteAccountFinal => 'Вы действительно хотите удалить аккаунт?';

  @override
  String get accountDeleted => 'Аккаунт удалён';

  @override
  String get continueAction => 'Продолжить';

  @override
  String get reschedule => 'Перенести приём';

  @override
  String get rescheduleTitle => 'Выберите новое время';

  @override
  String rescheduleHint(int count) {
    return 'Оплата сохранится. Перенести можно ещё $count раз(а).';
  }

  @override
  String rescheduleConfirm(String time) {
    return 'Перенести приём на $time?';
  }

  @override
  String get rescheduled => 'Время приёма изменено';

  @override
  String get currentTime => 'Текущее время';

  @override
  String get errorTooLateToReschedule =>
      'До приёма меньше 24 часов — перенести нельзя';

  @override
  String get errorRescheduleLimit => 'Приём можно перенести не более двух раз';

  @override
  String get errorDoctorUnavailable => 'Врач сейчас не ведёт такой приём';

  @override
  String get errorRefundFailed =>
      'Платёжная система не выполнила возврат. Попробуйте позже';

  @override
  String get refundCompletedNow =>
      'Приём отменён. Деньги возвращены на карту — банк обычно зачисляет их за 5–10 дней.';

  @override
  String get liveConnected => 'На связи';
}
