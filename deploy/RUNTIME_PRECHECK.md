# Runtime Precheck — sandbox image-only deploy

Цель — до перехода к полноценной runtime acceptance проверить, что обе app images опубликованы, доступны серверу для pull, Compose настроен на них и sandbox проходит smoke. Этот документ — precheck/runbook, не разрешение выполнять server rollout, менять Nginx/TLS или серверные secrets.

## 1. Канонические image names и tags

Предложенные package names (нужно подтвердить при публикации CI приложения):

```dotenv
BACKEND_IMAGE=ghcr.io/aabrovarnik/ai-da-secretary-backend
FRONTEND_IMAGE=ghcr.io/aabrovarnik/ai-da-secretary-frontend
```

Для обоих сервисов задаются отдельные tags:

```dotenv
BACKEND_TAG=sha-<40-hex-app-source-commit>
FRONTEND_TAG=sha-<40-hex-app-source-commit>
```

Пример формата: `sha-0123456789abcdef0123456789abcdef01234567`. Это формат, не утверждение, что такой tag уже опубликован. Перед использованием заменить его реальным app source commit, опубликованным в обеих images. Допускаются immutable release tags при условии, что registry/publishing policy запрещает их перезапись. Не использовать `latest` или другие перемещаемые tags. Для строгой идентичности дополнительно фиксировать digest из registry.

Frontend image должен быть собран CI приложения с `VITE_API_BASE_URL=/api`. Backend и frontend tags должны относиться к согласованной версии приложения.

## 2. Проверить, что refs существуют и доступны

На машине, где выполняется precheck, определить registry auth до проверки приватных images.

- Для GHCR private pulls использовать GitHub PAT classic с минимальным `read:packages` scope и аккаунтом, которому выдан read access к package; либо выделенную automation identity/token, хранящуюся в разрешённом secret manager.
- В GitHub Actions использовать `GITHUB_TOKEN` с доступом workflow repository к package, если применимо.
- Не помещать токен в git, `.env.sandbox`, shell history, PR или логи. Предпочитать secret manager и `--password-stdin`.
- Публичные GHCR container images можно получать анонимно. Проверить фактическую visibility/access policy package.

Пример безопасного интерактивного входа (секрет подставлять из secret manager, не literal в команде):

```bash
printf '%s' "$GHCR_READ_TOKEN" | docker login ghcr.io --username "$GHCR_USERNAME" --password-stdin
```

Проверить manifests по каждому реальному ref. `imagetools inspect` — read-only registry metadata lookup:

```bash
docker buildx imagetools inspect ghcr.io/aabrovarnik/ai-da-secretary-backend:sha-<real-40-hex-commit>
docker buildx imagetools inspect ghcr.io/aabrovarnik/ai-da-secretary-frontend:sha-<real-40-hex-commit>
```

`manifest unknown`/`not found` означает, что package/tag не опубликован или ref неверен. `unauthorized`/`denied` означает, что нужно исправить registry authentication/package access; не считать это отсутствием image.

## 3. Compose precheck → pull → isolated up → smoke

Только в изолированной sandbox/test runtime, после выбора свободных loopback ports и отдельного Compose project name. Указать реальные image/tag values в `deploy/.env.sandbox`; файл содержит runtime secrets и не должен коммититься.

Из каталога deploy checkout:

```bash
cd /srv/ai-shared/web-sandbox/ai-da-secretary/deploy
docker compose --env-file .env.sandbox -f docker-compose.sandbox.yml config --quiet
docker compose --env-file .env.sandbox -f docker-compose.sandbox.yml config --images
docker compose --env-file .env.sandbox -f docker-compose.sandbox.yml pull
docker compose --env-file .env.sandbox -f docker-compose.sandbox.yml up -d --no-build --pull always
docker compose --env-file .env.sandbox -f docker-compose.sandbox.yml ps
# If using the example ports (substitute configured loopback ports if changed):
curl -fsS -I http://127.0.0.1:18080/
curl -fsS http://127.0.0.1:18081/health
```

После endpoint checks выполнить app smoke: register/login, create meeting, upload `.ogg`, invoke `process-latest-audio`, verify `ProcessingRun.status = succeeded`. Не использовать `down -v`; не удалять persistent volumes в рамках precheck.

## 4. PASS / FAIL gate

**PASS — разрешает запросить отдельный runtime acceptance этап**, если одновременно:

1. Все четыре image/tag values заменены на реальные refs, tags неизменяемые; manifests доступны с нужного runtime host/account.
2. Compose `config --quiet` завершается с exit 0; resolved `config --images` содержит ожидаемые backend/frontend images; у этих services нет `build:`.
3. Compose `pull` завершается с exit 0 для backend, frontend и postgres.
4. `up -d --no-build --pull always` завершается с exit 0; контейнеры running/healthy там, где healthcheck определён.
5. Frontend `HEAD /` и backend `GET /health` успешны; application smoke завершён, processing run имеет `succeeded`.
6. Использованы изолированный project name/свободные loopback ports; отсутствовали изменения host Nginx, TLS, firewall и systemd.

**FAIL / BLOCKED** при любом из условий: placeholder/плавающий tag, manifest отсутствует, pull auth denied, Compose parse/build invariant не проходит, pull/up или endpoint/smoke не проходит. Зафиксировать команду, exit code и безопасный фрагмент ошибки; секреты не включать. После устранения блокера повторить весь gate.

PASS этого precheck не является разрешением на production/server rollout. Для него требуется отдельное поручение и проверка границ следующего этапа.

## 5. Документация

- [GitHub Container Registry: authentication and image pull](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry)
- [GitHub Packages permissions and `read:packages`](https://docs.github.com/en/packages/learn-github-packages/about-permissions-for-github-packages)
