#!/bin/bash

# === Termux Telegram Bot Full Setup (Foreground + Auto-update + Persistent) ===

# 1. Update & install packages
pkg update -y && pkg upgrade -y
pkg install -y git golang procps nano curl termux-api

# Keep CPU awake so Android doesn't kill it
termux-wake-lock

# 2. Go to home directory
cd $HOME

# 3. Clone repo or pull latest
REPO_URL="https://github.com/RadeLj/telegram-bot.git"
REPO_DIR="$HOME/telegram-bot"

if [ -d "$REPO_DIR" ]; then
    echo "[INFO] Repo exists. Pulling latest changes..."
    cd "$REPO_DIR"
    git reset --hard
    git clean -fd
    git pull origin main
else
    echo "[INFO] Cloning repo..."
    git clone "$REPO_URL"
    cd "$REPO_DIR"
fi

# 4. Ensure .env exists
ENV_FILE="$REPO_DIR/.env"
if [ ! -f "$ENV_FILE" ]; then
    touch "$ENV_FILE"
fi

# Load env vars and prompt for missing ones
set -o allexport
source "$ENV_FILE"

if [ -z "$TELEGRAM_BOT_TOKEN" ]; then
    read -p "Enter your TELEGRAM_BOT_TOKEN: " BOT_TOKEN
    echo "TELEGRAM_BOT_TOKEN=$BOT_TOKEN" >> "$ENV_FILE"
    TELEGRAM_BOT_TOKEN=$BOT_TOKEN
fi

if [ -z "$TELEGRAM_CHAT_ID" ]; then
    read -p "Enter your TELEGRAM_CHAT_ID: " CHAT_ID
    echo "TELEGRAM_CHAT_ID=$CHAT_ID" >> "$ENV_FILE"
    TELEGRAM_CHAT_ID=$CHAT_ID
fi
set +o allexport

# 5. Function to build the bot
build_bot() {
    echo "[INFO] Building bot..."
    go build -o telegram-bot
    if [ $? -ne 0 ]; then
        echo "[ERROR] Build failed. Fix errors first."
        exit 1
    fi
    echo "[INFO] Build successful."
}

# 6. Kill old bot if running
pkill -f telegram-bot 2>/dev/null

# 7. Build initially
build_bot

# 8. Function to start bot in foreground
start_bot() {
    echo "[INFO] Starting bot in foreground... (Ctrl+C to stop)"
    ./telegram-bot
}

# 9. Main loop: auto-update + bot restart
while true; do
    # Check for updates every 60s in background
    git fetch origin main
    LOCAL=$(git rev-parse HEAD)
    REMOTE=$(git rev-parse origin/main)

    if [ "$LOCAL" != "$REMOTE" ]; then
        echo "[INFO] New commit detected. Pulling and rebuilding..."
        git reset --hard
        git clean -fd
        git pull origin main
        build_bot
        pkill -f telegram-bot 2>/dev/null
        echo "[INFO] Bot rebuilt, restarting..."
    fi

    # Start bot in foreground and wait until it exits
    start_bot

    echo "[WARN] Bot stopped unexpectedly. Restarting in 5s..."
    sleep 5
done
