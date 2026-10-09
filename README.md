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
1. Скопировать `deploy/.env.sandbox.example` -> `deploy/.env.sandbox` и заполнить секреты.
2. Запустить из каталога `deploy`:
   - `docker compose --env-file .env.sandbox -f docker-compose.sandbox.yml up -d --build`

## Примечание по TLS
Если сертификат для `sandbox...` ещё выпускается, статус TLS считается промежуточным и не трактуется как финальная ошибка до завершения выдачи.