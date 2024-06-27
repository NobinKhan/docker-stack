from pydantic import Field, PositiveInt
from pydantic_settings import BaseSettings, SettingsConfigDict
from settings.env import env_config

class ServicesSettings(BaseSettings):
    AUTH_SERVICE_URL: str = Field(frozen=True, alias="AUTH_SERVICE_URL")
    AUTH_SERVICE_PORT: PositiveInt = Field(frozen=True, alias="AUTH_SERVICE_PORT")

    model_config = SettingsConfigDict(
        env_file=env_config.env_file,
        extra="ignore",
        case_sensitive=True,
    )


services_config = ServicesSettings()
