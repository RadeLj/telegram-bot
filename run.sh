#!/bin/bash

# === Termux Telegram Bot Full Setup ===

# 1. Update & install required packages
pkg update -y && pkg upgrade -y
pkg install -y git golang procps nano curl tmux

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

# 4. Create .env file if it doesn't exist
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
go build -o telegram-bot

# 6. Create auto-update + run loop script
UPDATE_SCRIPT="$REPO_DIR/update_and_run.sh"
cat > "$UPDATE_SCRIPT" << 'EOF'
#!/bin/bash

cd $HOME/telegram-bot

# Load env vars
set -o allexport
source .env
set +o allexport

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

# 7. Start everything in a tmux session
SESSION_NAME="telegram-bot"

# Kill any old session & bot
tmux kill-session -t $SESSION_NAME 2>/dev/null
pkill -f telegram-bot 2>/dev/null

# Start a new session running the update_and_run script
tmux new-session -d -s $SESSION_NAME "$UPDATE_SCRIPT"

echo "[DONE] Setup complete!!"
echo "The bot is running in tmux session '$SESSION_NAME'."
echo "Attach to see logs: tmux attach -t $SESSION_NAME"
echo "Detach safely: Ctrl+B then D"
echo "Bot log: $REPO_DIR/bot.log"
