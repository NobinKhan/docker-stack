from django.contrib import admin

from base.admin import MultiDBModelAdmin
from enroll.models import Enrollment


admin.site.register(Enrollment, MultiDBModelAdmin)
