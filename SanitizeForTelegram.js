// MarkdownV2-safe + split >4096 for Telegram
// Place this code into an n8n Code node named "SanitizeForTelegram"
// Input: any item with fields output/text/message
// Output: one or many items with field tg_text (escaped for MarkdownV2)

function escapeMdV2(s) {
  let t = String(s ?? '');

  // Order matters: escape backslash first
  t = t.replace(/\\/g, '\\\\');
  t = t.replace(/_/g, '\\_');
  t = t.replace(/\*/g, '\\*');
  t = t.replace(/\[/g, '\\[');
  t = t.replace(/\]/g, '\\]');
  t = t.replace(/\(/g, '\\(');
  t = t.replace(/\)/g, '\\)');
  t = t.replace(/~/g, '\\~');
  t = t.replace(/`/g, '\\`');
  t = t.replace(/>/g, '\\>');
  t = t.replace(/#/g, '\\#');
  t = t.replace(/\+/g, '\\+');
  t = t.replace(/-/g, '\\-');
  t = t.replace(/=/g, '\\=');
  t = t.replace(/\|/g, '\\|');
  t = t.replace(/{/g, '\\{');
  t = t.replace(/}/g, '\\}');
  t = t.replace(/\./g, '\\.');
  t = t.replace(/!/g, '\\!');

  return t;
}

function chunk(text, max = 3500) { // safe margin under Telegram 4096 limit
  const out = [];
  for (let i = 0; i < text.length; i += max) out.push(text.slice(i, i + max));
  return out;
}

const raw = $json.output ?? $json.text ?? $json.message ?? '';
const escaped = escapeMdV2(raw);
const parts = chunk(escaped);

// Return 1..N parts so Telegram node will send them sequentially
return parts.map(p => ({ json: { tg_text: p, ...$json } }));
