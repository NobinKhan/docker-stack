from django.contrib import admin
from .models import Ambulance, AmbulanceOrder


# Register your models here.


@admin.register(Ambulance)
class AmbulanceAdmin(admin.ModelAdmin):
    list_display = (
        "id",
        "ambulanceType",
        "minPrice",
        "maxPrice",
    )


@admin.register(AmbulanceOrder)
class AmbulanceOrderAdmin(admin.ModelAdmin):
    # readonly_fields = ('user', 'updatedBy', 'cbProfit')
    readonly_fields = ("updatedBy", "cbProfit")
    list_display = (
        "id",
        "user",
        "ambulance",
        "orderStatus",
        "updated",
    )

    def save_model(self, request, obj, form, change):
        if obj.id:
            obj.updatedBy = request.user
        super().save_model(request, obj, form, change)
