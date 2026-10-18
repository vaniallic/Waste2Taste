import { cors } from './_cors.js';

// GET /api/recipes?ingredients=egg,rice,chicken
// Finds TheMealDB recipes that use the most of your ingredients.
const MEALDB = 'https://www.themealdb.com/api/json/v1/1';

export default async function handler(req, res) {
  if (cors(req, res)) return;

  const ingredients = String(req.query.ingredients || '')
    .split(',')
    .map((s) => s.trim().toLowerCase())
    .filter(Boolean)
    .slice(0, 10);

  if (ingredients.length === 0) {
    return res.status(400).json({ error: 'Add ?ingredients=egg,rice' });
  }

  try {
    // 1. For each ingredient, get the meals that use it.
    const lists = await Promise.all(
      ingredients.map(async (name) => {
        const r = await fetch(`${MEALDB}/filter.php?i=${encodeURIComponent(name.replace(/ /g, '_'))}`);
        const j = await r.json().catch(() => ({}));
        return j.meals || [];
      }),
    );

    // 2. Count how many of your ingredients each meal uses.
    const counts = new Map();
    for (const list of lists) {
      for (const m of list) {
        const c = counts.get(m.idMeal) || { id: m.idMeal, hits: 0 };
        c.hits++;
        counts.set(m.idMeal, c);
      }
    }
    const top = [...counts.values()].sort((a, b) => b.hits - a.hits).slice(0, 8);

    // 3. Get full details for the best ones.
    const meals = await Promise.all(
      top.map(async ({ id, hits }) => {
        const r = await fetch(`${MEALDB}/lookup.php?i=${id}`);
        const m = (await r.json()).meals?.[0];
        return m ? toRecipe(m, hits) : null;
      }),
    );

    res.setHeader('Cache-Control', 's-maxage=86400, stale-while-revalidate');
    res.status(200).json({ recipes: meals.filter(Boolean) });
  } catch (e) {
    res.status(502).json({ error: 'Could not reach TheMealDB' });
  }
}

function toRecipe(m, hits) {
  const ingredients = [];
  for (let i = 1; i <= 20; i++) {
    const name = (m[`strIngredient${i}`] || '').trim();
    if (name) ingredients.push({ name, measure: (m[`strMeasure${i}`] || '').trim() });
  }
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
    matches: hits,
    ingredients,
    steps,
    youtube: m.strYoutube || null,
  };
}
