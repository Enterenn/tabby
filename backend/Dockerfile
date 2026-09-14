FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

# Install dependencies first (cached layer)
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

RUN groupadd --system --gid 10001 tabby \
    && useradd --system --uid 10001 --gid tabby --home-dir /app tabby

COPY --chown=tabby:tabby . .
RUN mkdir -p /app/uploads && chown tabby:tabby /app/uploads

USER tabby

EXPOSE 8000

CMD ["sh", "-c", "alembic upgrade head && uvicorn app.main:app --host 0.0.0.0 --port 8000"]
