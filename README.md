# Kernelly

Мобильное Duolingo-подобное приложение для изучения программирования, Linux, DevOps и других
IT-тем: короткие уроки с интерактивными упражнениями, streak, XP, достижения и социальные фичи
(подписки, лента, сравнение активности с друзьями).

## Стек

- **Backend** — FastAPI + PostgreSQL + SQLAlchemy
- **Mobile** — Flutter (Dart ≥ 3.12)
- **Auth** — device-token (Bearer) для гостей, опционально Google Sign-In со слиянием прогресса
- **Deploy** — Docker (`docker/`) на проде, локально бэкенд удобнее гонять напрямую через uvicorn

## Структура репозитория

```
backend/    FastAPI-приложение (app/), сиды демо-контента (seeds/), venv в backend/venv
mobile/     Flutter-приложение: lib/screens, lib/services, lib/widgets
docker/     Dockerfile и docker-compose для backend + postgres (продовый деплой)
design/     HTML-макеты экранов (kernelly-standalone-src.html — основной, 5 экранов)
```

## Быстрый старт

### Backend

```bash
cd backend
python -m venv venv
venv/Scripts/python.exe -m pip install -r requirements.txt   # Windows; на Linux/macOS venv/bin/python
```

Создать `backend/.env` с адресом БД:

```
DATABASE_URL=postgresql://your_username:your_password@localhost:5432/kernelly
```

Запуск (таблицы создаются автоматически при старте):

```bash
venv/Scripts/python.exe -m uvicorn app.main:app --reload
```

Наполнить демо-контентом (курсы/уроки/упражнения; можно запускать повторно — идемпотентно):

```bash
venv/Scripts/python.exe -m seeds.seed_demo
```

### Mobile

```bash
cd mobile
flutter pub get
flutter run
```

По умолчанию мобильное приложение обращается к `http://127.0.0.1:8000` (или `10.0.2.2:8000` для
Android-эмулятора). Для реального устройства/удалённого бэкенда указать адрес через:

```bash
flutter run --dart-define=API_BASE_URL=https://your-backend-host
```

### Продовый деплой (Docker)

```bash
cd docker
docker compose up -d
```

Требует `.env` рядом с `docker-compose.yml` с `POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_DB`,
`DOCKERHUB_USERNAME`, `TAG`. CI пушит образ бэкенда автоматически при изменениях в `backend/**`;
`Base.metadata.create_all` создаёт только новые таблицы — изменения существующих требуют ручного
`ALTER TABLE` на сервере.

## Модель данных

`Course → Section → Lesson → Exercise` — основной контент, плюс `User`, `UserProgress`, `Answer`,
`SkillProgress` (интервальные повторения), `LessonMastery` (уровни мастерства урока), `Follow`
(подписки), `Post` (лента), `AchievementUnlock`. Блокировка курсов — через `required_course_id` +
`required_percent` и `is_coming_soon`.

## Авторизация

Каждое устройство генерирует случайный `device_token`, который сервер резолвит в пользователя
(гостя или Google-аккаунт) и который передаётся как `Authorization: Bearer <device_token>` в
каждом запросе, кроме `POST /users/guest` и `POST /auth/google`. Приватные поля (email, телефон,
настройки streak-shield) отдаются только владельцу аккаунта; чужой профиль/статистику/достижения
смотреть можно, но без личных данных. Чувствительные к перебору эндпоинты (`/users/guest`,
`/auth/google`, `/users/search`, `/contacts-match`) ограничены по частоте запросов.

Контакты из телефонной книги пользователя **не сохраняются на сервере** — сверка с уже
зарегистрированными (по опциональному полю телефона в профиле) происходит только в рамках
одного запроса.

## Известные ограничения

См. раздел «Что не реализовано» в [CLAUDE.md](CLAUDE.md) — там же живут все конвенции разработки,
дизайн-система (цвета/шрифты/иконки) и детали, важные при внесении изменений.
