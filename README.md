
# @Seal agent — reproducible package

This folder contains the minimal set of files to reproduce the working Telegram flow in n8n (MarkdownV2 safe, chunked messages, robust DB writes).

## Files

- `code/SanitizeForTelegram.js` — Code node to escape MarkdownV2 and split long messages into chunks under Telegram's 4096 char limit.
- `sql/register_or_find_user.sql` — Upsert user by Telegram ID; **no chat logging here**.
- `sql/save_user_message.sql` — Single point of logging **incoming** messages (stores raw Telegram update into `metadata`).
- `sql/update_bot_response.sql` — Updates the same `chat_log` record **after** sending the bot reply (stores `response` and `metadata.tg_out.message_id`).

> Keep your n8n export of the workflow, e.g. `workflows/@Seal_agent.json`, alongside these files.

## Expected DB tables (columns used)

- `user(id uuid pk, role text, createdAt timestamptz, gtc_user_id int or uuid)`
- `auth_telegram(user_id uuid fk, telegram_id bigint unique, username text, first_name text, last_name text, chat_count int, created_at timestamptz, updated_at timestamptz)`
- `chat_log(id serial/bigserial pk, user_id uuid fk, gtc_user_id int/uuid, message text, response text, channel text, session_id text, timestamp timestamptz, metadata jsonb)`

> Adjust types to your schema if they differ; the SQL uses only the columns listed above.

## n8n node wiring (critical)

1) **Telegram Trigger** → **RegisterOrFind User** → **Save User Message1**.  
   - `Save User Message1` query = `sql/save_user_message.sql`  
   - Parameters:  
     - `$1` = `{{ $node["RegisterOrFind User"].json["user_id"] }}`  
     - `$2` = `{{ $node["RegisterOrFind User"].json["gtc_user_id"] }}`  
     - `$3` = `{{ $node["Telegram Trigger"].json["message"]["text"] || $node["Telegram Trigger"].json["message"]["caption"] || "[non_text_message]" }}`  
     - `$4` = `{{ $node["Telegram Trigger"].json["message"]["chat"]["id"] }}`  
     - `$5` = `{{ JSON.stringify($node["Telegram Trigger"].json) }}`

2) **Prompt/AI Agent** branch as you have it (no changes needed here).

3) **SanitizeForTelegram (Code)** → **Telegram SendMessage**  
   - Code: `code/SanitizeForTelegram.js`  
   - Telegram node:  
     - **Parse Mode** = `MarkdownV2`  
     - **Text** (Expression) = `{{ $json.tg_text }}` (no leading `=`)  

4) **Save Bot Response** after Telegram send (UPDATE):  
   - Query = `sql/update_bot_response.sql`  
   - Parameters:  
     - `$1` = `{{ $node["Save User Message1"].json["id"] }}`  
     - `$2` = `{{ $node["AI Agent"].json["output"] }}`  
     - `$3` = `{{ $json["message_id"] || $json["result"]?.["message_id"] }}`  
     - `$4` = `{{ $json["chat"]?.["id"] || $json["result"]?.["chat"]?.["id"] }}`  
     - `$5` = `{{ JSON.stringify($json) }}`

## Telegram gotchas

- Escape is mandatory under MarkdownV2, including characters like `_ * [ ] ( ) ~ ` > # + - = | { } . !`.
- Do **not** put any literal characters before `{{ ... }}` in Text (no leading `=`).  
- Long messages are chunked to ~3500 characters automatically in `SanitizeForTelegram`.

## Test checklist

- Amounts and symbols: `2000$`, `50%`, `A=B`  
- Wi‑Fi / email / URLs with `[]()`  
- Emojis 😄 🛍️  
- Long answers (>4096) — should arrive as multiple messages  
- Non-text messages (photo/video/voice) — `message` gets `[non_text_message]`; raw update is in `metadata`

## Security notes

- Never commit tokens/credentials; keep them in n8n credentials or env vars.
- If you export workflows, scrub credential IDs and secrets.
- Consider row-level security for user-scoped reads if exposing an API later.
