#!/bin/bash
DB=/home/ubuntu/webai/data/webai.db
echo "=== API keys ==="
sqlite3 "$DB" "SELECT name, user_id FROM api_keys;"
echo "=== Recent messages (thoughts = visitor/ip) ==="
sqlite3 "$DB" "SELECT role, substr(text,1,70), substr(thoughts,1,80), created_at FROM messages ORDER BY created_at DESC LIMIT 12;"
echo "=== Portfolio-like questions ==="
sqlite3 "$DB" "SELECT COUNT(*) FROM messages WHERE text LIKE '%Who is Peter%' OR text LIKE '%portfolio assistant%';"
echo "=== Chats today (count per chat_id) ==="
sqlite3 "$DB" "SELECT chat_id, COUNT(*) FROM messages WHERE date(created_at) = date('now') GROUP BY chat_id;"
