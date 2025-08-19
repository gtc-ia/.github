-- Upsert user by telegram_id without logging messages
WITH p AS (
  SELECT
    $1::bigint  AS telegram_id,
    $2::text    AS username,
    $3::text    AS first_name,
    $4::text    AS last_name
),
ins_user AS (
  INSERT INTO "user"(id, "role", "createdAt")
  VALUES (gen_random_uuid(), 'user', NOW())
  ON CONFLICT DO NOTHING
  RETURNING id
),
upsert_auth AS (
  INSERT INTO auth_telegram(
    user_id, telegram_id, username, first_name, last_name, chat_count, created_at, updated_at
  )
  SELECT
    COALESCE(
      (SELECT id FROM ins_user),
      (SELECT id FROM "user" WHERE id = (
        SELECT user_id FROM auth_telegram WHERE telegram_id = p.telegram_id
      ))
    ),
    p.telegram_id,
    COALESCE(p.username, ''),
    COALESCE(p.first_name, ''),
    COALESCE(p.last_name, ''),
    1, NOW(), NOW()
  FROM p
  ON CONFLICT (telegram_id) DO UPDATE
  SET username = EXCLUDED.username,
      first_name = EXCLUDED.first_name,
      last_name  = EXCLUDED.last_name,
      updated_at = NOW()
  RETURNING user_id
)
SELECT u.id AS user_id, u.gtc_user_id
FROM upsert_auth a
JOIN "user" u ON u.id = a.user_id;
