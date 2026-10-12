importScripts("https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js");

firebase.initializeApp({
  apiKey: 'AIzaSyDumSx7JvbHhzmXJxlS0peTVgGJ2jMoJyE',
  authDomain: "campusconnect-ffa2e.firebaseapp.com",
  projectId: "campusconnect-ffa2e",
  storageBucket: "campusconnect-ffa2e.firebasestorage.app",
  messagingSenderId: "422014240922",
  appId: "1:422014240922:web:f9e7616455283c6e957723",
});

const messaging = firebase.messaging();