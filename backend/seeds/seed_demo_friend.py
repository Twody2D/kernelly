"""Демо-друг с придуманной активностью — нужен, чтобы было с кем сравнивать
недельный график на экране чужого профиля.

Запуск из папки backend:
    venv\\Scripts\\python.exe -m seeds.seed_demo_friend

Идемпотентен: если пользователь mars_dev уже существует, повторно ничего не создаёт.
"""

from datetime import datetime, timedelta

from app.database import SessionLocal
from app import models

ME_USER_ID = 19  # Twody — реальный аккаунт в текущей dev-базе
FRIEND_USERNAME = "mars_dev"

# XP по дням пн..вс — при XP_PER_CORRECT=10 это число правильных ответов * 10
DAILY_XP = [300, 260, 190, 490, 60, 340, 120]


def seed():
    db = SessionLocal()
    try:
        friend = db.query(models.User).filter(models.User.username == FRIEND_USERNAME).first()
        if friend is not None:
            print(f"пропущено: {FRIEND_USERNAME} уже существует (id={friend.id})")
            return

        exercise = db.query(models.Exercise).first()
        if exercise is None:
            print("нет ни одного упражнения в базе — сначала запусти seed_demo")
            return

        friend = models.User(
            username=FRIEND_USERNAME,
            avatar="rocket",
            auth_provider="guest",
            xp=sum(DAILY_XP) * 3,
            streak=12,
            created_at=datetime.utcnow() - timedelta(days=40),
        )
        db.add(friend)
        db.flush()

        db.add(models.Follow(follower_id=ME_USER_ID, followee_id=friend.id))
        db.add(models.Follow(follower_id=friend.id, followee_id=ME_USER_ID))

        today = datetime.utcnow().date()
        start = today - timedelta(days=6)
        for offset, xp in enumerate(DAILY_XP):
            day = start + timedelta(days=offset)
            correct_count = xp // 10
            for i in range(correct_count):
                db.add(models.Answer(
                    user_id=friend.id,
                    exercise_id=exercise.id,
                    is_correct=True,
                    created_at=datetime.combine(day, datetime.min.time()) + timedelta(hours=10, minutes=i),
                ))

        db.commit()
        print(f"создан друг {FRIEND_USERNAME} (id={friend.id}), взаимная подписка с user_id={ME_USER_ID}")
    finally:
        db.close()


if __name__ == "__main__":
    seed()
