# Proposal: image-only deploy для sandbox

Статус: proposal на review, ещё не подтверждён публикацией приложенческих images.
Дата: 2026-10-10.
Ветка: `ai/deploy-image-only`.

## Цель

Устранить зависимость sandbox deploy checkout от source tree приложения. Deploy Compose должен только получать и запускать готовые backend/frontend images; CI приложения отвечает за сборку и публикацию.

## Предлагаемый контракт

- Compose принимает image names и tags раздельно через `BACKEND_IMAGE`/`BACKEND_TAG` и `FRONTEND_IMAGE`/`FRONTEND_TAG`.
- Предложенные GHCR packages: `ghcr.io/aabrovarnik/ai-da-secretary-backend` и `ghcr.io/aabrovarnik/ai-da-secretary-frontend`.
- Каждый deploy указывает immutable commit-SHA tag либо digest; `latest` не использовать.
- Frontend image publisher должен собирать приложение с `VITE_API_BASE_URL=/api`, как в прежнем Compose build arg.
- `pull_policy: always`; запуск — `docker compose pull`, затем `docker compose up -d --no-build --pull always`.
- Compose не содержит `build:` и не нуждается в app source tree.

## Включено в task branch

- Compose переведён с локальных build contexts на обязательные image names/tags.
- `.env.sandbox.example`, README и deploy runbook описывают image refs и config/pull/up порядок.
- Rollback описан как возврат сохранённых refs без удаления persistent volumes.

## Открытые prerequisites / blockers

1. В доступном GitHub account listing нет app source repository или опубликованных packages, а GitHub Packages API недоступен текущему токену (`403`, отсутствует `read:packages`). Поэтому существование предложенных GHCR packages не подтверждено.
2. Требуется подтвердить имена packages и обеспечить CI приложения, который публикует backend/frontend images для согласованного immutable tag.
3. Требуется определить безопасную выдачу pull credentials, если packages private. Credentials не включать в git или `.env.sandbox`.
4. Без опубликованных refs и pull-доступа нельзя честно пройти `pull` и `up`; они остаются release acceptance gates.

## QA gate

На отдельной sandbox/test runtime с изолированным Compose project name, уникальными host ports и временными тестовыми секретами:

1. `docker compose ... config --quiet` — PASS; отдельно проверить, что `backend.build` и `frontend.build` отсутствуют, а обе image names/tags разрешены.
2. `docker compose ... pull` — PASS для app images и postgres.
3. `docker compose ... up -d --no-build --pull always` — PASS; затем проверить `docker compose ps`, UI `/`, backend `/health` и application smoke.
4. Удаление окружения, если требуется, не удаляет volumes; `down -v` запрещён для sandbox с нужными данными.

В этой task ветке `config` может быть проверен с безопасными placeholder values. `pull/up` намеренно не запускаются без реальных опубликованных images: это не серверная задача и сейчас нет подтверждённых refs.

## Вне scope

Серверный deploy, server `.env`, host Nginx, TLS/certbot, systemd, DNS/firewall и production publication changes. PR merge не выполняется автоматически.
