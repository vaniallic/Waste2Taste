import { cors } from './_cors.js';

// GET /api/ingredients?q=chick
// Searches the ingredient list of TheMealDB (500+ items, each with a photo).
// Without ?q it returns the first ones in A-Z order. ?limit=1000 returns everything (default 60).
const MEALDB = 'https://www.themealdb.com/api/json/v1/1';

// The full list barely changes, so keep it in memory between requests.
let cache = null;
let cachedAt = 0;
const DAY = 24 * 60 * 60 * 1000;

async function loadAll() {
  if (cache && Date.now() - cachedAt < DAY) return cache;
  const r = await fetch(`${MEALDB}/list.php?i=list`);
  const j = await r.json();
  cache = (j.meals || []).map(toIngredient).sort((a, b) => a.name.localeCompare(b.name));
  cachedAt = Date.now();
  return cache;
}

export default async function handler(req, res) {
  if (cors(req, res)) return;

  const q = String(req.query.q || '').trim().toLowerCase();
  const limit = Math.min(Math.max(parseInt(req.query.limit, 10) || 60, 1), 1000);

  try {
    let list = await loadAll();
    if (q) {
      // Names that start with the search come first, then names that only contain it.
      const starts = list.filter((i) => i.name.toLowerCase().startsWith(q));
      const has = list.filter((i) => !i.name.toLowerCase().startsWith(q) && i.name.toLowerCase().includes(q));
      list = [...starts, ...has];
    }
    res.setHeader('Cache-Control', 's-maxage=86400, stale-while-revalidate');
    res.status(200).json({ ingredients: list.slice(0, limit) });
  } catch (e) {
    res.status(502).json({ error: 'Could not reach TheMealDB' });
  }
}

// Same shape the app uses for its own ingredients (see lib/data/models.dart).
export function toIngredient(m) {
  const name = String(m.strIngredient || '').trim();
  const { category, shelfDays } = guess(name.toLowerCase());
  return {
    id: name.toLowerCase().replace(/[^a-z0-9]+/g, '_').replace(/^_|_$/g, ''),
    name,
    image: m.strThumb || `https://www.themealdb.com/images/ingredients/${encodeURIComponent(name)}.png`,
    category,
    shelfDays,
  };
}

// TheMealDB has no categories (strType is almost always empty), so guess one from the name.
// shelfDays >= 180 means "pantry" in the app: it never runs out when you cook.
// Whole-word match (plural allowed), so "ham" doesn't hit "champagne" or "pea" "peanut".
const has = (name, words) => words.some((w) => new RegExp(`\\b${w}(e?s)?\\b`).test(name));

export function guess(name) {
  if (has(name, ['egg'])) return { category: 'Protein', shelfDays: 21 };
  if (has(name, ['bacon', 'ham', 'sausage', 'chorizo', 'salami', 'pancetta'])) return { category: 'Protein', shelfDays: 7 };
  if (has(name, ['tofu', 'tempeh'])) return { category: 'Protein', shelfDays: 4 };
  if (has(name, ['chicken', 'beef', 'pork', 'lamb', 'mutton', 'turkey', 'duck', 'veal', 'venison', 'goat', 'mince', 'steak', 'liver',
    'fish', 'salmon', 'tuna', 'cod', 'haddock', 'mackerel', 'sardine', 'prawn', 'shrimp', 'squid', 'mussel', 'oyster', 'crab', 'lobster', 'scallop', 'clam', 'anchovy', 'anchovies'])
    && !has(name, ['stock', 'sauce', 'oil', 'seasoning', 'powder'])) return { category: 'Protein', shelfDays: 3 };
  if (has(name, ['butter', 'cheese', 'parmesan', 'cheddar', 'mozzarella', 'feta', 'ghee']) && !has(name, ['peanut', 'butternut', 'buttermilk'])) return { category: 'Dairy', shelfDays: 30 };
  if (has(name, ['milk', 'cream', 'yogurt', 'yoghurt', 'custard']) && !has(name, ['coconut', 'almond', 'powder'])) return { category: 'Dairy', shelfDays: 7 };
  if (has(name, ['sauce', 'ketchup', 'mayonnaise', 'mustard', 'vinegar', 'paste', 'stock', 'broth', 'honey', 'syrup', 'jam', 'chutney', 'dressing'])) return { category: 'Sauces', shelfDays: 365 };
  if (has(name, ['bread', 'baguette', 'bun', 'roll', 'bagel', 'pita', 'tortilla', 'naan'])) return { category: 'Carbs', shelfDays: 5 };
  if (has(name, ['rice', 'noodle', 'pasta', 'spaghetti', 'macaroni', 'penne', 'fettuccine', 'lasagne', 'couscous', 'bulgur', 'oat', 'vermicelli'])) return { category: 'Carbs', shelfDays: 180 };
  if (has(name, ['garlic', 'ginger', 'onion', 'shallot', 'potato', 'sweet potato', 'carrot', 'pumpkin', 'squash'])) return { category: 'Veggies', shelfDays: 30 };
  if (has(name, ['tomato', 'pepper', 'chilli', 'chili', 'cabbage', 'lettuce', 'spinach', 'broccoli', 'cauliflower', 'cucumber', 'mushroom', 'celery', 'leek',
    'courgette', 'zucchini', 'aubergine', 'eggplant', 'kale', 'pea', 'corn', 'beetroot', 'radish', 'asparagus', 'avocado', 'lemon', 'lime', 'orange',
    'apple', 'banana', 'mango', 'pineapple', 'berry', 'berries', 'grape', 'coriander', 'parsley', 'basil', 'mint', 'dill', 'spring onion', 'green bean', 'bean sprout'])
    && !has(name, ['powder', 'dried', 'ground', 'flakes', 'peppercorn', 'black pepper', 'cayenne'])) return { category: 'Veggies', shelfDays: 5 };
  return { category: 'Pantry', shelfDays: 365 };
}
