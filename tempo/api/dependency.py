from typing import Any
from decimal import Decimal
from datetime import timedelta

import orjson

from fastapi import HTTPException, Request
from fastapi.responses import ORJSONResponse

from authx import AuthX, AuthXConfig


config = AuthXConfig(JWT_ACCESS_TOKEN_EXPIRES=timedelta(minutes=30))
config.JWT_ALGORITHM = "HS256"
config.JWT_SECRET_KEY = "SECRET_KEY"

auth_token = AuthX(config=config)


async def get_token_header(access: Request):
    try:
        await auth_token.access_token_required(access)
    except Exception:
        raise HTTPException(status_code=401, detail={"message": "Bad credentials"})


class CustomResponse(ORJSONResponse):
    def custom_encoder(self, obj):
        if isinstance(obj, Decimal):
            return str(obj)
        return super().default(obj)

    def render(self, content: Any) -> bytes:
        return orjson.dumps(
            content,
            default=self.custom_encoder,
            option=orjson.OPT_NON_STR_KEYS | orjson.OPT_SERIALIZE_NUMPY,
        )
