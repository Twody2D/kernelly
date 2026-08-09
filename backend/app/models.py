from sqlalchemy import Column, Integer, String, ForeignKey, JSON, DateTime, Date, Boolean, UniqueConstraint
from sqlalchemy.orm import relationship
from datetime import datetime
from app.database import Base


class Course(Base):
    __tablename__ = "courses"
    id = Column(Integer, primary_key=True)
    title = Column(String, nullable=False)
    description = Column(String)
    required_course_id = Column(Integer, ForeignKey("courses.id"), nullable=True)
    required_percent = Column(Integer, nullable=True)
    is_coming_soon = Column(Boolean, nullable=False, default=False)
    requires_account = Column(Boolean, nullable=False, default=False)


class Section(Base):
    __tablename__ = "sections"
    id = Column(Integer, primary_key=True)
    title = Column(String, nullable=False)
    order = Column(Integer, nullable=False)
    course_id = Column(Integer, ForeignKey("courses.id"), nullable=False)


class Lesson(Base):
    __tablename__ = "lessons"
    id = Column(Integer, primary_key=True)
    title = Column(String, nullable=False)
    order = Column(Integer, nullable=False)
    section_id = Column(Integer, ForeignKey("sections.id"), nullable=False)
    story = Column(String, nullable=True)


class Exercise(Base):
    __tablename__ = "exercises"
    id = Column(Integer, primary_key=True)
    type = Column(String, nullable=False)
    question = Column(String, nullable=False)
    content = Column(JSON, nullable=False)
    correct_answer = Column(JSON, nullable=False)
    order = Column(Integer, nullable=False)
    lesson_id = Column(Integer, ForeignKey("lessons.id"), nullable=False)
    skill_tags = Column(JSON, nullable=True)
    hints = Column(JSON, nullable=True)
    # уровень сложности прохождения урока (1 = обычное, 2/3 = усложнённые
    # повторы для системы мастерства); NULL в БД читается как 1
    difficulty = Column(Integer, nullable=False, default=1)


class User(Base):
    __tablename__ = "users"
    id = Column(Integer, primary_key=True)
    username = Column(String, nullable=True, unique=True)
    avatar = Column(String, nullable=True)
    email = Column(String, nullable=True)
    phone = Column(String, nullable=True, unique=True, index=True)
    device_token = Column(String, nullable=True, unique=True, index=True)
    auth_provider = Column(String, nullable=False, default="guest")
    external_id = Column(String, nullable=True)
    xp = Column(Integer, nullable=False, default=0)
    streak = Column(Integer, nullable=False, default=0)
    last_activity_date = Column(Date, nullable=True)
    created_at = Column(DateTime, nullable=False, default=datetime.utcnow)
    # «Защита streak»: пропущенный день не сбрасывает streak, если включено и
    # есть заряд заморозки. Заряды пополняются раз в неделю автоматически;
    # заряды сверх этого можно докупить за «ядра» (см. cores ниже).
    streak_shield_enabled = Column(Boolean, nullable=False, default=False)
    streak_freezes = Column(Integer, nullable=False, default=1)
    streak_freeze_refreshed_at = Column(Date, nullable=True)
    # Игровая валюта — «ядра». Выдаются сундуками за золото на уроке,
    # завершение курса, ежедневный вход и достижения (см. _award_cores и
    # точки начисления в main.py); тратятся на покупку заморозок streak.
    cores = Column(Integer, nullable=False, default=0)
    last_chest_login_date = Column(Date, nullable=True)
    # Число попыток прохождения урока без единой ошибки — метрика для семьи
    # достижений «Точность» (см. ACHIEVEMENT_FAMILIES в main.py). Растёт при
    # каждом идеальном прохождении, не только при первом (в отличие от
    # lessons_completed, который считает уникальные уроки).
    perfect_lessons_count = Column(Integer, nullable=False, default=0)


class Answer(Base):
    __tablename__ = "answers"
    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    exercise_id = Column(Integer, ForeignKey("exercises.id"), nullable=False)
    is_correct = Column(Boolean, nullable=False)
    created_at = Column(DateTime, nullable=False, default=datetime.utcnow)


class UserProgress(Base):
    __tablename__ = "user_progress"
    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    lesson_id = Column(Integer, ForeignKey("lessons.id"), nullable=False)
    completed_at = Column(DateTime, default=datetime.utcnow)


class SkillProgress(Base):
    """Состояние spaced repetition (алгоритм Лейтнера) по одному skill_tag
    для одного пользователя — одна строка на пару (user_id, skill_tag)."""

    __tablename__ = "skill_progress"
    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    skill_tag = Column(String, nullable=False)
    box = Column(Integer, nullable=False, default=1)
    next_review_at = Column(DateTime, nullable=False, default=datetime.utcnow)


class LessonMastery(Base):
    """Сколько раз пользователь успешно прошёл урок — источник для уровней
    мастерства (бронза/серебро/золото) и подбора сложности следующей попытки."""

    __tablename__ = "lesson_mastery"
    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    lesson_id = Column(Integer, ForeignKey("lessons.id"), nullable=False)
    completions = Column(Integer, nullable=False, default=0)


class Follow(Base):
    """Подписка в стиле Instagram: follower видит ленту followee, согласие не
    требуется. Взаимная подписка помечается на бэкенде как «друзья» —
    это лишь косметический статус, на видимость ленты он не влияет."""

    __tablename__ = "follows"
    __table_args__ = (UniqueConstraint("follower_id", "followee_id", name="uq_follow_pair"),)
    id = Column(Integer, primary_key=True)
    follower_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    followee_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    created_at = Column(DateTime, nullable=False, default=datetime.utcnow)


class Post(Base):
    """Текстовый статус-апдейт пользователя для ленты активности."""

    __tablename__ = "posts"
    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    text = Column(String, nullable=False)
    created_at = Column(DateTime, nullable=False, default=datetime.utcnow)


class PostLike(Base):
    """Лайк элемента ленты — не только поста, но и разблокировки достижения
    (target_type='achievement', target_id — id строки AchievementUnlock,
    у неё нет своего пользовательского экрана вне ленты, но id стабилен)."""

    __tablename__ = "post_likes"
    __table_args__ = (
        UniqueConstraint("target_type", "target_id", "user_id", name="uq_feed_like"),
    )
    id = Column(Integer, primary_key=True)
    target_type = Column(String, nullable=False, default="post")
    target_id = Column(Integer, nullable=False)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    created_at = Column(DateTime, nullable=False, default=datetime.utcnow)


class PostComment(Base):
    __tablename__ = "post_comments"
    id = Column(Integer, primary_key=True)
    target_type = Column(String, nullable=False, default="post")
    target_id = Column(Integer, nullable=False)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    text = Column(String, nullable=False)
    created_at = Column(DateTime, nullable=False, default=datetime.utcnow)


class Notification(Base):
    """Уведомление владельцу элемента ленты (поста или разблокировки
    достижения). Лайки одного элемента агрегируются в одну строку (count
    растёт, read сбрасывается в False при каждом новом лайке, actor_id —
    последний лайкнувший) — иначе десять лайков дали бы десять отдельных
    уведомлений. У комментариев — отдельная строка на каждый."""

    __tablename__ = "notifications"
    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    actor_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    target_type = Column(String, nullable=False, default="post")
    target_id = Column(Integer, nullable=False)
    type = Column(String, nullable=False)  # 'like' | 'comment'
    count = Column(Integer, nullable=False, default=1)
    comment_text = Column(String, nullable=True)
    read = Column(Boolean, nullable=False, default=False)
    created_at = Column(DateTime, nullable=False, default=datetime.utcnow)
    updated_at = Column(DateTime, nullable=False, default=datetime.utcnow)


class AchievementUnlock(Base):
    """Момент разблокировки достижения — сами достижения считаются на лету
    (см. ACHIEVEMENTS в main.py), но для ленты нужен факт и время события."""

    __tablename__ = "achievement_unlocks"
    __table_args__ = (UniqueConstraint("user_id", "code", name="uq_achievement_unlock"),)
    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    code = Column(String, nullable=False)
    unlocked_at = Column(DateTime, nullable=False, default=datetime.utcnow)
    # Сундук с ядрами за достижение открывается вручную в профиле, не сразу
    # при разблокировке — default=True, чтобы существующие (уже «зачтённые»
    # по старой логике) записи не стали внезапно выглядеть как новые.
    chest_claimed = Column(Boolean, nullable=False, default=True)