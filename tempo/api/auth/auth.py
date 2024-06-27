from pydantic import BaseModel

from fastapi import APIRouter, HTTPException

from authx import AuthX, AuthXConfig

from app.auth.model import AuthUser

config = AuthXConfig()
config.JWT_ALGORITHM = "HS256"
config.JWT_SECRET_KEY = "SECRET_KEY"
security = AuthX(config=config)

router = APIRouter(
    prefix="/api/v1/auth",
    tags=["auth"],
    responses={404: {"description": "Not found"}},
)


class LoginData(BaseModel):
    username: str
    password: str


@router.post("/login/")
async def login(data: LoginData):
    user = await AuthUser.login(data.username, data.password)
    if user:
        access_token = security.create_access_token(
            uid=f"{user['id']}",
            user_id=user["id"],
        )
        return {"access_token": access_token}
    raise HTTPException(status_code=401, detail={"message": "Bad credentials"})
