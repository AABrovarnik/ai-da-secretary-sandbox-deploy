# AI-да-Секретарь: image-only deploy в WEB-песочницу

Compose получает готовые backend/frontend images из registry. Локальная сборка из этого deploy-репозитория не используется. Публикация images приложением и соответствие package refs описаны в `IMAGE_ONLY_DEPLOY_PROPOSAL.md`.

## 1) Подготовка конфигурации

```bash
cd /srv/ai-shared/web-sandbox/ai-da-secretary/deploy
cp -n .env.sandbox.example .env.sandbox
```

В `deploy/.env.sandbox` обязательно задать опубликованные image names `BACKEND_IMAGE`/`FRONTEND_IMAGE` и их `BACKEND_TAG`/`FRONTEND_TAG` (immutable commit/release tags; не `latest`), секреты `POSTGRES_PASSWORD`, `SESSION_SECRET`, `OPENAI_API_KEY` и при необходимости порты. Для приватного GHCR выполнить `docker login ghcr.io` безопасным способом; токен не хранить в репозитории или `.env.sandbox`.

## 2) Проверка, pull и запуск

Из каталога `deploy`:

```bash
docker compose --env-file .env.sandbox -f docker-compose.sandbox.yml config --quiet
docker compose --env-file .env.sandbox -f docker-compose.sandbox.yml pull
docker compose --env-file .env.sandbox -f docker-compose.sandbox.yml up -d --no-build --pull always
docker compose --env-file .env.sandbox -f docker-compose.sandbox.yml ps
```

`config` должен завершиться без ошибок; `pull` должен получить все образы; `up` не должен собирать images локально. Не использовать `down -v`: sandbox database/audio volumes содержат постоянные данные.

## 3) Runtime smoke

```bash
curl -fsS -I http://127.0.0.1:18080/
curl -fsS http://127.0.0.1:18081/health
```

Ожидается успешный HTTP-ответ UI и backend health endpoint. Затем выполнить application smoke: register/login, создать meeting, загрузить `.ogg`, запустить `process-latest-audio`, подтвердить `ProcessingRun.status = succeeded`.

## 4) Nginx/TLS и внешний smoke

Действующие server block, выпуск TLS и внешние проверки остаются отдельным системным этапом; этот image-only change их не выполняет и не меняет.

## 5) Rollback

Сохранить текущие image names/tags. Для rollback вернуть предыдущие `BACKEND_TAG`/`FRONTEND_TAG` в `.env.sandbox`, затем повторить `pull` и `up -d --no-build --pull always`. Не удалять volumes при rollback.
