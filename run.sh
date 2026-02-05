#!/bin/bash

# === Termux Telegram Bot Full Setup ===

# 1. Update & install required packages
pkg update -y && pkg upgrade -y
pkg install -y git golang procps nano curl

# Optional: install tmux if you want manual session management
pkg install -y tmux

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

# 4. Create .env file if it doesn't exist or missing required variables
ENV_FILE="$REPO_DIR/.env"
if [ ! -f "$ENV_FILE" ]; then
    touch "$ENV_FILE"
fi

# Ensure required vars are present
source "$ENV_FILE"

if [ -z "$TELEGRAM_BOT_TOKEN" ]; then
    read -p "Enter your TELEGRAM_BOT_TOKEN: " BOT_TOKEN
    echo "TELEGRAM_BOT_TOKEN=$BOT_TOKEN" >> "$ENV_FILE"
fi

if [ -z "$TELEGRAM_CHAT_ID" ]; then
    read -p "Enter your TELEGRAM_CHAT_ID: " CHAT_ID
    echo "TELEGRAM_CHAT_ID=$CHAT_ID" >> "$ENV_FILE"
fi

# 5. Build the bot initially
go build -o telegram-bot

# 6. Create auto-update + run loop script
UPDATE_SCRIPT="$REPO_DIR/update_and_run.sh"
cat > "$UPDATE_SCRIPT" << 'EOF'
#!/bin/bash

cd $HOME/telegram-bot

# Load env vars
export $(grep -v '^#' .env | xargs)

# Infinite loop for auto-update & crash recovery
while true; do
    # Check for updates
    git fetch origin main
    LOCAL=$(git rev-parse HEAD)
    REMOTE=$(git rev-parse origin/main)

    if [ "$LOCAL" != "$REMOTE" ]; then
        echo "[INFO] Changes detected. Pulling and rebuilding..."
        git reset --hard
        git clean -fd
        git pull origin main
        go build -o telegram-bot
        echo "[INFO] Bot rebuilt."
    fi

    # Restart bot if not running
    if ! pgrep -f telegram-bot >/dev/null; then
        echo "[INFO] Bot is not running. Starting..."
        nohup ./telegram-bot > bot.log 2>&1 &
    fi

    sleep 60
done
EOF

chmod +x "$UPDATE_SCRIPT"

# 7. Start the bot forever with nohup
echo "[INFO] Starting bot and auto-update loop..."
nohup "$UPDATE_SCRIPT" > setup.log 2>&1 &

echo "[DONE] Setup complete!"
echo "The bot is running in the background. Logs:"
echo " - Bot output: $REPO_DIR/bot.log"
echo " - Setup logs: $REPO_DIR/setup.log"
echo "To see live logs: tail -f $REPO_DIR/bot.log"
