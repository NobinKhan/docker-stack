from datetime import datetime
from decimal import Decimal

from asyncpg import UniqueViolationError
from piccolo.query import Avg
from pydantic import BaseModel, validator

from fastapi import APIRouter, Depends, HTTPException, Request
from fastapi.responses import ORJSONResponse

from authx import AuthX

from api.dependency import get_token_header, config, CustomResponse
from app.auth.model import AuthUser
from app.movie.tables import Movie, Rating


router = APIRouter(
    prefix="/api/v1/movie",
    tags=["movie"],
    dependencies=[Depends(get_token_header)],
)


class CreateMovie(BaseModel):
    name: str
    genre: Movie.Genre
    rating: Movie.Rating
    release_date: datetime

    @validator("release_date", pre=True, always=True)
    def pre_release_date(cls, value, values):
        datetime_obj = datetime.strptime(value, "%d-%m-%Y")
        return datetime_obj


class CreateMovieRating(BaseModel):
    rating: Decimal


@router.post("/create/", status_code=201)
async def create_movie(data: CreateMovie):
    # create mvoie
    try:
        await Movie(**data.model_dump()).save()
    except Exception:
        raise HTTPException(status_code=400, detail={"message": "Something went wrong"})
    return ORJSONResponse(
        status_code=201,
        content={"message": "Movie created successfully"},
    )


@router.get("/all/")
async def get_movies():
    movies: list = (
        await Movie.select()
        .columns(
            Movie.id,
            Movie.name,
            Movie.genre,
            Movie.rating,
            Movie.release_date,
        )
        .order_by(Movie.id)
        .output()
    )
    return ORJSONResponse(movies)


@router.get("/search/", dependencies=None)
async def search_movies(keyword: str):
    if keyword:
        movies = (
            await Rating.select(
                Rating.movie_id,
                Rating.movie_id.name,
                Rating.movie_id.genre,
                Rating.movie_id.rating,
            )
            .where(
                Rating.movie_id.name.ilike(f"%{keyword}%"),
            )
            .distinct()
        )

        user_rating = (
            await Rating.select(Avg(Rating.rating))
            .where(
                Rating.movie_id.name.ilike(f"%{keyword}%"),
            )
            .group_by(Rating.movie_id)
        )

        data = []
        for counter in range(0, len(movies)):
            data.append(
                {
                    "movie_id": movies[counter]["movie_id"],
                    "movie_name": movies[counter]["movie_id.name"],
                    "movie_genre": movies[counter]["movie_id.genre"],
                    "rated": movies[counter]["movie_id.rating"],
                    "avarage_user_rating": user_rating[counter]["avg"].quantize(
                        Decimal("0.0"),
                    ),
                },
            )

    return CustomResponse(data)


@router.get("/rating/all/")
async def get_movie_ratings():
    movie_ratings: list = (
        await Rating.select()
        .columns(
            Rating.id,
            Rating.user_id,
            Rating.movie_id,
            Rating.rating,
        )
        .order_by(Rating.id)
        .output()
    )
    return CustomResponse(movie_ratings)


@router.post("/{movie_id}/rate/", status_code=201)
async def create_rate(movie_id: int, data: CreateMovieRating, request: Request):
    payload = await AuthX(config=config).access_token_required(request)
    user = await AuthUser.objects().where(AuthUser.id == int(payload.sub)).first()

    # create rating
    try:
        await Rating(user_id=user.id, movie_id=movie_id, rating=data.rating).save()
    except UniqueViolationError:
        raise HTTPException(
            status_code=400,
            detail={"message": "You have already rated this movie!"},
        )
    except ValueError as error:
        raise HTTPException(status_code=400, detail={"message": error.args})

    except Exception:
        raise HTTPException(status_code=400, detail={"message": "something went wrong"})

    return ORJSONResponse(
        status_code=201,
        content={"message": "Movie Rating created successfully"},
    )
