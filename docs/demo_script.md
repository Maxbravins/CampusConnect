# CampusConnect — Demo Script

A suggested walkthrough for presenting the project, roughly 10–15 minutes.
Each step says what to do, what to say, and which part of your proposal
it demonstrates.

## Before you start

- [ ] Backend running (`npm run dev` in `backend/`) — confirm with
      `http://localhost:5000/api/health`
- [ ] Mobile app running in Chrome (`flutter run -d chrome` in `frontend/mobile`)
- [ ] Admin app running in a **separate** Chrome window (`flutter run -d chrome`
      in `frontend/admin`) — side by side with the mobile window if possible,
      so status changes are visible on both screens at once
- [ ] You have one admin account and remember its password
- [ ] Decide whether you're demoing M-Pesa live (needs ngrok running and
      fresh Daraja credentials) or skipping it and just describing the flow
- [ ] Optional: have a couple of test student accounts already registered
      so the admin's student list and reports don't look empty

---

## 1. Introduce the problem (30 seconds)

**Say:** "Students at most institutions still queue at physical offices for
things like ID replacement or transcripts — separate steps for requesting,
paying, and tracking status. CampusConnect brings all of that into one
mobile app, with a companion admin panel for staff."

## 2. Show the architecture (30 seconds)

**Say:** "It's three parts: a Flutter mobile app for students, a Flutter
Web admin panel — so both share the same language — and a Node.js/Express
backend with MongoDB, talking to Safaricom's M-Pesa API and an email
service."

*(Optionally show the folder structure or the proposal's architecture diagram here.)*

## 3. Student: register and log in

**Do:** In the mobile app, register a new account (or log in with an
existing one).

**Say:** "Registration is secured with hashed passwords and issues a JWT
token. It also triggers a welcome email automatically." *(Optionally
switch to your email inbox to show it arriving.)*

**Demonstrates:** secure registration/login, email notifications.

## 4. Admin: add a service (if not already present)

**Do:** Switch to the admin window → Manage Services → Add Service (e.g.
"Transcript Request", a fee, and processing days).

**Say:** "Administrators control what services exist and what they cost —
this is fully dynamic, nothing is hardcoded."

**Demonstrates:** service management.

## 5. Student: browse and request a service

**Do:** Switch back to the mobile window, refresh Campus Services — the
new service should appear. Tap it, confirm, and submit a request.

**Say:** "The student sees exactly what the admin just created — this is
a shared MongoDB database, not two separate systems. The request gets a
unique reference number automatically."

**Demonstrates:** service browsing, request submission, reference number
generation.

## 6. Student: track the request

**Do:** Go to My Requests — show the new request with a "Payment Required"
status chip.

**Say:** "Students can track every request they've made and its current
stage — Pending, Payment Required, Paid, Processing, Completed."

## 7. Payment — live or described

**If demoing live:**
**Do:** Tap "Pay Now", leave the sandbox test number as-is, submit, and
watch the backend terminal for the STK push and callback.
**Say:** "This goes through Safaricom's Daraja sandbox — a real STK push
flow, safely testable without moving real money."

**If skipping live payment:**
**Say:** "Payment is handled through Safaricom's Daraja API with STK
Push — I've tested this end-to-end in the sandbox environment; I'm not
triggering it live today to keep the demo focused."

**Demonstrates:** M-Pesa integration.

## 8. Admin: manage the request

**Do:** Switch to admin → Manage Requests. Show the same request. Tap its
status chip and change it (e.g. to "Processing" or "Completed").

**Say:** "Admins can filter by status and move requests through their
lifecycle. Any change here — "

**Do:** Switch to mobile → My Requests → refresh.

**Say:** " — is immediately visible to the student, and also generates
an in-app notification and an email."

**Demonstrates:** request management, real-time status sync, notifications.

## 9. Student: notifications and profile

**Do:** Show the Notifications screen (the update from step 8 should be
there). Then show Profile — edit the phone number and save.

**Demonstrates:** notifications, profile management.

## 10. Admin: student management

**Do:** Manage Students → search for a student by name → show the
active/inactive toggle.

**Say:** "Admins can search the student base and deactivate an account if
needed — for example, if someone withdraws."

**Demonstrates:** role-based access control, student management.

## 11. Admin: reports

**Do:** Reports & Stats — walk through the numbers (total students,
requests by status, successful payments, recent activity lists).

**Say:** "This gives administrators visibility into overall system usage
without digging through the database directly."

**Demonstrates:** reporting.

## 12. Wrap-up (30 seconds)

**Say:** "That covers the core proposal: secure auth, service requests,
M-Pesa payments, email and in-app notifications, and admin tools for
services, requests, students, and reporting — all built on Flutter, Node,
Express, and MongoDB."

---

## Anticipated questions

- **"Why Flutter Web for admin instead of React?"** — Keeps the whole
  project in one language (Dart), reducing the tech stack's complexity
  for a project this size.
- **"Is this production-ready?"** — It's fully functional against
  Safaricom's sandbox; going live would need production Daraja
  credentials, a verified email-sending domain, and deployment to a real
  server instead of localhost/ngrok.
- **"What would you build next?"** — Payment history screen (the backend
  endpoint already exists), push notifications, and iOS support.
