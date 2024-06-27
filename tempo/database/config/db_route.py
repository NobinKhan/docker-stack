class DefaultRouter:
    """
    A router to control all database operations on models in all applications.
    """

    deafult_app_labels = {"admin", "auth", "contenttypes", "sessions"}
    olp_app_labels = {"user", "course", "enroll"}

    def db_for_read(self, model, **hints):
        """
        Attempts to read auth and contenttypes models go to default.
        """
        if model._meta.app_label in self.deafult_app_labels:
            return "default"
        elif model._meta.app_label in self.olp_app_labels:
            return "OLP_DB"
        return None

    def db_for_write(self, model, **hints):
        """
        Attempts to write auth and contenttypes models go to default.
        """
        if model._meta.app_label in self.deafult_app_labels:
            return "default"
        elif model._meta.app_label in self.olp_app_labels:
            return "OLP_DB"
        return None

    def allow_relation(self, obj1, obj2, **hints):
        """
        Allow relations if a model in the auth or contenttypes apps is
        involved.
        """
        if (
            obj1._meta.app_label in self.deafult_app_labels
            and obj2._meta.app_label in self.deafult_app_labels
        ):
            return True
        elif (
            obj1._meta.app_label in self.olp_app_labels
            and obj2._meta.app_label in self.olp_app_labels
        ):
            return True
        return None

    def allow_migrate(self, db, app_label, model_name=None, **hints):
        """
        Make sure the auth and contenttypes apps only appear in the
        'default' database.
        """
        if app_label in self.deafult_app_labels:
            return db == "default"
        elif app_label in self.olp_app_labels:
            return db == "OLP_DB"
        return None
