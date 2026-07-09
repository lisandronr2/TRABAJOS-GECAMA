// ============================================================
//  GECAMA PWA - Service Worker
//  Estrategia: Cache-first para shell, Network-first para datos
// ============================================================
const CACHE_NAME   = 'gecama-v1';
const DATA_CACHE   = 'gecama-data-v1';
const SHELL_ASSETS = ['./index.html', './manifest.json', './icon.svg'];

// ── Instalación: pre-cachear shell ──────────────────────────
self.addEventListener('install', e => {
  e.waitUntil(
    caches.open(CACHE_NAME)
      .then(c => c.addAll(SHELL_ASSETS))
      .then(() => self.skipWaiting())
  );
});

// ── Activación: limpiar cachés viejos ───────────────────────
self.addEventListener('activate', e => {
  e.waitUntil(
    caches.keys().then(keys =>
      Promise.all(keys
        .filter(k => k !== CACHE_NAME && k !== DATA_CACHE)
        .map(k => caches.delete(k))
      )
    ).then(() => self.clients.claim())
  );
});

// ── Fetch: shell desde cache, Drive API desde red ───────────
self.addEventListener('fetch', e => {
  const url = e.request.url;

  // Peticiones a Google Drive API → Network-first, cache fallback
  if (url.includes('googleapis.com') || url.includes('drive.google')) {
    e.respondWith(
      caches.open(DATA_CACHE).then(async cache => {
        try {
          const netRes = await fetch(e.request.clone(), { credentials: 'include' });
          if (netRes.ok) {
            cache.put(e.request, netRes.clone());
          }
          return netRes;
        } catch {
          const cached = await cache.match(e.request);
          return cached || new Response(
            JSON.stringify({ error: 'Sin conexión y sin caché disponible' }),
            { headers: { 'Content-Type': 'application/json' } }
          );
        }
      })
    );
    return;
  }

  // Shell assets → Cache-first
  e.respondWith(
    caches.match(e.request).then(cached => cached || fetch(e.request))
  );
});

// ── Mensaje de actualización desde la app ───────────────────
self.addEventListener('message', e => {
  if (e.data === 'SKIP_WAITING') self.skipWaiting();
});
