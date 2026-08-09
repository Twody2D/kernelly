"""Одноразовая ручная миграция: добавляет колонки cores, last_chest_login_date
в таблицу users на уже существующей БД (Base.metadata.create_all не меняет
существующие таблицы — см. CLAUDE.md). Идемпотентно за счёт IF NOT EXISTS.

Запуск: venv/Scripts/python.exe -m seeds.migrate_cores
"""
from sqlalchemy import text
from app.database import engine

STATEMENTS = [
    "ALTER TABLE users ADD COLUMN IF NOT EXISTS cores INTEGER NOT NULL DEFAULT 0",
    "ALTER TABLE users ADD COLUMN IF NOT EXISTS last_chest_login_date DATE",
]


def run():
    with engine.begin() as conn:
        for stmt in STATEMENTS:
            print(f"-> {stmt}")
            conn.execute(text(stmt))
    print("Готово.")


if __name__ == "__main__":
    run()
