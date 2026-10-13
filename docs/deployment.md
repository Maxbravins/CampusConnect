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
- Payments left pending are now reconciled automatically (see "Payment reconciliation" below). Still verify it in the sandbox before go-live.
- Review privacy, terms, data export/deletion, admin account provisioning, and secret rotation procedures.
- Confirm the deployment host supports HTTPS callbacks and configure production CORS origins, database network access, and Firebase service credentials.
- Build and verify Android and web release artifacts. iOS support requires Apple signing and push setup and has not been validated by this repository review.

## Payment reconciliation

A background job starts with the server and runs every 2 minutes. It also runs once at startup, because a restart is when callbacks are most likely to have been missed.

- **Pending for 3+ minutes with Daraja identifiers:** the job asks Daraja for the STK push result. Success marks the payment paid and fulfils the request. A definitive failure (cancelled, timed out, insufficient funds) marks it failed and unlocks the request so the student can retry. Any query error is treated as "still processing" and retried on the next run.
- **Pending for 15+ minutes without identifiers** (the initiate call timed out before Daraja answered): the payment is marked failed with result code `UNCONFIRMED` and `needsReview: true`, and the request is unlocked. An admin should check the M-Pesa statement before refunding or retrying. List these with `GET /api/payments?needsReview=true`.
- **Receipt numbers:** Daraja's query does not return the M-Pesa receipt number. If the real callback arrives later it fills the receipt in; otherwise the receipt stays empty and the record's `reconcileNote` explains why.
- **Manual run:** admins can trigger a pass with `POST /api/payments/reconcile`.
- **Retry guard:** when a student retries payment for a request with an old pending attempt, that attempt is reconciled first.

Known gap: a late successful callback for an `UNCONFIRMED` payment is not matched automatically, because the payment never stored a CheckoutRequestID. Those are resolved by an admin from the review list.
