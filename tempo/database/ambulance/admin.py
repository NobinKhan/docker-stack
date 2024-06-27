from django.contrib import admin

from base.admin import MultiDBModelAdmin
from course.models import Course


admin.site.register(Course, MultiDBModelAdmin)
