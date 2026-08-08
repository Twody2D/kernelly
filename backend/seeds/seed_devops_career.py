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


def theory(explanation, example=None, skill_tags=None):
    """Шаг LEARN — объясняет команды/понятия до того, как их спросят, а не после."""
    return {
        "type": "theory",
        "question": explanation,
        "content": {"example": example} if example else {},
        "correct_answer": {},
        "skill_tags": skill_tags,
        "hints": None,
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
                    "story": "Твой руководитель показывает рабочее место и выдаёт первый доступ. "
                    "Начнём с простого — освоиться в компании и на сервере.",
                    "exercises": [
                        theory(
                            "В Linux ты управляешь сервером через терминал — текстовый интерфейс, "
                            "куда вводишь команды вместо кликов мышкой.\n\n"
                            "Команда `whoami` показывает, под каким пользователем ты сейчас работаешь.",
                            example="$ whoami\nengineer",
                            skill_tags=["linux.basics"],
                        ),
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
                            "Твой первый вход на сервер Acme.\n\n"
                            "Набери команду, которая покажет, под каким пользователем ты сейчас работаешь.",
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
                    "story": "Тебе выдали доступ к первому серверу Acme Cloud. Прежде чем что-то "
                    "менять, нужно понять, где ты вообще находишься.",
                    "exercises": [
                        theory(
                            "Каждая команда выполняется в какой-то папке (директории).\n\n"
                            "`pwd` (Print Working Directory) показывает, где ты сейчас находишься.\n\n"
                            "`ls` показывает, что лежит в этой папке.\n\n"
                            "А `cd` (change directory) переносит тебя в другую папку. Например, "
                            "`cd ..` поднимает на уровень выше.",
                            example="$ pwd\n/home/engineer\n$ ls\napp  config  logs\n$ cd ..\n$ pwd\n/home",
                            skill_tags=["linux.basics"],
                        ),
                        terminal(
                            "Прежде чем что-то делать на сервере, полезно понимать, где ты находишься.\n\n"
                            "Покажи путь к текущей директории.",
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
                    "story": "Коллега из бэкенда только что задеплоил новую версию — и сайт лёг. "
                    "Твоя первая настоящая задача: разобраться, что пошло не так.",
                    "exercises": [
                        theory(
                            "Когда что-то ломается после деплоя, первым делом смотрят логи — файлы, "
                            "куда программа записывает всё, что происходило.\n\n"
                            "Команда `tail` показывает последние строки файла — то есть самые "
                            "свежие записи.",
                            example="$ tail app.log\n[ERROR] Connection refused",
                            skill_tags=["linux.basics"],
                        ),
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
                    "story": "Приложение, за которое ты теперь отвечаешь, крутится на одном из "
                    "серверов Acme. Найди его и осмотрись.",
                    "exercises": [
                        theory(
                            "Ты уже знаешь `cd` для перехода между папками — теперь с конкретным "
                            "путём вместо `..`.\n\n"
                            "Например, `cd /var/log` переносит тебя в папку с логами.",
                            example="$ cd /var/log\n$ pwd\n/var/log",
                            skill_tags=["linux.basics"],
                        ),
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
                    "story": "Конфиг nginx где-то потерялся среди тысяч файлов сервера. Классика "
                    "первого месяца — учись искать быстро.",
                    "exercises": [
                        theory(
                            "Если не знаешь, где лежит файл — используй `find`.\n\n"
                            "А чтобы увидеть вообще все файлы в папке, включая скрытые (начинающиеся "
                            "с точки), у `ls` есть флаги `-l` (подробно) и `-a` (все файлы).",
                            example="$ find / -name nginx.conf\n/etc/nginx/nginx.conf\n$ ls -la\n-rw-r--r-- .env",
                            skill_tags=["linux.basics"],
                        ),
                        terminal(
                            "На сервере где-то лежит конфиг nginx.conf, но ты не знаешь где именно.\n\n"
                            "Найди его по всей системе.",
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
                    "story": "Скрипт автодеплоя перестал запускаться. Оказывается, дело в правах — "
                    "самая частая причина «само не работает» в Linux.",
                    "exercises": [
                        theory(
                            "У каждого файла в Linux есть права доступа — кто может читать, писать "
                            "и запускать файл.\n\n"
                            "`chmod` меняет эти права. Например, `chmod +x` делает файл "
                            "исполняемым — без этого скрипт просто откажется запускаться.",
                            example="$ chmod +x deploy.sh\n$ ./deploy.sh\nDeploying...",
                            skill_tags=["linux.basics"],
                        ),
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
                            "Скрипт deploy.sh не запускается — не хватает прав на исполнение.\n\n"
                            "Почини это.",
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
                    "story": "Сайт Acme недоступен: nginx упал. Пора разобраться, как посмотреть, "
                    "что вообще происходит на сервере, и перезапустить сервис.",
                    "exercises": [
                        theory(
                            "Каждая программа на сервере — это процесс.\n\n"
                            "`ps aux` показывает все запущенные процессы.\n\n"
                            "А сервисами (например, nginx) управляет `systemctl` — им можно "
                            "запускать, останавливать и перезапускать программы.",
                            example="$ systemctl restart nginx\n$ systemctl status nginx\nactive (running)",
                            skill_tags=["linux.basics"],
                        ),
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
                            "Сайт лежит из-за упавшего nginx.\n\n"
                            "Перезапусти сервис.",
                            "systemctl restart nginx",
                            skill_tags=["linux.systemctl"],
                            hints=["Используй ту команду, что отвечает за управление службами", "restart, не start", "systemctl restart nginx"],
                        ),
                    ],
                },
                {
                    "title": "Диагностика по логам",
                    "story": "После рестарта сервис снова падает через пару минут. Ответ почти "
                    "всегда — в логах. Научись их читать.",
                    "exercises": [
                        theory(
                            "`journalctl` показывает системный журнал — логи всех служб, "
                            "управляемых systemd.\n\n"
                            "А `grep` ищет нужный текст внутри файла, например конкретную ошибку "
                            "среди тысяч строк.",
                            example="$ journalctl -u nginx\n$ grep error app.log\n[ERROR] ...",
                            skill_tags=["linux.basics"],
                        ),
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
                lesson = models.Lesson(
                    title=lesson_data["title"],
                    story=lesson_data.get("story"),
                    order=lesson_order,
                    section_id=section.id,
                )
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
