from django.db.models import Q, EmailField, CharField, BooleanField, CheckConstraint

from base.models import BaseModel


class User(BaseModel):
    email = EmailField(unique=True, db_index=True, null=True, blank=True)
    full_name = CharField(max_length=100, null=True, blank=True)
    is_student = BooleanField(default=True, null=True, blank=True)
    is_instructor = BooleanField(default=False, null=True, blank=True)

    class Meta:
        db_table = "user"
        verbose_name = "User"
        verbose_name_plural = "Users"
        constraints = [
            CheckConstraint(
                check=(
                    Q(is_instructor=True, is_student=False) | Q(is_instructor=False, is_student=True)
                ),
                name="is_instructor_or_is_student",
            )
        ]

    def __str__(self):
        return self.email or self.full_name or str(self.id)
