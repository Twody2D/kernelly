from fastapi import FastAPI, Depends, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from google.auth.transport import requests as google_requests
from google.oauth2 import id_token as google_id_token
from sqlalchemy import func
from sqlalchemy.orm import Session
from app.database import Base, engine, get_db
from app import models, schemas
from datetime import date, datetime, timedelta
import random

XP_PER_CORRECT = 10

# Алгоритм Лейтнера: box → через сколько дней повторять. Правильный ответ по
# тегу навыка поднимает его на box выше (интервал растёт), неправильный
# сбрасывает в box 1 — «повторить завтра». MAX_BOX ограничивает верхнюю границу.
REVIEW_INTERVALS_DAYS = {1: 1, 2: 3, 3: 7, 4: 16, 5: 35}
MAX_BOX = max(REVIEW_INTERVALS_DAYS)
REVIEW_SESSION_SIZE = 12


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

app = FastAPI() #test backend

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

Base.metadata.create_all(bind=engine)


@app.get("/")
def read_root():
    return {"status": "Kernelly API is running"}


@app.get("/courses", response_model=list[schemas.CourseOut])
def get_courses(db: Session = Depends(get_db)):
    return db.query(models.Course).all()


@app.post("/courses", response_model=schemas.CourseOut)
def create_course(course: schemas.CourseCreate, db: Session = Depends(get_db)):
    new_course = models.Course(title=course.title, description=course.description)
    db.add(new_course)
    db.commit()
    db.refresh(new_course)
    return new_course


@app.get("/sections", response_model=list[schemas.SectionOut])
def get_sections(db: Session = Depends(get_db)):
    return db.query(models.Section).all()


@app.post("/sections", response_model=schemas.SectionOut)
def create_section(section: schemas.SectionCreate, db: Session = Depends(get_db)):
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
def get_lessons(db: Session = Depends(get_db)):
    return db.query(models.Lesson).all()


@app.post("/lessons", response_model=schemas.LessonOut)
def create_lesson(lesson: schemas.LessonCreate, db: Session = Depends(get_db)):
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
def get_exercises(db: Session = Depends(get_db)):
    return db.query(models.Exercise).all()


@app.post("/exercises", response_model=schemas.ExerciseOut)
def create_exercise(exercise: schemas.ExerciseCreate, db: Session = Depends(get_db)):
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


@app.get("/users/{user_id}", response_model=schemas.UserOut)
def get_user(user_id: int, db: Session = Depends(get_db)):
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if user is None:
        raise HTTPException(status_code=404, detail="User not found")
    return user


@app.post("/users", response_model=schemas.UserOut)
def create_user(user: schemas.UserCreate, db: Session = Depends(get_db)):
    new_user = models.User(username=user.username)
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    return new_user


@app.post("/users/guest", response_model=schemas.UserOut)
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


@app.post("/auth/google", response_model=schemas.UserOut)
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
def update_profile(user_id: int, payload: schemas.ProfileUpdate, db: Session = Depends(get_db)):
    """Имя и аватарка, которые выбираются один раз после первого входа через Google."""
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
def get_lesson(lesson_id: int, user_id: int, db: Session = Depends(get_db)):
    _assert_course_unlocked(db, _course_id_for_lesson(db, lesson_id), user_id)
    lesson = db.query(models.Lesson).filter(models.Lesson.id == lesson_id).first()
    if lesson is None:
        raise HTTPException(status_code=404, detail="Lesson not found")
    return lesson


@app.get("/lessons/{lesson_id}/exercises", response_model=list[schemas.ExerciseOut])
def get_lesson_exercises(lesson_id: int, user_id: int, db: Session = Depends(get_db)):
    _assert_course_unlocked(db, _course_id_for_lesson(db, lesson_id), user_id)
    return (
        db.query(models.Exercise)
        .filter(models.Exercise.lesson_id == lesson_id)
        .order_by(models.Exercise.order)
        .all()
    )


@app.post("/exercises/{exercise_id}/submit")
def submit_answer(exercise_id: int, submission: schemas.AnswerSubmit, db: Session = Depends(get_db)):
    exercise = db.query(models.Exercise).filter(models.Exercise.id == exercise_id).first()
    if exercise is None:
        raise HTTPException(status_code=404, detail="Exercise not found")

    _assert_course_unlocked(db, _course_id_for_lesson(db, exercise.lesson_id), submission.user_id)

    is_correct = submission.answer == exercise.correct_answer

    user = db.query(models.User).filter(models.User.id == submission.user_id).first()
    if user is None:
        raise HTTPException(status_code=404, detail="User not found")

    db.add(models.Answer(user_id=submission.user_id, exercise_id=exercise_id, is_correct=is_correct))
    _update_skill_progress(db, submission.user_id, exercise.skill_tags, is_correct)

    # день засчитывается в streak только за верный ответ
    if is_correct:
        today = date.today()
        if user.last_activity_date != today:
            if user.last_activity_date == today - timedelta(days=1):
                user.streak += 1
            else:
                user.streak = 1
            user.last_activity_date = today

    db.commit()

    # ответ уже дан, поэтому правильный вариант можно показать
    correct_answer = exercise.correct_answer
    if isinstance(correct_answer, dict):
        correct_answer = correct_answer.get("answer")

    return {"correct": is_correct, "correct_answer": correct_answer, "streak": user.streak}


@app.get("/users/{user_id}/review/due")
def get_review_due(user_id: int, db: Session = Depends(get_db)):
    """Сколько навыков сейчас просрочено для повторения — бейдж на карточке
    «Повторение» на главном экране."""
    count = (
        db.query(models.SkillProgress)
        .filter(models.SkillProgress.user_id == user_id, models.SkillProgress.next_review_at <= datetime.utcnow())
        .count()
    )
    return {"due": count}


@app.get("/users/{user_id}/review/session", response_model=list[schemas.ReviewExerciseOut])
def get_review_session(user_id: int, db: Session = Depends(get_db)):
    """Собирает сессию повторения: по одному случайному упражнению на каждый
    просроченный навык, самые просроченные — первыми."""
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
def award_xp(user_id: int, payload: schemas.LessonComplete, db: Session = Depends(get_db)):
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if user is None:
        raise HTTPException(status_code=404, detail="User not found")
    user.xp += payload.correct_count * XP_PER_CORRECT
    db.commit()
    return {"xp": user.xp}

@app.get("/sections/{section_id}/lessons-progress")
def get_lessons_progress(section_id: int, user_id: int, db: Session = Depends(get_db)):
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
        })

    return result

@app.post("/lessons/{lesson_id}/complete")
def complete_lesson(lesson_id: int, user_id: int, db: Session = Depends(get_db)):
    lesson = db.query(models.Lesson).filter(models.Lesson.id == lesson_id).first()
    if lesson is None:
        raise HTTPException(status_code=404, detail="Lesson not found")

    _assert_course_unlocked(db, _course_id_for_section(db, lesson.section_id), user_id)

    existing = (
        db.query(models.UserProgress)
        .filter(models.UserProgress.user_id == user_id, models.UserProgress.lesson_id == lesson_id)
        .first()
    )
    if existing is None:
        progress = models.UserProgress(user_id=user_id, lesson_id=lesson_id)
        db.add(progress)
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

    return {
        "status": "ok",
        "lesson_title": lesson.title,
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
def get_course_sections(course_id: int, user_id: int, db: Session = Depends(get_db)):
    _assert_course_unlocked(db, course_id, user_id)
    return (
        db.query(models.Section)
        .filter(models.Section.course_id == course_id)
        .order_by(models.Section.order)
        .all()
    )


@app.get("/courses/{course_id}/sections-progress")
def get_sections_progress(course_id: int, user_id: int, db: Session = Depends(get_db)):
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
def get_course_progress(course_id: int, user_id: int, db: Session = Depends(get_db)):
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


@app.get("/courses/overview")
def get_courses_overview(user_id: int, db: Session = Depends(get_db)):
    return _courses_with_status(db, user_id)


@app.get("/users/{user_id}/current-section")
def get_current_section(user_id: int, db: Session = Depends(get_db)):
    """Раздел, с которого пользователю продолжать: первый незавершённый
    в первом незавершённом доступном курсе."""
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

ACHIEVEMENTS = [
    {"code": "streak_3", "title": "3 дня", "description": "Три дня подряд", "icon": "🔥", "style": "gold", "metric": "streak", "target": 3},
    {"code": "streak_7", "title": "7 дней", "description": "Неделя без пропусков", "icon": "🔥", "style": "gold", "metric": "streak", "target": 7},
    {"code": "streak_14", "title": "14 дней", "description": "Две недели подряд", "icon": "🔥", "style": "gold", "metric": "streak", "target": 14},
    {"code": "streak_30", "title": "30 дней", "description": "Месяц без пропусков", "icon": "🔥", "style": "gold", "metric": "streak", "target": 30},
    {"code": "streak_60", "title": "60 дней", "description": "Два месяца подряд", "icon": "🔥", "style": "gold", "metric": "streak", "target": 60},
    {"code": "streak_100", "title": "100 дней", "description": "Сто дней подряд", "icon": "🔥", "style": "gold", "metric": "streak", "target": 100},

    {"code": "lessons_1", "title": "первый", "description": "Первый пройденный урок", "icon": "✓", "style": "green", "metric": "lessons", "target": 1},
    {"code": "lessons_5", "title": "5 уроков", "description": "Пять пройденных уроков", "icon": "✓", "style": "green", "metric": "lessons", "target": 5},
    {"code": "lessons_10", "title": "10 уроков", "description": "Десять пройденных уроков", "icon": "✓", "style": "green", "metric": "lessons", "target": 10},
    {"code": "lessons_25", "title": "25 уроков", "description": "Двадцать пять уроков", "icon": "✓", "style": "green", "metric": "lessons", "target": 25},
    {"code": "lessons_50", "title": "50 уроков", "description": "Полсотни уроков", "icon": "✓", "style": "green", "metric": "lessons", "target": 50},
    {"code": "lessons_100", "title": "100 уроков", "description": "Сто пройденных уроков", "icon": "✓", "style": "green", "metric": "lessons", "target": 100},

    {"code": "xp_100", "title": "старт", "description": "Первые 100 XP", "icon": "100", "style": "teal", "metric": "xp", "target": 100},
    {"code": "xp_500", "title": "разгон", "description": "500 XP", "icon": "500", "style": "teal", "metric": "xp", "target": 500},
    {"code": "xp_1000", "title": "root", "description": "1000 XP", "icon": "sudo", "style": "teal", "metric": "xp", "target": 1000},
    {"code": "xp_2500", "title": "2.5k", "description": "2500 XP", "icon": "2.5k", "style": "teal", "metric": "xp", "target": 2500},
    {"code": "xp_5000", "title": "5k", "description": "5000 XP", "icon": "5k", "style": "teal", "metric": "xp", "target": 5000},
    {"code": "xp_10000", "title": "10k", "description": "10000 XP", "icon": "10k", "style": "teal", "metric": "xp", "target": 10000},

    {"code": "acc_70", "title": "70%", "description": "Точность 70%", "icon": "🎯", "style": "teal", "metric": "accuracy", "target": 70},
    {"code": "acc_80", "title": "80%", "description": "Точность 80%", "icon": "🎯", "style": "teal", "metric": "accuracy", "target": 80},
    {"code": "acc_90", "title": "90%", "description": "Точность 90%", "icon": "🎯", "style": "teal", "metric": "accuracy", "target": 90},
    {"code": "acc_95", "title": "95%", "description": "Точность 95%", "icon": "🎯", "style": "teal", "metric": "accuracy", "target": 95},
    {"code": "acc_99", "title": "99%", "description": "Точность 99%", "icon": "🎯", "style": "teal", "metric": "accuracy", "target": 99},
    {"code": "acc_100", "title": "без ошибок", "description": "Точность 100%", "icon": "🎯", "style": "teal", "metric": "accuracy", "target": 100},
]


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


@app.get("/users/{user_id}/stats")
def get_user_stats(user_id: int, db: Session = Depends(get_db)):
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if user is None:
        raise HTTPException(status_code=404, detail="User not found")

    stats = _collect_stats(user, db)

    return {
        "id": user.id,
        "username": user.username,
        "avatar": user.avatar,
        "email": user.email,
        "xp": user.xp,
        "streak": user.streak,
        "lessons_completed": stats["lessons_completed"],
        "accuracy": stats["accuracy"],
        "created_at": user.created_at,
        "auth_provider": user.auth_provider,
    }


@app.get("/users/{user_id}/daily-progress")
def get_daily_progress(user_id: int, db: Session = Depends(get_db)):
    """Сколько уроков пройдено сегодня. Саму цель хранит приложение локально."""
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if user is None:
        raise HTTPException(status_code=404, detail="User not found")

    today = date.today()
    lessons_completed = (
        db.query(models.UserProgress)
        .filter(
            models.UserProgress.user_id == user_id,
            func.date(models.UserProgress.completed_at) == today,
        )
        .count()
    )

    return {"date": today.isoformat(), "lessons_completed": lessons_completed}


@app.get("/users/{user_id}/activity")
def get_user_activity(user_id: int, db: Session = Depends(get_db)):
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if user is None:
        raise HTTPException(status_code=404, detail="User not found")

    today = date.today()
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
def get_user_achievements(user_id: int, db: Session = Depends(get_db)):
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if user is None:
        raise HTTPException(status_code=404, detail="User not found")

    stats = _collect_stats(user, db)
    values = {
        "streak": user.streak,
        "xp": user.xp,
        "lessons": stats["lessons_completed"],
        "accuracy": stats["accuracy"] or 0,
    }

    enough_answers = stats["total_answers"] >= MIN_ANSWERS_FOR_ACCURACY

    items = []
    for achievement in ACHIEVEMENTS:
        metric = achievement["metric"]
        value = values[metric]
        unlocked = value >= achievement["target"]
        if metric == "accuracy" and not enough_answers:
            unlocked = False

        items.append({
            "code": achievement["code"],
            "title": achievement["title"],
            "description": achievement["description"],
            "icon": achievement["icon"],
            "style": achievement["style"],
            "unlocked": unlocked,
        })

    return {
        "unlocked": sum(1 for i in items if i["unlocked"]),
        "total": len(items),
        "items": items,
    }