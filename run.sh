#!/bin/bash

# === Termux Telegram Bot Full Setup (No tmux) ===

# 1. Update & install required packages
pkg update -y && pkg upgrade -y
pkg install -y git golang procps nano curl

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

# Load existing env vars
set -o allexport
source "$ENV_FILE"

# Prompt for missing vars
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

# 6. Create update_and_run.sh script
UPDATE_SCRIPT="$REPO_DIR/update_and_run.sh"
cat > "$UPDATE_SCRIPT" << 'EOF'
#!/bin/bash

cd $HOME/telegram-bot

# Load env vars
export $(grep -v '^#' .env | xargs)

while true; do
    # Check for updates
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

    # Restart bot if not running
    if ! pgrep -f telegram-bot >/dev/null; then
        echo "[INFO] Bot not running. Starting..."
        ./telegram-bot > bot.log 2>&1 &
        echo "[INFO] Bot started."
    fi

    sleep 60
done
EOF

chmod +x "$UPDATE_SCRIPT"

# 7. Kill any previous bot instance
pkill -f telegram-bot 2>/dev/null

# 8. Start the update_and_run loop directly in this terminal
echo "[INFO] Starting update + bot loop. Logs will appear below..."
"$UPDATE_SCRIPT"
