// Very small rate limiter: max N requests per IP in a time window.
// It lives in the function's memory, so it is best-effort (each Vercel instance
// counts on its own), but it stops casual spam from burning the Gemini quota.
const hits = new Map();

export function tooMany(req, res, { name, max, windowMs }) {
  const ip = String(req.headers?.['x-forwarded-for'] || req.socket?.remoteAddress || 'unknown').split(',')[0].trim();
  const key = `${name}:${ip}`;
  const now = Date.now();
  const recent = (hits.get(key) || []).filter((t) => now - t < windowMs);

  if (recent.length >= max) {
    res.setHeader('Retry-After', Math.ceil((windowMs - (now - recent[0])) / 1000));
    res.status(429).json({ error: 'Too many requests, try again in a few minutes' });
    return true;
  }

  recent.push(now);
  hits.set(key, recent);

  // Forget old IPs now and then so the map doesn't grow forever.
  if (hits.size > 5000) {
    for (const [k, v] of hits) if (!v.some((t) => now - t < windowMs)) hits.delete(k);
  }
  return false;
}
