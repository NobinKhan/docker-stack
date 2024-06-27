from pydantic import Field, SecretStr, field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict
from settings.env import EnvironmentChoices, env_config


class SecuritySettings(BaseSettings):
    SECRET_KEY: SecretStr = Field(frozen=True, alias="AMBULANCE_SECRET_KEY")
    DEBUG: bool = Field(default=False, frozen=True)

    model_config = SettingsConfigDict(
        env_file=env_config.env_file,
        extra="ignore",
        case_sensitive=True,
    )

    @field_validator("DEBUG", mode="after")
    def check_debug(cls, field: bool) -> bool:
        if env_config.PROJECT_ENVIRONMENT != EnvironmentChoices.PRODUCTION:
            return True
        return field

    @field_validator("SECRET_KEY", mode="after")
    def check_secret_key(cls, field: SecretStr) -> SecretStr:
        if env_config.PROJECT_ENVIRONMENT != EnvironmentChoices.PRODUCTION:
            return True
        return field


security_config = SecuritySettings()
