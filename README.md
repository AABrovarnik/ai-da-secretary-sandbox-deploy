# AI-да-Секретарь — Sandbox Deploy Repo

Этот репозиторий содержит только артефакты развертывания WEB-песочницы.

## Содержимое
- `deploy/docker-compose.sandbox.yml`
- `deploy/.env.sandbox.example`
- `deploy/WEB_SANDBOX_DEPLOY.md`
- `docker/backend.Dockerfile`
- `docker/frontend.Dockerfile`
- `nginx/frontend.nginx.conf`

## Назначение
- Единый source-of-truth для агента развертывания (Тесля).
- Изоляция deploy-артефактов от основной разработки.

## Быстрый старт
1. Скопировать `deploy/.env.sandbox.example` -> `deploy/.env.sandbox`, указать опубликованные image names и immutable tags в `BACKEND_IMAGE`/`BACKEND_TAG` и `FRONTEND_IMAGE`/`FRONTEND_TAG`, затем заполнить секреты.
2. Из каталога `deploy` проверить и получить образы:
   - `docker compose --env-file .env.sandbox -f docker-compose.sandbox.yml config --quiet`
   - `docker compose --env-file .env.sandbox -f docker-compose.sandbox.yml pull`
3. Запустить без локальной сборки:
   - `docker compose --env-file .env.sandbox -f docker-compose.sandbox.yml up -d --no-build --pull always`

Публикация backend/frontend images должна выполняться CI приложения. Контракт package names пока proposal — см. `deploy/IMAGE_ONLY_DEPLOY_PROPOSAL.md`.

## Примечание по TLS
Если сертификат для `sandbox...` ещё выпускается, статус TLS считается промежуточным и не трактуется как финальная ошибка до завершения выдачи.
