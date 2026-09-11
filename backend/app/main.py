import asyncio
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api.health import router as health_router
from app.api.v1.auth import router as auth_router
from app.api.v1.categories import router as categories_router
from app.api.v1.expenses import router as expenses_router
from app.api.v1.groups import router as groups_router
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
from app.scheduler import recurring_job_loop


@asynccontextmanager
async def lifespan(app: FastAPI):
    task = asyncio.create_task(recurring_job_loop())
    yield
    task.cancel()
    try:
        await task
    except asyncio.CancelledError:
        pass


app = FastAPI(
    title=settings.app_name,
    version=settings.version,
    docs_url="/docs" if settings.debug else None,
    redoc_url="/redoc" if settings.debug else None,
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(health_router)
app.include_router(auth_router)
app.include_router(groups_router)
app.include_router(categories_router)
app.include_router(expenses_router)
app.include_router(recurring_router)
app.include_router(recurring_global_router)
app.include_router(budgets_router)
app.include_router(budgets_global_router)
app.include_router(stats_router)
