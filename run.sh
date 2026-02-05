#!/data/data/com.termux/files/usr/bin/bash
cd ~/mybot || exit

# Pull latest code
git pull origin main

# Load env variables
export $(grep -v '^#' .env | xargs)

# Build bot
go build -o bot main.go

# Run bot in background
./bot &
