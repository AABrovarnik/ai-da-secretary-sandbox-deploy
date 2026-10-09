# AI-да-Секретарь: деплой в WEB-песочницу

## Цель
Развернуть приложение изолированно в Docker Compose и опубликовать через существующий host Nginx на `sandbox.xn--01-dlcyz9d7b.xn--p1ai`, не затрагивая текущий сайт.

## 1) Подготовка на сервере
```bash
mkdir -p /srv/ai-shared/web-sandbox/ai-da-secretary
cd /srv/ai-shared/web-sandbox/ai-da-secretary
# git clone <repo-url> .
cp deploy/.env.sandbox.example deploy/.env.sandbox
```

Заполнить `deploy/.env.sandbox`:
- `POSTGRES_PASSWORD`
- `SESSION_SECRET`
- `OPENAI_API_KEY`

## 2) Запуск compose
```bash
cd /srv/ai-shared/web-sandbox/ai-da-secretary/deploy
docker compose --env-file .env.sandbox -f docker-compose.sandbox.yml up -d --build
docker compose --env-file .env.sandbox -f docker-compose.sandbox.yml ps
```

Проверки localhost на сервере:
```bash
curl -I http://127.0.0.1:18080/
curl -I http://127.0.0.1:18081/health
```

## 3) Nginx host-route (отдельный vhost)
Создать новый server block для sandbox-хоста (без правки текущего academy vhost):

```nginx
server {
  listen 80;
  server_name sandbox.xn--01-dlcyz9d7b.xn--p1ai;

  location / {
    proxy_pass http://127.0.0.1:18080;
    proxy_http_version 1.1;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
  }
}
```

После этого:
```bash
nginx -t
systemctl reload nginx
```

## 4) TLS для sandbox hostname
Выпустить отдельный сертификат на sandbox hostname (без замены сертификата текущего сайта).
Проверить:
```bash
openssl s_client -connect sandbox.xn--01-dlcyz9d7b.xn--p1ai:443 -servername sandbox.xn--01-dlcyz9d7b.xn--p1ai </dev/null 2>/dev/null | openssl x509 -noout -subject -issuer -ext subjectAltName
```

## 5) Smoke-тест приложения
С локальной машины/или на сервере через проброс:
- зайти в UI
- зарегистрироваться/войти
- создать meeting
- загрузить `audio_2026-10-06_16-15-16.ogg`
- запустить process-latest-audio
- проверить переход run в `succeeded`

CLI сценарий:
```powershell
pwsh -File .\scripts\smoke-audio.ps1 -ApiBase "https://sandbox.xn--01-dlcyz9d7b.xn--p1ai" -AudioPath "C:\Users\aabro\Downloads\audio_2026-10-06_16-15-16.ogg"
```

## 6) Обновление
```bash
cd /srv/ai-shared/web-sandbox/ai-da-secretary
git pull
cd deploy
docker compose --env-file .env.sandbox -f docker-compose.sandbox.yml up -d --build
```