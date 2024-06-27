from django.contrib import admin

from base.admin import MultiDBModelAdmin
from user.models import User


admin.site.register(User, MultiDBModelAdmin)
