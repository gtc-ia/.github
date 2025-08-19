-- Update the same chat_log record after Telegram send
UPDATE chat_log
SET
  response = $2,
  metadata = jsonb_set(
    COALESCE(metadata, '{}'::jsonb),
    '{tg_out}',
    jsonb_build_object(
      'message_id', $3::bigint,
      'chat_id',    $4::bigint,
      'raw',        $5::jsonb
    ),
    true
  )
WHERE id = $1
RETURNING *;
