import asyncio
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
from starlette.responses import Response
from slowapi.middleware import SlowAPIMiddleware

from app.api.health import router as health_router
from app.api.v1.auth import router as auth_router
from app.api.v1.avatars import router as avatars_router
from app.api.v1.categories import router as categories_router
from app.api.v1.expenses import router as expenses_router
from app.api.v1.groups import router as groups_router
from app.api.v1.devices import router as devices_router
from app.api.v1.loyalty_cards import router as loyalty_cards_router
from app.api.v1.personal_expenses import router as personal_expenses_router
from app.api.v1.stats import router as stats_router
from app.api.v1.budgets import (
    global_router as budgets_global_router,
    router as budgets_router,
)
from app.api.v1.recurring_expenses import (
    global_router as recurring_global_router,
    router as recurring_router,
)
from app.core.config import settings
from app.core.database import AsyncSessionLocal
from app.core.rate_limit import (
    ApiRateLimitMiddleware,
    RateLimitExceeded,
    limiter,
    rate_limit_exceeded_handler,
)
from app.core.uploads import ensure_upload_dirs
from app.core.refresh_tokens import purge_expired_refresh_tokens
from app.scheduler import recurring_job_loop


@asynccontextmanager
async def lifespan(_app: FastAPI):
    async with AsyncSessionLocal() as db:
        await purge_expired_refresh_tokens(db)
        await db.commit()
    task = asyncio.create_task(recurring_job_loop())
    yield
    task.cancel()
    try:
        await task
    except asyncio.CancelledError:
        pass


_docs_enabled = settings.debug

app = FastAPI(
    title=settings.app_name,
    version=settings.version,
    docs_url="/docs" if _docs_enabled else None,
    redoc_url="/redoc" if _docs_enabled else None,
    openapi_url="/openapi.json" if _docs_enabled else None,
    lifespan=lifespan,
)


class SecurityHeadersMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next) -> Response:
        response = await call_next(request)
        response.headers["X-Content-Type-Options"] = "nosniff"
        response.headers["X-Frame-Options"] = "DENY"
        response.headers["Referrer-Policy"] = "no-referrer"
        response.headers["Permissions-Policy"] = "camera=(), microphone=(), geolocation=()"
        response.headers["Cache-Control"] = "no-store"
        if not settings.debug:
            response.headers["Strict-Transport-Security"] = (
                "max-age=31536000; includeSubDomains"
            )
        return response


app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, rate_limit_exceeded_handler)
app.add_middleware(SlowAPIMiddleware)
app.add_middleware(ApiRateLimitMiddleware)
app.add_middleware(SecurityHeadersMiddleware)

_cors_origins = [
    origin.strip()
    for origin in settings.public_origin.split(",")
    if origin.strip()
]
if _cors_origins:
    app.add_middleware(
        CORSMiddleware,
        allow_origins=_cors_origins,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )
elif settings.debug:
    app.add_middleware(
        CORSMiddleware,
        allow_origins=["*"],
        allow_credentials=False,
        allow_methods=["*"],
        allow_headers=["*"],
    )

app.include_router(health_router)
app.include_router(auth_router)
app.include_router(avatars_router)
app.include_router(groups_router)
app.include_router(categories_router)
app.include_router(expenses_router)
app.include_router(recurring_router)
app.include_router(recurring_global_router)
app.include_router(budgets_router)
app.include_router(budgets_global_router)
app.include_router(stats_router)
app.include_router(devices_router)
app.include_router(loyalty_cards_router)
app.include_router(personal_expenses_router)

ensure_upload_dirs()
