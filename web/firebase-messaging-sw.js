importScripts("https://www.gstatic.com/firebasejs/10.7.1/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.7.1/firebase-messaging-compat.js");

// Initialize the Firebase app in the service worker by passing in the
// messagingSenderId, apiKey, projectId, and appId. This is required to 
// receive background messages in the browser.
firebase.initializeApp({
  apiKey: 'AIzaSyC2frZiFLpJLGaZUb5KWD3y0isKHPTyOao',
  appId: '1:869953916567:web:f7a182782eef581c1d23d2',
  messagingSenderId: '869953916567',
  projectId: 'kirana-billing-app',
  authDomain: 'kirana-billing-app.firebaseapp.com',
  storageBucket: 'kirana-billing-app.firebasestorage.app',
});

// Retrieve an instance of Firebase Messaging so that it can handle background
// messages.
const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  console.log(
    '[firebase-messaging-sw.js] Received background message ',
    payload
  );
  // Customize notification here if needed
  const notificationTitle = payload.notification.title;
  const notificationOptions = {
    body: payload.notification.body,
    icon: '/icons/Icon-192.png'
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});
