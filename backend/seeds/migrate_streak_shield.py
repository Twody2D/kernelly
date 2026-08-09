"""Одноразовая ручная миграция: добавляет колонки streak_shield_enabled,
streak_freezes, streak_freeze_refreshed_at в таблицу users на уже
существующей БД (Base.metadata.create_all не меняет существующие таблицы —
см. CLAUDE.md). Идемпотентно за счёт IF NOT EXISTS.

Запуск: venv/Scripts/python.exe -m seeds.migrate_streak_shield
"""
from sqlalchemy import text
from app.database import engine

STATEMENTS = [
    "ALTER TABLE users ADD COLUMN IF NOT EXISTS streak_shield_enabled BOOLEAN NOT NULL DEFAULT FALSE",
    "ALTER TABLE users ADD COLUMN IF NOT EXISTS streak_freezes INTEGER NOT NULL DEFAULT 1",
    "ALTER TABLE users ADD COLUMN IF NOT EXISTS streak_freeze_refreshed_at DATE",
]


def run():
    with engine.begin() as conn:
        for stmt in STATEMENTS:
            print(f"-> {stmt}")
            conn.execute(text(stmt))
    print("Готово.")


if __name__ == "__main__":
    run()
