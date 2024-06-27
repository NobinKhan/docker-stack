from django.db import models


class BaseModel(models.Model):
    created_at = models.DateTimeField(
        auto_now_add=True, null=True, blank=True, editable=False
    )
    updated_at = models.DateTimeField(
        auto_now=True, null=True, blank=True, editable=True
    )

    class Meta:
        abstract = True
