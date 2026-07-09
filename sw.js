// ============================================================
//  GECAMA PWA — Service Worker v4
//  Auto-actualización: cada deploy a Netlify llega solo a la app
// ============================================================
const SHELL_VER  = 'gecama-shell-v4';
const DATA_VER   = 'gecama-data-v4';

// Archivos del shell que se cachean
const SHELL_ASSETS = [
  './manifest.json',
  './icon.svg',
  './icon-192.png',
  './icon-512.png'
  // index.html NO se cachea → siempre se intenta red primero
];

// ── Instalación ───────────────────────────────────────────────
self.addEventListener('install', e => {
  e.waitUntil(
    caches.open(SHELL_VER)
      .then(c => c.addAll(SHELL_ASSETS))
      .then(() => self.skipWaiting())  // activa inmediatamente sin esperar
  );
});

// ── Activación: borra cachés viejos ──────────────────────────
self.addEventListener('activate', e => {
  e.waitUntil(
    caches.keys()
      .then(keys => Promise.all(
        keys
          .filter(k => k !== SHELL_VER && k !== DATA_VER)
          .map(k => {
            console.log('[SW] Borrando caché obsoleta:', k);
            return caches.delete(k);
          })
      ))
      .then(() => self.clients.claim())
  );
});

// ── Estrategia de fetch ───────────────────────────────────────
self.addEventListener('fetch', e => {
  const { url } = e.request;

  // Google Drive / Sheets → Red primero, caché de respaldo
  if (url.includes('googleapis.com') || url.includes('drive.google') || url.includes('docs.google')) {
    e.respondWith(networkFirst(e.request, DATA_VER));
    return;
  }

  // CDN de XLSX.js → Caché primero (es estático)
  if (url.includes('cdnjs.cloudflare.com')) {
    e.respondWith(cacheFirst(e.request, DATA_VER));
    return;
  }

  // index.html y version.json → Red primero (para detectar actualizaciones)
  if (url.endsWith('/') || url.includes('index.html') || url.includes('version.json')) {
    e.respondWith(networkFirst(e.request, SHELL_VER));
    return;
  }

  // Resto del shell → Caché primero, actualización silenciosa
  e.respondWith(staleWhileRevalidate(e.request, SHELL_VER));
});

// ── Red primero con caché de respaldo ─────────────────────────
async function networkFirst(req, cacheName) {
  const cache = await caches.open(cacheName);
  try {
    const res = await fetch(req.clone(), { cache: 'no-cache' });
    if (res.ok) cache.put(req, res.clone());
    return res;
  } catch {
    const cached = await cache.match(req);
    return cached || new Response('', { status: 503 });
  }
}

// ── Caché primero ─────────────────────────────────────────────
async function cacheFirst(req, cacheName) {
  const cached = await caches.match(req);
  if (cached) return cached;
  const cache = await caches.open(cacheName);
  const res   = await fetch(req);
  if (res.ok) cache.put(req, res.clone());
  return res;
}

// ── Stale-while-revalidate ────────────────────────────────────
async function staleWhileRevalidate(req, cacheName) {
  const cache  = await caches.open(cacheName);
  const cached = await cache.match(req);
  const netProm = fetch(req).then(res => {
    if (res.ok) cache.put(req, res.clone());
    return res;
  }).catch(() => null);
  return cached || netProm;
}

// ── Background Sync ───────────────────────────────────────────
self.addEventListener('sync', e => {
  if (e.tag === 'sync-gecama') {
    e.waitUntil(broadcastSync());
  }
});

async function broadcastSync() {
  const clients = await self.clients.matchAll({ type: 'window', includeUncontrolled: true });
  clients.forEach(c => c.postMessage({ type: 'SW_SYNC' }));
}

// ── Mensajes desde la app ─────────────────────────────────────
self.addEventListener('message', e => {
  if (e.data === 'SKIP_WAITING') self.skipWaiting();
});

// ── Push notifications ────────────────────────────────────────
self.addEventListener('push', e => {
  if (!e.data) return;
  let data = {};
  try { data = e.data.json(); } catch { data = { body: e.data.text() }; }
  e.waitUntil(
    self.registration.showNotification(data.title || 'GECAMA', {
      body:  data.body  || 'Nuevos datos disponibles',
      icon:  './icon-192.png',
      badge: './icon-192.png',
      data:  { url: './index.html' }
    })
  );
});

self.addEventListener('notificationclick', e => {
  e.notification.close();
  e.waitUntil(clients.openWindow(e.notification.data?.url || './index.html'));
});
