# Deployment and release checklist

CampusConnect is still a development MVP. The repository does not define a hosting provider, so deployment commands below describe the required configuration without assuming one.

## Backend

1. Use Node.js 22 or newer and install dependencies with `npm ci` from `backend/`.
2. Set `NODE_ENV=production`, `PORT`, `MONGO_URI`, a unique random `JWT_SECRET` (at least 32 characters), `JWT_EXPIRES_IN`, and `CORS_ORIGIN` to the exact browser origins that may call the API. Comma-separate origins when needed. Never reuse the example values.
3. Set Daraja credentials and `MPESA_ENV=production` only after Safaricom has approved the production app. Configure `MPESA_CALLBACK_URL` as a public HTTPS URL. The backend queries Daraja before accepting successful callbacks; verify query behavior in the sandbox before go-live.
4. Configure SMTP values and provide the Firebase Admin service account through a secret-mounted file referenced by `FIREBASE_SERVICE_ACCOUNT_PATH`. Keep the service-account JSON out of Git and out of the frontend.
5. Run `npm test`, then `npm start`. Check `GET /api/health` after deployment.

## Flutter apps

Build each app with the deployed API URL supplied as a compile-time value:

```sh
cd frontend/mobile
flutter pub get
flutter build apk --dart-define=API_BASE_URL=https://api.example.com/api

cd ../admin
flutter pub get
flutter build web --dart-define=API_BASE_URL=https://api.example.com/api
```

For an Android emulator, use `http://10.0.2.2:5000/api`; for a physical device, use a reachable HTTPS development host. Configure Firebase platform options, web VAPID key, Android package identity, iOS push entitlements, and notification permission behavior for the actual release targets.

## Before a public release

- Complete end-to-end sandbox testing for registration, password reset, request lifecycle, Daraja success/failure/callback retry, emails, and push notifications.
- Add database backups, monitoring, error reporting, request rate limiting, and retention policies for student/payment data.
- Reconcile payments left pending after network timeouts before allowing a student to retry; Daraja may have accepted an STK push even when the app did not receive its response.
- Review privacy, terms, data export/deletion, admin account provisioning, and secret rotation procedures.
- Confirm the deployment host supports HTTPS callbacks and configure production CORS origins, database network access, and Firebase service credentials.
- Build and verify Android and web release artifacts. iOS support requires Apple signing and push setup and has not been validated by this repository review.
