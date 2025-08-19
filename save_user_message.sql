-- Single point of logging incoming messages
INSERT INTO chat_log (
  user_id, gtc_user_id, message, channel, session_id, timestamp, metadata
) VALUES (
  $1, $2,
  $3,                    -- text or placeholder
  'telegram',
  $4,                    -- chat_id
  NOW(),
  $5::jsonb              -- full raw Telegram update (JSON.stringify)
)
RETURNING *;
