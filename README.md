# CampusConnect

A mobile campus services and payment management system. Students browse
campus services, submit requests, pay via M-Pesa, track status, and get
notified of updates — all from a Flutter app. Administrators manage
services, requests, students, and see reporting stats from a companion
Flutter Web admin panel.

## Tech Stack

| Layer            | Technology                                      |
|-------------------|--------------------------------------------------|
| Mobile app         | Flutter & Dart                                    |
| Admin panel        | Flutter Web                                       |
| Backend            | Node.js + Express.js                              |
| Database           | MongoDB (MongoDB Atlas)                           |
| Auth               | JWT + bcrypt                                      |
| Payments           | Safaricom Daraja API (M-Pesa STK Push, sandbox)   |
| Email              | Brevo (SMTP relay via Nodemailer)                 |

## Project Structure

```
campusconnect/
├── backend/                 Node.js + Express REST API
│   ├── server.js
│   └── src/
│       ├── config/           MongoDB connection
│       ├── models/           Mongoose schemas
│       ├── controllers/      Route handlers
│       ├── routes/           Express routers
│       ├── middleware/       Auth (JWT) + error handling
│       └── services/         Email (Brevo) and M-Pesa (Daraja) integrations
├── frontend/
│   ├── mobile/               Flutter app (students)
│   └── admin/                Flutter Web app (administrators)
└── docs/                     Project proposal and other documentation
```

## Features

### Student (mobile app)
- Register, log in, log out (session persists across app restarts/refreshes)
- Browse active campus services
- Submit a service request and receive a unique reference number
- Track request status: Pending → Payment Required → Paid → Processing → Completed
- Pay for a request via M-Pesa STK Push (Daraja sandbox)
- View notifications for request and payment updates
- View and edit profile (name, phone)

### Administrator (Flutter Web panel)
- Log in (role-restricted — student accounts are rejected)
- Manage services: add, deactivate, reactivate
- Manage requests: view, filter by status, update status
- Manage students: search, activate/deactivate accounts
- View reports: total students, total/pending/completed requests,
  successful payments, recent requests and transactions

### Backend
- JWT authentication with role-based access control (student vs admin)
- Email notifications (registration, payment received, request status
  changes, request completed) via Brevo's SMTP relay
- In-app notifications created automatically on request status changes
  and successful payments
- M-Pesa STK Push initiation and callback handling

## Setup

### 1. Backend

```bash
cd backend
npm install
cp .env.example .env
```

Fill in `.env` with real values (see table below), then:

```bash
npm run dev
```

The API runs at `http://localhost:5000`. Confirm it's up:

```bash
curl http://localhost:5000/api/health
# -> {"status":"ok"}
```

#### Environment variables

| Variable | Description |
|---|---|
| `PORT` | Port the API runs on (default 5000) |
| `MONGO_URI` | MongoDB connection string (Atlas or local) |
| `JWT_SECRET` | Any long random string, used to sign auth tokens |
| `JWT_EXPIRES_IN` | Token lifetime, e.g. `7d` |
| `MPESA_CONSUMER_KEY` / `MPESA_CONSUMER_SECRET` | From a Daraja app with the "Lipa Na M-Pesa Online" / "M-PESA Express Sandbox" product enabled |
| `MPESA_SHORTCODE` / `MPESA_PASSKEY` | Sandbox test credentials from the Daraja "Test Credentials" page |
| `MPESA_CALLBACK_URL` | A public HTTPS URL (via ngrok in development) pointing to `/api/payments/callback` |
| `MPESA_ENV` | `sandbox` or `production` |
| `SMTP_HOST` | `smtp-relay.brevo.com` |
| `SMTP_PORT` | `587` |
| `SMTP_USER` / `SMTP_PASS` | From Brevo's SMTP & API settings page |
| `SMTP_FROM` | e.g. `"CampusConnect <you@example.com>"` — must match the email you signed up to Brevo with |

### 2. Mobile app (students)

Requires the Flutter SDK installed locally.

```bash
cd frontend/mobile
flutter pub get
```

Open `lib/config/api_config.dart` and set the correct base URL for your
testing target:
- Chrome / desktop: `http://localhost:5000/api`
- Android emulator: `http://10.0.2.2:5000/api`
- Physical device on the same network: `http://<your-PC-LAN-IP>:5000/api`

Run it:

```bash
flutter run -d chrome
```

### 3. Admin panel

```bash
cd frontend/admin
flutter pub get
flutter run -d chrome
```

`lib/config/api_config.dart` here is already set to `http://localhost:5000/api`
since the admin panel only runs in a browser.

#### Creating your first admin account

There's no self-service way to become an admin (by design). To create one:
1. Register a normal account through the mobile app.
2. In MongoDB Atlas, open the `campusconnect` database → `users` collection.
3. Find that user's document and change `role` from `"student"` to `"admin"`.
4. Log in with that account in the admin panel.

## Testing M-Pesa (sandbox)

- **Only use the designated sandbox test number, `254708374149`**, when
  testing payments. Using a real phone number can trigger a real STK
  prompt against that number's actual M-Pesa balance, even against
  sandbox credentials — the receiving side is fake, but the sending
  side is real.
- ngrok's free tier generates a new URL every restart — update
  `MPESA_CALLBACK_URL` in `.env` and restart the backend whenever you
  restart ngrok.
- A successful sandbox payment updates the request to `Paid`, creates a
  `Payment` record, sends a confirmation email, and creates an in-app
  notification.

## Known Limitations / Not Yet Built

- Payment history screen (student-facing list of past payments) —
  backend endpoint (`GET /api/payments/mine`) already exists
- Announcements feature
- Push notifications (current notifications are in-app/email only)
- iOS and production deployment (currently Android + Web only)

## Documentation

See `docs/CampusConnect_Proposal.docx` for the original project proposal,
including objectives, scope, methodology, and timeline.
