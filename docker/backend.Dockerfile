FROM node:20-alpine AS build
WORKDIR /app

COPY package.json package-lock.json ./
COPY apps/backend/package.json apps/backend/package.json
COPY apps/frontend/package.json apps/frontend/package.json
COPY apps/worker/package.json apps/worker/package.json
COPY prisma ./prisma
RUN npm ci

COPY . .
RUN npm run db:generate
RUN npm --workspace apps/backend run build

FROM node:20-alpine AS runtime
WORKDIR /app
ENV NODE_ENV=production

COPY --from=build /app /app

EXPOSE 4000
CMD ["sh", "-lc", "npm run db:deploy && npm --workspace apps/backend run start"]