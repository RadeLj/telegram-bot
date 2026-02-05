package main

import (
	"context"
	"encoding/json"
	"fmt"
	"github.com/go-telegram/bot/models"
	"io"
	"log"
	"net/http"
	"os"
	"strconv"
	"time"

	telegram "github.com/go-telegram/bot"
	"github.com/joho/godotenv"
)

func main() {
	// Load env variables
	_ = godotenv.Load(".env")

	token := os.Getenv("TELEGRAM_BOT_TOKEN")
	chatIDStr := os.Getenv("TELEGRAM_CHAT_ID")
	chatID, err := strconv.ParseInt(chatIDStr, 10, 64)
	if err != nil {
		log.Fatalf("Invalid TELEGRAM_CHAT_ID: %v", err)
	}

	ctx := context.Background()

	bot, err := telegram.New(token)
	if err != nil {
		log.Fatalf("Failed to create Telegram bot: %v", err)
	}

	log.Println("Bot started, polling prices every 1 min...")

	ticker := time.NewTicker(1 * time.Minute)
	defer ticker.Stop()

	for {
		select {
		case <-ticker.C:
			msg, err := fetchPrices()
			if err != nil {
				log.Println("Price fetch error:", err)
				continue
			}

			// send message
			_, err = bot.SendMessage(ctx, &telegram.SendMessageParams{
				ChatID:    chatID,
				Text:      msg,
				ParseMode: models.ParseModeHTML,
			})
			if err != nil {
				log.Println("Telegram send error:", err)
			} else {
				log.Println("Message sent successfully!!2")
			}
		}
	}
}

// fetchPrices gets BTC & ETH price + 1h + 24h change
func fetchPrices() (string, error) {
	url := "https://api.coingecko.com/api/v3/simple/price?ids=bitcoin,ethereum&vs_currencies=usd&include_1h_change=true&include_24hr_change=true"
	resp, err := http.Get(url)
	if err != nil {
		return "", err
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return "", err
	}

	var data map[string]map[string]float64
	if err := json.Unmarshal(body, &data); err != nil {
		return "", err
	}

	btc := data["bitcoin"]
	eth := data["ethereum"]

	msg := fmt.Sprintf(
		"<b>Price Update</b>\n"+
			"BTC: $%.2f | 24h: %.2f%%\n"+
			"ETH: $%.2f | 24h: %.2f%%",
		btc["usd"], btc["usd_24h_change"],
		eth["usd"], eth["usd_24h_change"],
	)
	return msg, nil
}
