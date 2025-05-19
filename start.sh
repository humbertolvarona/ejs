#!/bin/sh

log()     { echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO] $1"; }
error()   { echo "$(date '+%Y-%m-%d %H:%M:%S') [ERROR] $1" >&2; }
success() { echo "$(date '+%Y-%m-%d %H:%M:%S') [SUCCESS] $1"; }
warn()    { echo "$(date '+%Y-%m-%d %H:%M:%S') [WARNING] $1"; }

set -e

REQUIRED_ENV="JWT_SECRET JWT_EXPIRES_IN"
ENTRYPOINTS="index.js app.js main.js server.js src/index.js dist/index.js index.ts"
INSTALLED_OK=1

log "Starting Node.js universal container"
log "Node version: $(node -v)"
log "NPM version: $(npm -v)"
log "Current directory: $(pwd)"
log "Present files: $(ls -1)"
log "Environment variables:"
log "  NODE_ENV: ${NODE_ENV:-undefined}"
log "  PORT: ${PORT:-undefined}"

if [ -f ".env" ]; then
    log ".env file found, exporting variables"
    export $(grep -v '^#' .env | xargs)
fi

for var in $REQUIRED_ENV; do
    eval "VAL=\${$var}"
    if [ -z "$VAL" ]; then
        error "Required environment variable $var is missing."
        INSTALLED_OK=0
    else
        log "Required variable $var: $VAL"
    fi
done

if [ $INSTALLED_OK -eq 0 ]; then
    error "Startup aborted due to missing required environment variables."
    exit 1
fi

if [ -f "package.json" ]; then
    if [ ! -d "node_modules" ]; then
        warn "node_modules directory does not exist. Creating node_modules..."
        mkdir node_modules
    fi

    if [ "$NODE_ENV" = "production" ]; then
        NPM_INSTALL_CMD="npm install --omit=dev"
    else
        NPM_INSTALL_CMD="npm install"
    fi

    warn "package.json found. Running $NPM_INSTALL_CMD to ensure dependencies are present..."
    npm list --json > /tmp/npm-list-before.json || true

    if $NPM_INSTALL_CMD; then
        success "Dependencies installed successfully."
        npm list --json > /tmp/npm-list-after.json || true
        PKGS=$(jq -r '.dependencies // {} | to_entries[] | .key' package.json)
        for pkg in $PKGS; do
            OLD_VER=$(jq -r --arg p "$pkg" '.dependencies[$p].version // empty' /tmp/npm-list-before.json)
            NEW_VER=$(jq -r --arg p "$pkg" '.dependencies[$p].version // empty' /tmp/npm-list-after.json)
            if [ -z "$NEW_VER" ]; then
                error "Package $pkg is missing or failed to install."
                INSTALLED_OK=0
            elif [ -z "$OLD_VER" ]; then
                success "Package $pkg was newly installed (version $NEW_VER)."
            elif [ "$OLD_VER" != "$NEW_VER" ]; then
                warn "Package $pkg was updated from $OLD_VER to $NEW_VER."
            else
                log "Package $pkg was already installed (version $NEW_VER)."
            fi
        done
    else
        error "Error installing dependencies."
        exit 1
    fi
else
    log "Skipping dependency installation (package.json missing)."
fi

if [ $INSTALLED_OK -eq 0 ]; then
    error "Startup aborted due to missing or failed dependencies."
    exit 1
fi

if [ "$NODE_ENV" = "development" ] && command -v nodemon >/dev/null 2>&1; then
    success "NODE_ENV=development and nodemon is available. Running app with nodemon..."
    for entry in $ENTRYPOINTS; do
        if [ -f "$entry" ]; then
            exec nodemon "$entry"
        fi
    done
    warn "No standard entrypoint found for nodemon ($ENTRYPOINTS)."
    exec /bin/sh
else
    for entry in $ENTRYPOINTS; do
        if [ -f "$entry" ]; then
            success "$entry found. Running the application..."
            exec node "$entry"
        fi
    done
    warn "No standard entrypoint found ($ENTRYPOINTS)."
    warn "Starting shell for debug."
    exec /bin/sh
fi
