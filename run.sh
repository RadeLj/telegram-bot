#!/bin/bash

cd $HOME/telegram-bot

# Load .env
set -o allexport
source .env
set +o allexport

# Kill any old bot
pkill -f telegram-bot 2>/dev/null

# Build
go build -o telegram-bot
if [ $? -ne 0 ]; then
    echo "Build failed"
    exit 1
fi

# Run in foreground for debugging
./telegram-bot
