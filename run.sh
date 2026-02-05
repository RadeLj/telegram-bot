#!/bin/bash

cd $HOME/telegram-bot

# Load env
set -o allexport
source .env
set +o allexport

# Kill old bot
pkill -f telegram-bot 2>/dev/null

# Build initial
go build -o telegram-bot

# --- Background updater ---
(
while true; do
    git fetch origin main
    LOCAL=$(git rev-parse HEAD)
    REMOTE=$(git rev-parse origin/main)
    if [ "$LOCAL" != "$REMOTE" ]; then
        echo "[INFO] New commit detected. Pulling and rebuilding..."
        git reset --hard
        git clean -fd
        git pull origin main
        pkill -f telegram-bot 2>/dev/null
        go build -o telegram-bot
        echo "[INFO] Bot rebuilt."
    fi
    sleep 60
done
) &

# --- Foreground bot (logs visible) ---
echo "[INFO] Starting bot in foreground..."
./telegram-bot
