from fastapi import FastAPI, Depends, HTTPException, Header, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from google.auth.transport import requests as google_requests
from google.oauth2 import id_token as google_id_token
from sqlalchemy import func
from sqlalchemy.orm import Session
from app.database import Base, engine, get_db
from app import models, schemas
from datetime import date, datetime, timedelta
from collections import defaultdict, deque
import random
import secrets
import time

def _today() -> date:
    """«Сегодня» строго в UTC — все timestamp-колонки (created_at,
    completed_at) пишутся через datetime.utcnow(), а date.today() отдаёт
    локальную дату сервера. На проде и локально это разные часовые пояса,
    так что сравнение с date.today() иногда «теряло» только что пройденный
    урок из дневной цели, пока не наступит локальная полночь по UTC."""
    return datetime.utcnow().date()


XP_PER_CORRECT = 10

# Игровая валюта «ядра» — выдаётся сундуками (см. _award_cores и точки
# начисления ниже), тратится на покупку заморозок streak.
CORES_GOLD_LESSON = (5, 15)
CORES_COURSE_COMPLETE = (40, 80)
CORES_DAILY_LOGIN = (3, 8)
# Ядра за достижения зависят от уровня (бронза..бедрок) — см. CORES_BY_LEVEL ниже.

MAX_STREAK_FREEZES = 3
STREAK_FREEZE_PRICE_CORES = 40

# Ядра за топ-3 места в еженедельной лиге (см. _finalize_league_week).
LEAGUE_REWARD_CORES = {1: (80, 120), 2: (50, 80), 3: (25, 45)}

# Ежедневные квесты — сбрасываются сами по себе, т.к. прогресс каждого
# считается «за сегодня» по Answer/UserProgress (см. _daily_quest_progress),
# без отдельного крон-сброса. target в answers/xp — количество ВЕРНЫХ
# ответов за сегодня либо производное от него (XP = ответы * XP_PER_CORRECT).
DAILY_QUESTS = [
    {"code": "quest_answers", "title": "Реши 5 упражнений", "metric": "answers", "target": 5, "cores": (5, 8)},
    {"code": "quest_lesson", "title": "Пройди урок", "metric": "lessons", "target": 1, "cores": (8, 15)},
    {"code": "quest_xp", "title": "Заработай 100 XP", "metric": "xp", "target": 100, "cores": (10, 18)},
]


def _daily_quest_progress(db: Session, user_id: int, today: date) -> dict[str, int]:
    correct_today = (
        db.query(models.Answer)
        .filter(
            models.Answer.user_id == user_id,
            models.Answer.is_correct.is_(True),
            func.date(models.Answer.created_at) == today,
        )
        .count()
    )
    lessons_today = (
        db.query(models.UserProgress)
        .filter(
            models.UserProgress.user_id == user_id,
            func.date(models.UserProgress.completed_at) == today,
        )
        .count()
    )
    return {"answers": correct_today, "lessons": lessons_today, "xp": correct_today * XP_PER_CORRECT}


def _msk_week_start(dt: datetime) -> date:
    """Понедельник 00:00 по МСК (UTC+3), которому принадлежит момент dt
    (naive datetime в UTC, как и все остальные timestamp в проекте)."""
    msk = dt + timedelta(hours=3)
    monday_msk = msk - timedelta(days=msk.weekday())
    return monday_msk.date()


def _week_start_to_utc(week_start_msk: date) -> datetime:
    return datetime(week_start_msk.year, week_start_msk.month, week_start_msk.day) - timedelta(hours=3)


def _finalize_league_week(db: Session) -> None:
    """Вызывается перед каждым чтением топа игроков. Если с прошлого раза
    наступил новый понедельник по МСК — подводит итог только что закончившейся
    недели (топ-3 по XP получают LeagueResult, сундук открывается вручную —
    см. AchievementUnlock.chest_claimed) и сдвигает окно живого топа на новую
    неделю. При гонке параллельных запросов возможна редкая двойная попытка
    записи итогов — эта ветка защищена уникальным (user_id, week_start) и
    просто больше ничего не сделает при повторе, поэтому не критично."""
    current_week = _msk_week_start(datetime.utcnow())
    state = db.query(models.LeaderboardState).first()
    if state is None:
        db.add(models.LeaderboardState(week_start=current_week))
        db.commit()
        return
    if state.week_start >= current_week:
        return

    prev_start_utc = _week_start_to_utc(state.week_start)
    prev_end_utc = prev_start_utc + timedelta(days=7)
    rows = (
        db.query(models.Answer.user_id, func.count(models.Answer.id).label("correct"))
        .filter(
            models.Answer.is_correct.is_(True),
            models.Answer.created_at >= prev_start_utc,
            models.Answer.created_at < prev_end_utc,
        )
        .group_by(models.Answer.user_id)
        .all()
    )
    ranked = sorted(rows, key=lambda r: r.correct, reverse=True)[:3]
    for i, row in enumerate(ranked):
        if row.correct <= 0:
            continue
        rank = i + 1
        exists = (
            db.query(models.LeagueResult)
            .filter(
                models.LeagueResult.user_id == row.user_id,
                models.LeagueResult.week_start == state.week_start,
            )
            .first()
        )
        if exists is not None:
            continue
        amount = random.randint(*LEAGUE_REWARD_CORES[rank])
        db.add(
            models.LeagueResult(
                user_id=row.user_id,
                week_start=state.week_start,
                rank=rank,
                cores=amount,
                chest_claimed=False,
            )
        )

    state.week_start = current_week
    db.commit()


def _award_cores(user: models.User, low: int, high: int) -> int:
    amount = random.randint(low, high)
    user.cores += amount
    return amount

# Алгоритм Лейтнера: box → через сколько дней повторять. Правильный ответ по
# тегу навыка поднимает его на box выше (интервал растёт), неправильный
# сбрасывает в box 1 — «повторить завтра». MAX_BOX ограничивает верхнюю границу.
REVIEW_INTERVALS_DAYS = {1: 1, 2: 3, 3: 7, 4: 16, 5: 35}
MAX_BOX = max(REVIEW_INTERVALS_DAYS)
REVIEW_SESSION_SIZE = 12

# Мастерство урока: каждое успешное прохождение поднимает уровень (1=бронза,
# 2=серебро, 3=золото), а следующая попытка подтягивает контент на уровень
# сложнее — MAX_MASTERY ограничивает и уровень, и сложность контента сверху.
MAX_MASTERY = 3


def _lesson_mastery(db: Session, user_id: int, lesson_id: int) -> int:
    row = (
        db.query(models.LessonMastery)
        .filter(models.LessonMastery.user_id == user_id, models.LessonMastery.lesson_id == lesson_id)
        .first()
    )
    return min(row.completions, MAX_MASTERY) if row else 0


def _normalize_terminal_answer(value: str) -> str:
    value = value.strip()
    if value.startswith("$"):
        value = value[1:].strip()
    return " ".join(value.lower().split())


def _is_close_terminal_answer(submitted: dict, correct: dict) -> bool:
    """Реальный терминал чувствителен к регистру, поэтому `Whoami` всё же
    неверно — но стоит явно подсказать, что дело именно в написании, а не в
    том, что команда выбрана не та."""
    submitted_answer = submitted.get("answer") if isinstance(submitted, dict) else None
    correct_answer = correct.get("answer") if isinstance(correct, dict) else None
    if not isinstance(submitted_answer, str) or not isinstance(correct_answer, str):
        return False
    return _normalize_terminal_answer(submitted_answer) == _normalize_terminal_answer(correct_answer)


def _update_skill_progress(db: Session, user_id: int, skill_tags: list[str] | None, is_correct: bool) -> None:
    if not skill_tags:
        return
    now = datetime.utcnow()
    for tag in skill_tags:
        progress = (
            db.query(models.SkillProgress)
            .filter(models.SkillProgress.user_id == user_id, models.SkillProgress.skill_tag == tag)
            .first()
        )
        if progress is None:
            progress = models.SkillProgress(user_id=user_id, skill_tag=tag, box=1)
            db.add(progress)

        progress.box = min(progress.box + 1, MAX_BOX) if is_correct else 1
        progress.next_review_at = now + timedelta(days=REVIEW_INTERVALS_DAYS[progress.box])

# Client ID не секретны (зашиты в приложение), поэтому спокойно живут в коде.
# Три штуки — по одной на платформу, но токен, пришедший от любой из них, валиден.
GOOGLE_CLIENT_IDS = {
    "969523130284-iu9vl4pc3r3rv2n3gcprn7uf2uskgc6t.apps.googleusercontent.com",  # web
    "969523130284-rd0mvtnkq186ffg2uc61e8ij4545nv10.apps.googleusercontent.com",  # ios
    "969523130284-i04jjpc4jlmon85eeosmqljpp86pr7bl.apps.googleusercontent.com",  # android
}
_google_request = google_requests.Request()


def get_current_user(authorization: str | None = Header(None), db: Session = Depends(get_db)) -> models.User:
    """Раньше почти все эндпоинты принимали user_id прямо от клиента и ничего
    не проверяли — любой мог подставить чужой id и читать/менять чужие данные
    (IDOR). Теперь device_token — который и так уникален и выдаётся один раз
    на пользователя при /users/guest или /auth/google — передаётся как
    Bearer-токен и подтверждает, кто на самом деле делает запрос."""
    if not authorization or not authorization.lower().startswith("bearer "):
        raise HTTPException(status_code=401, detail="Missing bearer token")
    token = authorization[7:].strip()
    if not token:
        raise HTTPException(status_code=401, detail="Missing bearer token")
    user = db.query(models.User).filter(models.User.device_token == token).first()
    if user is None:
        raise HTTPException(status_code=401, detail="Invalid token")

    # Троттлинг: пишем last_seen_at не чаще раза в минуту на пользователя,
    # иначе каждый запрос от активного клиента бил бы в БД.
    now = datetime.utcnow()
    if user.last_seen_at is None or now - user.last_seen_at > timedelta(minutes=1):
        user.last_seen_at = now
        db.commit()

    return user


ONLINE_WINDOW = timedelta(minutes=5)


def _is_online(user: models.User) -> bool:
    return user.last_seen_at is not None and datetime.utcnow() - user.last_seen_at < ONLINE_WINDOW


def _require_self(current_user: models.User, user_id: int) -> None:
    """Для эндпоинтов, где user_id в пути/параметре — это тот, от чьего лица
    делается запрос (не произвольная просматриваемая цель)."""
    if current_user.id != user_id:
        raise HTTPException(status_code=403, detail="Forbidden")


class _RateLimiter:
    """Примитивный лимитер на скользящем окне в памяти процесса — этого
    достаточно, пока бэкенд крутится одним процессом uvicorn (как сейчас),
    но не переживёт несколько воркеров/инстансов без общего хранилища вроде
    Redis. До этой правки ни один эндпоинт вообще не был ограничен по частоте —
    /users/guest можно было дёргать в цикле и штамповать гостевые аккаунты,
    а /auth/google, поиск и сверку контактов — перебирать без всякого лимита."""

    def __init__(self):
        self._hits: dict[str, deque] = defaultdict(deque)

    def hit(self, key: str, limit: int, window_seconds: float) -> bool:
        now = time.monotonic()
        q = self._hits[key]
        while q and now - q[0] > window_seconds:
            q.popleft()
        if len(q) >= limit:
            return False
        q.append(now)
        return True


_rate_limiter = _RateLimiter()


def rate_limit(limit: int, window_seconds: float):
    """Depends-фабрика для точечного лимита поверх общего лимита из middleware —
    чувствительные к перебору ручки (регистрация гостя, вход, поиск людей,
    сверка контактов) ограничены сильнее, чем обычное чтение экранов."""

    def dependency(request: Request):
        client_ip = request.client.host if request.client else "unknown"
        key = f"{request.url.path}:{client_ip}"
        if not _rate_limiter.hit(key, limit, window_seconds):
            raise HTTPException(status_code=429, detail="Слишком много запросов, попробуйте позже")

    return dependency


app = FastAPI() #test backend

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.middleware("http")
async def _global_rate_limit(request: Request, call_next):
    """Общий предохранитель от скриптового перебора по всему API — щедрый
    лимит, не мешающий обычному использованию (несколько экранов дёргают
    бэкенд параллельно), но режущий явный DoS/брутфорс."""
    client_ip = request.client.host if request.client else "unknown"
    if not _rate_limiter.hit(f"global:{client_ip}", 240, 60):
        return JSONResponse(status_code=429, content={"detail": "Слишком много запросов, попробуйте позже"})
    return await call_next(request)


Base.metadata.create_all(bind=engine)


@app.get("/")
def read_root():
    return {"status": "Kernelly API is running"}


@app.get("/courses", response_model=list[schemas.CourseOut])
def get_courses(db: Session = Depends(get_db), current_user: models.User = Depends(get_current_user)):
    return db.query(models.Course).all()


@app.post("/courses", response_model=schemas.CourseOut)
def create_course(
    course: schemas.CourseCreate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    new_course = models.Course(title=course.title, description=course.description)
    db.add(new_course)
    db.commit()
    db.refresh(new_course)
    return new_course


@app.get("/sections", response_model=list[schemas.SectionOut])
def get_sections(db: Session = Depends(get_db), current_user: models.User = Depends(get_current_user)):
    return db.query(models.Section).all()


@app.post("/sections", response_model=schemas.SectionOut)
def create_section(
    section: schemas.SectionCreate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    new_section = models.Section(
        title=section.title,
        order=section.order,
        course_id=section.course_id,
    )
    db.add(new_section)
    db.commit()
    db.refresh(new_section)
    return new_section


@app.get("/lessons", response_model=list[schemas.LessonOut])
def get_lessons(db: Session = Depends(get_db), current_user: models.User = Depends(get_current_user)):
    return db.query(models.Lesson).all()


@app.post("/lessons", response_model=schemas.LessonOut)
def create_lesson(
    lesson: schemas.LessonCreate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    new_lesson = models.Lesson(
        title=lesson.title,
        order=lesson.order,
        section_id=lesson.section_id,
    )
    db.add(new_lesson)
    db.commit()
    db.refresh(new_lesson)
    return new_lesson


@app.get("/exercises", response_model=list[schemas.ExerciseOut])
def get_exercises(db: Session = Depends(get_db), current_user: models.User = Depends(get_current_user)):
    return db.query(models.Exercise).all()


@app.post("/exercises", response_model=schemas.ExerciseOut)
def create_exercise(
    exercise: schemas.ExerciseCreate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    new_exercise = models.Exercise(
        type=exercise.type,
        question=exercise.question,
        content=exercise.content,
        correct_answer=exercise.correct_answer,
        order=exercise.order,
        lesson_id=exercise.lesson_id,
    )
    db.add(new_exercise)
    db.commit()
    db.refresh(new_exercise)
    return new_exercise


@app.get("/users/search", dependencies=[Depends(rate_limit(30, 60))])
def search_users(
    q: str,
    user_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    """Литеральный путь должен быть объявлен раньше /users/{user_id} —
    иначе FastAPI пытается распарсить "search" как user_id и падает в 422.
    user_id — это тот, от чьего лица ищем (влияет на исключение себя из
    результатов и на is_following), поэтому обязан совпадать с токеном."""
    _require_self(current_user, user_id)

    query = q.strip()
    if len(query) < 2:
        return []

    matches = (
        db.query(models.User)
        .filter(models.User.username.ilike(f"%{query}%"), models.User.id != user_id)
        .limit(20)
        .all()
    )
    following_ids = {
        row.followee_id for row in db.query(models.Follow).filter(models.Follow.follower_id == user_id).all()
    }
    return [
        {"id": u.id, "username": u.username, "avatar": u.avatar, "is_following": u.id in following_ids}
        for u in matches
    ]


@app.get("/users/{user_id}", response_model=schemas.UserOut)
def get_user(
    user_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    """Отдаёт email и телефон, поэтому доступен только самому пользователю —
    иначе это была бы утечка контактных данных всей базы по перебору id."""
    _require_self(current_user, user_id)
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if user is None:
        raise HTTPException(status_code=404, detail="User not found")
    return user


@app.post("/users", response_model=schemas.UserOut)
def create_user(
    user: schemas.UserCreate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    new_user = models.User(username=user.username)
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    return new_user


@app.post("/users/guest", response_model=schemas.UserOut, dependencies=[Depends(rate_limit(10, 60))])
def get_or_create_guest(guest: schemas.GuestCreate, db: Session = Depends(get_db)):
    """Находит гостя по device_token или заводит нового — вызывается при каждом
    старте приложения, до того как экраны начнут запрашивать данные пользователя."""
    user = db.query(models.User).filter(models.User.device_token == guest.device_token).first()
    if user is None:
        user = models.User(device_token=guest.device_token, auth_provider="guest")
        db.add(user)
        db.commit()
        db.refresh(user)
    return user


def _merge_guest_into_account(db: Session, guest_user: models.User, target_user: models.User) -> None:
    """Переносит прогресс гостя на аккаунт, с которым он логинится: уроки без
    дублей, все ответы, XP суммируется, streak — больший из двух, дата
    активности — более свежая. Гостевая запись удаляется."""
    existing_lesson_ids = {
        row.lesson_id
        for row in db.query(models.UserProgress.lesson_id).filter(models.UserProgress.user_id == target_user.id)
    }
    for progress in db.query(models.UserProgress).filter(models.UserProgress.user_id == guest_user.id).all():
        if progress.lesson_id in existing_lesson_ids:
            db.delete(progress)
        else:
            progress.user_id = target_user.id
            existing_lesson_ids.add(progress.lesson_id)

    db.query(models.Answer).filter(models.Answer.user_id == guest_user.id).update(
        {"user_id": target_user.id}, synchronize_session=False
    )

    target_user.xp += guest_user.xp
    target_user.streak = max(target_user.streak, guest_user.streak)
    if guest_user.last_activity_date and (
        target_user.last_activity_date is None or guest_user.last_activity_date > target_user.last_activity_date
    ):
        target_user.last_activity_date = guest_user.last_activity_date

    db.delete(guest_user)
    db.flush()  # физически убрать гостя до того, как его device_token достанется target_user


@app.post("/auth/google", response_model=schemas.UserOut, dependencies=[Depends(rate_limit(10, 60))])
def google_sign_in(payload: schemas.GoogleSignIn, db: Session = Depends(get_db)):
    try:
        idinfo = google_id_token.verify_oauth2_token(payload.id_token, _google_request)
    except ValueError:
        raise HTTPException(status_code=401, detail="Invalid Google token")

    if idinfo.get("aud") not in GOOGLE_CLIENT_IDS:
        raise HTTPException(status_code=401, detail="Invalid Google token")

    external_id = idinfo["sub"]
    email = idinfo.get("email")

    google_user = (
        db.query(models.User)
        .filter(models.User.auth_provider == "google", models.User.external_id == external_id)
        .first()
    )

    device_owner = db.query(models.User).filter(models.User.device_token == payload.device_token).first()
    mergeable_guest = device_owner if device_owner is not None and device_owner.auth_provider == "guest" else None

    if google_user is None:
        if mergeable_guest is not None:
            # первый вход этим Google-аккаунтом на этом устройстве — повышаем гостя до аккаунта.
            # username/avatar остаются пустыми — клиент увидит avatar=null и предложит их выбрать
            mergeable_guest.auth_provider = "google"
            mergeable_guest.external_id = external_id
            mergeable_guest.email = email
            db.commit()
            db.refresh(mergeable_guest)
            return mergeable_guest

        google_user = models.User(
            auth_provider="google",
            external_id=external_id,
            email=email,
            device_token=payload.device_token if device_owner is None else None,
        )
        db.add(google_user)
        db.commit()
        db.refresh(google_user)
        return google_user

    # аккаунт уже существует (вход с нового устройства) — переносим на него прогресс гостя
    if mergeable_guest is not None and mergeable_guest.id != google_user.id:
        _merge_guest_into_account(db, mergeable_guest, google_user)
        google_user.device_token = payload.device_token

    google_user.email = email
    db.commit()
    db.refresh(google_user)
    return google_user


ALLOWED_AVATARS = {"terminal", "code", "bug", "rocket", "bolt", "shield", "flame", "star"}


@app.patch("/users/{user_id}/profile", response_model=schemas.UserOut)
def update_profile(
    user_id: int,
    payload: schemas.ProfileUpdate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    """Имя и аватарка, которые выбираются один раз после первого входа через Google."""
    _require_self(current_user, user_id)
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if user is None:
        raise HTTPException(status_code=404, detail="User not found")

    username = payload.username.strip()
    if not username:
        raise HTTPException(status_code=422, detail="Имя не может быть пустым")

    if payload.avatar not in ALLOWED_AVATARS:
        raise HTTPException(status_code=422, detail="Неизвестная аватарка")

    conflict = (
        db.query(models.User)
        .filter(models.User.username == username, models.User.id != user_id)
        .first()
    )
    if conflict is not None:
        raise HTTPException(status_code=409, detail="Это имя уже занято")

    user.username = username
    user.avatar = payload.avatar
    db.commit()
    db.refresh(user)
    return user


@app.patch("/users/{user_id}/streak-shield")
def update_streak_shield(
    user_id: int,
    payload: schemas.StreakShieldUpdate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    """Синхронизирует локальный тумблер «Защита streak» с бэкендом — сама
    логика заморозки применяется в submit_answer."""
    _require_self(current_user, user_id)
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if user is None:
        raise HTTPException(status_code=404, detail="User not found")

    user.streak_shield_enabled = payload.enabled
    db.commit()
    return {"streak_shield_enabled": user.streak_shield_enabled, "streak_freezes": user.streak_freezes}


@app.post("/users/{user_id}/streak-freezes/purchase")
def purchase_streak_freeze(
    user_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    """Докупить заряд защиты streak за ядра, не дожидаясь еженедельного
    пополнения (см. submit_answer) — ограничено ценой и максимумом зарядов."""
    _require_self(current_user, user_id)
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if user is None:
        raise HTTPException(status_code=404, detail="User not found")

    if user.streak_freezes >= MAX_STREAK_FREEZES:
        raise HTTPException(status_code=409, detail="Уже максимум зарядов")
    if user.cores < STREAK_FREEZE_PRICE_CORES:
        raise HTTPException(status_code=402, detail="Недостаточно ядер")

    user.cores -= STREAK_FREEZE_PRICE_CORES
    user.streak_freezes += 1
    db.commit()
    return {"cores": user.cores, "streak_freezes": user.streak_freezes}


@app.post("/users/{user_id}/daily-login-chest")
def claim_daily_login_chest(
    user_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    """Один сундук в день просто за то, что открыл приложение — не зависит от
    прохождения уроков, поэтому отдельное поле даты, а не last_activity_date
    (тот засчитывается только за верный ответ, см. submit_answer)."""
    _require_self(current_user, user_id)
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if user is None:
        raise HTTPException(status_code=404, detail="User not found")

    today = _today()
    if user.last_chest_login_date == today:
        return {"awarded": False, "amount": 0, "cores": user.cores}

    amount = _award_cores(user, *CORES_DAILY_LOGIN)
    user.last_chest_login_date = today
    db.commit()
    return {"awarded": True, "amount": amount, "cores": user.cores}


@app.post("/users/{user_id}/achievements/{code}/claim-chest")
def claim_achievement_chest(
    user_id: int,
    code: str,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    """Сундук за достижение открывается вручную в профиле (см. chest_claimed
    в get_user_achievements), а не сразу при разблокировке — чтобы был повод
    зайти и приятное действие, а не тихое начисление в фоне."""
    _require_self(current_user, user_id)
    unlock = (
        db.query(models.AchievementUnlock)
        .filter(models.AchievementUnlock.user_id == user_id, models.AchievementUnlock.code == code)
        .first()
    )
    if unlock is None:
        raise HTTPException(status_code=404, detail="Achievement not unlocked")
    if unlock.chest_claimed:
        raise HTTPException(status_code=409, detail="Chest already claimed")

    try:
        level_index = int(code.rsplit("_", 1)[1])
        level_name = ACHIEVEMENT_LEVELS[level_index - 1]
    except (IndexError, ValueError):
        raise HTTPException(status_code=400, detail="Invalid achievement code")

    user = db.query(models.User).filter(models.User.id == user_id).first()
    amount = _award_cores(user, *CORES_BY_LEVEL[level_name])
    unlock.chest_claimed = True
    db.commit()
    return {"amount": amount, "cores": user.cores}


@app.post("/users/{user_id}/league-chest/claim")
def claim_league_chest(
    user_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    """Открывает сундук за последнее подведённое место в лиге — тот же
    паттерн отложенного начисления, что и у claim_achievement_chest."""
    _require_self(current_user, user_id)
    last_result = (
        db.query(models.LeagueResult)
        .filter(models.LeagueResult.user_id == user_id)
        .order_by(models.LeagueResult.week_start.desc())
        .first()
    )
    if last_result is None:
        raise HTTPException(status_code=404, detail="No league result")
    if last_result.chest_claimed:
        raise HTTPException(status_code=409, detail="Chest already claimed")

    user = db.query(models.User).filter(models.User.id == user_id).first()
    user.cores += last_result.cores
    last_result.chest_claimed = True
    db.commit()
    return {"amount": last_result.cores, "cores": user.cores}


@app.patch("/users/{user_id}/phone", response_model=schemas.UserOut)
def update_phone(
    user_id: int,
    payload: schemas.PhoneUpdate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    """Телефон опционален и нужен только для поиска друзей по контактам —
    никнейм и вход в аккаунт от него не зависят."""
    _require_self(current_user, user_id)
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if user is None:
        raise HTTPException(status_code=404, detail="User not found")

    phone = payload.phone.strip() if payload.phone else None

    if phone:
        conflict = (
            db.query(models.User)
            .filter(models.User.phone == phone, models.User.id != user_id)
            .first()
        )
        if conflict is not None:
            raise HTTPException(status_code=409, detail="Этот номер уже привязан к другому аккаунту")

    user.phone = phone
    db.commit()
    db.refresh(user)
    return user


@app.post("/users/{user_id}/rotate-token", dependencies=[Depends(rate_limit(5, 60))])
def rotate_token(
    user_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    """device_token бессрочный и сервер не хранит историю сессий для точечного
    отзыва — если он мог утечь (лог, потерянное/скомпрометированное
    устройство), единственный способ его обесценить — заменить на новый.
    Прежний токен после этого сразу перестаёт проходить get_current_user."""
    _require_self(current_user, user_id)
    current_user.device_token = secrets.token_hex(16)
    db.commit()
    db.refresh(current_user)
    return {"device_token": current_user.device_token}


def _course_id_for_lesson(db: Session, lesson_id: int) -> int | None:
    row = (
        db.query(models.Section.course_id)
        .join(models.Lesson, models.Lesson.section_id == models.Section.id)
        .filter(models.Lesson.id == lesson_id)
        .first()
    )
    return row.course_id if row else None


def _course_id_for_section(db: Session, section_id: int) -> int | None:
    row = db.query(models.Section.course_id).filter(models.Section.id == section_id).first()
    return row.course_id if row else None


def _assert_course_unlocked(db: Session, course_id: int | None, user_id: int) -> None:
    """Гость не должен пройти дальше списка курсов, если курс требует регистрации —
    список курсов лишь прячет карточку, а не защищает сами эндпоинты."""
    if course_id is None:
        return
    course = db.query(models.Course).filter(models.Course.id == course_id).first()
    if course is None or not course.requires_account:
        return
    user = db.query(models.User).filter(models.User.id == user_id).first()
    is_guest = user is None or user.auth_provider == "guest"
    if is_guest:
        raise HTTPException(status_code=403, detail="Курс требует регистрации")


@app.get("/lessons/{lesson_id}", response_model=schemas.LessonOut)
def get_lesson(
    lesson_id: int,
    user_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    _require_self(current_user, user_id)
    _assert_course_unlocked(db, _course_id_for_lesson(db, lesson_id), user_id)
    lesson = db.query(models.Lesson).filter(models.Lesson.id == lesson_id).first()
    if lesson is None:
        raise HTTPException(status_code=404, detail="Lesson not found")
    return schemas.LessonOut(
        id=lesson.id,
        title=lesson.title,
        order=lesson.order,
        section_id=lesson.section_id,
        story=lesson.story,
        mastery=_lesson_mastery(db, user_id, lesson_id),
    )


@app.get("/lessons/{lesson_id}/exercises", response_model=list[schemas.ExerciseOut])
def get_lesson_exercises(
    lesson_id: int,
    user_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    _require_self(current_user, user_id)
    _assert_course_unlocked(db, _course_id_for_lesson(db, lesson_id), user_id)

    # следующая попытка сложнее предыдущей: 0 успешных прохождений → сложность
    # 1, 1 прохождение → 2, 2+ → 3 (и дальше держится на золоте)
    target_difficulty = min(_lesson_mastery(db, user_id, lesson_id) + 1, MAX_MASTERY)

    exercises = (
        db.query(models.Exercise)
        .filter(models.Exercise.lesson_id == lesson_id, models.Exercise.difficulty == target_difficulty)
        .order_by(models.Exercise.order)
        .all()
    )
    # для уроков без версии этой сложности (ещё не написана) — сложность 1 как основа
    if not exercises and target_difficulty != 1:
        exercises = (
            db.query(models.Exercise)
            .filter(models.Exercise.lesson_id == lesson_id, models.Exercise.difficulty == 1)
            .order_by(models.Exercise.order)
            .all()
        )
    return exercises


@app.post("/exercises/{exercise_id}/submit")
def submit_answer(
    exercise_id: int,
    submission: schemas.AnswerSubmit,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    _require_self(current_user, submission.user_id)
    exercise = db.query(models.Exercise).filter(models.Exercise.id == exercise_id).first()
    if exercise is None:
        raise HTTPException(status_code=404, detail="Exercise not found")

    _assert_course_unlocked(db, _course_id_for_lesson(db, exercise.lesson_id), submission.user_id)

    is_correct = submission.answer == exercise.correct_answer
    is_close = (
        not is_correct
        and exercise.type == "terminal"
        and _is_close_terminal_answer(submission.answer, exercise.correct_answer)
    )

    user = db.query(models.User).filter(models.User.id == submission.user_id).first()
    if user is None:
        raise HTTPException(status_code=404, detail="User not found")

    db.add(models.Answer(user_id=submission.user_id, exercise_id=exercise_id, is_correct=is_correct))
    _update_skill_progress(db, submission.user_id, exercise.skill_tags, is_correct)

    # день засчитывается в streak только за верный ответ
    if is_correct:
        today = _today()
        if user.last_activity_date != today:
            # заряды заморозки пополняются раз в неделю, независимо от того,
            # включена ли защита — чтобы «неделя без пропуска» не сгорала впустую.
            # max(...) — а не прямое присваивание 1 — чтобы еженедельный рефилл
            # не срезал заряды, докупленные за XP (см. purchase_streak_freeze)
            if user.streak_freeze_refreshed_at is None or (today - user.streak_freeze_refreshed_at).days >= 7:
                user.streak_freezes = max(user.streak_freezes, 1)
                user.streak_freeze_refreshed_at = today

            if user.last_activity_date == today - timedelta(days=1):
                user.streak += 1
            elif user.streak_shield_enabled and user.streak_freezes > 0:
                # пропущенный день, но есть активная защита и заряд — тратим
                # заряд и продолжаем streak как обычный день (без сброса).
                user.streak_freezes -= 1
                user.streak += 1
            else:
                user.streak = 1
            user.last_activity_date = today

    db.commit()
    new_achievements = _record_achievement_unlocks(db, user)

    # ответ уже дан, поэтому правильный вариант можно показать
    correct_answer = exercise.correct_answer
    if isinstance(correct_answer, dict):
        correct_answer = correct_answer.get("answer")

    return {
        "correct": is_correct,
        "correct_answer": correct_answer,
        "streak": user.streak,
        "close": is_close,
        "new_achievements": new_achievements,
    }


@app.get("/users/{user_id}/review/due")
def get_review_due(
    user_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    """Сколько навыков сейчас просрочено для повторения — бейдж на карточке
    «Повторение» на главном экране."""
    _require_self(current_user, user_id)
    count = (
        db.query(models.SkillProgress)
        .filter(models.SkillProgress.user_id == user_id, models.SkillProgress.next_review_at <= datetime.utcnow())
        .count()
    )
    return {"due": count}


@app.get("/users/{user_id}/review/session", response_model=list[schemas.ReviewExerciseOut])
def get_review_session(
    user_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    """Собирает сессию повторения: по одному случайному упражнению на каждый
    просроченный навык, самые просроченные — первыми."""
    _require_self(current_user, user_id)
    due = (
        db.query(models.SkillProgress)
        .filter(models.SkillProgress.user_id == user_id, models.SkillProgress.next_review_at <= datetime.utcnow())
        .order_by(models.SkillProgress.next_review_at)
        .limit(REVIEW_SESSION_SIZE)
        .all()
    )
    if not due:
        return []

    due_tags = [row.skill_tag for row in due]
    candidates = (
        db.query(models.Exercise)
        .filter(models.Exercise.type != "theory")
        .all()
    )

    by_tag: dict[str, list[models.Exercise]] = {}
    for exercise in candidates:
        for tag in exercise.skill_tags or []:
            by_tag.setdefault(tag, []).append(exercise)

    session = []
    for tag in due_tags:
        pool = by_tag.get(tag)
        if pool:
            session.append(random.choice(pool))
    return session


@app.post("/users/{user_id}/award-xp")
def award_xp(
    user_id: int,
    payload: schemas.LessonComplete,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    _require_self(current_user, user_id)
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if user is None:
        raise HTTPException(status_code=404, detail="User not found")
    user.xp += payload.correct_count * XP_PER_CORRECT
    db.commit()
    new_achievements = _record_achievement_unlocks(db, user)
    return {"xp": user.xp, "new_achievements": new_achievements}

@app.get("/sections/{section_id}/lessons-progress")
def get_lessons_progress(
    section_id: int,
    user_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    _require_self(current_user, user_id)
    _assert_course_unlocked(db, _course_id_for_section(db, section_id), user_id)

    lessons = (
        db.query(models.Lesson)
        .filter(models.Lesson.section_id == section_id)
        .order_by(models.Lesson.order)
        .all()
    )

    completed_lesson_ids = {
        row.lesson_id
        for row in db.query(models.UserProgress)
        .filter(models.UserProgress.user_id == user_id)
        .all()
    }

    lesson_ids = [lesson.id for lesson in lessons]
    mastery_by_lesson = {
        row.lesson_id: min(row.completions, MAX_MASTERY)
        for row in db.query(models.LessonMastery)
        .filter(models.LessonMastery.user_id == user_id, models.LessonMastery.lesson_id.in_(lesson_ids))
        .all()
    }

    result = []
    unlocked_found = False
    for lesson in lessons:
        if lesson.id in completed_lesson_ids:
            status = "done"
        elif not unlocked_found:
            status = "current"
            unlocked_found = True
        else:
            status = "locked"
        result.append({
            "id": lesson.id,
            "title": lesson.title,
            "order": lesson.order,
            "status": status,
            "mastery": mastery_by_lesson.get(lesson.id, 0),
        })

    return result

@app.post("/lessons/{lesson_id}/complete")
def complete_lesson(
    lesson_id: int,
    user_id: int,
    perfect: bool = False,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    _require_self(current_user, user_id)
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if user is None:
        raise HTTPException(status_code=404, detail="User not found")
    lesson = db.query(models.Lesson).filter(models.Lesson.id == lesson_id).first()
    if lesson is None:
        raise HTTPException(status_code=404, detail="Lesson not found")

    _assert_course_unlocked(db, _course_id_for_section(db, lesson.section_id), user_id)

    existing = (
        db.query(models.UserProgress)
        .filter(models.UserProgress.user_id == user_id, models.UserProgress.lesson_id == lesson_id)
        .first()
    )
    is_first_completion = existing is None
    if is_first_completion:
        progress = models.UserProgress(user_id=user_id, lesson_id=lesson_id)
        db.add(progress)
        db.commit()
    else:
        # Обновляем дату прохождения и при повторном прохождении — иначе
        # повтор урока не засчитывается в дневную цель (/daily-progress
        # считает по completed_at) и не поддерживает серию.
        existing.completed_at = datetime.utcnow()
        db.commit()

    completed_lesson_ids = {
        row.lesson_id
        for row in db.query(models.UserProgress.lesson_id)
        .filter(models.UserProgress.user_id == user_id)
        .all()
    }

    section = db.query(models.Section).filter(models.Section.id == lesson.section_id).first()
    course = db.query(models.Course).filter(models.Course.id == section.course_id).first()

    section_lessons = (
        db.query(models.Lesson)
        .filter(models.Lesson.section_id == section.id)
        .order_by(models.Lesson.order)
        .all()
    )
    section_done = len([l for l in section_lessons if l.id in completed_lesson_ids])
    section_complete = section_done == len(section_lessons)

    course_sections = (
        db.query(models.Section)
        .filter(models.Section.course_id == course.id)
        .order_by(models.Section.order)
        .all()
    )

    # что показать пользователю как «дальше»
    next_up = None
    if section_complete:
        for candidate in course_sections:
            if candidate.order <= section.order:
                continue
            candidate_lessons = (
                db.query(models.Lesson).filter(models.Lesson.section_id == candidate.id).all()
            )
            if any(l.id not in completed_lesson_ids for l in candidate_lessons):
                next_up = {"type": "section", "order": candidate.order, "title": candidate.title}
                break
    else:
        for candidate in section_lessons:
            if candidate.id not in completed_lesson_ids:
                next_up = {"type": "lesson", "order": candidate.order, "title": candidate.title}
                break

    sections_done = 0
    for candidate in course_sections:
        candidate_lessons = db.query(models.Lesson).filter(models.Lesson.section_id == candidate.id).all()
        if candidate_lessons and all(l.id in completed_lesson_ids for l in candidate_lessons):
            sections_done += 1

    mastery = (
        db.query(models.LessonMastery)
        .filter(models.LessonMastery.user_id == user_id, models.LessonMastery.lesson_id == lesson_id)
        .first()
    )
    if mastery is None:
        mastery = models.LessonMastery(user_id=user_id, lesson_id=lesson_id, completions=0)
        db.add(mastery)
    previous_level = min(mastery.completions, MAX_MASTERY)
    mastery.completions = min(mastery.completions + 1, MAX_MASTERY)
    new_level = mastery.completions

    if perfect:
        user.perfect_lessons_count += 1

    course_complete = bool(course_sections) and sections_done == len(course_sections)

    chests = []
    if new_level == MAX_MASTERY and previous_level < MAX_MASTERY:
        chests.append({"reason": "lesson_gold", "amount": _award_cores(user, *CORES_GOLD_LESSON)})
    # is_first_completion гарантирует, что это первый раз, когда курс дошёл до
    # 100% — иначе этот lesson_id уже был бы в completed_lesson_ids раньше
    if is_first_completion and course_complete:
        chests.append({"reason": "course_complete", "amount": _award_cores(user, *CORES_COURSE_COMPLETE)})

    db.commit()

    new_achievements = _record_achievement_unlocks(db, user)

    return {
        "status": "ok",
        "lesson_title": lesson.title,
        "new_achievements": new_achievements,
        "chests": chests,
        "mastery": {"level": new_level, "leveled_up": new_level > previous_level},
        "section": {
            "id": section.id,
            "title": section.title,
            "order": section.order,
            "completed": section_done,
            "total": len(section_lessons),
            "is_complete": section_complete,
        },
        "course": {
            "id": course.id,
            "title": course.title,
            "sections_total": len(course_sections),
            "sections_done": sections_done,
        },
        "next": next_up,
    }


@app.get("/courses/{course_id}/sections", response_model=list[schemas.SectionOut])
def get_course_sections(
    course_id: int,
    user_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    _require_self(current_user, user_id)
    _assert_course_unlocked(db, course_id, user_id)
    return (
        db.query(models.Section)
        .filter(models.Section.course_id == course_id)
        .order_by(models.Section.order)
        .all()
    )


@app.get("/courses/{course_id}/sections-progress")
def get_sections_progress(
    course_id: int,
    user_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    _require_self(current_user, user_id)
    course = db.query(models.Course).filter(models.Course.id == course_id).first()
    if course is None:
        raise HTTPException(status_code=404, detail="Course not found")

    _assert_course_unlocked(db, course_id, user_id)

    sections = (
        db.query(models.Section)
        .filter(models.Section.course_id == course_id)
        .order_by(models.Section.order)
        .all()
    )

    # все уроки курса одним запросом, чтобы не ходить в базу за каждым разделом
    lessons = (
        db.query(models.Lesson)
        .join(models.Section, models.Lesson.section_id == models.Section.id)
        .filter(models.Section.course_id == course_id)
        .all()
    )
    lessons_by_section = {}
    for lesson in lessons:
        lessons_by_section.setdefault(lesson.section_id, []).append(lesson.id)

    completed_lesson_ids = {
        row.lesson_id
        for row in db.query(models.UserProgress.lesson_id)
        .filter(models.UserProgress.user_id == user_id)
        .all()
    }

    result = []
    current_found = False
    for section in sections:
        section_lesson_ids = lessons_by_section.get(section.id, [])
        total = len(section_lesson_ids)
        completed = len([i for i in section_lesson_ids if i in completed_lesson_ids])

        if total > 0 and completed == total:
            status = "done"
        elif not current_found:
            status = "current"
            current_found = True
        else:
            status = "locked"

        result.append({
            "id": section.id,
            "title": section.title,
            "order": section.order,
            "completed": completed,
            "total": total,
            "status": status,
        })

    return {"course_title": course.title, "sections": result}


@app.get("/courses/{course_id}/progress")
def get_course_progress(
    course_id: int,
    user_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    _require_self(current_user, user_id)
    _assert_course_unlocked(db, course_id, user_id)

    lesson_ids = [
        row.id
        for row in db.query(models.Lesson.id)
        .join(models.Section, models.Lesson.section_id == models.Section.id)
        .filter(models.Section.course_id == course_id)
        .all()
    ]

    total = len(lesson_ids)
    completed = (
        db.query(models.UserProgress)
        .filter(models.UserProgress.user_id == user_id, models.UserProgress.lesson_id.in_(lesson_ids))
        .count()
        if lesson_ids
        else 0
    )

    return {"completed": completed, "total": total}


def _courses_with_status(db: Session, user_id: int) -> list[dict]:
    """Курсы с прогрессом и статусом блокировки. Общая основа для списка курсов
    и поиска текущего раздела."""
    user = db.query(models.User).filter(models.User.id == user_id).first()
    is_guest = user is None or user.auth_provider == "guest"

    courses = db.query(models.Course).all()
    completed_ids = {
        row.lesson_id
        for row in db.query(models.UserProgress.lesson_id)
        .filter(models.UserProgress.user_id == user_id)
        .all()
    }

    stats = {}
    for c in courses:
        lesson_ids = [
            r.id
            for r in db.query(models.Lesson.id)
            .join(models.Section, models.Lesson.section_id == models.Section.id)
            .filter(models.Section.course_id == c.id)
            .all()
        ]
        total = len(lesson_ids)
        done = len([i for i in lesson_ids if i in completed_ids])
        stats[c.id] = {"completed": done, "total": total}

    titles = {c.id: c.title for c in courses}

    result = []
    for c in courses:
        s = stats[c.id]
        locked = False
        requirement = None
        reason = None

        if c.is_coming_soon:
            locked = True
            requirement = "скоро"
            reason = "coming_soon"
        elif c.requires_account and is_guest:
            locked = True
            requirement = "нужна регистрация"
            reason = "requires_account"
        elif c.required_course_id is not None:
            req = stats.get(c.required_course_id, {"completed": 0, "total": 0})
            pct = (req["completed"] / req["total"] * 100) if req["total"] else 0
            need = c.required_percent or 0
            if pct < need:
                locked = True
                requirement = f'нужен «{titles.get(c.required_course_id, "")}» {need}%'
                reason = "prerequisite"

        result.append({
            "id": c.id,
            "title": c.title,
            "completed": s["completed"],
            "total": s["total"],
            "locked": locked,
            "requirement": requirement,
            "reason": reason,
        })

    return result


def _current_course_title(db: Session, user_id: int) -> str | None:
    """Курс, который пользователь сейчас проходит — для бейджа в чужом
    профиле. В отличие от /current-section (self-only, учитывает клиентский
    preferred_course_id из настроек), тут просто «курс последнего движения»,
    без клиентских предпочтений, которые для чужого профиля не применимы."""
    courses = _courses_with_status(db, user_id)
    unfinished = [
        c for c in courses if not c["locked"] and c["total"] > 0 and c["completed"] < c["total"]
    ]
    if not unfinished:
        return None

    last_progress = (
        db.query(models.UserProgress)
        .filter(models.UserProgress.user_id == user_id)
        .order_by(models.UserProgress.completed_at.desc())
        .first()
    )
    if last_progress is not None:
        lesson = db.query(models.Lesson).filter(models.Lesson.id == last_progress.lesson_id).first()
        if lesson is not None:
            section = db.query(models.Section).filter(models.Section.id == lesson.section_id).first()
            if section is not None:
                match = next((c for c in unfinished if c["id"] == section.course_id), None)
                if match is not None:
                    return match["title"]

    return unfinished[0]["title"]


@app.get("/courses/overview")
def get_courses_overview(
    user_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    _require_self(current_user, user_id)
    return _courses_with_status(db, user_id)


@app.get("/users/{user_id}/current-section")
def get_current_section(
    user_id: int,
    preferred_course_id: int | None = None,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    """Раздел, с которого пользователю продолжать: первый незавершённый
    в первом незавершённом доступном курсе. preferred_course_id — курс,
    выбранный в онбординге (или потом в настройках) — если он доступен,
    выводим его вперёд остальных вне зависимости от порядка «в работе»."""
    _require_self(current_user, user_id)
    courses = _courses_with_status(db, user_id)
    available = [c for c in courses if not c["locked"] and c["total"] > 0]
    if not available:
        return None

    completed_lesson_ids = {
        row.lesson_id
        for row in db.query(models.UserProgress.lesson_id)
        .filter(models.UserProgress.user_id == user_id)
        .all()
    }

    # сначала курсы в работе, потом остальные — как в баннере «продолжить»
    unfinished = [c for c in available if c["completed"] < c["total"]]
    ordered = unfinished + [c for c in available if c not in unfinished]

    if preferred_course_id is not None:
        preferred = next((c for c in ordered if c["id"] == preferred_course_id), None)
        if preferred is not None:
            ordered = [preferred] + [c for c in ordered if c is not preferred]

    for course in ordered:
        sections = (
            db.query(models.Section)
            .filter(models.Section.course_id == course["id"])
            .order_by(models.Section.order)
            .all()
        )
        for section in sections:
            lesson_ids = [
                r.id
                for r in db.query(models.Lesson.id)
                .filter(models.Lesson.section_id == section.id)
                .all()
            ]
            if not lesson_ids:
                continue
            if any(i not in completed_lesson_ids for i in lesson_ids):
                return {
                    "course_id": course["id"],
                    "course_title": course["title"],
                    "section_id": section.id,
                    "section_title": section.title,
                }

    # всё пройдено — возвращаем последний раздел первого курса, чтобы было куда зайти
    last = ordered[0]
    section = (
        db.query(models.Section)
        .filter(models.Section.course_id == last["id"])
        .order_by(models.Section.order.desc())
        .first()
    )
    if section is None:
        return None
    return {
        "course_id": last["id"],
        "course_title": last["title"],
        "section_id": section.id,
        "section_title": section.title,
    }


# точность считается только когда ответов достаточно, иначе один верный ответ даёт 100%
MIN_ANSWERS_FOR_ACCURACY = 20

# Каждое достижение теперь — не плоский список порогов, а «семья» с 5
# уровнями (бронза → бедрок), растянутыми из прежних 6 плоских порогов.
ACHIEVEMENT_LEVELS = ["bronze", "silver", "gold", "diamond", "bedrock"]
ACHIEVEMENT_LEVEL_TITLES = {
    "bronze": "Бронза",
    "silver": "Серебро",
    "gold": "Золото",
    "diamond": "Алмаз",
    "bedrock": "Бедрок",
}
# Ядра растут с уровнем — бедрок ощутимо ценнее бронзы
CORES_BY_LEVEL = {
    "bronze": (10, 20),
    "silver": (20, 35),
    "gold": (35, 55),
    "diamond": (55, 80),
    "bedrock": (80, 120),
}

ACHIEVEMENT_FAMILIES = [
    {
        "family": "streak",
        "metric": "streak",
        "title": "Серия дней",
        "icon": "🔥",
        "unit": "дней подряд",
        "verb": "Продержи серию",
        "thresholds": [3, 14, 30, 60, 100],
    },
    {
        "family": "xp",
        "metric": "xp",
        "title": "Опыт",
        "icon": "⚡",
        "unit": "XP",
        "verb": "Набери",
        "thresholds": [100, 500, 1000, 2500, 5000],
    },
    {
        "family": "lessons",
        "metric": "lessons",
        "title": "Уроки",
        "icon": "✓",
        "unit": "уроков",
        "verb": "Пройди",
        "thresholds": [5, 10, 25, 50, 100],
    },
    {
        # Раньше «точность» — % правильных ответов за всё время; теперь —
        # число уроков, пройденных со 100% точностью (см. complete_lesson).
        "family": "accuracy",
        "metric": "perfect_lessons",
        "title": "Точность",
        "icon": "🎯",
        "unit": "уроков со 100% точностью",
        "verb": "Пройди",
        "thresholds": [1, 5, 10, 25, 50],
    },
]
FAMILIES_BY_KEY = {f["family"]: f for f in ACHIEVEMENT_FAMILIES}


def _achievement_code(family: str, level_index: int) -> str:
    return f"{family}_{level_index}"


def _family_level_description(family: dict, threshold: int) -> str:
    """Полная формулировка условия уровня — «Пройди 25 уроков», а не
    голое «25 уроков» — так понятно, что вообще нужно сделать."""
    return f'{family["verb"]} {threshold} {family["unit"]}'


def _family_level(value: int, thresholds: list[int]) -> int:
    """Сколько порогов (0..5) уже пройдено этим значением."""
    level = 0
    for threshold in thresholds:
        if value >= threshold:
            level += 1
        else:
            break
    return level


def _achievement_values(user: models.User, stats: dict) -> dict:
    return {
        "streak": user.streak,
        "xp": user.xp,
        "lessons": stats["lessons_completed"],
        "perfect_lessons": user.perfect_lessons_count,
    }


def _collect_stats(user: models.User, db: Session) -> dict:
    lessons_completed = (
        db.query(models.UserProgress)
        .filter(models.UserProgress.user_id == user.id)
        .count()
    )

    total_answers = (
        db.query(models.Answer)
        .filter(models.Answer.user_id == user.id)
        .count()
    )
    correct_answers = (
        db.query(models.Answer)
        .filter(models.Answer.user_id == user.id, models.Answer.is_correct.is_(True))
        .count()
    )

    accuracy = round(correct_answers / total_answers * 100) if total_answers else None

    return {
        "lessons_completed": lessons_completed,
        "total_answers": total_answers,
        "accuracy": accuracy,
    }


def _record_achievement_unlocks(db: Session, user: models.User) -> list[dict]:
    """Достижения считаются на лету по 4 семьям × 5 уровней (бронза..бедрок),
    но для ленты активности и всплывающего поздравления нужен сам факт
    разблокировки уровня — записываем его один раз, при первом пересечении
    порога, и возвращаем то, что разблокировалось только что."""
    stats = _collect_stats(user, db)
    values = _achievement_values(user, stats)

    already = {
        row.code
        for row in db.query(models.AchievementUnlock).filter(models.AchievementUnlock.user_id == user.id).all()
    }

    newly_unlocked = []
    for family in ACHIEVEMENT_FAMILIES:
        reached_level = _family_level(values[family["metric"]], family["thresholds"])
        for level_index in range(1, reached_level + 1):
            code = _achievement_code(family["family"], level_index)
            if code in already:
                continue
            # chest_claimed=False — сундук с ядрами открывается вручную в
            # профиле (см. claim_achievement_chest), не начисляется тут же.
            db.add(models.AchievementUnlock(user_id=user.id, code=code, chest_claimed=False))
            level_name = ACHIEVEMENT_LEVELS[level_index - 1]
            newly_unlocked.append({
                "code": code,
                "title": family["title"],
                "description": f'{family["thresholds"][level_index - 1]} {family["unit"]}',
                "icon": family["icon"],
                "style": level_name,
            })
    if newly_unlocked:
        db.commit()
    return newly_unlocked


@app.get("/users/{user_id}/stats")
def get_user_stats(
    user_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    """Доступен для просмотра любого пользователя (нужно для чужих профилей),
    но email и настройки защиты streak — личные и отдаются только себе."""
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if user is None:
        raise HTTPException(status_code=404, detail="User not found")

    stats = _collect_stats(user, db)
    followers_count = db.query(models.Follow).filter(models.Follow.followee_id == user_id).count()
    following_count = db.query(models.Follow).filter(models.Follow.follower_id == user_id).count()
    last_league_result = (
        db.query(models.LeagueResult)
        .filter(models.LeagueResult.user_id == user_id)
        .order_by(models.LeagueResult.week_start.desc())
        .first()
    )

    result = {
        "id": user.id,
        "username": user.username,
        "avatar": user.avatar,
        "xp": user.xp,
        "streak": user.streak,
        "is_online": _is_online(user),
        "lessons_completed": stats["lessons_completed"],
        "accuracy": stats["accuracy"],
        "created_at": user.created_at,
        "followers_count": followers_count,
        "following_count": following_count,
        # Место в лиге за последнюю подведённую неделю — видно в любом
        # профиле, как медаль-бейдж (не только своём).
        "last_league_rank": last_league_result.rank if last_league_result else None,
        # Какой курс сейчас проходит — тоже видно всем, как и достижения.
        "current_course_title": _current_course_title(db, user_id),
    }
    if current_user.id == user_id:
        result["email"] = user.email
        result["phone"] = user.phone
        result["auth_provider"] = user.auth_provider
        result["streak_shield_enabled"] = user.streak_shield_enabled
        result["streak_freezes"] = user.streak_freezes
        result["cores"] = user.cores
        result["has_unclaimed_league_chest"] = (
            last_league_result is not None and not last_league_result.chest_claimed
        )
    return result


@app.get("/users/{user_id}/daily-progress")
def get_daily_progress(
    user_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    """Сколько уроков пройдено сегодня. Саму цель хранит приложение локально."""
    _require_self(current_user, user_id)
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if user is None:
        raise HTTPException(status_code=404, detail="User not found")

    today = _today()
    lessons_completed = (
        db.query(models.UserProgress)
        .filter(
            models.UserProgress.user_id == user_id,
            func.date(models.UserProgress.completed_at) == today,
        )
        .count()
    )

    return {"date": today.isoformat(), "lessons_completed": lessons_completed}


@app.get("/users/{user_id}/daily-quests")
def get_daily_quests(
    user_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    """3 квеста дня поверх обычной цели — прогресс считается на лету, а
    награда начисляется сразу в момент, когда прогресс впервые достиг цели
    (тот же ленивый паттерн, что у _finalize_league_week: не нужен отдельный
    крон на сброс, квесты «сбрасываются» сами с наступлением нового дня,
    т.к. прогресс считается заново по сегодняшним данным)."""
    _require_self(current_user, user_id)
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if user is None:
        raise HTTPException(status_code=404, detail="User not found")

    today = _today()
    progress = _daily_quest_progress(db, user_id, today)
    claims_by_code = {
        row.code: row.cores
        for row in db.query(models.DailyQuestClaim).filter(
            models.DailyQuestClaim.user_id == user_id,
            models.DailyQuestClaim.date == today,
        )
    }

    quests = []
    newly_completed = []
    for quest in DAILY_QUESTS:
        current = min(progress[quest["metric"]], quest["target"])
        completed = current >= quest["target"]
        cores_awarded = claims_by_code.get(quest["code"])
        if completed and cores_awarded is None:
            cores_awarded = _award_cores(user, *quest["cores"])
            db.add(models.DailyQuestClaim(
                user_id=user_id, date=today, code=quest["code"], cores=cores_awarded,
            ))
            newly_completed.append({"code": quest["code"], "title": quest["title"], "amount": cores_awarded})
        quests.append({
            "code": quest["code"],
            "title": quest["title"],
            "progress": current,
            "target": quest["target"],
            "completed": completed,
            "cores": cores_awarded,
        })
    if newly_completed:
        db.commit()

    return {"quests": quests, "newly_completed": newly_completed}


@app.get("/users/{user_id}/activity")
def get_user_activity(
    user_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    """Доступен для любого user_id (нужно для сравнения графиков в чужом
    профиле) — данных без личной информации, только требуется валидный токен."""
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if user is None:
        raise HTTPException(status_code=404, detail="User not found")

    today = _today()
    start = today - timedelta(days=6)

    rows = (
        db.query(
            func.date(models.Answer.created_at).label("day"),
            func.count(models.Answer.id).label("correct"),
        )
        .filter(
            models.Answer.user_id == user_id,
            models.Answer.is_correct.is_(True),
            func.date(models.Answer.created_at) >= start,
        )
        .group_by(func.date(models.Answer.created_at))
        .all()
    )
    by_day = {row.day: row.correct for row in rows}

    days = []
    for offset in range(7):
        day = start + timedelta(days=offset)
        days.append({
            "date": day.isoformat(),
            "xp": by_day.get(day, 0) * XP_PER_CORRECT,
        })

    return {"total_xp": sum(d["xp"] for d in days), "days": days}


@app.get("/users/{user_id}/achievements")
def get_user_achievements(
    user_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    """Доступен для любого user_id (просмотр достижений в чужом профиле).
    Каждый item — целая семья (streak/xp/lessons/accuracy) с текущим уровнем
    0..5, а не отдельное плоское достижение, как раньше."""
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if user is None:
        raise HTTPException(status_code=404, detail="User not found")

    stats = _collect_stats(user, db)
    values = _achievement_values(user, stats)

    unlocks_by_code = {
        row.code: row
        for row in db.query(models.AchievementUnlock).filter(models.AchievementUnlock.user_id == user.id).all()
    }
    is_self = current_user.id == user_id

    items = []
    for family in ACHIEVEMENT_FAMILIES:
        value = values[family["metric"]]
        max_level = len(family["thresholds"])
        reached_level = _family_level(value, family["thresholds"])
        style = ACHIEVEMENT_LEVELS[reached_level - 1] if reached_level > 0 else "locked"

        if reached_level >= max_level:
            next_threshold = None
            description = f'Получено: {family["title"]}, текущий счёт: {value}'
        else:
            next_threshold = family["thresholds"][reached_level]
            description = _family_level_description(family, next_threshold)

        item = {
            "family": family["family"],
            "title": family["title"],
            "icon": family["icon"],
            "style": style,
            "level": reached_level,
            "max_level": max_level,
            "value": value,
            "next_threshold": next_threshold,
            "description": description,
            # Условие и статус каждого отдельного уровня — для свайпа по всем
            # порогам семьи на экране деталей (не только следующего).
            "levels": [
                {
                    "level": i + 1,
                    "threshold": threshold,
                    "description": _family_level_description(family, threshold),
                    "reached": i + 1 <= reached_level,
                }
                for i, threshold in enumerate(family["thresholds"])
            ],
        }
        # «Новое» на карточке имеет смысл только в своём профиле — не
        # раскрываем это состояние про чужой сундук на просмотре чужого профиля.
        if is_self:
            next_unclaimed_code = None
            for level_index in range(1, reached_level + 1):
                code = _achievement_code(family["family"], level_index)
                unlock = unlocks_by_code.get(code)
                if unlock is not None and not unlock.chest_claimed:
                    next_unclaimed_code = code
                    break
            item["has_unclaimed_chest"] = next_unclaimed_code is not None
            item["next_unclaimed_code"] = next_unclaimed_code
        items.append(item)

    return {
        "unlocked": sum(i["level"] for i in items),
        "total": sum(i["max_level"] for i in items),
        "items": items,
    }


LEADERBOARD_SIZE = 20


@app.get("/leaderboard")
def get_leaderboard(
    user_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    """Топ по XP за текущую неделю лиги (Пн 00:00 МСК — следующий Пн 00:00
    МСК), а не скользящие 7 дней — так у топа есть чёткая точка сброса, и
    топ-3 прошлой недели получают награду (см. _finalize_league_week)."""
    _require_self(current_user, user_id)
    _finalize_league_week(db)

    start_utc = _week_start_to_utc(_msk_week_start(datetime.utcnow()))
    rows = (
        db.query(models.Answer.user_id, func.count(models.Answer.id).label("correct"))
        .filter(models.Answer.is_correct.is_(True), models.Answer.created_at >= start_utc)
        .group_by(models.Answer.user_id)
        .all()
    )
    xp_by_user = {row.user_id: row.correct * XP_PER_CORRECT for row in rows}

    user_ids = set(xp_by_user.keys()) | {user_id}
    users = db.query(models.User).filter(models.User.id.in_(user_ids)).all()
    following_ids = {
        row.followee_id for row in db.query(models.Follow).filter(models.Follow.follower_id == user_id).all()
    }

    entries = [
        {
            "user_id": u.id,
            "username": u.username or "Игрок",
            "avatar": u.avatar,
            "xp_week": xp_by_user.get(u.id, 0),
            "streak": u.streak,
            "is_following": u.id in following_ids,
        }
        for u in users
    ]
    entries.sort(key=lambda e: e["xp_week"], reverse=True)
    for i, entry in enumerate(entries):
        entry["rank"] = i + 1

    top = entries[:LEADERBOARD_SIZE]
    me = next((e for e in entries if e["user_id"] == user_id), None)
    if me is not None and me not in top:
        top.append(me)

    return {"entries": top, "me": me}


@app.post("/users/{user_id}/follow/{target_id}")
def follow_user(
    user_id: int,
    target_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    _require_self(current_user, user_id)
    if user_id == target_id:
        raise HTTPException(status_code=400, detail="Cannot follow yourself")
    target = db.query(models.User).filter(models.User.id == target_id).first()
    if target is None:
        raise HTTPException(status_code=404, detail="User not found")

    existing = (
        db.query(models.Follow)
        .filter(models.Follow.follower_id == user_id, models.Follow.followee_id == target_id)
        .first()
    )
    if existing is None:
        db.add(models.Follow(follower_id=user_id, followee_id=target_id))
        db.commit()
    return {"status": "ok"}


@app.delete("/users/{user_id}/follow/{target_id}")
def unfollow_user(
    user_id: int,
    target_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    _require_self(current_user, user_id)
    db.query(models.Follow).filter(
        models.Follow.follower_id == user_id, models.Follow.followee_id == target_id
    ).delete()
    db.commit()
    return {"status": "ok"}


def _viewer_follow_flags(db: Session, ids: set[int], viewer_id: int) -> tuple[set[int], set[int]]:
    """Кого из ids смотрящий (viewer_id) читает и кто из ids читает его самого —
    нужно, чтобы кнопка «подписаться» в чужом списке подписок/подписчиков
    показывала состояние именно смотрящего, а не владельца списка."""
    viewer_following = {
        row.followee_id
        for row in db.query(models.Follow)
        .filter(models.Follow.follower_id == viewer_id, models.Follow.followee_id.in_(ids))
        .all()
    }
    viewer_followers = {
        row.follower_id
        for row in db.query(models.Follow)
        .filter(models.Follow.followee_id == viewer_id, models.Follow.follower_id.in_(ids))
        .all()
    }
    return viewer_following, viewer_followers


@app.get("/users/{user_id}/following")
def get_following(
    user_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    """user_id — чей список подписок смотрим (может быть любой), а
    is_following/is_friend всегда считаются от лица токена, а не клиентского
    параметра — иначе можно было бы подсмотреть чужое состояние подписки."""
    viewer_id = current_user.id

    following_ids = {
        row.followee_id for row in db.query(models.Follow).filter(models.Follow.follower_id == user_id).all()
    }
    if not following_ids:
        return []

    viewer_following, viewer_followers = _viewer_follow_flags(db, following_ids, viewer_id)

    users = db.query(models.User).filter(models.User.id.in_(following_ids)).all()
    return [
        {
            "id": u.id,
            "username": u.username,
            "avatar": u.avatar,
            "is_following": u.id in viewer_following,
            "is_friend": u.id in viewer_following and u.id in viewer_followers,
            "is_online": _is_online(u),
        }
        for u in users
    ]


@app.get("/users/{user_id}/followers")
def get_followers(
    user_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    viewer_id = current_user.id

    follower_ids = {
        row.follower_id for row in db.query(models.Follow).filter(models.Follow.followee_id == user_id).all()
    }
    if not follower_ids:
        return []

    viewer_following, viewer_followers = _viewer_follow_flags(db, follower_ids, viewer_id)

    users = db.query(models.User).filter(models.User.id.in_(follower_ids)).all()
    return [
        {
            "id": u.id,
            "username": u.username,
            "avatar": u.avatar,
            "is_following": u.id in viewer_following,
            "is_friend": u.id in viewer_following and u.id in viewer_followers,
            "is_online": _is_online(u),
        }
        for u in users
    ]


SUGGESTIONS_LIMIT = 20


@app.get("/users/{user_id}/suggestions")
def get_suggestions(
    user_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    """«Вы можете их знать» — те, на кого подписаны люди, на которых
    подписан сам пользователь (друзья друзей), кроме уже подписанных и себя."""
    _require_self(current_user, user_id)
    following_ids = {
        row.followee_id for row in db.query(models.Follow).filter(models.Follow.follower_id == user_id).all()
    }

    candidates = (
        db.query(models.Follow.followee_id, func.count(models.Follow.id).label("mutual"))
        .filter(models.Follow.follower_id.in_(following_ids), models.Follow.followee_id != user_id)
        .group_by(models.Follow.followee_id)
        .order_by(func.count(models.Follow.id).desc())
        .limit(SUGGESTIONS_LIMIT + len(following_ids))
        .all()
    )

    suggested_ids = [row.followee_id for row in candidates if row.followee_id not in following_ids][:SUGGESTIONS_LIMIT]
    if not suggested_ids:
        return []

    mutual_by_id = {row.followee_id: row.mutual for row in candidates}
    users = db.query(models.User).filter(models.User.id.in_(suggested_ids)).all()
    users_by_id = {u.id: u for u in users}
    return [
        {"id": uid, "username": users_by_id[uid].username, "avatar": users_by_id[uid].avatar, "mutual": mutual_by_id[uid]}
        for uid in suggested_ids
        if uid in users_by_id
    ]


def _normalized_phone_suffix(phone: str) -> str | None:
    """Сравниваем по последним 10 цифрам, чтобы различия в префиксе кода
    страны (+7 vs 8, +1 vs без плюса и т.д.) не мешали найти совпадение."""
    digits = "".join(ch for ch in phone if ch.isdigit())
    if len(digits) < 10:
        return None
    return digits[-10:]


@app.post("/users/{user_id}/contacts-match", dependencies=[Depends(rate_limit(5, 60))])
def match_contacts(
    user_id: int,
    payload: schemas.ContactsMatchRequest,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    """Сопоставляет номера из телефонной книги пользователя с телефонами,
    привязанными другими пользователями к своим аккаунтам. Без привязки к
    токену это был бы открытый «оракул номеров» — любой мог бы перебирать
    произвольные телефоны и узнавать, кто из них зарегистрирован в Kernelly."""
    _require_self(current_user, user_id)
    wanted_suffixes = {
        suffix for phone in payload.phones if (suffix := _normalized_phone_suffix(phone)) is not None
    }
    if not wanted_suffixes:
        return []

    candidates = (
        db.query(models.User)
        .filter(models.User.phone.isnot(None), models.User.id != user_id)
        .all()
    )
    matched = [
        u for u in candidates if _normalized_phone_suffix(u.phone) in wanted_suffixes
    ]
    if not matched:
        return []

    matched_ids = {u.id for u in matched}
    viewer_following, viewer_followers = _viewer_follow_flags(db, matched_ids, user_id)
    return [
        {
            "id": u.id,
            "username": u.username,
            "avatar": u.avatar,
            "is_following": u.id in viewer_following,
            # клиенту нужен исходный телефон, чтобы понять, какой именно контакт
            # из книги совпал, и не предлагать его повторно в списке «Пригласить»
            "phone": u.phone,
        }
        for u in matched
    ]


@app.post("/users/{user_id}/posts")
def create_post(
    user_id: int,
    payload: schemas.PostCreate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    _require_self(current_user, user_id)
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if user is None:
        raise HTTPException(status_code=404, detail="User not found")

    text = payload.text.strip()
    if not text:
        raise HTTPException(status_code=400, detail="Post text is empty")

    db.add(models.Post(user_id=user_id, text=text[:500]))
    db.commit()
    return {"status": "ok"}


def _feed_target_owner(db: Session, target_type: str, target_id: int) -> int:
    """Возвращает user_id владельца элемента ленты — автора поста или того,
    кто разблокировал достижение. Лайки/комментарии/уведомления общие для
    обоих типов элементов ленты, отличаются только тем, где искать владельца."""
    if target_type == "post":
        post = db.query(models.Post).filter(models.Post.id == target_id).first()
        if post is None:
            raise HTTPException(status_code=404, detail="Post not found")
        return post.user_id
    if target_type == "achievement":
        unlock = db.query(models.AchievementUnlock).filter(models.AchievementUnlock.id == target_id).first()
        if unlock is None:
            raise HTTPException(status_code=404, detail="Achievement unlock not found")
        return unlock.user_id
    raise HTTPException(status_code=400, detail="Invalid target type")


@app.post("/feed/{target_type}/{target_id}/like")
def toggle_feed_like(
    target_type: str,
    target_id: int,
    user_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    """Переключает лайк. При проставлении — обновляет/создаёт агрегированное
    уведомление владельцу элемента (не уведомляем самого себя о своих лайках)."""
    _require_self(current_user, user_id)
    owner_id = _feed_target_owner(db, target_type, target_id)

    existing = (
        db.query(models.PostLike)
        .filter(
            models.PostLike.target_type == target_type,
            models.PostLike.target_id == target_id,
            models.PostLike.user_id == user_id,
        )
        .first()
    )
    if existing is not None:
        db.delete(existing)
        db.commit()
        liked = False
    else:
        db.add(models.PostLike(target_type=target_type, target_id=target_id, user_id=user_id))
        db.commit()
        liked = True

        if owner_id != user_id:
            notif = (
                db.query(models.Notification)
                .filter(
                    models.Notification.target_type == target_type,
                    models.Notification.target_id == target_id,
                    models.Notification.type == "like",
                )
                .first()
            )
            if notif is None:
                db.add(models.Notification(
                    user_id=owner_id, actor_id=user_id, target_type=target_type, target_id=target_id,
                    type="like", count=1, read=False,
                ))
            else:
                notif.count += 1
                notif.actor_id = user_id
                notif.read = False
                notif.updated_at = datetime.utcnow()
            db.commit()

    like_count = (
        db.query(models.PostLike)
        .filter(models.PostLike.target_type == target_type, models.PostLike.target_id == target_id)
        .count()
    )
    return {"liked": liked, "like_count": like_count}


@app.get("/feed/{target_type}/{target_id}")
def get_feed_item(
    target_type: str,
    target_id: int,
    user_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    _require_self(current_user, user_id)
    like_count = (
        db.query(models.PostLike)
        .filter(models.PostLike.target_type == target_type, models.PostLike.target_id == target_id)
        .count()
    )
    comment_count = (
        db.query(models.PostComment)
        .filter(models.PostComment.target_type == target_type, models.PostComment.target_id == target_id)
        .count()
    )
    liked_by_me = (
        db.query(models.PostLike)
        .filter(
            models.PostLike.target_type == target_type,
            models.PostLike.target_id == target_id,
            models.PostLike.user_id == user_id,
        )
        .first()
        is not None
    )
    common = {
        "target_type": target_type,
        "target_id": target_id,
        "like_count": like_count,
        "comment_count": comment_count,
        "liked_by_me": liked_by_me,
    }

    def _user_out(author: models.User) -> dict:
        is_following = (
            author.id != user_id
            and db.query(models.Follow)
            .filter(models.Follow.follower_id == user_id, models.Follow.followee_id == author.id)
            .first()
            is not None
        )
        return {
            "id": author.id,
            "username": author.username,
            "avatar": author.avatar,
            "is_following": is_following,
        }

    if target_type == "post":
        post = db.query(models.Post).filter(models.Post.id == target_id).first()
        if post is None:
            raise HTTPException(status_code=404, detail="Post not found")
        author = db.query(models.User).filter(models.User.id == post.user_id).first()
        return {
            **common,
            "type": "post",
            "user": _user_out(author),
            "text": post.text,
            "created_at": post.created_at,
        }
    if target_type == "achievement":
        unlock = db.query(models.AchievementUnlock).filter(models.AchievementUnlock.id == target_id).first()
        if unlock is None:
            raise HTTPException(status_code=404, detail="Achievement unlock not found")
        author = db.query(models.User).filter(models.User.id == unlock.user_id).first()
        achievement = _achievement_feed_info(unlock.code)
        return {
            **common,
            "type": "achievement",
            "user": _user_out(author),
            "achievement": achievement,
            "created_at": unlock.unlocked_at,
        }
    raise HTTPException(status_code=400, detail="Invalid target type")


@app.get("/feed/{target_type}/{target_id}/comments")
def get_feed_comments(
    target_type: str,
    target_id: int,
    user_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    _require_self(current_user, user_id)
    _feed_target_owner(db, target_type, target_id)

    comments = (
        db.query(models.PostComment)
        .filter(models.PostComment.target_type == target_type, models.PostComment.target_id == target_id)
        .order_by(models.PostComment.created_at.asc())
        .all()
    )
    author_ids = {c.user_id for c in comments}
    users_by_id = {u.id: u for u in db.query(models.User).filter(models.User.id.in_(author_ids)).all()}
    following_ids = {
        row.followee_id for row in db.query(models.Follow).filter(models.Follow.follower_id == user_id).all()
    }
    return [
        {
            "id": c.id,
            "user": {
                "id": c.user_id,
                "username": users_by_id[c.user_id].username if c.user_id in users_by_id else "Игрок",
                "avatar": users_by_id[c.user_id].avatar if c.user_id in users_by_id else None,
                "is_following": c.user_id != user_id and c.user_id in following_ids,
            },
            "text": c.text,
            "created_at": c.created_at,
        }
        for c in comments
    ]


@app.post("/feed/{target_type}/{target_id}/comments")
def add_feed_comment(
    target_type: str,
    target_id: int,
    user_id: int,
    payload: schemas.CommentCreate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    _require_self(current_user, user_id)
    owner_id = _feed_target_owner(db, target_type, target_id)

    text = payload.text.strip()
    if not text:
        raise HTTPException(status_code=400, detail="Comment text is empty")
    text = text[:300]

    db.add(models.PostComment(target_type=target_type, target_id=target_id, user_id=user_id, text=text))

    if owner_id != user_id:
        db.add(models.Notification(
            user_id=owner_id, actor_id=user_id, target_type=target_type, target_id=target_id,
            type="comment", count=1, comment_text=text, read=False,
        ))

    db.commit()
    return {"status": "ok"}


@app.get("/users/{user_id}/notifications")
def get_notifications(
    user_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    _require_self(current_user, user_id)
    notifications = (
        db.query(models.Notification)
        .filter(models.Notification.user_id == user_id)
        .order_by(models.Notification.updated_at.desc())
        .limit(50)
        .all()
    )
    actor_ids = {n.actor_id for n in notifications}
    users_by_id = {u.id: u for u in db.query(models.User).filter(models.User.id.in_(actor_ids)).all()}
    return [
        {
            "id": n.id,
            "type": n.type,
            "target_type": n.target_type,
            "target_id": n.target_id,
            "count": n.count,
            "comment_text": n.comment_text,
            "read": n.read,
            "actor": {
                "id": n.actor_id,
                "username": users_by_id[n.actor_id].username if n.actor_id in users_by_id else "Игрок",
            },
            "updated_at": n.updated_at,
        }
        for n in notifications
    ]


@app.post("/users/{user_id}/notifications/read")
def mark_notifications_read(
    user_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    _require_self(current_user, user_id)
    db.query(models.Notification).filter(
        models.Notification.user_id == user_id, models.Notification.read.is_(False)
    ).update({"read": True})
    db.commit()
    return {"status": "ok"}


def _achievement_feed_info(code: str) -> dict | None:
    """Разбирает code вида "streak_3" (семья_уровень) для отображения в ленте."""
    try:
        family_key, level_str = code.rsplit("_", 1)
        level_index = int(level_str)
    except ValueError:
        return None
    family = FAMILIES_BY_KEY.get(family_key)
    if family is None or not (1 <= level_index <= len(family["thresholds"])):
        return None
    level_name = ACHIEVEMENT_LEVELS[level_index - 1]
    return {
        "code": code,
        "title": f'{family["title"]} · {ACHIEVEMENT_LEVEL_TITLES[level_name]}',
        "icon": family["icon"],
        "style": level_name,
    }


FEED_PAGE_SIZE = 50


@app.get("/users/{user_id}/feed")
def get_feed(
    user_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    """Лента активности: посты и разблокировки достижений от тех, на кого
    подписан пользователь, плюс его собственные — подписка односторонняя,
    видимость взаимности не требует."""
    _require_self(current_user, user_id)
    following_ids = {
        row.followee_id for row in db.query(models.Follow).filter(models.Follow.follower_id == user_id).all()
    }
    scope_ids = following_ids | {user_id}

    users_by_id = {u.id: u for u in db.query(models.User).filter(models.User.id.in_(scope_ids)).all()}

    events = []

    posts = (
        db.query(models.Post)
        .filter(models.Post.user_id.in_(scope_ids))
        .order_by(models.Post.created_at.desc())
        .limit(FEED_PAGE_SIZE)
        .all()
    )
    unlocks = (
        db.query(models.AchievementUnlock)
        .filter(models.AchievementUnlock.user_id.in_(scope_ids))
        .order_by(models.AchievementUnlock.unlocked_at.desc())
        .limit(FEED_PAGE_SIZE)
        .all()
    )

    # лайки/комментарии считаем одним запросом сразу для постов и
    # достижений этой страницы ленты — targets хранит (type, id) → запись
    post_ids = [post.id for post in posts]
    unlock_ids = [unlock.id for unlock in unlocks]

    like_counts: dict[tuple[str, int], int] = {}
    for target_type, target_id, count in (
        db.query(models.PostLike.target_type, models.PostLike.target_id, func.count(models.PostLike.id))
        .filter(
            ((models.PostLike.target_type == "post") & (models.PostLike.target_id.in_(post_ids)))
            | ((models.PostLike.target_type == "achievement") & (models.PostLike.target_id.in_(unlock_ids)))
        )
        .group_by(models.PostLike.target_type, models.PostLike.target_id)
        .all()
    ):
        like_counts[(target_type, target_id)] = count

    comment_counts: dict[tuple[str, int], int] = {}
    for target_type, target_id, count in (
        db.query(models.PostComment.target_type, models.PostComment.target_id, func.count(models.PostComment.id))
        .filter(
            ((models.PostComment.target_type == "post") & (models.PostComment.target_id.in_(post_ids)))
            | ((models.PostComment.target_type == "achievement") & (models.PostComment.target_id.in_(unlock_ids)))
        )
        .group_by(models.PostComment.target_type, models.PostComment.target_id)
        .all()
    ):
        comment_counts[(target_type, target_id)] = count

    liked_targets = {
        (row.target_type, row.target_id)
        for row in db.query(models.PostLike.target_type, models.PostLike.target_id)
        .filter(
            models.PostLike.user_id == user_id,
            (
                ((models.PostLike.target_type == "post") & (models.PostLike.target_id.in_(post_ids)))
                | ((models.PostLike.target_type == "achievement") & (models.PostLike.target_id.in_(unlock_ids)))
            ),
        )
        .all()
    }

    for post in posts:
        author = users_by_id.get(post.user_id)
        if author is None:
            continue
        events.append({
            "type": "post",
            "target_type": "post",
            "target_id": post.id,
            "user": {
                "id": author.id, "username": author.username, "avatar": author.avatar,
                "is_following": author.id in following_ids,
            },
            "text": post.text,
            "created_at": post.created_at,
            "like_count": like_counts.get(("post", post.id), 0),
            "comment_count": comment_counts.get(("post", post.id), 0),
            "liked_by_me": ("post", post.id) in liked_targets,
        })

    for unlock in unlocks:
        author = users_by_id.get(unlock.user_id)
        achievement = _achievement_feed_info(unlock.code)
        if author is None or achievement is None:
            continue
        events.append({
            "type": "achievement",
            "target_type": "achievement",
            "target_id": unlock.id,
            "user": {
                "id": author.id, "username": author.username, "avatar": author.avatar,
                "is_following": author.id in following_ids,
            },
            "achievement": {
                "code": achievement["code"],
                "title": achievement["title"],
                "icon": achievement["icon"],
                "style": achievement["style"],
            },
            "created_at": unlock.unlocked_at,
            "like_count": like_counts.get(("achievement", unlock.id), 0),
            "comment_count": comment_counts.get(("achievement", unlock.id), 0),
            "liked_by_me": ("achievement", unlock.id) in liked_targets,
        })

    events.sort(key=lambda e: e["created_at"], reverse=True)
    return events[:FEED_PAGE_SIZE]