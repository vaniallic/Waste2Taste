import { cors } from './_cors.js';

// POST /api/scan   body: { "image": "<base64>", "mime": "image/jpeg" }
// Sends the photo to Gemini and returns the ingredients it sees.
// The API key stays here on the server, never in the app.
const MODEL = 'gemini-2.5-flash';

// Same ids as lib/data/sample_data.dart, so the app can add them straight away.
const KNOWN = [
  'rice', 'egg', 'chicken', 'beef', 'spam', 'tofu', 'tempe', 'tomato', 'veggies',
  'garlic', 'spring_onion', 'noodles', 'bread', 'butter', 'soy_sauce', 'paprika', 'salt',
];

const PROMPT = `You look at a photo of a fridge, a table or groceries and list the food ingredients you can see.
Return JSON only, in this shape:
{"ingredients":[{"id":"egg","name":"Egg","confidence":0.9}]}
Use one of these ids when the item matches: ${KNOWN.join(', ')}.
For anything else, use a short lowercase id with underscores (for example "carrot", "bell_pepper").
"name" is a short English name. Skip things that are not food. If you see no food, return {"ingredients":[]}.`;

export default async function handler(req, res) {
  if (cors(req, res)) return;
  if (req.method !== 'POST') return res.status(405).json({ error: 'Use POST' });

  const key = process.env.GEMINI_API_KEY;
  if (!key) return res.status(500).json({ error: 'GEMINI_API_KEY is not set on the server' });

  const { image, mime = 'image/jpeg' } = req.body || {};
  if (!image || typeof image !== 'string') return res.status(400).json({ error: 'Send { image: base64 }' });
  if (image.length > 4_000_000) return res.status(413).json({ error: 'Image too big, use a smaller photo' });

  try {
    const r = await fetch(`https://generativelanguage.googleapis.com/v1beta/models/${MODEL}:generateContent`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'x-goog-api-key': key },
      body: JSON.stringify({
        contents: [{ parts: [{ text: PROMPT }, { inline_data: { mime_type: mime, data: image } }] }],
        generationConfig: { responseMimeType: 'application/json', temperature: 0.2 },
      }),
    });
    const j = await r.json();
    if (!r.ok) return res.status(502).json({ error: j.error?.message || 'Gemini error' });

    const text = j.candidates?.[0]?.content?.parts?.[0]?.text || '{}';
    const parsed = JSON.parse(text);
    const ingredients = (parsed.ingredients || [])
      .filter((i) => i && i.id && i.name)
      .map((i) => ({ id: String(i.id), name: String(i.name), known: KNOWN.includes(i.id), confidence: Number(i.confidence) || null }));

    res.status(200).json({ ingredients });
  } catch (e) {
    res.status(502).json({ error: 'Could not read the photo' });
  }
}
