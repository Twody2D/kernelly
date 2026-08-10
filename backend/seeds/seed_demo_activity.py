"""Пара демо-пользователей с иллюзией активности — чтобы лента, топ игроков и
чужие профили не выглядели пустыми при демонстрации приложения. В отличие от
seed_demo_friend.py (один друг под сравнение недельного графика), тут сразу
двое: заметно разного уровня, с постами в ленте и настоящими достижениями.

Запуск из папки backend:
    venv\\Scripts\\python.exe -m seeds.seed_demo_activity

Идемпотентен: пропускает уже существующих по username пользователей.
"""

from datetime import datetime, timedelta

from app.database import SessionLocal
from app import models
from app.main import _msk_week_start, _week_start_to_utc

ME_USER_ID = 19  # Twody — реальный аккаунт в текущей dev-базе

PERSONAS = [
    {
        "username": "kate_codes",
        "avatar": "star",
        "xp": 1820,
        "streak": 45,
        "cores": 210,
        "streak_freezes": 2,
        "perfect_lessons_count": 9,
        "lessons_completed": 35,
        "created_days_ago": 95,
        # XP по дням текущей недели лиги, пн..вс
        "daily_xp": [400, 350, 200, 550, 150, 600, 250],
        "posts": [
            "Наконец разобралась с systemd — юниты теперь не кажутся магией",
            "45 дней подряд, не останавливаюсь!",
        ],
    },
    {
        "username": "devlex",
        "avatar": "bug",
        "xp": 340,
        "streak": 6,
        "cores": 40,
        "streak_freezes": 1,
        "perfect_lessons_count": 2,
        "lessons_completed": 12,
        "created_days_ago": 12,
        "daily_xp": [40, 0, 60, 30, 0, 20, 10],
        "posts": [
            "Первую неделю прошёл без пропусков, погнали дальше",
        ],
    },
]

# Должно совпадать с ACHIEVEMENT_FAMILIES в app/main.py — пороги захардкожены
# тут же, чтобы не тянуть достижения на лету: сиду важно, что запишется в
# AchievementUnlock, а не как именно на сервере считается уровень.
FAMILY_THRESHOLDS = {
    "streak": [3, 14, 30, 60, 100],
    "xp": [100, 500, 1000, 2500, 5000],
    "lessons": [5, 10, 25, 50, 100],
    "accuracy": [1, 5, 10, 25, 50],
}


def _reached_level(value: int, thresholds: list[int]) -> int:
    level = 0
    for threshold in thresholds:
        if value >= threshold:
            level += 1
        else:
            break
    return level


def seed():
    db = SessionLocal()
    try:
        lessons = db.query(models.Lesson).order_by(models.Lesson.id).all()
        if not lessons:
            print("нет ни одного урока в базе — сначала запусти seed_demo")
            return

        week_start_utc = _week_start_to_utc(_msk_week_start(datetime.utcnow()))

        for persona in PERSONAS:
            existing = db.query(models.User).filter(models.User.username == persona["username"]).first()
            if existing is not None:
                print(f"пропущено: {persona['username']} уже существует (id={existing.id})")
                continue

            user = models.User(
                username=persona["username"],
                avatar=persona["avatar"],
                auth_provider="guest",
                xp=persona["xp"],
                streak=persona["streak"],
                cores=persona["cores"],
                streak_freezes=persona["streak_freezes"],
                perfect_lessons_count=persona["perfect_lessons_count"],
                created_at=datetime.utcnow() - timedelta(days=persona["created_days_ago"]),
            )
            db.add(user)
            db.flush()

            db.add(models.Follow(follower_id=ME_USER_ID, followee_id=user.id))
            db.add(models.Follow(follower_id=user.id, followee_id=ME_USER_ID))

            # Уроки — для стата «lessons_completed» и достижений семьи «lessons»
            for lesson in lessons[: persona["lessons_completed"]]:
                db.add(models.UserProgress(
                    user_id=user.id,
                    lesson_id=lesson.id,
                    completed_at=datetime.utcnow() - timedelta(days=persona["created_days_ago"] - 1),
                ))

            # Ответы этой недели лиги — чтобы попасть в топ игроков и в график
            # сравнения активности на чужом профиле
            exercise_id = db.query(models.Exercise).first().id
            for offset, xp in enumerate(persona["daily_xp"]):
                correct_count = xp // 10
                day_start = week_start_utc + timedelta(days=offset, hours=10)
                for i in range(correct_count):
                    db.add(models.Answer(
                        user_id=user.id,
                        exercise_id=exercise_id,
                        is_correct=True,
                        created_at=day_start + timedelta(minutes=i),
                    ))

            # Достижения — реальные разблокировки по тем же порогам, что и на сервере
            values = {
                "streak": persona["streak"],
                "xp": persona["xp"],
                "lessons": persona["lessons_completed"],
                "accuracy": persona["perfect_lessons_count"],
            }
            for family, thresholds in FAMILY_THRESHOLDS.items():
                reached = _reached_level(values[family], thresholds)
                for level_index in range(1, reached + 1):
                    db.add(models.AchievementUnlock(
                        user_id=user.id,
                        code=f"{family}_{level_index}",
                        unlocked_at=datetime.utcnow() - timedelta(days=persona["created_days_ago"] - 2),
                    ))

            # Пара постов в ленту
            for i, text in enumerate(persona["posts"]):
                db.add(models.Post(
                    user_id=user.id,
                    text=text,
                    created_at=datetime.utcnow() - timedelta(days=i, hours=3),
                ))

            db.commit()
            print(f"создан {persona['username']} (id={user.id})")
    finally:
        db.close()


if __name__ == "__main__":
    seed()
