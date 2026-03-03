// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'Taler ID';

  @override
  String get search => 'Поиск';

  @override
  String get appSubtitle => 'Единая идентификация экосистемы';

  @override
  String get login => 'Вход в аккаунт';

  @override
  String get loginButton => 'Войти';

  @override
  String get register => 'Создать аккаунт';

  @override
  String get registerButton => 'Создать аккаунт';

  @override
  String get email => 'Email';

  @override
  String get password => 'Пароль';

  @override
  String get confirmPassword => 'Подтвердить пароль';

  @override
  String get firstName => 'Имя';

  @override
  String get lastName => 'Фамилия';

  @override
  String get noAccount => 'Нет аккаунта?';

  @override
  String get createOne => 'Создать';

  @override
  String get haveAccount => 'Уже есть аккаунт?';

  @override
  String get signIn => 'Войти';

  @override
  String get passwordMinLength => 'Минимум 8 символов';

  @override
  String get invalidEmail => 'Введите корректный email';

  @override
  String get fieldRequired => 'Обязательное поле';

  @override
  String get twoFATitle => 'Двухфакторная аутентификация';

  @override
  String get twoFASubtitle =>
      'Введите 6-значный код из приложения-аутентификатора';

  @override
  String get twoFACode => 'Код 2FA';

  @override
  String get verify => 'Подтвердить';

  @override
  String get tabProfile => 'Профиль';

  @override
  String get tabKyc => 'KYC';

  @override
  String get tabOrganization => 'Организация';

  @override
  String get tabSettings => 'Настройки';

  @override
  String get profile => 'Профиль';

  @override
  String get editProfile => 'Редактировать профиль';

  @override
  String get phone => 'Телефон';

  @override
  String get country => 'Страна';

  @override
  String get dateOfBirth => 'Дата рождения';

  @override
  String get documents => 'Документы';

  @override
  String get addDocument => 'Добавить документ';

  @override
  String get noDocuments => 'Документы не загружены';

  @override
  String get save => 'Сохранить';

  @override
  String get profileUpdated => 'Профиль обновлён';

  @override
  String get personalData => 'Личные данные';

  @override
  String get passport => 'Паспорт';

  @override
  String get drivingLicense => 'Водительское удостоверение';

  @override
  String get diploma => 'Диплом';

  @override
  String get nationalId => 'Национальный ID';

  @override
  String get certificate => 'Сертификат';

  @override
  String get notSpecified => 'Не указан';

  @override
  String get notSpecifiedFemale => 'Не указана';

  @override
  String get documentType => 'Тип документа';

  @override
  String get passportId => 'Паспорт / ID';

  @override
  String get diplomaCertificate => 'Диплом / Сертификат';

  @override
  String get loadError => 'Ошибка загрузки';

  @override
  String get verification => 'Верификация';

  @override
  String get countryAustria => 'Австрия';

  @override
  String get countryGermany => 'Германия';

  @override
  String get countryRussia => 'Россия';

  @override
  String get countryUkraine => 'Украина';

  @override
  String get countryKazakhstan => 'Казахстан';

  @override
  String get countryBelarus => 'Беларусь';

  @override
  String get countryOther => 'Другая';

  @override
  String get kycTitle => 'Верификация KYC';

  @override
  String get kycVerified => 'Верифицирован';

  @override
  String get kycPending => 'На проверке';

  @override
  String get kycRejected => 'Отклонено';

  @override
  String get kycUnverified => 'Не верифицирован';

  @override
  String get kycVerifiedDesc =>
      'Ваша личность подтверждена. У вас есть полный доступ ко всем функциям экосистемы Taler.';

  @override
  String get kycPendingDesc =>
      'Ваши документы проходят верификацию. Обычно это занимает 1-2 рабочих дня.';

  @override
  String get kycRejectedDesc =>
      'Верификация не пройдена. Ознакомьтесь с причиной и отправьте документы повторно.';

  @override
  String get kycUnverifiedDesc =>
      'Пройдите верификацию для получения полного доступа к финансовым функциям экосистемы Taler.';

  @override
  String get startVerification => 'Пройти верификацию';

  @override
  String get retryVerification => 'Пройти повторно';

  @override
  String verifiedAt(String date) {
    return 'Верифицирован: $date';
  }

  @override
  String get documentsSubmitted => 'Документы отправлены на проверку';

  @override
  String get documentsSubmittedDesc =>
      'Обычно проверка занимает 1-2 рабочих дня. Вы получите push-уведомление о результате.';

  @override
  String get securityAes => 'Ваши данные защищены AES-256 шифрованием';

  @override
  String get verificationTime => 'Верификация занимает 1-2 рабочих дня';

  @override
  String get pushNotification => 'Вы получите push-уведомление о результате';

  @override
  String get kycWebOnly =>
      'KYC-верификация доступна только в мобильном приложении.';

  @override
  String verificationError(String code) {
    return 'Ошибка верификации: $code';
  }

  @override
  String get organizations => 'Организации';

  @override
  String get noOrganizations => 'Нет организаций';

  @override
  String get noOrganizationsDesc =>
      'Создайте организацию или примите приглашение';

  @override
  String get createOrganization => 'Создать организацию';

  @override
  String get newOrganization => 'Новая организация';

  @override
  String get orgName => 'Название *';

  @override
  String get orgDescription => 'Описание';

  @override
  String get orgEmail => 'Контактный email';

  @override
  String get orgWebsite => 'Веб-сайт';

  @override
  String get orgLegalAddress => 'Юридический адрес';

  @override
  String get create => 'Создать';

  @override
  String get organization => 'Организация';

  @override
  String get contacts => 'Контакты';

  @override
  String members(int count) {
    return 'Участники ($count)';
  }

  @override
  String get inviteMember => 'Пригласить участника';

  @override
  String get invite => 'Пригласить';

  @override
  String get sendInvite => 'Отправить приглашение';

  @override
  String inviteSent(String email) {
    return 'Приглашение отправлено на $email';
  }

  @override
  String get role => 'Роль';

  @override
  String get roleOwner => 'Owner';

  @override
  String get roleAdmin => 'Admin';

  @override
  String get roleOperator => 'Operator';

  @override
  String get roleViewer => 'Viewer';

  @override
  String get editOrganization => 'Редактировать';

  @override
  String get editOrganizationTitle => 'Редактировать организацию';

  @override
  String get removeMember => 'Удалить участника';

  @override
  String removeMemberConfirm(String name) {
    return 'Удалить $name из организации?';
  }

  @override
  String get memberRemoved => 'Участник удалён';

  @override
  String get roleChanged => 'Роль изменена';

  @override
  String get kybVerified => 'Верифицирована';

  @override
  String get kybPending => 'На проверке';

  @override
  String get kybRejected => 'Отклонено';

  @override
  String get kybNone => 'Не верифицирована';

  @override
  String get kybVerification => 'Пройти KYB-верификацию';

  @override
  String get kybStartBusiness => 'Пройти бизнес-верификацию';

  @override
  String get kybStatusLabel => 'Статус KYB';

  @override
  String get noKyb => 'Без KYB';

  @override
  String get kybBusinessVerificationTitle => 'Бизнес-верификация (KYB)';

  @override
  String get kybVerifiedOrgDesc => 'Организация успешно верифицирована.';

  @override
  String get kybPendingOrgDesc =>
      'Документы проходят проверку. Обычно это занимает 1-3 рабочих дня.';

  @override
  String get kybRejectedOrgDesc =>
      'Верификация не пройдена. Попробуйте повторно.';

  @override
  String get kybNoneOrgDesc =>
      'Верифицируйте организацию для доступа к бизнес-функциям.';

  @override
  String get invitePlus => '+ Пригласить';

  @override
  String get kybVerificationTitle => 'KYB-верификация';

  @override
  String get kybWebOnlyBusiness =>
      'KYB-верификация доступна только в мобильном приложении.';

  @override
  String get unknownDevice => 'Неизвестное устройство';

  @override
  String get ipUnknown => 'IP неизвестен';

  @override
  String get currentSessionLabel => 'Текущая';

  @override
  String get endSessionAction => 'Завершить';

  @override
  String get deviceLoggedOut => 'Устройство будет выведено из аккаунта.';

  @override
  String get acceptInvitationTitle => 'Приглашение в организацию';

  @override
  String get acceptInvitation => 'Принять приглашение';

  @override
  String get acceptInvitationDesc =>
      'Вас пригласили присоединиться к организации в экосистеме Taler.';

  @override
  String get accept => 'Принять';

  @override
  String get reject => 'Отклонить';

  @override
  String get sessions => 'Активные сессии';

  @override
  String get currentSession => 'Текущая сессия';

  @override
  String get deleteSession => 'Завершить сессию';

  @override
  String get deleteSessionConfirm => 'Завершить эту сессию?';

  @override
  String get sessionDeleted => 'Сессия завершена';

  @override
  String get noSessions => 'Нет активных сессий';

  @override
  String minutesAgo(int count) {
    return '$count мин. назад';
  }

  @override
  String hoursAgo(int count) {
    return '$count ч. назад';
  }

  @override
  String daysAgo(int count) {
    return '$count дн. назад';
  }

  @override
  String get justNow => 'Только что';

  @override
  String get settings => 'Настройки';

  @override
  String get security => 'Безопасность';

  @override
  String get biometrics => 'Биометрия';

  @override
  String get biometricsDesc => 'Быстрый вход по Face ID или отпечатку';

  @override
  String get biometricsConfirm =>
      'Подтвердите биометрию для включения быстрого входа';

  @override
  String get biometricsError =>
      'Не удалось включить биометрию. Проверьте настройки устройства.';

  @override
  String get changePassword => 'Изменить пароль';

  @override
  String get twoFactorAuth => 'Двухфакторная аутентификация';

  @override
  String get currentPassword => 'Текущий пароль';

  @override
  String get newPassword => 'Новый пароль';

  @override
  String get confirmNewPassword => 'Подтвердить новый пароль';

  @override
  String get notifications => 'Уведомления';

  @override
  String get pushKycStatus => 'Push о KYC-статусе';

  @override
  String get pushKycStatusDesc => 'Результат верификации';

  @override
  String get pushLogins => 'Push о входах';

  @override
  String get pushLoginsDesc => 'При входе с нового устройства';

  @override
  String get account => 'Аккаунт';

  @override
  String get language => 'Язык';

  @override
  String get languageRussian => 'Русский';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageSelect => 'Язык интерфейса';

  @override
  String get exportData => 'Экспорт данных (GDPR)';

  @override
  String get deleteAccount => 'Удалить аккаунт';

  @override
  String get deleteAccountConfirm => 'Удалить аккаунт?';

  @override
  String get deleteAccountDesc =>
      'Все ваши данные будут удалены (GDPR). Это действие необратимо.';

  @override
  String get logout => 'Выйти';

  @override
  String get logoutConfirm => 'Выйти из аккаунта?';

  @override
  String get logoutDesc => 'Вы будете выведены из Taler ID на этом устройстве.';

  @override
  String version(String version) {
    return 'Taler ID v$version';
  }

  @override
  String get pinCode => 'PIN-код';

  @override
  String get pinCodeDesc => 'Быстрый вход по 4-значному коду';

  @override
  String get setupPin => 'Установить PIN-код';

  @override
  String get enterPin => 'Введите PIN-код';

  @override
  String get confirmPin => 'Подтвердите PIN-код';

  @override
  String get pinMismatch => 'PIN-коды не совпадают';

  @override
  String get pinSet => 'PIN-код установлен';

  @override
  String get enterPinToLogin => 'Введите PIN для входа';

  @override
  String get pinIncorrect => 'Неверный PIN-код';

  @override
  String get removePin => 'Удалить PIN-код';

  @override
  String get pinRemoved => 'PIN-код удалён';

  @override
  String get cancel => 'Отмена';

  @override
  String get delete => 'Удалить';

  @override
  String get ok => 'OK';

  @override
  String get retry => 'Повторить';

  @override
  String get loading => 'Загрузка...';

  @override
  String get error => 'Ошибка';

  @override
  String get success => 'Успешно';

  @override
  String get noData => 'Нет данных';

  @override
  String get failedToLoad => 'Не удалось загрузить данные';

  @override
  String get failedToLoadProfile => 'Не удалось загрузить профиль';

  @override
  String get failedToSave => 'Не удалось сохранить изменения';

  @override
  String get failedToLoadOrgs => 'Не удалось загрузить список организаций';

  @override
  String get failedToLoadOrg => 'Не удалось загрузить данные организации';

  @override
  String get failedToCreateOrg => 'Не удалось создать организацию';

  @override
  String get failedToInvite => 'Не удалось отправить приглашение';

  @override
  String get failedToAcceptInvite => 'Не удалось принять приглашение';

  @override
  String get failedToLoadSessions => 'Не удалось загрузить сессии';

  @override
  String get failedToDeleteSession => 'Не удалось завершить сессию';

  @override
  String get failedToLoadKyc => 'Не удалось загрузить статус верификации';

  @override
  String get failedToStartKyc => 'Не удалось запустить верификацию';

  @override
  String get verifiedPersonalInfo => 'Подтверждённые данные';

  @override
  String get middleName => 'Отчество';

  @override
  String get placeOfBirth => 'Место рождения';

  @override
  String get nationality => 'Гражданство';

  @override
  String get gender => 'Пол';

  @override
  String get genderMale => 'Мужской';

  @override
  String get genderFemale => 'Женский';

  @override
  String get docNumber => 'Номер';

  @override
  String get docIssuedDate => 'Дата выдачи';

  @override
  String get docValidUntil => 'Действителен до';

  @override
  String get docIssuedBy => 'Кем выдан';

  @override
  String get address => 'Адрес';

  @override
  String get refreshData => 'Обновить данные';

  @override
  String get failedToLoadSumsubData =>
      'Не удалось загрузить данные верификации';

  @override
  String get sumsubDataLoading => 'Загрузка данных верификации...';

  @override
  String get reviewResultGreen => 'Проверка пройдена';

  @override
  String get reviewResultRed => 'Проверка не пройдена';

  @override
  String get chatTitle => 'Ассистент';

  @override
  String get chatHint => 'Напишите сообщение...';

  @override
  String get chatListening => 'Слушаю...';

  @override
  String get chatError => 'Ошибка соединения';

  @override
  String get chatClear => 'Очистить чат';

  @override
  String get chatEmpty => 'Задайте вопрос ассистенту';

  @override
  String get tabAssistant => 'Ассистент';

  @override
  String get assistantConnecting => 'Подключение…';

  @override
  String get assistantSpeaking => 'Говорит…';

  @override
  String get assistantListening => 'Слушает…';

  @override
  String get assistantTapToStart => 'Нажмите для начала';

  @override
  String get assistantTapToTalk => 'Нажмите для разговора с AI';

  @override
  String get assistantRealtimeDesc =>
      'Ассистент отвечает голосом в реальном времени';

  @override
  String get assistantConnectingToAssistant => 'Подключение к ассистенту...';

  @override
  String get assistantAiSpeaking => 'AI говорит...';

  @override
  String get assistantAiListening => 'AI слушает';

  @override
  String get assistantSpeakerOn => 'Динамик вкл';

  @override
  String get assistantSpeaker => 'Динамик';

  @override
  String get assistantEnd => 'Завершить';

  @override
  String get assistantUnmute => 'Включить';

  @override
  String get assistantMicrophone => 'Микрофон';

  @override
  String get assistantConnectionError => 'Ошибка подключения';

  @override
  String get tabMessenger => 'Сообщения';

  @override
  String get appearance => 'Оформление';

  @override
  String get appearanceSelect => 'Выбор темы';

  @override
  String get themeLight => 'Светлая';

  @override
  String get themeDark => 'Тёмная';

  @override
  String get themeSystem => 'Системная';
}
