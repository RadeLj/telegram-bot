#!/bin/bash

cd $HOME/telegram-bot

# Load env vars
set -o allexport
source .env
set +o allexport

while true; do
    # 1. Check for updates
    git fetch origin main
    LOCAL=$(git rev-parse HEAD)
    REMOTE=$(git rev-parse origin/main)

    if [ "$LOCAL" != "$REMOTE" ]; then
        echo "[INFO] New commit detected. Pulling and rebuilding..."
        git reset --hard
        git clean -fd
        git pull origin main
        go build -o telegram-bot
        echo "[INFO] Bot rebuilt."
    fi

    # 2. Kill old bot if still running
    pkill -f telegram-bot 2>/dev/null

    # 3. Start bot in background
    nohup ./telegram-bot > bot.log 2>&1 &
    BOT_PID=$!
    echo "[INFO] Bot running with PID $BOT_PID"

    # 4. Wait 60s before next update check
    sleep 60
done
