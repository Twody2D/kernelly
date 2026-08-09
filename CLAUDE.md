# Kernelly

Мобильное Duolingo-подобное приложение для изучения программирования, Linux, DevOps и IT-тем.

## Структура

- `backend/` — FastAPI + PostgreSQL + SQLAlchemy, venv в `backend/venv`
- `mobile/` — Flutter, структура `lib/screens`, `lib/services`, `lib/widgets`
- `docker/` — Dockerfile и compose для backend+postgres (DevOps-этап)
- `design/` — HTML-макеты экранов (`kernelly-standalone-src.html` — основной, 5 экранов)
- `.env` в `backend/` — DATABASE_URL, пароли не хардкодить

## Запуск

Для разработки используется **локальный uvicorn, а не контейнер** — чтобы не было конфликта портов 8000/5432:

```bash
cd backend && venv/Scripts/python.exe -m uvicorn app.main:app --reload
cd mobile && flutter run
```

Наполнение демо-контентом (идемпотентно): `venv/Scripts/python.exe -m seeds.seed_demo`

CI/CD: push в `backend/**` автоматически передеплоивает прод. `Base.metadata.create_all` создаёт
только новые таблицы — изменения существующих требуют ручного `ALTER TABLE` на сервере.

## Соглашения

- Коммиты делает пользователь сам. Предлагать **однострочные** Conventional Commits и всегда
  указывать, какие файлы входят в каждый коммит (см. память проекта).
- Объяснять, что делается и почему — пользователь учится по ходу.
- Работать микрозадачами: один экран / одна проблема за раз, с остановкой на коммит.
- После правок фронта прогонять `flutter analyze lib`.

## Дизайн-система (не менять без явного запроса)

Цвета: бирюзовый `#00C9B7` / тёмный `#00A896`, фон `#F6F9F9`, текст `#1B2430` / второстепенный
`#5C6B73`, успех `#58CC02` / фон `#EAF9DC`, ошибка `#FF4B4B` / фон `#FFEAEA`, streak `#FF9500`,
звёзды `#FFD98A`, заблокировано `#C2CDCD` / фон `#E7EEEE`.

Шрифты подключены **локально** через `pubspec.yaml` как семейства `Fredoka`, `JetBrains Mono`,
`Inter`. Использовать `TextStyle(fontFamily: ...)`, **не** пакет `google_fonts` — он грузит шрифты
асинхронно и вызывает мигание текста.

Иконки — только `Icons.*`. Текстовые глифы (`✓`, `◎`) моргают при первой отрисовке, так как
отсутствуют в подключённых шрифтах.

Макеты рисовались под ширину 360px. На широких экранах контент ограничивать `maxWidth: 420`.

## Данные

`Course → Section → Lesson → Exercise`, плюс `User`, `UserProgress`, `Answer`, `SkillProgress`
(интервальные повторения), `LessonMastery` (уровни мастерства урока), `Follow` (подписки),
`Post` (лента), `AchievementUnlock`.
Блокировка курсов — через `required_course_id` + `required_percent` и `is_coming_soon`.

Выбор курса в онбординге (и потом в Настройки → Курсы) сохраняется локально как
`PrefKeys.selectedCourseId` и передаётся в `GET /users/{id}/current-section` как
`preferred_course_id` — сервер выводит его вперёд остальных, если он не заблокирован.
Не персистится в БД — это чисто клиентское предпочтение.

**Авторизация — реальная, через `device_token`.** Каждое устройство генерирует случайный токен
(`Random.secure()`, `lib/services/user_prefs.dart`), сервер находит/заводит по нему гостя
(`POST /users/guest`) или привязывает Google-аккаунт (`POST /auth/google`). Дальше токен передаётся
как `Authorization: Bearer <device_token>` в **каждом** запросе — это единственные два эндпоинта
без него. Бэкенд резолвит его в `get_current_user` (`backend/app/main.py`) и почти везде вызывает
`_require_self(current_user, user_id)`, где `user_id` — это «от чьего лица» запрос (действующий
пользователь), а не произвольная просматриваемая цель (чужой профиль/статистику смотреть можно).
Приватные поля (email, телефон, настройки streak-shield) отдаются только себе.
`POST /users/{id}/rotate-token` обесценивает старый токен, если он мог утечь.

На чувствительные к перебору эндпоинты (`/users/guest`, `/auth/google`, `/users/search`,
`/contacts-match`) навешан in-memory rate limit (`rate_limit()` в `main.py`), плюс щедрый общий
лимит на все запросы через middleware.

Номер телефона в профиле — опциональный, нужен только для поиска друзей по контактам
(`/contacts-match`); контакты из телефонной книги пользователя **не сохраняются**, сверка
происходит только «на лету» в рамках одного запроса.

Игровая валюта — «ядра» (`User.cores`). Сундуки за золото на уроке, завершение курса и
ежедневный вход (`POST /users/{id}/daily-login-chest`) начисляются сразу на сервере — сумма уже
известна, `chest_reward_screen.dart` (`showChestRewards`) только показывает анимацию открытия
по тапу. Сундук за достижение — иначе: сумма НЕ начисляется при разблокировке (`chest_claimed`
у `AchievementUnlock` = False), а только когда пользователь сам открывает его в профиле
(`POST /users/{id}/achievements/{code}/claim-chest`, `showClaimableChestReward` — тап на сундук
сам вызывает claim).

**Достижения — 4 семьи × 5 уровней** (бронза/серебро/золото/алмаз/бедрок; `ACHIEVEMENT_FAMILIES`/
`ACHIEVEMENT_LEVELS` в `main.py`): streak (3/14/30/60/100 дней), XP (100/500/1000/2500/5000),
уроки (5/10/25/50/100), точность — **не** % правильных ответов за всё время, а число уроков,
пройденных со 100% точностью (`User.perfect_lessons_count`, инкрементируется в `complete_lesson`
по параметру `perfect`, который считает клиент — все упражнения решены с первой попытки).
Код разблокировки — `{family}_{level}`, например `streak_3`. Ядра за уровень растут
(`CORES_BY_LEVEL`). На максимальном уровне `description` в ответе `/achievements` — «Получено:
…, текущий счёт: N», а не следующий порог. Неоткрытые сундуки помечены «NEW» на бейдже
(`profile_screen.dart`, `achievements_catalog_screen.dart`) — поля `chest_claimed`/
`has_unclaimed_chest`/`next_unclaimed_code` в ответе `/achievements` есть только при просмотре
своего профиля. Переход со старой плоской системы (24 отдельных достижения) — одноразовый
скрипт `seeds/migrate_achievements_v2.py`, пересчитывает всех пользователей по новым порогам
и помечает уже пройденные уровни как `chest_claimed=True` (без повторной выдачи ядер).

Заряды защиты streak (`streak_freezes`) пополняются автоматически раз в неделю и их можно
докупить за ядра (`POST /users/{id}/streak-freezes/purchase`, `MAX_STREAK_FREEZES`/
`STREAK_FREEZE_PRICE_CORES` в `main.py`) — до максимума.

Локальные настройки (`SharedPreferences`) — ключи и цели в `lib/services/user_prefs.dart`.

## Что не реализовано

- Тёмная тема работает не везде: система (`ThemeController`, `AppTheme.light/dark`) реализована,
  но часть экранов ещё на захардкоженных цветах вместо `context.colors` и не меняется при переключении
- Автоопределение номера телефона (`lib/services/device_phone.dart`) работает только на Android
  и не на всех устройствах/операторах — это ожидаемо, не баг
- HTTPS на проде и CORS (`allow_origins=["*"]`) — не проверено/не закрыто, деплой сейчас не активен
