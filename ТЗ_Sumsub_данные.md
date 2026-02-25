# ТЗ: Получение персональных данных из Sumsub в Taler ID Mobile

## Контекст

Сейчас KYC-верификация через Sumsub возвращает только статус (VERIFIED/PENDING/REJECTED). Персональные данные (ФИО, дата рождения, страна) пользователь вводит вручную в Edit Profile. Нужно автоматически подтягивать все верифицированные данные из Sumsub:
- **Автоматически** при успешной верификации (статус VERIFIED)
- **Вручную** по нажатию кнопки "Обновить" на экране KYC
- **Все доступные данные**: персональная информация, документы (тип, номер, даты), адреса, результаты проверок

---

## Часть 1: Backend — Новый эндпоинт

### `GET /kyc/applicant-data`

Бэкенд `id.taler.tirol` (отдельный сервис, не n8n) должен реализовать эндпоинт, который:

1. Извлекает `userId` из JWT (Authorization: Bearer)
2. Находит Sumsub `applicantId` в БД (сохранён при `/kyc/start`)
3. Вызывает Sumsub API `GET /resources/applicants/{applicantId}` с HMAC-SHA256 авторизацией (заголовки: `X-App-Token`, `X-App-Access-Ts`, `X-App-Access-Sig`)
4. Вызывает `GET /resources/applicants/{applicantId}/requiredIdDocsStatus` для статуса документов
5. Возвращает объединённый JSON

**Авторизация**: JWT Bearer token (как все остальные эндпоинты)

**Ответ 200 OK:**
```json
{
  "applicantId": "65a1b2c3...",
  "createdAt": "2025-01-15T10:30:00.000Z",
  "reviewStatus": "completed",
  "reviewResult": {
    "reviewAnswer": "GREEN",
    "rejectLabels": []
  },
  "info": {
    "firstName": "Иван",
    "lastName": "Петров",
    "middleName": "Сергеевич",
    "dob": "1990-05-15",
    "placeOfBirth": "Москва",
    "country": "RUS",
    "nationality": "RUS",
    "gender": "M"
  },
  "addresses": [
    {
      "street": "Тверская",
      "buildingNumber": "10",
      "flatNumber": "5",
      "town": "Москва",
      "state": null,
      "postCode": "125009",
      "country": "RUS"
    }
  ],
  "idDocs": [
    {
      "idDocType": "PASSPORT",
      "number": "1234567890",
      "firstName": "ИВАН",
      "lastName": "ПЕТРОВ",
      "issuedDate": "2015-03-20",
      "validUntil": "2025-03-20",
      "issuedBy": "МВД",
      "country": "RUS"
    }
  ]
}
```

**Ошибки:**
- `401` — невалидный/истёкший JWT
- `404` — для пользователя не найден Sumsub applicant (KYC не начинался)
- `503` — Sumsub API недоступен

---

## Часть 2: Flutter — Domain Layer

### 2.1 Новая сущность: `SumsubApplicantEntity`

**Новый файл:** `lib/features/kyc/domain/entities/sumsub_applicant_entity.dart`

Freezed-класс с вложенными типами:
- `SumsubApplicantEntity` — корневой (applicantId, reviewStatus, reviewResult, info, addresses[], idDocs[])
- `SumsubReviewResult` — результат проверки (reviewAnswer, rejectLabels[])
- `SumsubPersonInfo` — персональные данные (firstName, lastName, middleName, dob, placeOfBirth, country, nationality, gender)
- `SumsubAddress` — адрес (street, buildingNumber, flatNumber, town, state, postCode, country)
- `SumsubIdDoc` — документ (idDocType, number, firstName, lastName, issuedDate, validUntil, issuedBy, country)

Все с `fromJson` / `toJson` через `json_serializable`.

### 2.2 Расширение интерфейса репозитория

**Файл:** `lib/features/kyc/domain/repositories/i_kyc_repository.dart`

Добавить метод:
```dart
Future<SumsubApplicantEntity> getApplicantData();
```

---

## Часть 3: Flutter — Data Layer

### 3.1 Новый метод в datasource

**Файл:** `lib/features/kyc/data/datasources/kyc_remote_datasource.dart`

```dart
Future<Map<String, dynamic>> getApplicantData() =>
    client.get('/kyc/applicant-data', fromJson: (d) => Map<String, dynamic>.from(d));
```

### 3.2 Реализация в репозитории

**Файл:** `lib/features/kyc/data/repositories/kyc_repository_impl.dart`

Метод `getApplicantData()` с cache-fallback (по аналогии с `getKycStatus()`):
- Вызывает `remote.getApplicantData()`
- Сохраняет в кэш через `cache.saveSumsubData(data)`
- При ошибке сети — возвращает данные из кэша
- Десериализует в `SumsubApplicantEntity.fromJson(data)`

### 3.3 Кэш для Sumsub-данных

**Файл:** `lib/core/storage/cache_service.dart`

- Новый Hive-бокс: `sumsub_cache`
- TTL: 10 минут (600 секунд)
- Методы: `saveSumsubData(Map<String, dynamic>)`, `getSumsubData() → Map?` (с TTL-проверкой)
- Добавить `Hive.openBox('sumsub_cache')` в `init()`
- Добавить очистку в `clearAll()`

---

## Часть 4: Flutter — BLoC (State Management)

### 4.1 Новый event

**Файл:** `lib/features/kyc/presentation/bloc/kyc_event.dart`

```dart
class KycApplicantDataRequested extends KycEvent {}
```

### 4.2 Изменение state

**Файл:** `lib/features/kyc/presentation/bloc/kyc_state.dart`

Добавить поле `applicantData` в `KycStatusLoaded`:
```dart
class KycStatusLoaded extends KycState {
  final String status;
  final String? rejectionReason;
  final String? verifiedAt;
  final SumsubApplicantEntity? applicantData; // НОВОЕ ПОЛЕ

  KycStatusLoaded({
    required this.status,
    this.rejectionReason,
    this.verifiedAt,
    this.applicantData,
  });

  @override
  List<Object?> get props => [status, rejectionReason, verifiedAt, applicantData];
}
```

Новое состояние для загрузки данных (сохраняет статус видимым пока грузятся данные):
```dart
class KycApplicantDataLoading extends KycState {
  final String status;
  final String? verifiedAt;

  KycApplicantDataLoading({required this.status, this.verifiedAt});

  @override
  List<Object?> get props => [status, verifiedAt];
}
```

### 4.3 Обработчик в BLoC

**Файл:** `lib/features/kyc/presentation/bloc/kyc_bloc.dart`

1. Регистрация: `on<KycApplicantDataRequested>(_onApplicantData)`
2. Обработчик `_onApplicantData`:
   - emit `KycApplicantDataLoading(status, verifiedAt)` из текущего стейта
   - `await repo.getApplicantData()`
   - emit `KycStatusLoaded(status, verifiedAt, applicantData: data)`
   - При ошибке: emit `KycError('Не удалось загрузить данные верификации')`
3. Модификация `_onStatus`: при статусе `VERIFIED` автоматически `add(KycApplicantDataRequested())`

**Поток состояний:**
```
KycStatusRequested
  → KycLoading
  → KycStatusLoaded(VERIFIED, applicantData: null)
  → [auto] KycApplicantDataRequested
  → KycApplicantDataLoading(VERIFIED)
  → KycStatusLoaded(VERIFIED, applicantData: {...})
```

---

## Часть 5: Flutter — UI

### 5.1 Новый виджет: `SumsubDataCard`

**Новый файл:** `lib/features/kyc/presentation/widgets/sumsub_data_card.dart`

Принимает `SumsubApplicantEntity`, отображает три секции:

**1. Личные данные** — `AppCard`:
| Поле | Значение |
|------|---------|
| Имя | info.firstName |
| Фамилия | info.lastName |
| Отчество | info.middleName |
| Дата рождения | info.dob (формат DD.MM.YYYY) |
| Место рождения | info.placeOfBirth |
| Гражданство | info.nationality (ISO → название страны) |
| Пол | info.gender (M → Мужской, F → Женский) |

Каждое поле с иконкой ✓ (зелёная) — данные подтверждены Sumsub.

**2. Документы** — `AppCard` со списком `idDocs[]`:
| Поле | Значение |
|------|---------|
| Тип | idDocType (PASSPORT → Паспорт, DRIVING_LICENSE → ВУ, ID_CARD → ID и т.д.) |
| Номер | number |
| ФИО на документе | firstName + lastName |
| Дата выдачи | issuedDate (DD.MM.YYYY) |
| Действителен до | validUntil (DD.MM.YYYY) |
| Кем выдан | issuedBy |
| Страна | country (ISO → название) |

**3. Адреса** — `AppCard` со списком `addresses[]`:
- Форматированный адрес: `улица, дом, кв., город, индекс, страна`

Использует существующие компоненты: `AppCard`, `_infoRow`-паттерн, `AppColors` из `lib/core/theme/`.

### 5.2 Изменение KYC Screen

**Файл:** `lib/features/kyc/presentation/screens/kyc_screen.dart`

В методе `_buildStatus()`, после блока со статусом, при `state.status == 'VERIFIED'`:
- Если `state.applicantData != null` → рендерить `SumsubDataCard(data: state.applicantData!)`
- Кнопка "Обновить данные" → dispatch `KycApplicantDataRequested()`

В `builder` добавить обработку `KycApplicantDataLoading`:
- Показывать карточку статуса (VERIFIED) + `CircularProgressIndicator` вместо данных

---

## Часть 6: Локализация

### `lib/l10n/app_ru.arb` — новые строки:
```json
"verifiedPersonalInfo": "Подтверждённые данные",
"middleName": "Отчество",
"placeOfBirth": "Место рождения",
"nationality": "Гражданство",
"gender": "Пол",
"genderMale": "Мужской",
"genderFemale": "Женский",
"docNumber": "Номер",
"docIssuedDate": "Дата выдачи",
"docValidUntil": "Действителен до",
"docIssuedBy": "Кем выдан",
"address": "Адрес",
"refreshData": "Обновить данные",
"failedToLoadSumsubData": "Не удалось загрузить данные верификации",
"sumsubDataLoading": "Загрузка данных верификации...",
"reviewResultGreen": "Проверка пройдена",
"reviewResultRed": "Проверка не пройдена"
```

### `lib/l10n/app_en.arb` — аналогичные строки:
```json
"verifiedPersonalInfo": "Verified Data",
"middleName": "Middle Name",
"placeOfBirth": "Place of Birth",
"nationality": "Nationality",
"gender": "Gender",
"genderMale": "Male",
"genderFemale": "Female",
"docNumber": "Number",
"docIssuedDate": "Issued",
"docValidUntil": "Valid Until",
"docIssuedBy": "Issued By",
"address": "Address",
"refreshData": "Refresh Data",
"failedToLoadSumsubData": "Failed to load verification data",
"sumsubDataLoading": "Loading verification data...",
"reviewResultGreen": "Verification passed",
"reviewResultRed": "Verification failed"
```

---

## Сводка по файлам

### Новые (2):
| Файл | Описание |
|------|---------|
| `lib/features/kyc/domain/entities/sumsub_applicant_entity.dart` | Freezed-сущность с вложенными типами |
| `lib/features/kyc/presentation/widgets/sumsub_data_card.dart` | Виджет отображения данных |

### Изменяемые (10):
| Файл | Изменение |
|------|---------|
| `lib/features/kyc/data/datasources/kyc_remote_datasource.dart` | +1 метод `getApplicantData()` |
| `lib/features/kyc/domain/repositories/i_kyc_repository.dart` | +1 метод в интерфейсе |
| `lib/features/kyc/data/repositories/kyc_repository_impl.dart` | +1 метод реализации с кэшем |
| `lib/core/storage/cache_service.dart` | +1 Hive-бокс, +2 метода, обновление clearAll |
| `lib/features/kyc/presentation/bloc/kyc_event.dart` | +1 event класс |
| `lib/features/kyc/presentation/bloc/kyc_state.dart` | Изменение KycStatusLoaded, +1 state класс |
| `lib/features/kyc/presentation/bloc/kyc_bloc.dart` | +1 handler, модификация _onStatus |
| `lib/features/kyc/presentation/screens/kyc_screen.dart` | Секция данных + кнопка обновления |
| `lib/l10n/app_ru.arb` | ~15 строк локализации |
| `lib/l10n/app_en.arb` | ~15 строк локализации |

### Генерируемые (build_runner):
- `sumsub_applicant_entity.freezed.dart`
- `sumsub_applicant_entity.g.dart`

---

## Порядок реализации

1. **Backend**: реализовать `GET /kyc/applicant-data` на `id.taler.tirol`
2. **Domain**: создать `sumsub_applicant_entity.dart` → `dart run build_runner build`
3. **Data**: расширить datasource, interface, repository, cache
4. **BLoC**: добавить event, изменить state, добавить handler + авто-загрузку
5. **UI**: создать `SumsubDataCard`, обновить `kyc_screen.dart`
6. **i18n**: добавить строки локализации
7. **Тестирование**

---

## Проверка

1. **Backend**: `curl -H 'Authorization: Bearer <jwt>' https://id.taler.tirol/kyc/applicant-data` → JSON с данными аппликанта
2. **Авто-загрузка**: открыть KYC-экран при статусе VERIFIED → данные загружаются автоматически → отображаются карточки ФИО, документов, адреса
3. **Ручное обновление**: кнопка "Обновить данные" → повторный запрос → обновление карточек
4. **Оффлайн**: закэшированные данные отображаются при отсутствии сети (TTL 10 мин)
5. **Не верифицирован**: при статусе UNVERIFIED/PENDING/REJECTED секция данных не показывается

---

## Предпосылки

- Бэкенд `id.taler.tirol` должен реализовать `GET /kyc/applicant-data` (описание контракта выше)
- Sumsub API credentials (App Token + Secret Key) уже настроены на бэкенде
- Sumsub applicantId сохраняется в БД при вызове `/kyc/start`
