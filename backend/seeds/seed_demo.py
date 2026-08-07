"""Демо-контент для разработки: несколько курсов, включая заблокированные.

Запуск из папки backend:
    venv\\Scripts\\python.exe -m seeds.seed_demo

Идемпотентен: курс с таким же названием повторно не создаётся.
Контент временный — нужен, чтобы на экранах было что показывать.
"""

from app.database import SessionLocal
from app import models


def mc(question, options, answer):
    """Упражнение с выбором одного варианта."""
    return {
        "type": "multiple_choice",
        "question": question,
        "content": {"options": options},
        "correct_answer": {"answer": answer},
    }


COURSES = [
    {
        "title": "Linux и терминал",
        "description": "Команды, файлы, права и пайпы — база, без которой никуда",
        "sections": [
            {
                "title": "Работа с файлами",
                "lessons": [
                    {
                        "title": "ls, cd, pwd",
                        "exercises": [
                            mc("Какая команда покажет содержимое текущей папки?", ["pwd", "ls", "cd", "rm"], "ls"),
                            mc("Какая команда покажет путь к текущей папке?", ["ls", "cd", "pwd", "find"], "pwd"),
                            mc("Как перейти на уровень выше?", ["cd ..", "cd /", "cd ~", "cd -"], "cd .."),
                        ],
                    },
                    {
                        "title": "rm, cp, mv",
                        "exercises": [
                            mc("Какая команда копирует файл?", ["mv", "cp", "rm", "ln"], "cp"),
                            mc("Какая команда переименовывает файл?", ["rename", "mv", "cp", "touch"], "mv"),
                            mc("Как удалить папку со всем содержимым?", ["rm -r", "rm -f", "rmdir", "del"], "rm -r"),
                        ],
                    },
                    {
                        "title": "права доступа",
                        "exercises": [
                            mc("Какая команда меняет права на файл?", ["chown", "chmod", "chgrp", "umask"], "chmod"),
                            mc("Что означает 755 для файла?", ["rwxr-xr-x", "rw-r--r--", "rwxrwxrwx", "r-xr-xr-x"], "rwxr-xr-x"),
                            mc("Какая команда меняет владельца файла?", ["chmod", "chown", "sudo", "passwd"], "chown"),
                        ],
                    },
                ],
            },
            {
                "title": "Поиск и пайпы",
                "lessons": [
                    {
                        "title": "grep, find",
                        "exercises": [
                            mc("Какая команда ищет текст внутри файлов?", ["find", "grep", "locate", "which"], "grep"),
                            mc("Какая команда ищет файлы по имени?", ["grep", "find", "ls", "cat"], "find"),
                            mc("Как искать без учёта регистра в grep?", ["grep -i", "grep -v", "grep -r", "grep -n"], "grep -i"),
                        ],
                    },
                    {
                        "title": "пайпы",
                        "exercises": [
                            mc("Какой символ передаёт вывод одной команды другой?", ["|", ">", "<", "&"], "|"),
                            mc("Какая команда покажет первые 10 строк?", ["tail", "head", "less", "more"], "head"),
                            mc("Как записать вывод команды в файл?", ["cmd > file", "cmd | file", "cmd < file", "cmd & file"], "cmd > file"),
                        ],
                    },
                ],
            },
        ],
    },
    {
        "title": "Git и GitHub",
        "description": "Версии, ветки и совместная работа над кодом",
        "sections": [
            {
                "title": "Основы Git",
                "lessons": [
                    {
                        "title": "init, add, commit",
                        "exercises": [
                            mc("Какая команда создаёт репозиторий?", ["git init", "git start", "git new", "git create"], "git init"),
                            mc("Какая команда добавляет файл в индекс?", ["git add", "git stage", "git put", "git track"], "git add"),
                            mc("Какая команда сохраняет изменения?", ["git save", "git commit", "git push", "git store"], "git commit"),
                        ],
                    },
                    {
                        "title": "ветки",
                        "exercises": [
                            mc("Какая команда создаёт ветку?", ["git branch", "git tree", "git fork", "git new"], "git branch"),
                            mc("Какая команда переключает ветку?", ["git switch", "git move", "git jump", "git go"], "git switch"),
                            mc("Какая команда сливает ветку в текущую?", ["git join", "git merge", "git mix", "git union"], "git merge"),
                        ],
                    },
                ],
            },
        ],
    },
    {
        "title": "Python с нуля",
        "description": "Синтаксис, типы данных и первые скрипты",
        "sections": [
            {
                "title": "Первые шаги",
                "lessons": [
                    {
                        "title": "переменные",
                        "exercises": [
                            mc("Как вывести текст на экран?", ["print()", "echo()", "write()", "output()"], "print()"),
                            mc("Какой тип у значения 3.14?", ["int", "float", "str", "bool"], "float"),
                            mc("Как получить длину списка?", ["size()", "len()", "count()", "length()"], "len()"),
                        ],
                    },
                    {
                        "title": "условия",
                        "exercises": [
                            mc("Какое ключевое слово начинает условие?", ["if", "when", "case", "check"], "if"),
                            mc("Как записать «иначе если»?", ["elseif", "elif", "else if", "elsif"], "elif"),
                            mc("Какой оператор проверяет равенство?", ["=", "==", "===", "eq"], "=="),
                        ],
                    },
                ],
            },
        ],
    },
    {
        "title": "Bash-скрипты",
        "description": "Автоматизация рутины на shell",
        "required_course": "Linux и терминал",
        "required_percent": 70,
        "sections": [
            {
                "title": "Основы скриптов",
                "lessons": [
                    {
                        "title": "shebang и запуск",
                        "exercises": [
                            mc("С чего начинается bash-скрипт?", ["#!/bin/bash", "//bash", "<?bash", "#bash"], "#!/bin/bash"),
                            mc("Как сделать файл исполняемым?", ["chmod +x", "chmod 644", "chown +x", "run +x"], "chmod +x"),
                        ],
                    },
                ],
            },
        ],
    },
    {
        "title": "SQL и базы данных",
        "description": "Запросы, выборки и связи между таблицами",
        "required_course": "Python с нуля",
        "required_percent": 40,
        "sections": [
            {
                "title": "Выборка данных",
                "lessons": [
                    {
                        "title": "SELECT",
                        "exercises": [
                            mc("Какой запрос выбирает все строки?", ["SELECT *", "GET *", "FETCH *", "SHOW *"], "SELECT *"),
                            mc("Какое слово фильтрует строки?", ["FILTER", "WHERE", "HAVING", "IF"], "WHERE"),
                        ],
                    },
                ],
            },
        ],
    },
    {
        "title": "Docker и контейнеры",
        "description": "Образы, контейнеры и docker compose",
        "is_coming_soon": True,
        "sections": [],
    },
]


def seed():
    db = SessionLocal()
    created = []
    skipped = []

    try:
        for course_data in COURSES:
            title = course_data["title"]

            exists = db.query(models.Course).filter(models.Course.title == title).first()
            if exists is not None:
                skipped.append(title)
                continue

            course = models.Course(
                title=title,
                description=course_data.get("description"),
                is_coming_soon=course_data.get("is_coming_soon", False),
                required_percent=course_data.get("required_percent"),
            )
            db.add(course)
            db.flush()

            for section_order, section_data in enumerate(course_data["sections"], start=1):
                section = models.Section(
                    title=section_data["title"],
                    order=section_order,
                    course_id=course.id,
                )
                db.add(section)
                db.flush()

                for lesson_order, lesson_data in enumerate(section_data["lessons"], start=1):
                    lesson = models.Lesson(
                        title=lesson_data["title"],
                        order=lesson_order,
                        section_id=section.id,
                    )
                    db.add(lesson)
                    db.flush()

                    for ex_order, exercise in enumerate(lesson_data["exercises"], start=1):
                        db.add(models.Exercise(lesson_id=lesson.id, order=ex_order, **exercise))

            created.append(title)

        db.commit()

        # зависимости проставляем вторым проходом: нужный курс мог создаваться позже
        for course_data in COURSES:
            required_title = course_data.get("required_course")
            if required_title is None:
                continue

            course = db.query(models.Course).filter(models.Course.title == course_data["title"]).first()
            required = db.query(models.Course).filter(models.Course.title == required_title).first()
            if course is not None and required is not None:
                course.required_course_id = required.id

        db.commit()

        print(f"создано курсов: {len(created)}")
        for title in created:
            print(f"  + {title}")
        if skipped:
            print(f"пропущено (уже есть): {', '.join(skipped)}")
    finally:
        db.close()


if __name__ == "__main__":
    seed()
