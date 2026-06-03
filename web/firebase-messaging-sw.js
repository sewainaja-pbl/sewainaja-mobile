// Import the Firebase SDK scripts
importScripts("https://www.gstatic.com/firebasejs/9.22.1/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/9.22.1/firebase-messaging-compat.js");

// Initialize Firebase
firebase.initializeApp({
  apiKey: "AIzaSyCJCr3VkZBlqFTbBF0EfnLheSO5hhP5jdw",
  appId: "1:1073702990942:web:395205356a1af0fe55f0cf",
  messagingSenderId: "1073702990942",
  projectId: "sewainaja-b4834",
  authDomain: "sewainaja-b4834.firebaseapp.com",
  databaseURL: "https://sewainaja-b4834-default-rtdb.firebaseio.com",
  storageBucket: "sewainaja-b4834.firebasestorage.app",
});

const messaging = firebase.messaging();

// Handle background messages
messaging.onBackgroundMessage((payload) => {
  console.log('Received background message ', payload);
  const notificationTitle = payload.notification.title || 'Notifikasi baru';
  const notificationOptions = {
    body: payload.notification.body || '',
    icon: '/icons/Icon-192.png'
  };
  return self.registration.showNotification(notificationTitle, notificationOptions);
});
