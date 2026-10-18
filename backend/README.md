# Waste2Taste API

Small serverless backend on Vercel for the Waste2Taste app.

| Endpoint | What it does |
|---|---|
| `GET /api/recipes?ingredients=egg,rice` | Recipes from TheMealDB that use your ingredients |
| `GET /api/ingredients?q=chick&limit=1000` | Search 500+ ingredients (with photos) from TheMealDB. No `q` = A-Z list |
| `POST /api/scan` | Photo → list of ingredients (Gemini) |

Set `GEMINI_API_KEY` in Vercel → Project Settings → Environment Variables.
