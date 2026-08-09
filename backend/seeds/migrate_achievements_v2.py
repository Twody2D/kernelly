"""Одноразовая ручная миграция: переход достижений с плоского списка (24 штуки)
на 4 семьи (streak/xp/lessons/accuracy) по 5 уровней (бронза..бедрок).

1. Добавляет колонку users.perfect_lessons_count (новая метрика для семьи
   «Точность» — раньше это был % правильных ответов за всё время, теперь —
   число уроков, пройденных со 100% точностью; для существующих пользователей
   стартует с 0, история такого не считала).
2. Полностью очищает старые записи achievement_unlocks (коды вида "streak_3"
   больше не соответствуют новой схеме "streak_1".."streak_5") и пересчитывает
   заново по текущим метрикам каждого пользователя.
3. Все пересчитанные уровни помечаются chest_claimed=True — то, что уже было
   пройдено раньше, не выдаёт ядра задним числом по новой схеме.

Запуск: venv/Scripts/python.exe -m seeds.migrate_achievements_v2
"""
from sqlalchemy import text
from app.database import engine, SessionLocal
from app import models

FAMILIES = [
    {"family": "streak", "metric": lambda u, lessons: u.streak, "thresholds": [3, 14, 30, 60, 100]},
    {"family": "xp", "metric": lambda u, lessons: u.xp, "thresholds": [100, 500, 1000, 2500, 5000]},
    {"family": "lessons", "metric": lambda u, lessons: lessons, "thresholds": [5, 10, 25, 50, 100]},
    {"family": "accuracy", "metric": lambda u, lessons: u.perfect_lessons_count, "thresholds": [1, 5, 10, 25, 50]},
]


def _level(value: int, thresholds: list[int]) -> int:
    level = 0
    for threshold in thresholds:
        if value >= threshold:
            level += 1
        else:
            break
    return level


def run():
    with engine.begin() as conn:
        stmt = "ALTER TABLE users ADD COLUMN IF NOT EXISTS perfect_lessons_count INTEGER NOT NULL DEFAULT 0"
        print(f"-> {stmt}")
        conn.execute(text(stmt))

    db = SessionLocal()
    try:
        deleted = db.query(models.AchievementUnlock).delete(synchronize_session=False)
        print(f"-> удалено старых записей achievement_unlocks: {deleted}")

        users = db.query(models.User).all()
        created = 0
        for user in users:
            lessons_completed = (
                db.query(models.UserProgress)
                .filter(models.UserProgress.user_id == user.id)
                .count()
            )
            for family in FAMILIES:
                value = family["metric"](user, lessons_completed)
                level = _level(value, family["thresholds"])
                for level_index in range(1, level + 1):
                    code = f'{family["family"]}_{level_index}'
                    db.add(models.AchievementUnlock(
                        user_id=user.id,
                        code=code,
                        chest_claimed=True,
                    ))
                    created += 1
        db.commit()
        print(f"-> пересчитано пользователей: {len(users)}, создано новых записей: {created}")
    finally:
        db.close()

    print("Готово.")


if __name__ == "__main__":
    run()
