# Screencasts for Meta App Review (LineUP)

Meta wants screen recordings with NO audio (use on-screen text captions), English UI,
MP4 or MOV, under 2 GB. Record at 1080p. Keep each one under about 2 minutes.

## Before you record (10 minutes, once)
1. Meta -> LineUP -> WhatsApp -> API setup: click **Generate token** (it expires in ~24 h,
   so do this right before recording). Note the Phone Number ID and WABA ID.
2. https://lineup-app-32c58.web.app (use an Incognito window so it is the newest version):
   sign in -> WABA tab -> Disconnect -> Connect, paste the three values. You should see
   the verified business name and number.
3. Create the template you will use in video 2 first, so it can be approved while you
   record video 1: Message Templates -> Create:
   - name `lineup_hello_1`, Utility, English (US)
   - body: `Hello {{1}}, thanks for contacting us. Reply STOP to unsubscribe.`
4. Make sure your own phone number is in the recipient list (Meta API setup page).
5. Open WhatsApp Web (https://web.whatsapp.com) signed in to the phone that is a recipient.
6. Start a screen recorder: Win+Shift+S -> video camera icon -> select the whole screen,
   or Win+G (Xbox Game Bar). Put LineUp on the left half and WhatsApp Web on the right half
   so both are visible at once.

Do NOT reply to messages in WhatsApp during the recording (another app is subscribed
to this number and may answer). Stop recording as soon as the message arrives.

## Video 1: whatsapp_business_messaging  (upload to this permission)
Caption each step on screen (a text box or the Snipping Tool's pen):
1. "LineUp web app, signed in" - show the dashboard briefly.
2. Open WABA tab -> "WhatsApp connected: <number>".
3. Tap **Send Message**.
4. Switch on "Send an approved template", choose an APPROVED template
   (`hello_world` or `lineup_hello_1`).
5. Type your own number with country code. Tap **Send**.
6. Look at the right side: "Message received in WhatsApp" - show the message arriving
   from the business number. Hold for 3 seconds. Stop.

## Video 2: whatsapp_business_management  (upload to this permission)
1. "LineUp - Message Templates (loaded live from the WhatsApp Business Account)".
2. Show the list of existing templates and their status.
3. Tap **Create**. Fill: name `lineup_demo_2` (a new name), Utility, English (US),
   body `Hi {{1}}, your order is ready. Reply STOP to unsubscribe.`
4. Tap **Submit to Meta**. Show "Template submitted to Meta for approval".
5. Show the new template in the list with status PENDING. Stop.
6. Optional but helpful: show the WABA card with the verified business name and phone number.

## Video 3: instagram_business_basic  (only if you have an Instagram professional account)
1. Instagram tab -> Connect. Enter the Instagram account ID and token.
2. Show the verified @username and follower count appear. Stop.
Without an Instagram professional account you cannot show this, so tell me and we
remove the Instagram permissions from this submission (recommended for a first review).

## Video 4: instagram_business_manage_messages  (upload to this permission)
Setup first (once):
1. Meta -> LineUP -> Use cases -> Instagram -> API setup with Instagram login:
   add your Instagram professional account, turn ON its webhook subscription for
   `messages`, and click **Generate token** (starts with `IG`). Note the Instagram account ID.
2. The account that sends the DM must have a role on the app (Roles -> Testers/Developers),
   because the app is still in development for Instagram messaging.
3. In LineUp: Instagram tab -> Connect with that ID and token. Make sure a bot is active
   and DM Automation is ON. (Optional: add an Instagram auto-reply for the keyword "price".)
Recording (LineUp left, Instagram Web https://www.instagram.com on the right, logged in as
the TESTER account, a different account from the one you connected):
1. "Instagram account connected in LineUp" - show @username.
2. On the tester account, open a DM to the connected account and send: `What are your opening hours?`
3. Show the reply arriving in the Instagram DM (from the connected account), written by the bot.
4. Back in LineUp show the new lead / notification. Stop.
If no reply arrives, check `firebase functions:log --only metaWebhook --project lineup-32c58`
and tell me what it says before you record.

## Where to upload
Meta -> LineUP -> App Review -> Allowed usage -> Get started on each permission ->
"Drag and drop your file". Use video 1 for whatsapp_business_messaging,
video 2 for whatsapp_business_management, video 3 for instagram_business_basic,
video 4 for instagram_business_manage_messages.
You can also add the same videos under Reviewer instructions -> supporting documentation.
