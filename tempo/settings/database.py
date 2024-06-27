from loguru import logger

from asyncpg import connect as postgres_connect
from asyncpg.exceptions import InvalidCatalogNameError, InvalidPasswordError

from pydantic import Field, SecretStr, PositiveInt
from pydantic_settings import BaseSettings, SettingsConfigDict

from settings.env import env_config


class DatabaseSettings(BaseSettings):
    # General Database Configuration

    # PostgreSQL Database Configuration
    POSTGRES_HOST: SecretStr = Field(default="localhost", frozen=True, repr=False)
    POSTGRES_PORT: PositiveInt = Field(default=5432, frozen=True, repr=False)
    POSTGRES_DB: SecretStr = Field(default="postgres", frozen=True, repr=False)
    POSTGRES_USER: SecretStr = Field(default="postgres", frozen=True, repr=False)
    POSTGRES_PASSWORD: SecretStr = Field(default="postgres", frozen=True, repr=False)
    ATOMIC_DB: bool = Field(default=True, frozen=True, repr=False)

    model_config = SettingsConfigDict(
        env_file=env_config.env_file,
        extra="ignore",
        case_sensitive=True,
    )

    def postgres_url(self) -> str:
        return (
            f"postgresql://{self.POSTGRES_USER.get_secret_value()}:"
            f"{self.POSTGRES_PASSWORD.get_secret_value()}@"
            f"{self.POSTGRES_HOST.get_secret_value()}:{self.POSTGRES_PORT}/"
            f"{self.POSTGRES_DB.get_secret_value()}"
        )


_db_config = DatabaseSettings()


class Postgresql:
    async def db_conn(self):
        try:
            logger.info("connecting to database")
            conn = await postgres_connect(dsn=_db_config.postgres_url())
            db_name = await conn.fetchval("SELECT current_database()")
            logger.info(f"database {db_name} connected")
            return conn
        except InvalidCatalogNameError:
            logger.error(
                f"database {_db_config.POSTGRES_DB.get_secret_value()} not found"
            )
        except ConnectionRefusedError:
            logger.error(
                "database connection refused, please check the database settings"
            )
        except InvalidPasswordError:
            logger.error("invalid credentials, please check the database settings")
