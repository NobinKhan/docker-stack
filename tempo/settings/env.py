from enum import Enum
from pydantic import Field, computed_field
from pydantic_settings import BaseSettings, SettingsConfigDict


class EnvironmentChoices(Enum):
    LOCAL = "local"
    TEST = "test"
    DEV = "dev"
    CI_CD = "ci_cd"
    STAGING = "staging"
    PRODUCTION = "production"


class EnvFileChoices(Enum):
    LOCAL = "env/.env.local"
    TEST = "env/.env.test"
    DEV = "env/.env.dev"
    CI_CD = "env/.env.ci_cd"
    STAGING = "env/.env.staging"
    PRODUCTION = "env/.env.prod"


class EnvSettings(BaseSettings):
    """
    This class defines the setting configuration for this auth service
    """

    PROJECT_ENVIRONMENT: EnvironmentChoices = Field(
        default=EnvironmentChoices.LOCAL,
        frozen=True,
    )

    @computed_field
    def env_file(self) -> str:
        match self.PROJECT_ENVIRONMENT:
            case EnvironmentChoices.LOCAL:
                return EnvFileChoices.LOCAL.value
            case EnvironmentChoices.TEST:
                return EnvFileChoices.TEST.value
            case EnvironmentChoices.DEV:
                return EnvFileChoices.DEV.value
            case EnvironmentChoices.CI_CD:
                return EnvFileChoices.CI_CD.value
            case EnvironmentChoices.STAGING:
                return EnvFileChoices.STAGING.value
            case EnvironmentChoices.PRODUCTION:
                return EnvFileChoices.PRODUCTION.value

    model_config = SettingsConfigDict(
        env_file=(".env"),
        extra="ignore",
        case_sensitive=True,
    )


env_config = EnvSettings()
