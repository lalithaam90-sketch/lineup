# LineUp

Flutter web app (plus Firebase backend) that lets a business connect its own WhatsApp
Business Account and Instagram professional account, send and receive messages, manage
templates, run AI replies (Gemini on Vertex AI) and capture leads.

- App: https://app.lineuptech.in (Firebase Hosting site `lineup-app-32c58`)
- Admin page: `admin/` -> Firebase Hosting site `lineup-admin-32c58`
- Backend: Cloud Functions in `functions/` (Node 22)
- Firebase project: `lineup-32c58`

## What is where

| Path | What it is |
|---|---|
| `lib/` | Flutter app (screens, services, theme) |
| `functions/index.js` | WhatsApp/Instagram webhook, send/template/campaign functions, AI reply |
| `functions/delivery.js` | Delivery tracking (sent/delivered/read/failed) |
| `functions/admin.js`, `access.js` | Admin back-office callables and shared access checks |
| `functions/instagram.js` | "Log in with Instagram" OAuth + Meta deauthorize/data-deletion callbacks |
| `functions/razorpay.js` | Razorpay payment links + webhook (switched off until keys exist) |
| `admin/` | Plain HTML/JS admin page (email + password login) |
| `web/privacy`, `web/terms`, `web/data-deletion` | Public legal pages served at app.lineuptech.in |
| `firestore.rules`, `firestore.indexes.json` | Database security rules and indexes |
| `META_*.md`, `RECOVERY_NOTES.md` | Meta App Review notes |

## Setting up on a new machine (for example a Mac)

1. Install Flutter (stable), Node 22, and the Firebase CLI: `npm install -g firebase-tools`.
2. `git clone` this repo, then in the project folder:
   ```bash
   flutter pub get
   cd functions && npm install && cd ..
   firebase login          # use the Google account that owns project lineup-32c58
   ```
3. Copy the backend flags: `cp functions/.env.example functions/.env`.
4. Run locally: `flutter run -d chrome --dart-define=IG_LOGIN=true`.

## Secrets (never in git)

Stored in Google Secret Manager for the project. Set with
`firebase functions:secrets:set NAME --project lineup-32c58` (it prompts for the value):

`META_VERIFY_TOKEN`, `META_APP_SECRET`, `INSTAGRAM_APP_SECRET`, and for payments
`RAZORPAY_KEY_ID`, `RAZORPAY_KEY_SECRET`, `RAZORPAY_WEBHOOK_SECRET`.

`functions/.env` only holds non-secret flags (`ENABLE_RAZORPAY`, `ENABLE_INSTAGRAM_LOGIN`,
`INSTAGRAM_APP_ID`).

## Build and deploy

```bash
# app (keep the Instagram login button on)
flutter build web --release --dart-define=IG_LOGIN=true
firebase deploy --only hosting:lineup-app-32c58 --project lineup-32c58

# backend
firebase deploy --only functions --project lineup-32c58

# admin page
firebase deploy --only hosting:lineup-admin-32c58 --project lineup-32c58

# database rules and indexes
firebase deploy --only firestore --project lineup-32c58
```

Windows note: `flutter pub get` can fail while OneDrive holds the `windows/flutter/ephemeral`
folder; run it again.

## Things to know

- **Admin login:** `control@lineuptech.admin` (email + password account created in the Firebase
  console). The allow-list lives in `functions/access.js` and `firestore.rules`; keep both in sync.
- **AI model:** `functions/index.js` tries a list of Gemini model names on Vertex AI and remembers
  the one that works (Gemini 2.5 was retired on Vertex on 2026-10-20).
- **Meta review (Nov 2026):** WhatsApp permissions and `public_profile` approved. The two Instagram
  permissions were rejected only for the screencast; they need a new video showing the full
  Instagram login and consent, then a resubmission.
- **Marketing site (lineuptech.in)** is a separate static site on Firebase Hosting site
  `lineup-32c58`; its source is not in this repo.
- **Razorpay** payments are written but off. To finish: set the three Razorpay secrets, add the
  webhook `https://us-central1-lineup-32c58.cloudfunctions.net/razorpayWebhook`
  (event `payment_link.paid`), set `ENABLE_RAZORPAY=true`, create plans in the admin page, deploy.
