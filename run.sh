#!/bin/bash

# === Termux Telegram Bot Setup Script ===

# 1. Update & install required packages
pkg update -y && pkg upgrade -y
pkg install -y git golang procps nano

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
    echo "[INFO] Creating .env file..."
    read -p "Enter your TELEGRAM_BOT_TOKEN: " BOT_TOKEN
    read -p "Enter your TELEGRAM_CHAT_ID: " CHAT_ID
    echo "TELEGRAM_BOT_TOKEN=$BOT_TOKEN" > "$ENV_FILE"
    echo "TELEGRAM_CHAT_ID=$CHAT_ID" >> "$ENV_FILE"
fi

# 5. Create auto-update script
UPDATE_SCRIPT="$REPO_DIR/update_and_run.sh"
cat > "$UPDATE_SCRIPT" << 'EOF'
#!/bin/bash

cd $HOME/telegram-bot

# Load env vars
export $(grep -v '^#' .env | xargs)

# Infinite loop for auto-update
while true; do
    git fetch origin main
    LOCAL=$(git rev-parse HEAD)
    REMOTE=$(git rev-parse origin/main)

    if [ "$LOCAL" != "$REMOTE" ]; then
        echo "[INFO] Changes detected. Updating bot..."
        git pull origin main
        go build -o telegram-bot
        pkill -f telegram-bot 2>/dev/null
        ./telegram-bot &
        echo "[INFO] Bot restarted."
    fi

    sleep 60
done
EOF

chmod +x "$UPDATE_SCRIPT"

# 6. Build bot initially
go build -o telegram-bot

# 7. Start the bot in background
./telegram-bot &

echo "[DONE] Setup complete!"
echo "Run '$UPDATE_SCRIPT' to enable auto-update loop."
