from fastapi import FastAPI, Depends, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import func
from sqlalchemy.orm import Session
from app.database import Base, engine, get_db
from app import models, schemas
from datetime import date, timedelta

XP_PER_CORRECT = 10

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


@app.get("/lessons/{lesson_id}/exercises", response_model=list[schemas.ExerciseOut])
def get_lesson_exercises(lesson_id: int, db: Session = Depends(get_db)):
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

    is_correct = submission.answer == exercise.correct_answer

    user = db.query(models.User).filter(models.User.id == 1).first()

    db.add(models.Answer(user_id=1, exercise_id=exercise_id, is_correct=is_correct))

    today = date.today()
    if user.last_activity_date != today:
        if user.last_activity_date == today - timedelta(days=1):
            user.streak += 1
        else:
            user.streak = 1
        user.last_activity_date = today

    db.commit()

    return {"correct": is_correct}


@app.post("/users/{user_id}/award-xp")
def award_xp(user_id: int, payload: schemas.LessonComplete, db: Session = Depends(get_db)):
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if user is None:
        raise HTTPException(status_code=404, detail="User not found")
    user.xp += payload.correct_count * XP_PER_CORRECT
    db.commit()
    return {"xp": user.xp}

@app.get("/sections/{section_id}/lessons-progress")
def get_lessons_progress(section_id: int, db: Session = Depends(get_db)):
    lessons = (
        db.query(models.Lesson)
        .filter(models.Lesson.section_id == section_id)
        .order_by(models.Lesson.order)
        .all()
    )

    completed_lesson_ids = {
        row.lesson_id
        for row in db.query(models.UserProgress)
        .filter(models.UserProgress.user_id == 1)
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
def complete_lesson(lesson_id: int, db: Session = Depends(get_db)):
    existing = (
        db.query(models.UserProgress)
        .filter(models.UserProgress.user_id == 1, models.UserProgress.lesson_id == lesson_id)
        .first()
    )
    if existing is None:
        progress = models.UserProgress(user_id=1, lesson_id=lesson_id)
        db.add(progress)
        db.commit()
    return {"status": "ok"}


@app.get("/courses/{course_id}/sections", response_model=list[schemas.SectionOut])
def get_course_sections(course_id: int, db: Session = Depends(get_db)):
    return (
        db.query(models.Section)
        .filter(models.Section.course_id == course_id)
        .order_by(models.Section.order)
        .all()
    )


@app.get("/courses/{course_id}/progress")
def get_course_progress(course_id: int, db: Session = Depends(get_db)):
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
        .filter(models.UserProgress.user_id == 1, models.UserProgress.lesson_id.in_(lesson_ids))
        .count()
        if lesson_ids
        else 0
    )

    return {"completed": completed, "total": total}


@app.get("/courses/overview")
def get_courses_overview(db: Session = Depends(get_db)):
    courses = db.query(models.Course).all()
    completed_ids = {
        row.lesson_id
        for row in db.query(models.UserProgress.lesson_id)
        .filter(models.UserProgress.user_id == 1)
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

        if c.is_coming_soon:
            locked = True
            requirement = "скоро"
        elif c.required_course_id is not None:
            req = stats.get(c.required_course_id, {"completed": 0, "total": 0})
            pct = (req["completed"] / req["total"] * 100) if req["total"] else 0
            need = c.required_percent or 0
            if pct < need:
                locked = True
                requirement = f'нужен «{titles.get(c.required_course_id, "")}» {need}%'

        result.append({
            "id": c.id,
            "title": c.title,
            "completed": s["completed"],
            "total": s["total"],
            "locked": locked,
            "requirement": requirement,
        })

    return result


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
        "xp": user.xp,
        "streak": user.streak,
        "lessons_completed": stats["lessons_completed"],
        "accuracy": stats["accuracy"],
        "created_at": user.created_at,
    }


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