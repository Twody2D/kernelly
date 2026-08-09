"""Одноразовая ручная миграция: добавляет колонку chest_claimed в таблицу
achievement_unlocks на уже существующей БД (Base.metadata.create_all не
меняет существующие таблицы — см. CLAUDE.md). DEFAULT TRUE — чтобы уже
существующие разблокировки (награда по ним уже выдавалась старой логикой)
не стали внезапно показываться как «новые» с сундуком. Идемпотентно за счёт
IF NOT EXISTS.

Запуск: venv/Scripts/python.exe -m seeds.migrate_achievement_chests
"""
from sqlalchemy import text
from app.database import engine

STATEMENTS = [
    "ALTER TABLE achievement_unlocks ADD COLUMN IF NOT EXISTS chest_claimed BOOLEAN NOT NULL DEFAULT TRUE",
]


def run():
    with engine.begin() as conn:
        for stmt in STATEMENTS:
            print(f"-> {stmt}")
            conn.execute(text(stmt))
    print("Готово.")


if __name__ == "__main__":
    run()
