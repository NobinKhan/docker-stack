from django.apps import AppConfig


class AmbulanceConfig(AppConfig):
    default_auto_field = "django.db.models.BigAutoField"
    name = "ambulance"

    def ready(self):
        import ambulance.signals  # noqa: F401
