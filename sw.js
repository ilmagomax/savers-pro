// ============================================
// MAGO MAX S.A.V.E.R.S. PRO v5.0 - SERVICE WORKER
// Con supporto: Offline, Push Notifications, Background Sync
// ============================================

const CACHE_VERSION = 'v5.3';
const CACHE_NAME = `savers-pro-v5-cache-${CACHE_VERSION}`;
const ASSETS_TO_CACHE = [
    './',
    './index.html',
    'https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800&display=swap',
    'https://cdn.jsdelivr.net/npm/chart.js'
];

// Install event - cache assets
self.addEventListener('install', event => {
    console.log('[SW] Installing Service Worker...');
    event.waitUntil(
        caches.open(CACHE_NAME)
            .then(cache => {
                console.log('[SW] Caching app shell...');
                return cache.addAll(ASSETS_TO_CACHE);
            })
            .then(() => self.skipWaiting())
            .catch(err => console.error('[SW] Cache failed:', err))
    );
});

// Activate event - clean old caches
self.addEventListener('activate', event => {
    console.log('[SW] Activating Service Worker...');
    event.waitUntil(
        caches.keys().then(cacheNames => {
            return Promise.all(
                cacheNames
                    .filter(name => name !== CACHE_NAME)
                    .map(name => {
                        console.log('[SW] Deleting old cache:', name);
                        return caches.delete(name);
                    })
            );
        }).then(() => self.clients.claim())
    );
});

// Fetch event - network-first for HTML, cache-first for assets
self.addEventListener('fetch', event => {
    // Skip non-GET requests
    if (event.request.method !== 'GET') return;

    // Skip cross-origin requests except for fonts and CDN
    const url = new URL(event.request.url);
    const isSameOrigin = url.origin === location.origin;
    const isCDN = url.hostname.includes('jsdelivr.net') ||
                  url.hostname.includes('googleapis.com') ||
                  url.hostname.includes('gstatic.com');

    if (!isSameOrigin && !isCDN) return;

    // For HTML pages, use network-first strategy to always get fresh content
    const isHTMLRequest = event.request.mode === 'navigate' ||
                          event.request.destination === 'document' ||
                          url.pathname.endsWith('.html') ||
                          url.pathname === '/' ||
                          url.pathname === '';

    if (isHTMLRequest) {
        // Network-first for HTML
        event.respondWith(
            fetch(event.request)
                .then(networkResponse => {
                    // Cache the fresh response
                    const responseToCache = networkResponse.clone();
                    caches.open(CACHE_NAME).then(cache => {
                        cache.put(event.request, responseToCache);
                    });
                    return networkResponse;
                })
                .catch(() => {
                    // Network failed, try cache
                    return caches.match(event.request)
                        .then(cachedResponse => {
                            return cachedResponse || caches.match('./index.html');
                        });
                })
        );
        return;
    }

    // For other assets, use cache-first strategy
    event.respondWith(
        caches.match(event.request)
            .then(cachedResponse => {
                if (cachedResponse) {
                    // Return cached version
                    return cachedResponse;
                }

                // Fetch from network
                return fetch(event.request)
                    .then(networkResponse => {
                        // Don't cache non-successful responses
                        if (!networkResponse || networkResponse.status !== 200) {
                            return networkResponse;
                        }

                        // Clone and cache
                        const responseToCache = networkResponse.clone();
                        caches.open(CACHE_NAME)
                            .then(cache => {
                                cache.put(event.request, responseToCache);
                            });

                        return networkResponse;
                    })
                    .catch(() => {
                        // Network failed
                        return new Response('Offline', { status: 503 });
                    });
            })
    );
});

// Background sync for offline data
self.addEventListener('sync', event => {
    if (event.tag === 'sync-data') {
        console.log('[SW] Background sync triggered');
        event.waitUntil(syncOfflineData());
    }
});

async function syncOfflineData() {
    // This would sync offline changes when back online
    // Implementation depends on your backend
    console.log('[SW] Syncing offline data...');
}

// Push notifications
self.addEventListener('push', event => {
    const options = {
        body: event.data?.text() || 'Nuova notifica da SAVERS',
        icon: './icon-192.png',
        badge: './icon-192.png',
        vibrate: [100, 50, 100],
        data: {
            dateOfArrival: Date.now(),
            primaryKey: 1
        },
        actions: [
            { action: 'open', title: 'Apri App' },
            { action: 'close', title: 'Chiudi' }
        ]
    };

    event.waitUntil(
        self.registration.showNotification('SAVERS PRO', options)
    );
});

self.addEventListener('notificationclick', event => {
    event.notification.close();

    if (event.action === 'open' || !event.action) {
        event.waitUntil(
            clients.openWindow('./')
        );
    }
});

console.log('[SW] Service Worker loaded');
