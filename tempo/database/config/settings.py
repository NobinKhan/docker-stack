import os
from pathlib import Path

from config.env import load_env


# Environment Configuration
if not load_env:
    raise ValueError("Failed to load .env file")

# Build paths inside the project like this: BASE_DIR / 'subdir'.
BASE_DIR: Path = Path(__file__).resolve().parent.parent

# Security Config
SECRET_KEY: str = os.environ.get("DJANGO_SECRET_KEY")
DEBUG: bool = True if os.environ.get("DJANGO_DEBUG") == "True" else False

# Host Config
ALLOWED_HOSTS: list = []
ROOT_URLCONF: str = "config.urls"
WSGI_APPLICATION: str = "config.wsgi.application"
SESSION_ENGINE: str = os.environ.get("DJANO_SESSION_ENGINE")

# Static files (CSS, JavaScript, Images)
STATIC_URL: str = "static/"

# Application definition
INSTALLED_APPS: list = [
    "django.contrib.admin",
    "django.contrib.auth",
    "django.contrib.contenttypes",
    "django.contrib.sessions",
    "django.contrib.messages",
    "django.contrib.staticfiles",
    "ambulance.apps.AmbulanceConfig",
]

MIDDLEWARE: list = [
    "django.middleware.security.SecurityMiddleware",
    "django.contrib.sessions.middleware.SessionMiddleware",
    "django.middleware.common.CommonMiddleware",
    "django.middleware.csrf.CsrfViewMiddleware",
    "django.contrib.auth.middleware.AuthenticationMiddleware",
    "django.contrib.messages.middleware.MessageMiddleware",
    "django.middleware.clickjacking.XFrameOptionsMiddleware",
]

TEMPLATES: list = [
    {
        "BACKEND": "django.template.backends.django.DjangoTemplates",
        "DIRS": [],
        "APP_DIRS": True,
        "OPTIONS": {
            "context_processors": [
                "django.template.context_processors.debug",
                "django.template.context_processors.request",
                "django.contrib.auth.context_processors.auth",
                "django.contrib.messages.context_processors.messages",
            ],
        },
    },
]

# Database
DATABASES: dict = {
    "default": {
        "ENGINE": "django.db.backends.postgresql",
        "NAME": os.environ.get("POSTGRES_DB_DJANGO"),
        "USER": os.environ.get("POSTGRES_USER"),
        "PASSWORD": os.environ.get("POSTGRES_PASSWORD"),
        "HOST": os.environ.get("POSTGRES_HOST"),
        "PORT": os.environ.get("POSTGRES_PORT"),
    },
    "OLP_DB": {
        "ENGINE": "django.db.backends.postgresql",
        "NAME": os.environ.get("POSTGRES_DB"),
        "USER": os.environ.get("POSTGRES_USER"),
        "PASSWORD": os.environ.get("POSTGRES_PASSWORD"),
        "HOST": os.environ.get("POSTGRES_HOST"),
        "PORT": os.environ.get("POSTGRES_PORT"),
    },
}

# Default primary key field type
DEFAULT_AUTO_FIELD: str = "django.db.models.BigAutoField"
DATABASE_ROUTERS: list = ["config.db_route.DefaultRouter"]

# cache settings
CACHES: dict = {
    "default": {
        "BACKEND": os.environ.get("DJANGO_CACHE_BACKEND"),
        "LOCATION": f"{os.environ.get('REDIS_SHCEME')}://{os.environ.get('REDIS_HOST')}:{os.environ.get('REDIS_PORT')}",
        "OPTIONS": {
            # 'PASSWORD': 'yourpassword',  # Make sure this line is commented out or removed
        },
    },
}

# Password validation
AUTH_PASSWORD_VALIDATORS: list = [
    {
        "NAME": "django.contrib.auth.password_validation.UserAttributeSimilarityValidator",
    },
    {
        "NAME": "django.contrib.auth.password_validation.MinimumLengthValidator",
    },
    {
        "NAME": "django.contrib.auth.password_validation.CommonPasswordValidator",
    },
    {
        "NAME": "django.contrib.auth.password_validation.NumericPasswordValidator",
    },
]

# Internationalization
LANGUAGE_CODE: str = "en-us"
TIME_ZONE: str = "UTC"
USE_I18N: bool = True
USE_TZ: bool = True
