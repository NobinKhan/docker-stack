from django.db.models import ForeignKey, CASCADE

from base.models import BaseModel
from course.models import Course
from user.models import User


class Enrollment(BaseModel):
    course = ForeignKey(Course, on_delete=CASCADE, related_name="enrolled_users")
    student = ForeignKey(User, on_delete=CASCADE, related_name="enrolled_courses")

    class Meta:
        db_table = "enrollment"
        verbose_name = "Course Enrollment"
        verbose_name_plural = "Course Enrollments"

    def __str__(self):
        return f"{self.student.full_name}:- {self.course}"
