from fastapi import FastAPI, Depends
from sqlalchemy.orm import Session
from app.database import Base, engine, get_db
from app import models, schemas

app = FastAPI()

Base.metadata.create_all(bind=engine)


@app.get("/")
def read_root():
    return {"status": "Kernelly API is running"}


@app.get("/courses", response_model=list[schemas.CourseOut])
def get_courses(db: Session = Depends(get_db)):
    return db.query(models.Course).all()


@app.post("/courses", response_model=schemas.CourseOut)
def create_course(course: schemas.CourseCreate, db: Session = Depends(get_db)):
    new_course = models.Course(title=course.title, description=course.description)
    db.add(new_course)
    db.commit()
    db.refresh(new_course)
    return new_course


@app.get("/sections", response_model=list[schemas.SectionOut])
def get_sections(db: Session = Depends(get_db)):
    return db.query(models.Section).all()


@app.post("/sections", response_model=schemas.SectionOut)
def create_section(section: schemas.SectionCreate, db: Session = Depends(get_db)):
    new_section = models.Section(
        title=section.title,
        order=section.order,
        course_id=section.course_id,
    )
    db.add(new_section)
    db.commit()
    db.refresh(new_section)
    return new_section


@app.get("/lessons", response_model=list[schemas.LessonOut])
def get_lessons(db: Session = Depends(get_db)):
    return db.query(models.Lesson).all()


@app.post("/lessons", response_model=schemas.LessonOut)
def create_lesson(lesson: schemas.LessonCreate, db: Session = Depends(get_db)):
    new_lesson = models.Lesson(
        title=lesson.title,
        order=lesson.order,
        section_id=lesson.section_id,
    )
    db.add(new_lesson)
    db.commit()
    db.refresh(new_lesson)
    return new_lesson


@app.get("/exercises", response_model=list[schemas.ExerciseOut])
def get_exercises(db: Session = Depends(get_db)):
    return db.query(models.Exercise).all()


@app.post("/exercises", response_model=schemas.ExerciseOut)
def create_exercise(exercise: schemas.ExerciseCreate, db: Session = Depends(get_db)):
    new_exercise = models.Exercise(
        type=exercise.type,
        question=exercise.question,
        content=exercise.content,
        correct_answer=exercise.correct_answer,
        order=exercise.order,
        lesson_id=exercise.lesson_id,
    )
    db.add(new_exercise)
    db.commit()
    db.refresh(new_exercise)
    return new_exercise