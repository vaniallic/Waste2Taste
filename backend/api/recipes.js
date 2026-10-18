import { cors } from './_cors.js';
import { tooMany } from './_limit.js';

// GET /api/recipes?ingredients=egg,rice,chicken
// Finds TheMealDB recipes that use the most of your ingredients.
const MEALDB = 'https://www.themealdb.com/api/json/v1/1';

export default async function handler(req, res) {
  if (cors(req, res)) return;
  // One search = ~30 calls to TheMealDB, so keep it polite: 40 per IP every 10 minutes.
  if (tooMany(req, res, { name: 'recipes', max: 40, windowMs: 10 * 60 * 1000 })) return;

  const ingredients = String(req.query.ingredients || '')
    .split(',')
    .map((s) => s.trim().toLowerCase())
    .filter(Boolean)
    .slice(0, 10);

  if (ingredients.length === 0) {
    return res.status(400).json({ error: 'Add ?ingredients=egg,rice' });
  }

  try {
    // 1. For each ingredient, get the meals that use it (also try the plural: egg → eggs).
    const lists = await Promise.all(
      ingredients.map(async (name) => {
        const q = name.replace(/ /g, '_');
        const variants = [q, q.endsWith('s') ? q.slice(0, -1) : `${q}s`];
        const found = await Promise.all(
          variants.map(async (v) => {
            const r = await fetch(`${MEALDB}/filter.php?i=${encodeURIComponent(v)}`);
            const j = await r.json().catch(() => ({}));
            return j.meals || [];
          }),
        );
        return found.flat();
      }),
    );

    // 2. Count how many of your ingredients each meal uses.
    const counts = new Map();
    lists.forEach((list) => {
      const seen = new Set();
      for (const m of list) {
        if (seen.has(m.idMeal)) continue;
        seen.add(m.idMeal);
        counts.set(m.idMeal, (counts.get(m.idMeal) || 0) + 1);
      }
    });
    const candidates = [...counts.entries()].sort((a, b) => b[1] - a[1]).slice(0, 16);

    // 3. Get details, then rank: most of your ingredients used, fewest extra ingredients needed.
    const meals = (
      await Promise.all(
        candidates.map(async ([id]) => {
          const r = await fetch(`${MEALDB}/lookup.php?i=${id}`);
          const m = (await r.json()).meals?.[0];
          return m ? toRecipe(m, ingredients) : null;
        }),
      )
    ).filter(Boolean);

    meals.sort((a, b) => b.matches - a.matches || a.missing - b.missing);

    res.setHeader('Cache-Control', 's-maxage=86400, stale-while-revalidate');
    res.status(200).json({ recipes: meals.slice(0, 10) });
  } catch (e) {
    res.status(502).json({ error: 'Could not reach TheMealDB' });
  }
}

function toRecipe(m, mine) {
  const ingredients = [];
  for (let i = 1; i <= 20; i++) {
    const name = (m[`strIngredient${i}`] || '').trim();
    if (name) ingredients.push({ name, measure: (m[`strMeasure${i}`] || '').trim() });
  }
  const has = (name) => mine.some((x) => name.toLowerCase().includes(x.replace(/_/g, ' ')));
  const matches = ingredients.filter((i) => has(i.name)).length;

  const steps = (m.strInstructions || '')
    .split(/\r?\n+/)
    .map((s) => s.replace(/^(step\s*)?\d+[.):]?\s*/i, '').trim())
    .filter((s) => s.length > 3);

  return {
    id: m.idMeal,
    name: m.strMeal,
    image: m.strMealThumb,
    category: m.strCategory,
    area: m.strArea,
    matches,
    missing: ingredients.length - matches,
    ingredients: ingredients.map((i) => ({ ...i, have: has(i.name) })),
    steps,
    youtube: m.strYoutube || null,
  };
}
