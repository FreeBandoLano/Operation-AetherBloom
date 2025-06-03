// Firebase Cloud Messaging Service Worker
// This file is required for FCM to work on web platforms

// Import Firebase scripts
importScripts('https://www.gstatic.com/firebasejs/10.5.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.5.0/firebase-messaging-compat.js');

// Initialize Firebase app in the service worker
firebase.initializeApp({
  apiKey: 'AIzaSyA4tAeEA9jx-Ssz2fhHF8iXLpfoHQW3Lqs',
  authDomain: 'aetherbloomapp.firebaseapp.com',
  projectId: 'aetherbloomapp',
  storageBucket: 'aetherbloomapp.firebasestorage.app',
  messagingSenderId: '393508175029',
  appId: '1:393508175029:web:7222352e96f1f6d47dd2fc',
  measurementId: 'G-11B84CLV9F',
});

// Retrieve Firebase Messaging object
const messaging = firebase.messaging();

// Handle background messages
messaging.onBackgroundMessage((payload) => {
  console.log('📱 Background message received in service worker:', payload);
  
  const notificationTitle = payload.notification?.title || 'AetherBloom Notification';
  const notificationOptions = {
    body: payload.notification?.body || 'You have a new notification',
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
    tag: 'aetherbloom-notification',
    requireInteraction: true,
    data: payload.data,
    actions: [
      {
        action: 'open',
        title: 'Open App',
        icon: '/icons/Icon-192.png'
      },
      {
        action: 'dismiss',
        title: 'Dismiss'
      }
    ]
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});

// Handle notification clicks
self.addEventListener('notificationclick', (event) => {
  console.log('📱 Notification click received:', event);
  
  event.notification.close();
  
  if (event.action === 'open' || !event.action) {
    // Open the app when notification is clicked
    event.waitUntil(
      clients.matchAll({ type: 'window', includeUncontrolled: true }).then((clientList) => {
        for (const client of clientList) {
          if (client.url.includes(self.location.origin) && 'focus' in client) {
            return client.focus();
          }
        }
        if (clients.openWindow) {
          return clients.openWindow('/');
        }
      })
    );
  }
});

// Service worker activation
self.addEventListener('activate', (event) => {
  console.log('📱 FCM Service Worker activated');
});

// Service worker installation
self.addEventListener('install', (event) => {
  console.log('📱 FCM Service Worker installed');
  self.skipWaiting();
}); 