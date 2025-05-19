# EJS: Universal Espress.js Docker Container

[![Docker](https://img.shields.io/badge/Docker-ready-blue)](https://www.docker.com/)
[![Alpine](https://img.shields.io/badge/Alpine-3.20-blue.svg)](https://alpinelinux.org)
[![Node](https://img.shields.io/badge/Node-22.15.1-blue.svg)](https://nodejs.org/)
[![NPM](https://img.shields.io/badge/NPM-10.9.2-orange)](https://www.npmjs.com/)

## 📘 Overview

A universal Docker container for Node.js (Express.js) applications based on Alpine Linux. Supports both development and production, pre-installed with SQLite, curl, jq, nano and more.
Includes healthcheck support, dynamic dependency installation, and hot-reload (Nodemon) in development mode.

---

## Features

- Based on: `node:lts-alpine3.20`
- Loads `.env` variables automatically
- Dynamic dependency installation via `start.sh`
- Hot-reload support with Nodemon in development
- Validates required environment variables before starting
- HTTP Healthcheck on `/health`
- Auto-detects and runs the most common entrypoints (index.js, app.js, etc.)

---

## File Structure

```text
Dockerfile
start.sh
/app/
  ├─ package.json
  ├─ index.js / app.js / main.js / server.js / src/index.js / dist/index.js
  └─ node_modules/
```

---

## Environment Variables

The following variables are **required** for secure startup:

- `JWT_SECRET`: Your app's JWT secret key.
- `JWT_EXPIRES_IN`: JWT token expiration time.

Optional variables:

- `NODE_ENV`: Runtime environment (`production` by default, use `development` for hot-reload).
- `PORT`: Port exposed by your app (default is `3000`).

You can define them in your shell, `.env` file, or with `-e` in Docker.

---

## Run Commands

### Build the Image

```sh
docker build -t humbertovarona/ejs .
```

### Run in **Production** Mode

```sh
docker run -d -p 3000:3000 \
  --name test_ejs \
  -v $(pwd)/app:/usr/src/app \
  -e JWT_SECRET=your_jwt_secret \
  -e JWT_EXPIRES_IN=1d \
  humbertovarona/ejs
```

### Run in **Development** Mode (hot-reload)

```sh
docker run -d -p 3000:3000 \
  --name test_ejs \
  -e NODE_ENV=development \
  -v $(pwd)/app:/usr/src/app \
  -e JWT_SECRET=your_jwt_secret \
  -e JWT_EXPIRES_IN=1d \
  humbertovarona/ejs
```

> **Note:** `nodemon` must be installed as a dependency (in `devDependencies`).

---

## Execution Modes

### Production Mode

- Installs dependencies with `npm install --omit=dev`
- Runs the app with `node` (searches for standard entrypoints)
- No automatic reload on code changes

### Development Mode

- Installs all dependencies (`npm install`)
- If `nodemon` is found, runs your app with hot-reload
- Ideal for active development

---

## Docker Compose (Multi-Profile)

You can use Docker Compose to manage multi-profile environments (production, development, test, etc.).

**docker-compose.yml:**

```yaml
version: "3.9"

services:
  app-prod:
    image: humbertovarona/ejs:latest:1.0
    container_name: app-express-prod
    restart: unless-stopped
    environment:
      NODE_ENV: production
      JWT_SECRET: "YOUR_SECRET_KEY"
      JWT_EXPIRES_IN: "2h"
      PORT: 3000
    ports:
      - "3000:3000"
    volumes:
      - ./app:/usr/src/app
  app-dev:
    image: humbertovarona/ejs:latest:1.0
    container_name: app-express-dev
    restart: unless-stopped
    environment:
      NODE_ENV: development
      JWT_SECRET: "YOUR_SECRET_KEY"
      JWT_EXPIRES_IN: "2h"
      PORT: 3001
    ports:
      - "3001:3000"
    volumes:
      - ./app:/usr/src/app
      - ./db/database_dev.sqlite:/usr/src/app/database.sqlite
```

### How to generate your secret key?

```sh
openssl rand -base64 64
```

### Basic commands to launch each profile:

#### 1. Production only:

```sh
docker-compose up -d --profile app-prod
```

This will launch only the production service (using the image, ports, and variables from that profile).

Your app will be located at:

http://localhost:3000

#### 2. Development only:

```sh
docker-compose up -d --profile app-dev
```

This will launch only the development service, with hot reload (if you use nodemon).
Your app will be located at:

http://localhost:3001

#### 3. Both at the same time:

```sh
docker-compose up -d
```

This will start both services (app-prod and app-dev).

> **Tip:** You can extend with multiple services (DB, cache, etc.) in the same file.

### Stop a profile/service:

For example, stop development only:

```sh
docker-compose stop app-dev
```

Stop production only:

```sh
docker-compose stop app-prod
```

### View a service's logs:

```sh
docker-compose logs -f app-prod
```

or

```sh
docker-compose logs -f app-dev
```

---

## Container Health

The container exposes `/health` for healthchecks (useful for Docker Swarm, Kubernetes, etc). Directly check health endpoint:

```sh
curl -k http://localhost:3000/health | jq
```

or

```sh
curl -k http://localhost:3001/health | jq
```

---

## Logs

View real-time logs from the container:

```sh
docker logs -f test_ejs
```

---

## Entrypoint and Startup

The script `/usr/local/bin/start.sh`:

- Validates required environment variables.
- Installs dependencies according to the environment.
- Searches for the first available entrypoint in this order:

  - `index.js`, `app.js`, `main.js`, `server.js`, `src/index.js`, `dist/index.js`, `index.ts`

- Runs the application with `node` (or with `nodemon` in development).

---

## Troubleshooting

- **Missing variables:** If `JWT_SECRET` or `JWT_EXPIRES_IN` are missing, the container will abort with an error.
- **Missing dependencies:** If a package is missing, it will be auto-installed at startup.
- **App does not start:** If no standard entrypoints are found, the container will launch a debug shell.
- **Permission issues:** Ensure files inside `/app` have proper permissions.
- **Health issues:** If `/health` does not respond, verify your application implements the `/health` route.

---

## Additional Notes

- You may extend the entry script or Dockerfile to suit your stack (support for other runtimes, more tools, etc).
- If you use TypeScript, ensure your code is compiled before running the container, or add the build step to `start.sh`.

---

## Example `.env` file:

```env
JWT_SECRET=SuperSecretKey
JWT_EXPIRES_IN=1d
PORT=3000
NODE_ENV=production
```

---

## 👤 Author

**HL Varona**
📧 [humberto.varona@gmail.com](mailto:humberto.varona@gmail.com)
🔧 Project: `VaronaTech`
