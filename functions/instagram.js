// "Log in with Instagram" (Instagram API with Instagram Login). Loaded only when
// ENABLE_INSTAGRAM_LOGIN=true in functions/.env, together with INSTAGRAM_APP_ID
// and the INSTAGRAM_APP_SECRET secret (both from Meta: Use cases -> Instagram ->
// API setup with Instagram login). The redirect URI shown below must be added to
// "Valid OAuth redirect URIs" on that same page.
const crypto = require('crypto');
const { onCall, onRequest, HttpsError } = require('firebase-functions/v2/https');
const { onSchedule } = require('firebase-functions/v2/scheduler');
const { defineSecret } = require('firebase-functions/params');
const logger = require('firebase-functions/logger');
const admin = require('firebase-admin');
const { logEvent } = require('./access');

const db = admin.firestore();
const { FieldValue } = admin.firestore;

const INSTAGRAM_APP_SECRET = defineSecret('INSTAGRAM_APP_SECRET');
const APP_ID = () => process.env.INSTAGRAM_APP_ID;
const PROJECT = process.env.GCLOUD_PROJECT || 'lineup-32c58';
const REDIRECT_URI = `https://us-central1-${PROJECT}.cloudfunctions.net/instagramCallback`;
const SITE = 'https://app.lineuptech.in';
const SCOPES = 'instagram_business_basic,instagram_business_manage_messages';

const b64 = (o) => Buffer.from(JSON.stringify(o)).toString('base64url');
const sign = (payload, secret) => crypto.createHmac('sha256', secret).update(payload).digest('base64url');

/** Signed-in user asks for the Instagram consent URL (state binds it to their uid). */
exports.getInstagramAuthUrl = onCall({ secrets: [INSTAGRAM_APP_SECRET] }, async (request) => {
  if (!request.auth) throw new HttpsError('unauthenticated', 'Sign in first.');
  const payload = b64({ uid: request.auth.uid, ts: Date.now() });
  const state = `${payload}.${sign(payload, INSTAGRAM_APP_SECRET.value())}`;
  const url =
    'https://www.instagram.com/oauth/authorize?' +
    new URLSearchParams({
      client_id: APP_ID(),
      redirect_uri: REDIRECT_URI,
      response_type: 'code',
      scope: SCOPES,
      state,
    }).toString();
  return { url };
});

/** Instagram redirects here with ?code=...&state=... after the owner approves. */
exports.instagramCallback = onRequest({ secrets: [INSTAGRAM_APP_SECRET] }, async (req, res) => {
  const fail = (msg) => res.redirect(`${SITE}/?ig=error&msg=${encodeURIComponent(msg)}`);
  try {
    if (req.query.error) return fail('Instagram connection was cancelled.');
    const [payload, mac] = String(req.query.state || '').split('.');
    const expected = sign(payload || '', INSTAGRAM_APP_SECRET.value());
    if (!payload || !mac || mac.length !== expected.length ||
        !crypto.timingSafeEqual(Buffer.from(mac), Buffer.from(expected))) {
      return fail('Invalid state. Please try again.');
    }
    const { uid, ts } = JSON.parse(Buffer.from(payload, 'base64url').toString());
    if (!uid || Date.now() - ts > 15 * 60 * 1000) return fail('Link expired. Please try again.');
    const code = String(req.query.code || '').replace(/#_$/, '');

    // 1) code -> short-lived token
    const short = await (await fetch('https://api.instagram.com/oauth/access_token', {
      method: 'POST',
      body: new URLSearchParams({
        client_id: APP_ID(),
        client_secret: INSTAGRAM_APP_SECRET.value(),
        grant_type: 'authorization_code',
        redirect_uri: REDIRECT_URI,
        code,
      }),
    })).json();
    if (!short.access_token) throw new Error('Token exchange failed: ' + JSON.stringify(short).slice(0, 200));

    // 2) short-lived -> long-lived (60 days)
    const long = await (await fetch(
      'https://graph.instagram.com/access_token?' +
        new URLSearchParams({
          grant_type: 'ig_exchange_token',
          client_secret: INSTAGRAM_APP_SECRET.value(),
          access_token: short.access_token,
        })
    )).json();
    const token = long.access_token || short.access_token;

    // 3) who is it
    const me = await (await fetch(
      'https://graph.instagram.com/v21.0/me?' +
        new URLSearchParams({ fields: 'user_id,username,followers_count', access_token: token })
    )).json();
    if (!me.username) throw new Error('Could not read Instagram profile: ' + JSON.stringify(me).slice(0, 200));

    // 4) receive messages for this account
    await fetch(
      'https://graph.instagram.com/v21.0/me/subscribed_apps?' +
        new URLSearchParams({ subscribed_fields: 'messages', access_token: token }),
      { method: 'POST' }
    );

    const f = me.followers_count || 0;
    const followers = f >= 1000000 ? `${(f / 1000000).toFixed(1)}M` : f >= 1000 ? `${(f / 1000).toFixed(1)}K` : `${f}`;
    const userRef = db.collection('users').doc(uid);
    await userRef.set(
      {
        igConnected: true,
        igUserId: String(me.user_id || short.user_id),
        igAccessToken: token,
        igTokenIssuedAt: FieldValue.serverTimestamp(),
        igAccount: `@${me.username}`,
        igFollowers: followers,
      },
      { merge: true }
    );
    await userRef.collection('notifications').add({
      title: 'Instagram Account Linked',
      desc: `Successfully connected @${me.username} to LineUp.`,
      type: 'bot',
      unread: true,
      createdAt: FieldValue.serverTimestamp(),
    });
    res.redirect(`${SITE}/?ig=connected`);
  } catch (e) {
    logger.error('Instagram callback failed', e);
    await logEvent('error', 'Instagram login failed: ' + (e && e.message), null);
    fail('Could not connect Instagram. Please try again.');
  }
});

/** Long-lived Instagram tokens last 60 days; refresh any older than 30 days. */
exports.refreshInstagramTokens = onSchedule('every 24 hours', async () => {
  const cutoff = admin.firestore.Timestamp.fromMillis(Date.now() - 30 * 86400000);
  const snap = await db.collection('users').where('igTokenIssuedAt', '<', cutoff).get();
  for (const d of snap.docs) {
    const t = d.data().igAccessToken;
    if (!t) continue;
    try {
      const j = await (await fetch(
        'https://graph.instagram.com/refresh_access_token?' +
          new URLSearchParams({ grant_type: 'ig_refresh_token', access_token: t })
      )).json();
      if (j.access_token) {
        await d.ref.set({ igAccessToken: j.access_token, igTokenIssuedAt: FieldValue.serverTimestamp() }, { merge: true });
      } else {
        await logEvent('warn', 'Instagram token refresh failed for a user', { uid: d.id });
      }
    } catch (e) {
      await logEvent('warn', 'Instagram token refresh error: ' + e.message, { uid: d.id });
    }
  }
});

// ---- Meta callbacks: deauthorize and data deletion (signed_request) ---------

/** Verifies Meta's signed_request and returns its payload, or null. */
function parseSignedRequest(signedRequest, secret) {
  const [sig, payload] = String(signedRequest || '').split('.');
  if (!sig || !payload) return null;
  const expected = crypto.createHmac('sha256', secret).update(payload).digest();
  const given = Buffer.from(sig, 'base64url');
  if (given.length !== expected.length || !crypto.timingSafeEqual(given, expected)) return null;
  try {
    return JSON.parse(Buffer.from(payload, 'base64url').toString());
  } catch (_) {
    return null;
  }
}

async function findByInstagramId(igId) {
  const snap = await db.collection('users').where('igUserId', '==', String(igId)).limit(1).get();
  return snap.empty ? null : snap.docs[0];
}

async function disconnectInstagram(userDoc) {
  await userDoc.ref.set(
    {
      igConnected: false,
      igUserId: FieldValue.delete(),
      igAccessToken: FieldValue.delete(),
      igAccount: FieldValue.delete(),
      igFollowers: FieldValue.delete(),
      igTokenIssuedAt: FieldValue.delete(),
    },
    { merge: true }
  );
}

/** The user removed LineUP in Instagram: drop the stored connection and token. */
exports.instagramDeauthorize = onRequest({ secrets: [INSTAGRAM_APP_SECRET] }, async (req, res) => {
  const data = parseSignedRequest(req.body && req.body.signed_request, INSTAGRAM_APP_SECRET.value());
  if (!data) return res.sendStatus(400);
  const doc = await findByInstagramId(data.user_id);
  if (doc) await disconnectInstagram(doc);
  res.sendStatus(200);
});

/** The user asked Instagram to delete their data held by LineUP. */
exports.instagramDataDeletion = onRequest({ secrets: [INSTAGRAM_APP_SECRET] }, async (req, res) => {
  const data = parseSignedRequest(req.body && req.body.signed_request, INSTAGRAM_APP_SECRET.value());
  if (!data) return res.sendStatus(400);
  const doc = await findByInstagramId(data.user_id);
  const code = crypto.randomBytes(8).toString('hex');
  if (doc) {
    await disconnectInstagram(doc);
    // Remove Instagram conversations, contacts and leads for this account.
    for (const col of ['conversations', 'contacts', 'leads']) {
      const snap = await doc.ref.collection(col).where('channel', '==', 'Instagram').get();
      for (const d of snap.docs) await db.recursiveDelete(d.ref);
    }
  }
  await logEvent('info', 'Instagram data deletion request handled', { code });
  res.json({ url: `${SITE}/data-deletion/`, confirmation_code: code });
});
