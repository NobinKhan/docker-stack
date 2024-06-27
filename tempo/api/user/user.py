from authx import AuthX
from pydantic import BaseModel, EmailStr
from asyncpg import UniqueViolationError

from fastapi import APIRouter, Depends, HTTPException, Request
from fastapi.responses import ORJSONResponse

from app.auth.model import AuthUser
from api.dependency import get_token_header, config


router = APIRouter(
    prefix="/api/v1/user",
    tags=["user"],
    responses={404: {"description": "Not found"}},
)


class CreateUser(BaseModel):
    name: str
    password: str
    email: EmailStr
    phone: str


@router.post("/create/", status_code=201)
async def create_user(data: CreateUser):
    # create user
    try:
        await AuthUser.create_user(username=data.name, **data.model_dump())
    except UniqueViolationError as error:
        raise HTTPException(status_code=400, detail={"message": error.detail})
    return ORJSONResponse(
        status_code=201,
        content={"message": "User created successfully"},
    )


@router.get("/all/", dependencies=[Depends(get_token_header)])
async def read_users():
    users: list = (
        await AuthUser.select()
        .columns(
            AuthUser.id,
            AuthUser.name,
            AuthUser.phone,
            AuthUser.password,
            AuthUser.email,
        )
        .order_by(AuthUser.id)
        .output()
    )
    return ORJSONResponse(users)


@router.get("/me/", dependencies=[Depends(get_token_header)])
async def read_user_me(payload: Request):
    data = await AuthX(config=config).access_token_required(payload)
    me = (
        await AuthUser.select(
            AuthUser.id,
            AuthUser.name,
            AuthUser.username,
            AuthUser.phone,
            AuthUser.email,
        )
        .where(AuthUser.id == int(data.sub))
        .first()
    )
    return ORJSONResponse(me)
