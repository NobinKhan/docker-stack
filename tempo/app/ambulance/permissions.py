from rest_framework.permissions import BasePermission
from django.contrib.auth.models import Group


class IsAmbulance_Admin(BasePermission):
    """Allowes access to only  Ambulance_Care_Admin users"""

    message = "You need to be a Ambulance_Care_Admin user"

    def has_permission(self, request, view):
        Ambulance_Care_Admin = (
            Group.objects.get(name="Ambulance_Admin")
            .user_set.all()
            .filter(id=request.user.id)
        )

        if Ambulance_Care_Admin:
            return True
        else:
            return False
