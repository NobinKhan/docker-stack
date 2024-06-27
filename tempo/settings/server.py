import anyio

from contextlib import asynccontextmanager

from loguru import logger
from fastapi import FastAPI

from settings.env import env_config
from settings.database import Postgresql
from settings.services import services_config
# from settings.security import security_config


# Async Database Configuration
@asynccontextmanager
async def lifespan(app: FastAPI):
    try:
        logger.info(f"Starting {env_config.PROJECT_ENVIRONMENT.value} server")

        async with await anyio.connect_tcp(
            services_config.AUTH_SERVICE_URL, services_config.AUTH_SERVICE_PORT
        ) as client:
            await client.send(b"Client\n")
            response = await client.receive()
            logger.info(response)

        db_conn = await Postgresql().db_conn()
        app.state = {"db_conn": db_conn}
        yield
    except ConnectionRefusedError:
        logger.error("Could not connect to auth service")
    except OSError:
        logger.error("Critical Error! Service will not work!")
    finally:
        yield


# main app
app = FastAPI(
    title="Ambulance Service",
    description="Ambulance Service API",
    version="0.1.0",
    lifespan=lifespan,
)


# routers definition
# app.include_router(auth.router)
# app.include_router(user.router)
# app.include_router(movie.router)


# main root url
@app.get("/")
async def root():
    return {"message": "Ambulance is coming"}
