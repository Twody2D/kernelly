"""DevOps career track — единственный курс на время разработки игровых механик
(missions/tools/incidents). Остальные демо-курсы удалены осознанно, чтобы
не путать тестирование новой системы со старым флоу multiple_choice.

Запуск из папки backend:
    venv\\Scripts\\python.exe -m seeds.seed_devops_career

Идемпотентен: если курс с таким названием уже есть — ничего не делает.
"""

from app.database import SessionLocal
from app import models


def mc(question, options, answer, skill_tags=None, hints=None):
    return {
        "type": "multiple_choice",
        "question": question,
        "content": {"options": options},
        "correct_answer": {"answer": answer},
        "skill_tags": skill_tags,
        "hints": hints,
    }


def terminal(question, answer, skill_tags=None, hints=None):
    return {
        "type": "terminal",
        "question": question,
        "content": {},
        "correct_answer": {"answer": answer},
        "skill_tags": skill_tags,
        "hints": hints,
    }


COURSE = {
    "title": "DevOps Engineer",
    "description": "Ты — новый инженер в Acme Cloud. От первого дня до продакшн-инцидентов через практику.",
    "requires_account": False,
    "is_coming_soon": False,
    "sections": [
        {
            "title": "Добро пожаловать в Acme Cloud",
            "lessons": [
                {
                    "title": "Первый день",
                    "exercises": [
                        mc(
                            "Тебя наняли в Acme Cloud инженером. Чем в основном занимается DevOps-инженер?",
                            [
                                "Автоматизирует разработку, сборку и доставку приложений",
                                "Рисует дизайн интерфейсов",
                                "Пишет только маркетинговые тексты",
                                "Отвечает исключительно за бухгалтерию",
                            ],
                            "Автоматизирует разработку, сборку и доставку приложений",
                        ),
                        mc(
                            "Что из этого НЕ относится к типичным задачам DevOps?",
                            ["Настройка CI/CD", "Мониторинг серверов", "Вёрстка лендинга", "Разбор инцидентов"],
                            "Вёрстка лендинга",
                        ),
                        terminal(
                            "Твой первый вход на сервер Acme. Набери команду, которая покажет, под каким пользователем ты сейчас работаешь.",
                            "whoami",
                            skill_tags=["linux.whoami"],
                            hints=[
                                "Каждая Linux-сессия принадлежит какому-то пользователю",
                                "Команда состоит из одного слова и отвечает на вопрос «кто я»",
                                "whoami",
                            ],
                        ),
                    ],
                },
                {
                    "title": "Твой первый сервер",
                    "exercises": [
                        terminal(
                            "Прежде чем что-то делать на сервере, полезно понимать, где ты находишься. Покажи путь к текущей директории.",
                            "pwd",
                            skill_tags=["linux.pwd"],
                            hints=["Print Working Directory — расшифровка команды это подсказка", "Три буквы", "pwd"],
                        ),
                        terminal(
                            "Посмотри, что вообще лежит в текущей папке.",
                            "ls",
                            skill_tags=["linux.ls"],
                            hints=["Самая частая команда в Linux вообще", "Две буквы", "ls"],
                        ),
                        mc(
                            "Что делает команда `cd ..`?",
                            [
                                "Переходит в родительскую (вышестоящую) папку",
                                "Удаляет текущую папку",
                                "Создаёт новую папку",
                                "Показывает историю команд",
                            ],
                            "Переходит в родительскую (вышестоящую) папку",
                        ),
                    ],
                },
                {
                    "title": "Первый деплой и его провал",
                    "exercises": [
                        mc(
                            "Что такое деплой (deployment)?",
                            [
                                "Процесс выкладки новой версии приложения на сервер",
                                "Резервное копирование базы данных",
                                "Написание документации",
                                "Дизайн логотипа компании",
                            ],
                            "Процесс выкладки новой версии приложения на сервер",
                        ),
                        mc(
                            "После твоего деплоя приложение перестало отвечать. Куда смотреть в первую очередь?",
                            ["В логи приложения", "В цвет иконки на рабочем столе", "В дату основания компании", "В настройки шрифта в IDE"],
                            "В логи приложения",
                        ),
                        terminal(
                            "Набери команду, которая покажет последние строки лог-файла — обычно там и есть свежая ошибка.",
                            "tail",
                            skill_tags=["linux.tail"],
                            hints=["Слово переводится как «хвост»", "Показывает конец файла, а не начало", "tail"],
                        ),
                    ],
                },
            ],
        },
        {
            "title": "Linux",
            "lessons": [
                {
                    "title": "Исследуй сервер",
                    "exercises": [
                        terminal(
                            "Снова пригодится — покажи путь к текущей директории.",
                            "pwd",
                            skill_tags=["linux.pwd"],
                            hints=["Та же команда, что и на первом сервере", "Три буквы", "pwd"],
                        ),
                        terminal(
                            "Перейди в папку /var/log — там Linux обычно хранит логи.",
                            "cd /var/log",
                            skill_tags=["linux.cd"],
                            hints=["Команда для смены директории", "cd + путь", "cd /var/log"],
                        ),
                        mc(
                            "Как называется корневая директория файловой системы Linux?",
                            ["/", "root", "C:\\", "home"],
                            "/",
                        ),
                    ],
                },
                {
                    "title": "Найди приложение",
                    "exercises": [
                        terminal(
                            "На сервере где-то лежит конфиг nginx.conf, но ты не знаешь где именно. Найди его по всей системе.",
                            "find / -name nginx.conf",
                            skill_tags=["linux.find"],
                            hints=[
                                "Нужна команда поиска файлов по имени, а не по содержимому",
                                "find <откуда искать> -name <имя>",
                                "find / -name nginx.conf",
                            ],
                        ),
                        terminal(
                            "Покажи содержимое папки подробно, включая скрытые файлы.",
                            "ls -la",
                            skill_tags=["linux.ls-flags"],
                            hints=["Это `ls` с дополнительными флагами", "-l для подробностей, -a для скрытых", "ls -la"],
                        ),
                        mc(
                            "Что означает точка в начале имени файла в Linux (например, `.env`)?",
                            ["Это скрытый файл", "Это системная ошибка", "Это временный файл", "Это исполняемый файл"],
                            "Это скрытый файл",
                        ),
                    ],
                },
                {
                    "title": "Права доступа",
                    "exercises": [
                        mc(
                            "Какая команда меняет права доступа к файлу?",
                            ["chown", "chmod", "chgrp", "umask"],
                            "chmod",
                        ),
                        mc(
                            "Что означают права 644 у файла?",
                            ["rw-r--r--", "rwxr-xr-x", "rwxrwxrwx", "r--r--r--"],
                            "rw-r--r--",
                        ),
                        terminal(
                            "Скрипт deploy.sh не запускается — не хватает прав на исполнение. Почини это.",
                            "chmod +x deploy.sh",
                            skill_tags=["linux.chmod"],
                            hints=[
                                "Проблема именно в правах на исполнение, а не в содержимом файла",
                                "chmod с флагом +x",
                                "chmod +x deploy.sh",
                            ],
                        ),
                    ],
                },
                {
                    "title": "Процессы и службы",
                    "exercises": [
                        terminal(
                            "Покажи список всех запущенных процессов на сервере.",
                            "ps aux",
                            skill_tags=["linux.ps"],
                            hints=["ps показывает процессы", "с флагами aux — вообще все, всех пользователей", "ps aux"],
                        ),
                        mc(
                            "Какая команда управляет службами systemd (запуск/остановка/перезапуск)?",
                            ["systemctl", "service-manager", "initctl", "launchd"],
                            "systemctl",
                        ),
                        terminal(
                            "Сайт лежит из-за упавшего nginx. Перезапусти сервис.",
                            "systemctl restart nginx",
                            skill_tags=["linux.systemctl"],
                            hints=["Используй ту команду, что отвечает за управление службами", "restart, не start", "systemctl restart nginx"],
                        ),
                    ],
                },
                {
                    "title": "Диагностика по логам",
                    "exercises": [
                        terminal(
                            "Посмотри логи сервиса nginx через journalctl.",
                            "journalctl -u nginx",
                            skill_tags=["linux.journalctl"],
                            hints=["journalctl читает системный журнал systemd", "флаг -u для конкретного unit/сервиса", "journalctl -u nginx"],
                        ),
                        terminal(
                            "В файле app.log нужно быстро найти все строки со словом error.",
                            "grep error app.log",
                            skill_tags=["linux.grep"],
                            hints=["Команда для поиска текста внутри файла", "grep <что> <где>", "grep error app.log"],
                        ),
                        mc(
                            "Сервис упал сразу после запуска. Где в первую очередь искать причину?",
                            ["В логах сервиса", "В истории браузера", "В настройках Wi-Fi", "В календаре"],
                            "В логах сервиса",
                        ),
                    ],
                },
            ],
        },
    ],
}


def seed():
    db = SessionLocal()
    try:
        exists = db.query(models.Course).filter(models.Course.title == COURSE["title"]).first()
        if exists is not None:
            print(f"пропущено (уже есть): {COURSE['title']}")
            return

        course = models.Course(
            title=COURSE["title"],
            description=COURSE["description"],
            requires_account=COURSE["requires_account"],
            is_coming_soon=COURSE["is_coming_soon"],
        )
        db.add(course)
        db.flush()

        for section_order, section_data in enumerate(COURSE["sections"], start=1):
            section = models.Section(title=section_data["title"], order=section_order, course_id=course.id)
            db.add(section)
            db.flush()

            for lesson_order, lesson_data in enumerate(section_data["lessons"], start=1):
                lesson = models.Lesson(title=lesson_data["title"], order=lesson_order, section_id=section.id)
                db.add(lesson)
                db.flush()

                for ex_order, exercise in enumerate(lesson_data["exercises"], start=1):
                    db.add(models.Exercise(lesson_id=lesson.id, order=ex_order, **exercise))

        db.commit()
        print(f"создан курс: {COURSE['title']} (id={course.id})")
    finally:
        db.close()


if __name__ == "__main__":
    seed()
