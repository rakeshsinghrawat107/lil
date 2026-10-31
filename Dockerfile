FROM node:22-alpine AS frontend-build

WORKDIR /app/frontend
COPY frontend/package*.json ./
RUN npm ci
COPY frontend/ ./
RUN npm run build

FROM python:3.12-slim

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONPATH=/app \
    FLASK_ENV=production \
    PORT=7860

RUN apt-get update \
    && apt-get install --no-install-recommends -y libpq5 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY backend/requirements.txt /app/backend/requirements.txt
RUN pip install --no-cache-dir -r /app/backend/requirements.txt

COPY backend/ /app/backend/
COPY ["volunteers CSV.csv", "/app/volunteers CSV.csv"]
COPY --from=frontend-build /app/frontend/dist/ /app/frontend/dist/

RUN useradd -m -u 1000 appuser && chown -R appuser:appuser /app
USER appuser

EXPOSE 7860

CMD ["sh", "-c", "python -m backend.app.db.migrate && python -m backend.app.db.seed && exec gunicorn --bind 0.0.0.0:${PORT:-7860} --workers 2 --threads 4 --timeout 120 backend.run:app"]
