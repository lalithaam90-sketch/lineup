const crypto = require('crypto');
const { onRequest } = require('firebase-functions/v2/https');
const { defineSecret } = require('firebase-functions/params');
const logger = require('firebase-functions/logger');
const admin = require('firebase-admin');

admin.initializeApp();
const { accessDecision, logEvent, getConfig } = require('./access');
const { recordOutbox, handleStatus } = require('./delivery');
const db = admin.firestore();
const { FieldValue } = admin.firestore;

const META_VERIFY_TOKEN = defineSecret('META_VERIFY_TOKEN');
const META_APP_SECRET = defineSecret('META_APP_SECRET');
const INSTAGRAM_APP_SECRET = defineSecret('INSTAGRAM_APP_SECRET');

// Override with the GEMINI_MODEL env var if Google renames/retires this one.
const MODEL_CANDIDATES = [
  { model: process.env.GEMINI_MODEL || 'gemini-flash-latest', location: 'global' },
  { model: 'gemini-3.5-flash', location: 'global' },
  { model: 'gemini-3-flash', location: 'global' },
  { model: 'gemini-flash-latest', location: 'us-central1' },
  { model: 'gemini-3.5-flash', location: 'us-central1' },
  { model: 'gemini-2.5-flash', location: 'us-central1' },
];
let workingModel = null;
const GRAPH = 'https://graph.facebook.com/v21.0';
const IG_GRAPH = 'https://graph.instagram.com/v21.0';
// Instagram Login tokens (IGAA...) must use graph.instagram.com; Facebook-Login tokens use graph.facebook.com.
const igBase = (token) => (String(token || '').startsWith('IG') ? IG_GRAPH : GRAPH);
const HISTORY_LIMIT = 10;
const STOP_RE = /^\s*(stop|unsubscribe|opt[ -]?out|cancel)\s*[.!]*\s*$/i;
const START_RE = /^\s*(start|subscribe|resume)\s*[.!]*\s*$/i;
const DEFAULT_DAILY_CAMPAIGN_CAP = 100;

/**
 * Single webhook for both WhatsApp and Instagram. Point Meta's webhook
 * callback URL at this function and use META_VERIFY_TOKEN as the verify token.
 */
exports.metaWebhook = onRequest(
  { secrets: [META_VERIFY_TOKEN, META_APP_SECRET, INSTAGRAM_APP_SECRET], region: 'us-central1' },
  async (req, res) => {
    if (req.method === 'GET') {
      const ok =
        req.query['hub.mode'] === 'subscribe' &&
        req.query['hub.verify_token'] === META_VERIFY_TOKEN.value();
      return ok ? res.status(200).send(req.query['hub.challenge']) : res.sendStatus(403);
    }
    if (req.method !== 'POST') return res.sendStatus(405);

    // WhatsApp webhooks are signed with the Meta app secret; Instagram ones with the Instagram app secret.
    if (!validSignature(req, META_APP_SECRET.value()) && !validSignature(req, INSTAGRAM_APP_SECRET.value())) {
      logger.warn('Rejected webhook with bad signature');
      return res.sendStatus(401);
    }

    // Meta expects a fast 200; handle messages before replying so the
    // function isn't frozen mid-work, but never fail the whole batch.
    try {
      const body = req.body || {};
      for (const entry of body.entry || []) {
        if (body.object === 'whatsapp_business_account') {
          for (const change of entry.changes || []) {
            await handleWhatsApp(change.value || {});
          }
        } else if (body.object === 'instagram') {
          for (const m of entry.messaging || []) {
            await handleInstagram(entry.id, m);
          }
        }
      }
    } catch (e) {
      logger.error('Webhook handling failed', e);
      await logEvent('error', 'Webhook handling failed: ' + (e && e.message), null);
    }
    res.sendStatus(200);
  }
);

function validSignature(req, appSecret) {
  const sig = req.get('x-hub-signature-256') || '';
  const expected =
    'sha256=' + crypto.createHmac('sha256', appSecret).update(req.rawBody).digest('hex');
  const a = Buffer.from(sig);
  const b = Buffer.from(expected);
  return a.length === b.length && crypto.timingSafeEqual(a, b);
}

async function handleWhatsApp(value) {
  const phoneNumberId = value.metadata && value.metadata.phone_number_id;
  if (!phoneNumberId) return;
  const user = await findUser('wabaPhoneNumberId', phoneNumberId);
  if (!user) return logger.warn('No user for WhatsApp number', phoneNumberId);

  // Delivery reports for messages we sent (sent / delivered / read / failed).
  for (const st of value.statuses || []) {
    try {
      await handleStatus(user, st);
    } catch (e) {
      logger.error('Status handling failed', e);
    }
  }

  for (const msg of value.messages || []) {
    if (msg.type !== 'text') continue; // text only for now
    const profile = (value.contacts || []).find((c) => c.wa_id === msg.from);
    await processMessage({
      user,
      channel: 'WhatsApp',
      contactId: msg.from,
      contactName: (profile && profile.profile && profile.profile.name) || msg.from,
      text: msg.text.body,
      counterField: 'wabaConversations',
      send: async (reply) => {
        const j = await graphPost(`${phoneNumberId}/messages`, user.data.wabaAccessToken, {
          messaging_product: 'whatsapp',
          to: msg.from,
          type: 'text',
          text: { body: reply },
        });
        const id = j && j.messages && j.messages[0] && j.messages[0].id;
        if (id) await recordOutbox(user.ref, { id, to: msg.from, kind: 'text', text: reply, source: 'bot' });
      },
    });
  }
}

async function handleInstagram(igId, m) {
  if (!m.message || m.message.is_echo || !m.message.text) return;
  const user = await findUser('igUserId', igId);
  if (!user) return logger.warn('No user for Instagram account', igId);
  const senderId = m.sender.id;
  await processMessage({
    user,
    channel: 'Instagram',
    contactId: senderId,
    contactName: senderId,
    text: m.message.text,
    counterField: 'igConversations',
    send: (reply) =>
      graphPost(
        `${igId}/messages`,
        user.data.igAccessToken,
        {
          recipient: { id: senderId },
          message: { text: String(reply).slice(0, 1000) }, // Instagram text limit
        },
        igBase(user.data.igAccessToken)
      ),
  });
}

async function findUser(field, value) {
  const snap = await db.collection('users').where(field, '==', value).limit(1).get();
  if (snap.empty) return null;
  const doc = snap.docs[0];
  return { ref: doc.ref, data: doc.data() };
}

async function processMessage({ user, channel, contactId, contactName, text, counterField, send }) {
  const access = await accessDecision(user.data);
  if (!access.allowed) return logger.info('Blocked by account status', user.ref.id, access.reason);

  // Opt-out / opt-in handling (STOP / START). Opted-out contacts get no
  // automatic replies and are skipped by campaigns until they send START.
  const contactRef = user.ref.collection('contacts').doc(`${channel}_${contactId}`);
  if (STOP_RE.test(text)) {
    await contactRef.set(
      { channel, contactId, optedOut: true, optedOutAt: FieldValue.serverTimestamp() },
      { merge: true }
    );
    return send("You've been unsubscribed and won't receive further messages. Reply START to resume.");
  }
  const contactSnap = await contactRef.get();
  if (contactSnap.exists && contactSnap.data().optedOut) {
    if (START_RE.test(text)) {
      await contactRef.set({ optedOut: false, optedInAt: FieldValue.serverTimestamp() }, { merge: true });
      await send('Welcome back! How can we help?');
    }
    return;
  }

  const convoRef = user.ref.collection('conversations').doc(`${channel}_${contactId}`);
  const convo = await convoRef.get();
  const isNew = !convo.exists;

  const history = await convoRef
    .collection('messages')
    .orderBy('createdAt', 'desc')
    .limit(HISTORY_LIMIT)
    .get();
  const turns = history.docs.reverse().map((d) => d.data());

  await convoRef.set(
    { channel, contactId, contactName, lastMessage: text, updatedAt: FieldValue.serverTimestamp() },
    { merge: true }
  );
  await convoRef.collection('messages').add({
    role: 'user',
    text,
    createdAt: FieldValue.serverTimestamp(),
  });

  if (isNew) {
    await user.ref.collection('leads').add({
      name: contactName,
      contact: contactId,
      channel,
      intent: text.slice(0, 200),
      tag: 'New',
      createdAt: FieldValue.serverTimestamp(),
    });
    await user.ref.collection('notifications').add({
      title: 'New Lead Captured',
      desc: `${contactName} reached out via ${channel}: "${text.slice(0, 120)}"`,
      type: 'lead',
      unread: true,
      createdAt: FieldValue.serverTimestamp(),
    });
    await user.ref.set({ [counterField]: FieldValue.increment(1) }, { merge: true });
  }

  const logBot = async (reply) => {
    await send(reply);
    await convoRef.collection('messages').add({
      role: 'bot',
      text: reply,
      createdAt: FieldValue.serverTimestamp(),
    });
  };

  // 1) Keyword auto-replies win over the AI.
  const rule = await matchAutoReply(user.ref, channel, text);
  if (rule) return logBot(rule.response);

  // 2) AI bot, unless switched off for this channel in the app.
  const aiOn = channel === 'WhatsApp' ? user.data.wabaAiEnabled : user.data.igAiEnabled;
  if (aiOn === false) return logger.info('AI switched off for', channel, user.ref.id);

  // Contacts reached by a sales campaign keep talking to the sales bot.
  const role = convo.exists ? convo.data().botRole : undefined;
  const botDoc = await pickBot(user.ref, role);
  if (!botDoc) return logger.info('No active bot; skipping auto-reply', user.ref.id);
  if (isNew) await botDoc.ref.set({ totalConversations: FieldValue.increment(1) }, { merge: true });

  const reply = await askGemini(botDoc.data(), turns, text, user.data.businessName);
  if (!reply) return;
  await logBot(reply);
}

async function matchAutoReply(userRef, channel, text) {
  const snap = await userRef.collection('autoReplies').where('enabled', '==', true).get();
  const t = text.toLowerCase();
  for (const d of snap.docs) {
    const r = d.data();
    if (r.channel && r.channel !== 'all' && r.channel !== channel) continue;
    if ((r.keywords || []).some((k) => k && t.includes(String(k).toLowerCase()))) return r;
  }
  return null;
}

// Returns the bot's document snapshot (so callers can use .ref and .data()).
async function pickBot(userRef, role) {
  let q = userRef.collection('bots').where('active', '==', true);
  if (role) q = q.where('role', '==', role);
  const snap = await q.limit(1).get();
  if (snap.empty && role) return pickBot(userRef); // role bot switched off: fall back
  return snap.empty ? null : snap.docs[0];
}

async function askGemini(bot, turns, text, businessName) {
  const facts = (bot.knowledge || []).filter(Boolean);
  const system =
    (bot.prompt || 'You are a helpful customer support assistant.') +
    (facts.length ? `\n\nBusiness knowledge (use this to answer, do not invent other facts):\n- ${facts.join('\n- ')}` : '') +
    `\n\nYou are replying on behalf of ${businessName || 'the business'} in a chat app. ` +
    'Keep replies short and plain text. If you do not know something, say a team member will follow up.';
  const contents = [
    ...turns.map((t) => ({ role: t.role === 'bot' ? 'model' : 'user', parts: [{ text: t.text }] })),
    { role: 'user', parts: [{ text }] },
  ];
  // Vertex AI (Google Cloud): paid, covered by Cloud data terms (not used for
  // model training). Auth uses this function's own service account, no API key.
  // Model names change (Gemini 2.5 was retired on Vertex on 2026-10-20), so we try
  // candidates in order and remember the first one that works.
  const project = process.env.GCLOUD_PROJECT || 'lineup-32c58';
  const token = (await admin.credential.applicationDefault().getAccessToken()).access_token;
  const payload = JSON.stringify({ systemInstruction: { parts: [{ text: system }] }, contents });
  const attempts = workingModel ? [workingModel] : MODEL_CANDIDATES;
  let r = null;
  let lastBody = '';
  for (const { model, location } of attempts) {
    const host = location === 'global' ? 'aiplatform.googleapis.com' : `${location}-aiplatform.googleapis.com`;
    r = await fetch(
      `https://${host}/v1/projects/${project}/locations/${location}/publishers/google/models/${model}:generateContent`,
      { method: 'POST', headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` }, body: payload }
    );
    if (r.ok) {
      if (!workingModel) {
        workingModel = { model, location };
        logger.info('Using Gemini model', model, location);
      }
      break;
    }
    lastBody = await r.text();
    if (r.status !== 404 && r.status !== 400) break; // only model-availability errors move on to the next candidate
  }
  if (!r.ok) {
    workingModel = null;
    logger.error('Gemini error', r.status, lastBody);
    await logEvent('error', 'Gemini error ' + r.status, { body: lastBody.slice(0, 300) });
    return null;
  }
  const j = await r.json();
  const parts = j.candidates && j.candidates[0] && j.candidates[0].content && j.candidates[0].content.parts;
  return parts ? parts.map((p) => p.text || '').join('').trim() : null;
}

async function graphPost(path, token, body, base = GRAPH) {
  const r = await fetch(`${base}/${path}`, {
    method: 'POST',
    headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  });
  if (!r.ok) {
    const body = await r.text();
    logger.error('Meta send failed', r.status, body);
    await logEvent('error', 'Meta send failed ' + r.status, { path, body: body.slice(0, 300) });
    return null;
  }
  return r.json().catch(() => null);
}

// ---------------------------------------------------------------------------
// Callable functions used by the LineUp app (signed-in user only). They act on
// the caller's own WhatsApp connection stored at users/{uid}.
// ---------------------------------------------------------------------------
const { onCall, HttpsError } = require('firebase-functions/v2/https');

async function wabaOf(request) {
  if (!request.auth) throw new HttpsError('unauthenticated', 'Sign in first.');
  const snap = await db.collection('users').doc(request.auth.uid).get();
  const d = snap.data() || {};
  const access = await accessDecision(d);
  if (!access.allowed) throw new HttpsError('permission-denied', access.reason);
  if (!d.wabaConnected || !d.wabaId || !d.wabaPhoneNumberId || !d.wabaAccessToken) {
    throw new HttpsError('failed-precondition', 'Connect WhatsApp first.');
  }
  return { uid: request.auth.uid, id: d.wabaId, phoneNumberId: d.wabaPhoneNumberId, token: d.wabaAccessToken };
}

async function graph(method, path, token, body) {
  const r = await fetch(`${GRAPH}/${path}`, {
    method,
    headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
    body: body ? JSON.stringify(body) : undefined,
  });
  const j = await r.json().catch(() => ({}));
  if (!r.ok) {
    const msg = (j.error && (j.error.error_user_msg || j.error.message)) || `Meta error ${r.status}`;
    throw new HttpsError('failed-precondition', msg);
  }
  return j;
}

/** Refuses to message a contact who replied STOP. */
async function assertNotOptedOut(uid, digitsOnly) {
  const c = await db.collection('users').doc(uid).collection('contacts').doc('WhatsApp_' + digitsOnly).get();
  if (c.exists && c.data().optedOut) {
    throw new HttpsError('failed-precondition', 'This contact opted out (replied STOP). They must send START before you can message them.');
  }
}

// Normalise to digits only (WhatsApp wants country code, no + or spaces).
function digits(s) {
  const n = String(s || '').replace(/\D/g, '');
  if (n.length < 8) throw new HttpsError('invalid-argument', 'Enter a full phone number with country code.');
  return n;
}

/** Send a free-text message. Only works inside the 24h customer-service window. */
exports.sendWhatsAppMessage = onCall(async (request) => {
  const w = await wabaOf(request);
  const text = String((request.data && request.data.text) || '').trim();
  if (!text) throw new HttpsError('invalid-argument', 'Message is empty.');
  await assertNotOptedOut(w.uid, digits(request.data.to));
  const j = await graph('POST', `${w.phoneNumberId}/messages`, w.token, {
    messaging_product: 'whatsapp',
    to: digits(request.data.to),
    type: 'text',
    text: { body: text },
  });
  const id = (j.messages && j.messages[0] && j.messages[0].id) || null;
  await recordOutbox(db.collection('users').doc(w.uid), { id, to: digits(request.data.to), kind: 'text', text, source: 'app' });
  return { messageId: id };
});

/** Send an approved template (needed to start a conversation). */
exports.sendWhatsAppTemplate = onCall(async (request) => {
  const w = await wabaOf(request);
  const { to, name, language } = request.data || {};
  if (!name) throw new HttpsError('invalid-argument', 'Pick a template.');
  await assertNotOptedOut(w.uid, digits(to));
  const j = await graph('POST', `${w.phoneNumberId}/messages`, w.token, {
    messaging_product: 'whatsapp',
    to: digits(to),
    type: 'template',
    template: { name, language: { code: language || 'en_US' } },
  });
  const id = (j.messages && j.messages[0] && j.messages[0].id) || null;
  await recordOutbox(db.collection('users').doc(w.uid), { id, to: digits(to), kind: 'template', templateName: name, source: 'app' });
  return { messageId: id };
});

/** List this account's message templates from Meta. */
exports.listWhatsAppTemplates = onCall(async (request) => {
  const w = await wabaOf(request);
  const j = await graph(
    'GET',
    `${w.id}/message_templates?fields=name,status,category,language,components&limit=50`,
    w.token
  );
  return { templates: j.data || [] };
});

/** Create a text-body message template (submitted to Meta for approval). */
exports.createWhatsAppTemplate = onCall(async (request) => {
  const w = await wabaOf(request);
  const { name, category, language, body } = request.data || {};
  if (!/^[a-z0-9_]{1,512}$/.test(name || '')) {
    throw new HttpsError('invalid-argument', 'Name: lowercase letters, numbers and underscores only.');
  }
  if (!['UTILITY', 'MARKETING'].includes(category)) {
    throw new HttpsError('invalid-argument', 'Category must be UTILITY or MARKETING.');
  }
  if (!String(body || '').trim()) throw new HttpsError('invalid-argument', 'Body is empty.');
  const j = await graph('POST', `${w.id}/message_templates`, w.token, {
    name,
    category,
    language: language || 'en_US',
    components: [{ type: 'BODY', text: String(body).trim() }],
  });
  return { id: j.id, status: j.status, category: j.category };
});

/** Phone number quality rating from Meta ("GREEN" | "YELLOW" | "RED" | "UNKNOWN"). */
async function qualityOf(w) {
  try {
    const j = await graph('GET', `${w.phoneNumberId}?fields=quality_rating,messaging_limit_tier`, w.token);
    return { quality: j.quality_rating || 'UNKNOWN', tier: j.messaging_limit_tier || null };
  } catch (_) {
    return { quality: 'UNKNOWN', tier: null };
  }
}

exports.getWhatsAppQuality = onCall(async (request) => {
  const w = await wabaOf(request);
  const q = await qualityOf(w);
  const used = (await db.collection('usage').doc(`${w.uid}_${dayKey()}`).get()).data() || {};
  const cfg = await getConfig();
  const cap = cfg.dailyCampaignCap || DEFAULT_DAILY_CAMPAIGN_CAP;
  return { ...q, cap, usedToday: used.campaignSends || 0 };
});

function dayKey() {
  return new Date().toISOString().slice(0, 10);
}

/**
 * Sales campaign: the active sales bot opens conversations with an uploaded
 * list of opted-in numbers using an approved template. Safeguards:
 *  - the caller must state how the contacts opted in (stored per contact)
 *  - contacts who replied STOP are skipped
 *  - the template must tell people how to opt out (mentions STOP)
 *  - a daily cap per account, and no sending while the number's quality is RED
 * Replies are then handled by the sales bot (see processMessage / pickBot).
 */
exports.startSalesCampaign = onCall({ timeoutSeconds: 300 }, async (request) => {
  const w = await wabaOf(request);
  const { templateName, language, numbers, optInConfirmed, optInSource } = request.data || {};
  if (optInConfirmed !== true) {
    throw new HttpsError('failed-precondition', 'Confirm that every contact has opted in to WhatsApp messages from you.');
  }
  const source = String(optInSource || '').trim();
  if (source.length < 3) {
    throw new HttpsError('invalid-argument', 'Say how these contacts opted in (e.g. "website signup form").');
  }
  if (!templateName) throw new HttpsError('invalid-argument', 'Pick an approved template.');

  const userRef = db.collection('users').doc(w.uid);
  const bots = await userRef.collection('bots').where('active', '==', true).where('role', '==', 'sales').limit(1).get();
  if (bots.empty) throw new HttpsError('failed-precondition', 'Create and switch on a Sales bot first.');

  // The template must include an opt-out instruction.
  const tpl = await graph(
    'GET',
    `${w.id}/message_templates?name=${encodeURIComponent(templateName)}&fields=status,components`,
    w.token
  );
  const t = (tpl.data || [])[0];
  if (!t || t.status !== 'APPROVED') throw new HttpsError('failed-precondition', 'Template is not approved.');
  const tplText = (t.components || []).map((c) => c.text || '').join(' ').toLowerCase();
  if (!tplText.includes('stop')) {
    throw new HttpsError(
      'failed-precondition',
      'This template has no opt-out line. Create one that includes e.g. "Reply STOP to unsubscribe".'
    );
  }

  const q = await qualityOf(w);
  if (q.quality === 'RED') {
    throw new HttpsError('failed-precondition', 'Your number\'s quality rating is low (RED). Outreach is paused to protect it.');
  }

  const list = [...new Set((numbers || []).map((n) => String(n).replace(/\D/g, '')).filter((n) => n.length >= 8))];
  if (!list.length) throw new HttpsError('invalid-argument', 'No valid phone numbers.');
  if (list.length > 100) throw new HttpsError('invalid-argument', 'Max 100 numbers per campaign run.');

  const cfg = await getConfig();
  const cap = cfg.dailyCampaignCap || DEFAULT_DAILY_CAMPAIGN_CAP;
  const usageRef = db.collection('usage').doc(`${w.uid}_${dayKey()}`);
  const used = ((await usageRef.get()).data() || {}).campaignSends || 0;
  let remaining = cap - used;
  if (remaining <= 0) {
    throw new HttpsError('resource-exhausted', `Daily outreach limit reached (${cap}). Try again tomorrow.`);
  }

  let sent = 0;
  let skippedOptedOut = 0;
  let skippedCap = 0;
  const errors = [];
  for (const to of list) {
    if (remaining <= 0) { skippedCap++; continue; }
    const contactRef = userRef.collection('contacts').doc(`WhatsApp_${to}`);
    const contact = await contactRef.get();
    if (contact.exists && contact.data().optedOut) { skippedOptedOut++; continue; }
    try {
      const sj = await graph('POST', `${w.phoneNumberId}/messages`, w.token, {
        messaging_product: 'whatsapp',
        to,
        type: 'template',
        template: { name: templateName, language: { code: language || 'en_US' } },
      });
      await recordOutbox(userRef, { id: sj.messages && sj.messages[0] && sj.messages[0].id, to, kind: 'template', templateName, source: 'campaign' });
      sent++;
      remaining--;
      await usageRef.set({ campaignSends: FieldValue.increment(1), uid: w.uid }, { merge: true });
      const patch = { channel: 'WhatsApp', contactId: to, optedIn: true, optInSource: source };
      if (!contact.exists || !contact.data().optInAt) patch.optInAt = FieldValue.serverTimestamp();
      await contactRef.set(patch, { merge: true });
      const convoRef = userRef.collection('conversations').doc(`WhatsApp_${to}`);
      await convoRef.set(
        { channel: 'WhatsApp', contactId: to, contactName: to, botRole: 'sales', lastMessage: `[template] ${templateName}`, updatedAt: FieldValue.serverTimestamp() },
        { merge: true }
      );
      await convoRef.collection('messages').add({ role: 'bot', text: `[template: ${templateName}]`, createdAt: FieldValue.serverTimestamp() });
      await userRef.collection('leads').add({
        name: to, contact: to, channel: 'WhatsApp', intent: 'Sales outreach', tag: 'Outreach', createdAt: FieldValue.serverTimestamp(),
      });
    } catch (e) {
      errors.push(`${to}: ${e.message}`);
    }
    await new Promise((r) => setTimeout(r, 300)); // gentle pacing
  }
  await userRef.collection('notifications').add({
    title: 'Sales campaign finished',
    desc: `Sent ${sent} of ${list.length}. Skipped ${skippedOptedOut} opted-out, ${skippedCap} over the daily limit.`,
    type: 'bot',
    unread: true,
    createdAt: FieldValue.serverTimestamp(),
  });
  return { sent, failed: errors.length, skippedOptedOut, skippedCap, errors: errors.slice(0, 10), dailyCap: cap };
});


/**
 * A signed-in user deletes their own account: profile, WhatsApp/Instagram
 * connections and tokens, bots, leads, conversations, notifications and their
 * login. Payment records are kept because tax/accounting law requires it.
 */
exports.deleteMyAccount = onCall(async (request) => {
  if (!request.auth) throw new HttpsError('unauthenticated', 'Sign in first.');
  const uid = request.auth.uid;
  if (!request.data || request.data.confirm !== 'DELETE') {
    throw new HttpsError('failed-precondition', 'Type DELETE to confirm.');
  }
  await db.recursiveDelete(db.collection('users').doc(uid));
  const usage = await db.collection('usage').where('uid', '==', uid).get();
  await Promise.all(usage.docs.map((d) => d.ref.delete()));
  try {
    await admin.auth().deleteUser(uid);
  } catch (e) {
    if (e.code !== 'auth/user-not-found') throw e;
  }
  await logEvent('info', 'User deleted their own account', { uid });
  return { ok: true };
});
// Admin back-office callables (see admin.js).
Object.assign(exports, require('./admin'));

// Razorpay payment links + webhook. Off until its secrets exist: set
// ENABLE_RAZORPAY=true in functions/.env after running
// `firebase functions:secrets:set RAZORPAY_KEY_ID|RAZORPAY_KEY_SECRET|RAZORPAY_WEBHOOK_SECRET`.
if (process.env.ENABLE_RAZORPAY === 'true') {
  Object.assign(exports, require('./razorpay'));
}

// "Log in with Instagram" OAuth. Off until INSTAGRAM_APP_ID and the
// INSTAGRAM_APP_SECRET secret exist (see instagram.js), then set
// ENABLE_INSTAGRAM_LOGIN=true in functions/.env.
if (process.env.ENABLE_INSTAGRAM_LOGIN === 'true') {
  Object.assign(exports, require('./instagram'));
}
