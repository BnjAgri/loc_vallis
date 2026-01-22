/* Minimal PWA service worker (cache-first for same-origin GET). */

const CACHE_NAME = "loc-vallis-v2";
const PRECACHE_URLS = [
  "/",
  "/manifest.json",
  "/icons/icon-192.png",
  "/icons/icon-512.png",
  "/icons/maskable-192.png",
  "/icons/maskable-512.png"
];

self.addEventListener("install", (event) => {
  event.waitUntil(
    caches
      .open(CACHE_NAME)
      .then((cache) => cache.addAll(PRECACHE_URLS))
      .then(() => self.skipWaiting())
  );
});

self.addEventListener("activate", (event) => {
  event.waitUntil(
    (async () => {
      const cacheNames = await caches.keys();
      await Promise.all(
        cacheNames
          .filter((name) => name !== CACHE_NAME)
          .map((name) => caches.delete(name))
      );
      await self.clients.claim();
    })()
  );
});

self.addEventListener("fetch", (event) => {
  const request = event.request;
  if (request.method !== "GET") return;

  const url = new URL(request.url);
  if (url.origin !== self.location.origin) return;

  // For navigation, try network first, fall back to cached "/".
  if (request.mode === "navigate") {
    event.respondWith(
      (async () => {
        try {
          const networkResponse = await fetch(request);
          const cache = await caches.open(CACHE_NAME);
          cache.put(request, networkResponse.clone());
          return networkResponse;
        } catch {
          const cached = await caches.match(request);
          return cached || caches.match("/");
        }
      })()
    );
    return;
  }

  // Cache-first for other same-origin GET requests.
  event.respondWith(
    (async () => {
      // Avoid stale JS/CSS during development and after deployments.
      const isScriptOrStyle = request.destination === "script" || request.destination === "style";
      if (isScriptOrStyle) {
        try {
          const networkResponse = await fetch(request);
          const cache = await caches.open(CACHE_NAME);
          cache.put(request, networkResponse.clone());
          return networkResponse;
        } catch {
          return (await caches.match(request)) || Response.error();
        }
      }

      const cachedResponse = await caches.match(request);
      if (cachedResponse) return cachedResponse;

      const networkResponse = await fetch(request);
      const cache = await caches.open(CACHE_NAME);
      cache.put(request, networkResponse.clone());
      return networkResponse;
    })()
  );
});
