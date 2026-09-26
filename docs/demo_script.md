## CampusConnect — Demo Script

A suggested walkthrough for presenting the project, roughly 10–15 minutes.

Each step explains what to do, what to say, and what part of the project it demonstrates.

Before you start

Backend running in backend/

Confirm API is working with:
http://localhost:5000/api/health

Student app running in Chrome

Admin app running in a separate Chrome window

Have one admin account ready

Have at least one registered student account ready

Have several campus services available

Have at least one announcement available

For live M-Pesa demonstration, use the designated Daraja sandbox test number only

Make sure your internet connection is working for email/API demonstrations

## Introduce the problem — 30 seconds

Say:

"Students often have to visit different offices to request services such as transcripts, certificates, ID replacement, accommodation or clearance. This creates separate processes for requesting, paying and tracking services.

CampusConnect brings these services together in one mobile application for students, with a companion web-based administration panel for staff."

Demonstrates:

The problem and motivation behind the project.

## Show the system architecture — 30 seconds

Say:

"CampusConnect has three main components. First, a Flutter mobile application for students. Second, a Flutter Web administration panel for staff. Third, a Node.js and Express backend connected to MongoDB.

The backend also integrates with Safaricom's Daraja API for M-Pesa payments and an SMTP email service for email notifications."

Show:

Flutter Mobile
      ↓
Node.js + Express API
      ↓
MongoDB
      ↓
M-Pesa / Email

Flutter Web Admin
      ↓
Node.js + Express API

## Student registration and login — 1 minute

Do:

Open the Student application.

Register a student or log in with an existing account.

Say:

"The student creates an account using their personal details. Passwords are securely hashed before being stored in the database, and authentication uses JSON Web Tokens.

Registration also triggers an email notification."

Demonstrates:

Registration

Authentication

Password hashing

JWT

Email integration

## Student password recovery — 1 minute

Do:

From Student Login:

Forgot Password?

Enter the registered email address.

Show the OTP reset screen.

Say:

"The system also provides password recovery. The user enters their registered email address, receives a time-limited OTP through email, verifies the OTP and creates a new password."

Demonstrates:

Password recovery

OTP verification

Email integration

Password update

You don't necessarily need to complete the entire reset during the main demo. Showing the flow is enough unless the examiner asks.

## Admin service management — 1 minute

Do:

Switch to the Admin panel.

Go to:

Services

Create or show a service such as:

Transcript Request
Fee: KES 500
Processing: 3 days
Category: Academic

Say:

"Administrators control the services available to students. Services include their name, description, fee, processing time and category.

This means the service catalogue is dynamic rather than being hardcoded into the mobile application."

## Demonstrates:

Admin functionality

CRUD/service management

Dynamic data

Service categories

## Student browses services and submits a request — 1 minute

Do:

Switch back to Student.

Open:

Services

Show the categories and service list.

Select a service and submit a request.

Say:

"The student receives the services directly from the backend. After selecting a service, the student submits a request and the system automatically generates a unique request reference number."

Demonstrates:

Service catalogue

Category filtering

Request submission

Unique request reference

## Track the request — 45 seconds

Do:

Open:

My Requests

Show the newly created request.

Say:

"Students can track their requests and see the current processing stage. The system uses statuses such as Payment Required, Paid, Processing and Completed."

Demonstrates:

Request tracking

Status management

## M-Pesa payment — 1 minute

Option A — live demonstration

Do:

Tap Pay Now.

Use the designated Safaricom Daraja sandbox test number, not a personal number.

Say:

"The payment process uses Safaricom's Daraja API and STK Push. The student initiates the payment, receives the payment prompt and enters the required PIN in the sandbox environment."

Then show the backend terminal if appropriate.

## Option B — skip live payment

Say:

"The system integrates with Safaricom's Daraja API using STK Push. I have tested the payment integration in the sandbox environment, but I am not triggering a live payment during this presentation."

Demonstrates:

M-Pesa integration

STK Push

Payment processing

Backend callback handling

## Payment history — 30 seconds

Do:

Open:

Payments

Show the payment history list.

Tap a payment to show the receipt details.

Say:

"Students can also view their previous payment transactions, including the service, amount, request reference, phone number, transaction reference and payment status."

Demonstrates:

Payment history

Transaction records

Payment receipts

## Admin manages the request — 1 minute

Do:

Switch to Admin.

Open:

Requests

Find the student's request.

Change the status.

For example:

Payment Required
        ↓
Processing
        ↓
Completed

Then switch back to Student.

Say:

"Administrators can view and manage student requests and update their status as the service is processed."

Then:

"These updates are stored centrally in MongoDB and are reflected in the student's request view. The system also generates an in-app notification and email when request statuses change."

## Demonstrates:

Admin request management

Shared database

Status updates

Notifications

Email

## Student notifications and profile — 45 seconds

Do:

Open:

Notifications

Show the notification generated from the request update.

Then open:

Profile

Show the profile information and editing functionality.

Say:

"Students receive in-app notifications when important events occur, such as payment confirmation and request status changes. They can also update their profile information."

Demonstrates:

Notifications

Profile management

12. Announcements — 45 seconds

Do:

## Switch to Admin.

Open:

Announcements

Publish an announcement.

Then switch to Student and open:

## Announcements

Say:

"Administrators can publish announcements through the admin panel. Students can then view these announcements from the mobile application."

## Demonstrates:

Admin communication

Announcement management

Student information access

## Student management and reports — 1 minute

Do:

In Admin, open:

Students

Search for a student and demonstrate the active/inactive account control.

Then open:

## Reports & Analytics

Say:

"Administrators can search and manage student accounts. The reporting dashboard provides an overview of students, requests, successful payments and recent system activity."

## Demonstrates:

Student management

Account control

Reporting

Analytics

## Admin role security — 30 seconds

Do:

You can simply explain this rather than demonstrate it.

Say:

"The system uses role-based access control. Student and administrator accounts have different permissions. Administrative endpoints require an authenticated administrator, while students can only access student-level functionality."

## Demonstrates:

RBAC

Protected API routes

Authorization

## Wrap-up — 30 seconds

Say:

"CampusConnect provides a centralized platform for campus services, allowing students to register, browse services, submit requests, make payments through M-Pesa, track request progress, view payment history, receive notifications, recover their passwords and access announcements.

Administrators can manage services, students, requests and announcements, while also viewing system reports.

The system is built using Flutter, Flutter Web, Node.js, Express.js, MongoDB, Safaricom Daraja and SMTP email services."

## ** Anticipated Questions **

## "Why did you use Flutter Web for the admin panel instead of React?"

"Using Flutter for both the mobile application and admin panel allows the project to use Dart across the frontend components while keeping the backend independent."

## "Why MongoDB?"

"MongoDB provides a document-oriented database that works well with the Node.js backend and allows the system to store users, services, requests, payments, notifications and announcements."

## "How does M-Pesa work in your system?"

"The student initiates payment, the backend communicates with Safaricom's Daraja API to initiate an STK Push, and Safaricom sends the payment result back through the callback endpoint. The backend then updates the payment and request records."

## "How does password recovery work?"

"The user enters their registered email, the backend generates a six-digit OTP and sends it through email. The OTP expires after a limited period. After successful verification, the user can create a new password."

## "How are passwords secured?"

"Passwords are hashed using bcrypt before they are stored. Authentication uses JWT tokens, and protected endpoints verify the authenticated user's role."

## "Is the system production-ready?"

"The core system is functional, but the current M-Pesa integration is configured for the Daraja sandbox and the development environment uses localhost. Production deployment would require production Daraja credentials, deployed backend infrastructure, production email configuration and additional operational security."

## What would you improve next?

"The next improvements would include push notifications, iOS support, production deployment and further security and monitoring enhancements."