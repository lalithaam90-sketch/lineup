# Meta App Review drafts: LineUP (App ID 2092289318324360)

Review before using. Items marked **[VERIFY]** describe behaviour I could not
confirm in the code (for example, automatic replies). Do not submit anything the
live app does not actually do, because reviewers test it.

## App summary (use wherever a description is asked)
LineUp is a dashboard for small businesses. A business owner signs in with their
phone number, connects their own WhatsApp Business Account and Instagram
Professional Account, creates AI assistant bots, and sees the leads and
conversations from those channels in one place. Each user only ever accesses
their own accounts and data.

## Permissions to request (keep)

### whatsapp_business_management
Used to read the business's WhatsApp Business Account: its verified business name
and display phone number, so the user can confirm the right account is
connected inside LineUp. We do not manage accounts that belong to other people.

### whatsapp_business_messaging
Used so the business can send and receive WhatsApp messages with its own
customers from LineUp, including replies drafted by the business's AI bot.
**[VERIFY]** Confirm the app actually sends messages, and demo that exact flow.

### instagram_business_basic
Used to read the connected Instagram professional account's username and
follower count, shown on the user's Instagram screen after connecting.

### instagram_business_manage_messages
Used to read and reply to Instagram direct messages sent to the business's own
account, so leads from DMs appear in LineUp. **[VERIFY]** Request this only if the
app really handles DMs.

### public_profile
Used only to identify the signed-in user, if Facebook Login is used.
**[VERIFY]** The app currently signs in by phone OTP. If Facebook Login isn't
used, remove this permission.

## Permissions to REMOVE (in Use cases -> Customize)
- catalog_management: no catalog feature exists in the app.
- instagram_manage_comments: no comment handling exists in the app.
Requesting permissions the app does not use is a common cause of rejection.

## Data handling answers (typical)
- Data used: WhatsApp/Instagram account identifiers, access tokens supplied by the
  user, and messages/leads from the user's own business accounts.
- Purpose: show the owner their own channels and leads, and run their AI bots.
- Stored in Google Firebase (Firestore), accessible only to the owning user via
  security rules (users/{uid}). Not sold or shared with third parties.
- Deletion: user can disconnect each channel in the app, and can request full
  deletion at the URL below.

## User data deletion page (publish at https://lineuptech.in/data-deletion)
> **Deleting your LineUp data**
> To disconnect a WhatsApp or Instagram account, open LineUp, go to that
> channel's screen and choose Disconnect. This removes the stored connection and
> access token.
> To delete your LineUp account and all associated data (profile, bots, leads,
> notifications), email lalitha.a.m90@gmail.com from the contact email on your
> account, or the phone number you signed in with, with the subject "Delete my
> data". We will delete it within 30 days and confirm by reply.

## Terms of Service URL
A short ToS page is needed at https://lineuptech.in/terms. I can draft one if you
want.

## Screencast checklist (you record; one video can cover several permissions)
1. Open https://lineup-app-32c58.web.app and sign in with phone OTP.
2. Connect WhatsApp: paste credentials, show the verified business name and number.
3. Show a WhatsApp message sent/received (only if supported **[VERIFY]**).
4. Connect Instagram, show the username and follower count.
5. Show leads and notifications appearing, then Disconnect.
Narrate or caption each permission as it is used. Keep each video under 2 minutes.

## Before submitting
- Business verification complete (Review -> Verification).
- Privacy URL, ToS URL and data deletion URL all load publicly.
- Meta app mode still "Unpublished": set up a test user or use app roles so
  reviewers can log in, and provide test instructions.
