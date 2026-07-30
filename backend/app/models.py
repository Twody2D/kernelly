from sqlalchemy import Column, Integer, String, ForeignKey, JSON, DateTime, Date
from sqlalchemy.orm import relationship
from datetime import datetime
from app.database import Base


class Course(Base):
    __tablename__ = "courses"
    id = Column(Integer, primary_key=True)
    title = Column(String, nullable=False)
    description = Column(String)


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


class Exercise(Base):
    __tablename__ = "exercises"
    id = Column(Integer, primary_key=True)
    type = Column(String, nullable=False)
    question = Column(String, nullable=False)
    content = Column(JSON, nullable=False)
    correct_answer = Column(JSON, nullable=False)
    order = Column(Integer, nullable=False)
    lesson_id = Column(Integer, ForeignKey("lessons.id"), nullable=False)


class User(Base):
    __tablename__ = "users"
    id = Column(Integer, primary_key=True)
    username = Column(String, nullable=False, unique=True)
    xp = Column(Integer, nullable=False, default=0)
    streak = Column(Integer, nullable=False, default=0)
    last_activity_date = Column(Date, nullable=True)


class UserProgress(Base):
    __tablename__ = "user_progress"
    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    lesson_id = Column(Integer, ForeignKey("lessons.id"), nullable=False)
    completed_at = Column(DateTime, default=datetime.utcnow)