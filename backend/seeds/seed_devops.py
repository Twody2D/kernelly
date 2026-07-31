from app.database import SessionLocal
from app import models

db = SessionLocal()

# Курс
course = models.Course(
    title="DevOps с нуля",
    description="Git, Docker, CI/CD и основы инфраструктуры через практику",
)
db.add(course)
db.commit()
db.refresh(course)

# Раздел 1 — Git и GitHub
section1 = models.Section(title="Git и GitHub", order=1, course_id=course.id)
db.add(section1)
db.commit()
db.refresh(section1)

lesson1 = models.Lesson(title="Основы Git", order=1, section_id=section1.id)
db.add(lesson1)
db.commit()
db.refresh(lesson1)

exercises_lesson1 = [
    {
        "type": "multiple_choice",
        "question": "Какая команда инициализирует новый Git-репозиторий?",
        "content": {"options": ["git init", "git start", "git new", "git create"]},
        "correct_answer": {"answer": "git init"},
        "order": 1,
    },
    {
        "type": "multiple_choice",
        "question": "Какая команда сохраняет изменения с сообщением коммита?",
        "content": {"options": ["git save", "git commit -m", "git push", "git add"]},
        "correct_answer": {"answer": "git commit -m"},
        "order": 2,
    },
    {
        "type": "multiple_choice",
        "question": "Какая команда показывает текущий статус репозитория?",
        "content": {"options": ["git status", "git log", "git diff", "git show"]},
        "correct_answer": {"answer": "git status"},
        "order": 3,
    },
]

for ex in exercises_lesson1:
    db.add(models.Exercise(lesson_id=lesson1.id, **ex))
db.commit()

lesson2 = models.Lesson(title="Ветки и слияние", order=2, section_id=section1.id)
db.add(lesson2)
db.commit()
db.refresh(lesson2)

exercises_lesson2 = [
    {
        "type": "multiple_choice",
        "question": "Какая команда создаёт новую ветку?",
        "content": {"options": ["git branch new-feature", "git tree new-feature", "git fork new-feature", "git copy new-feature"]},
        "correct_answer": {"answer": "git branch new-feature"},
        "order": 1,
    },
    {
        "type": "multiple_choice",
        "question": "Какая команда сливает ветку в текущую?",
        "content": {"options": ["git combine", "git merge", "git join", "git union"]},
        "correct_answer": {"answer": "git merge"},
        "order": 2,
    },
    {
        "type": "multiple_choice",
        "question": "Какая команда переключает текущую ветку?",
        "content": {"options": ["git switch", "git move", "git jump", "git select"]},
        "correct_answer": {"answer": "git switch"},
        "order": 3,
    },
]

for ex in exercises_lesson2:
    db.add(models.Exercise(lesson_id=lesson2.id, **ex))
db.commit()

# Раздел 2 — Docker
section2 = models.Section(title="Docker основы", order=2, course_id=course.id)
db.add(section2)
db.commit()
db.refresh(section2)

lesson3 = models.Lesson(title="Что такое контейнер", order=1, section_id=section2.id)
db.add(lesson3)
db.commit()
db.refresh(lesson3)

exercises_lesson3 = [
    {
        "type": "multiple_choice",
        "question": "Какая команда запускает контейнер из образа?",
        "content": {"options": ["docker run", "docker start", "docker launch", "docker build"]},
        "correct_answer": {"answer": "docker run"},
        "order": 1,
    },
    {
        "type": "multiple_choice",
        "question": "Какая команда показывает список запущенных контейнеров?",
        "content": {"options": ["docker list", "docker ps", "docker show", "docker containers"]},
        "correct_answer": {"answer": "docker ps"},
        "order": 2,
    },
    {
        "type": "multiple_choice",
        "question": "Какая команда показывает список скачанных образов?",
        "content": {"options": ["docker images", "docker pull", "docker ls", "docker registry"]},
        "correct_answer": {"answer": "docker images"},
        "order": 3,
    },
]

for ex in exercises_lesson3:
    db.add(models.Exercise(lesson_id=lesson3.id, **ex))
db.commit()

lesson4 = models.Lesson(title="Dockerfile", order=2, section_id=section2.id)
db.add(lesson4)
db.commit()
db.refresh(lesson4)

exercises_lesson4 = [
    {
        "type": "multiple_choice",
        "question": "Какая инструкция задаёт базовый образ в Dockerfile?",
        "content": {"options": ["BASE", "FROM", "IMAGE", "START"]},
        "correct_answer": {"answer": "FROM"},
        "order": 1,
    },
    {
        "type": "multiple_choice",
        "question": "Какая инструкция выполняет команду во время сборки образа?",
        "content": {"options": ["EXEC", "RUN", "CMD", "DO"]},
        "correct_answer": {"answer": "RUN"},
        "order": 2,
    },
    {
        "type": "multiple_choice",
        "question": "Какая инструкция задаёт команду запуска контейнера по умолчанию?",
        "content": {"options": ["START", "CMD", "ENTRY", "LAUNCH"]},
        "correct_answer": {"answer": "CMD"},
        "order": 3,
    },
]

for ex in exercises_lesson4:
    db.add(models.Exercise(lesson_id=lesson4.id, **ex))
db.commit()

print(f"Курс создан: id={course.id}, разделы: {section1.id}, {section2.id}")
db.close()