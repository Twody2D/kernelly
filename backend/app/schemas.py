from pydantic import BaseModel


class CourseOut(BaseModel):
    id: int
    title: str
    description: str | None = None

    class Config:
        from_attributes = True


class CourseCreate(BaseModel):
    title: str
    description: str | None = None


class SectionOut(BaseModel):
    id: int
    title: str
    order: int
    course_id: int

    class Config:
        from_attributes = True


class SectionCreate(BaseModel):
    title: str
    order: int
    course_id: int


class LessonOut(BaseModel):
    id: int
    title: str
    order: int
    section_id: int

    class Config:
        from_attributes = True


class LessonCreate(BaseModel):
    title: str
    order: int
    section_id: int


class ExerciseOut(BaseModel):
    id: int
    type: str
    question: str
    content: dict
    order: int
    lesson_id: int

    class Config:
        from_attributes = True


class ExerciseCreate(BaseModel):
    type: str
    question: str
    content: dict
    correct_answer: dict
    order: int
    lesson_id: int


class AnswerSubmit(BaseModel):
    answer: dict


class UserOut(BaseModel):
    id: int
    username: str
    xp: int
    streak: int

    class Config:
        from_attributes = True


class UserCreate(BaseModel):
    username: str