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
    story: str | None = None
    mastery: int = 0

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
    skill_tags: list[str] | None = None
    hints: list[str] | None = None

    class Config:
        from_attributes = True


class ExerciseCreate(BaseModel):
    type: str
    question: str
    content: dict
    correct_answer: dict
    order: int
    lesson_id: int
    skill_tags: list[str] | None = None
    hints: list[str] | None = None


class AnswerSubmit(BaseModel):
    answer: dict
    user_id: int


class UserOut(BaseModel):
    id: int
    username: str | None = None
    avatar: str | None = None
    email: str | None = None
    phone: str | None = None
    xp: int
    streak: int

    class Config:
        from_attributes = True


class UserCreate(BaseModel):
    username: str


class GuestCreate(BaseModel):
    device_token: str


class GoogleSignIn(BaseModel):
    id_token: str
    device_token: str


class ProfileUpdate(BaseModel):
    username: str
    avatar: str


class StreakShieldUpdate(BaseModel):
    enabled: bool


class PhoneUpdate(BaseModel):
    phone: str | None = None


class ContactsMatchRequest(BaseModel):
    phones: list[str]


class LessonComplete(BaseModel):
    correct_count: int


class LessonProgress(BaseModel):
    id: int
    title: str
    order: int
    status: str

    class Config:
        from_attributes = True


class LessonCompleteRequest(BaseModel):
    lesson_id: int


class PostCreate(BaseModel):
    text: str


class ReviewExerciseOut(BaseModel):
    id: int
    type: str
    question: str
    content: dict
    skill_tags: list[str] | None = None
    hints: list[str] | None = None

    class Config:
        from_attributes = True