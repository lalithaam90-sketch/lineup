// Delivery tracking for WhatsApp messages sent by LineUp.
// Every outgoing message is stored in users/{uid}/outbox/{wamid}. Meta then reports
// sent / delivered / read / failed (with an error code) through the webhook, and
// handleStatus() updates the record so the app can show why a message did not arrive.
const admin = require('firebase-admin');
const { logEvent } = require('./access');

const db = admin.firestore();
const { FieldValue } = admin.firestore;

const RANK = { sent: 1, delivered: 2, read: 3 };

// Plain-language reasons for the error codes people hit most.
const HINTS = {
  131047: 'Free-text messages only reach people who messaged you in the last 24 hours. Send an approved template instead.',
  131026: 'WhatsApp could not deliver this message. The number may not be on WhatsApp, or the user has not accepted the latest terms.',
  131030: 'This number is not on your allowed recipient list. With a Meta test number, add it as a recipient in the API setup page first.',
  131031: 'The WhatsApp Business account is restricted or locked. Check it in WhatsApp Manager.',
  131042: 'There is a payment-method problem on the WhatsApp Business account.',
  131048: 'Meta blocked this message as spam. Slow down, and check your template content and quality rating.',
  131049: 'Meta limited this message to protect user experience (marketing message limit). Try again later.',
  131051: 'Unsupported message type.',
  131053: 'Media could not be uploaded or downloaded.',
  132000: 'The template needs a different number of variables than were sent.',
  132001: 'The template does not exist in that language. Check the name and language.',
  132005: 'The translated text of the template is too long.',
  132007: 'The template text breaks Meta\'s content policy.',
  132012: 'A template variable has the wrong format.',
  132015: 'The template is paused because of low quality.',
  132016: 'The template is disabled after repeated low quality.',
  130429: 'Too many messages too fast. Slow down.',
  131056: 'Too many messages to the same person too fast. Try again later.',
  133010: 'This WhatsApp number is not registered.',
  190: 'The access token has expired or is invalid. Reconnect WhatsApp with a new token.',
};

function hintFor(code, fallback) {
  return HINTS[code] || fallback || 'WhatsApp could not deliver this message.';
}

/** Remember a message we just sent, so later delivery reports can be matched to it. */
async function recordOutbox(userRef, { id, to, kind, text, templateName, source }) {
  if (!id) return;
  await userRef.collection('outbox').doc(id).set(
    {
      to: String(to),
      kind, // 'text' | 'template'
      text: text ? String(text).slice(0, 300) : null,
      templateName: templateName || null,
      source: source || 'app', // 'app' (manual), 'bot' or 'campaign'
      status: 'sent',
      createdAt: FieldValue.serverTimestamp(),
    },
    { merge: true }
  );
}

/** Applies one entry of value.statuses from a WhatsApp webhook. */
async function handleStatus(user, st) {
  if (!st || !st.id) return;
  const ref = user.ref.collection('outbox').doc(st.id);
  const snap = await ref.get();
  const cur = snap.exists ? snap.data() : null;

  const update = { updatedAt: FieldValue.serverTimestamp() };
  if (!snap.exists) {
    // A message we did not record (for example sent from another tool): still keep it.
    update.to = String(st.recipient_id || '');
    update.kind = 'text';
    update.source = 'other';
    update.createdAt = FieldValue.serverTimestamp();
  }

  if (st.status === 'failed') {
    const e = (st.errors && st.errors[0]) || {};
    update.status = 'failed';
    update.errorCode = e.code || null;
    update.errorTitle = e.title || null;
    update.errorMessage = (e.error_data && e.error_data.details) || e.message || null;
    update.hint = hintFor(e.code, update.errorMessage);
    await ref.set(update, { merge: true });

    // Only alert once per message.
    if (!cur || cur.status !== 'failed') {
      const to = (cur && cur.to) || st.recipient_id || 'a contact';
      await user.ref.collection('notifications').add({
        title: 'Message not delivered',
        desc: `To ${to}: ${update.hint}`,
        type: 'bot',
        unread: true,
        createdAt: FieldValue.serverTimestamp(),
      });
      await logEvent('warn', 'WhatsApp delivery failed', { code: e.code || null, title: e.title || null });
    }
    return;
  }

  const rank = RANK[st.status];
  if (!rank) return; // ignore statuses we do not track
  if (cur && cur.status === 'failed') return; // failed is final
  if (cur && (RANK[cur.status] || 0) >= rank) return; // never move backwards
  update.status = st.status;
  update[`${st.status}At`] = FieldValue.serverTimestamp();
  await ref.set(update, { merge: true });
}

module.exports = { recordOutbox, handleStatus };
