FROM node:18-slim AS base
ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"
RUN corepack enable

FROM base AS build
COPY . /app
WORKDIR /app

RUN apt-get update && rm -rf /var/lib/apt/lists/*

# Install dependencies
RUN --mount=type=cache,id=pnpm,target=/pnpm/store pnpm install --frozen-lockfile

# Deploy only the dokploy app
ENV NODE_ENV=production
RUN pnpm run build

# Ensure /prod/dist exists
RUN mkdir -p /prod/dist && cp -R /app/dist /prod/dist

FROM base AS dokploy
WORKDIR /app

# Set production
ENV NODE_ENV=production

# Copy only the necessary files
COPY --from=build /prod/dist ./dist
COPY --from=build /app/package.json ./package.json
COPY --from=build /app/node_modules ./node_modules

CMD HOSTNAME=0.0.0.0 && pnpm start
