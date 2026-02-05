#!/bin/bash

# === Termux Telegram Bot Full Setup (Foreground + Auto-update) ===

# 1. Update & install required packages
pkg update -y && pkg upgrade -y
pkg install -y git golang procps nano curl

# Optional: keep CPU awake so Android doesn't kill it
pkg install -y termux-api
termux-wake-lock

# 2. Go to home directory
cd $HOME

# 3. Clone repo or pull latest if it exists
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

# 4. Ensure .env exists and load env vars
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

# 5. Build the bot initially
echo "[INFO] Building the bot..."
go build -o telegram-bot
if [ $? -ne 0 ]; then
    echo "[ERROR] Go build failed. Fix errors first."
    exit 1
fi

# 6. Kill any old bot instance
pkill -f telegram-bot 2>/dev/null

# 7. Start the main loop: auto-update + foreground bot
while true; do
    # Check for updates
    git fetch origin main
    LOCAL=$(git rev-parse HEAD)
    REMOTE=$(git rev-parse origin/main)

    if [ "$LOCAL" != "$REMOTE" ]; then
        echo "[INFO] New commit detected. Updating bot..."
        git reset --hard
        git clean -fd
        git pull origin main
        pkill -f telegram-bot 2>/dev/null
        go build -o telegram-bot
        echo "[INFO] Bot rebuilt."
    fi

    # Start bot in foreground and wait for it to exit
    echo "[INFO] Starting bot... (Ctrl+C to stop)"
    ./telegram-bot
    echo "[WARN] Bot stopped unexpectedly. Restarting in 5s..."
    sleep 5
done
