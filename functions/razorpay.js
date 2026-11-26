// Razorpay payment links + webhook. Loaded only when ENABLE_RAZORPAY=true
// (functions/.env) so the rest of the backend deploys without Razorpay keys.
const crypto = require('crypto');
const { onCall, onRequest, HttpsError } = require('firebase-functions/v2/https');
const { defineSecret } = require('firebase-functions/params');
const logger = require('firebase-functions/logger');
const admin = require('firebase-admin');
const { audit, logEvent, assertAdmin } = require('./access');

const db = admin.firestore();
const { FieldValue, Timestamp } = admin.firestore;

const RAZORPAY_KEY_ID = defineSecret('RAZORPAY_KEY_ID');
const RAZORPAY_KEY_SECRET = defineSecret('RAZORPAY_KEY_SECRET');
const RAZORPAY_WEBHOOK_SECRET = defineSecret('RAZORPAY_WEBHOOK_SECRET');


/** Admin creates a payment link for a user + plan and shares the short URL. */
exports.adminCreatePaymentLink = onCall(
  { secrets: [RAZORPAY_KEY_ID, RAZORPAY_KEY_SECRET] },
  async (request) => {
    const adminEmail = assertAdmin(request);
    const { uid, planId } = request.data || {};
    if (!uid || !planId) throw new HttpsError('invalid-argument', 'uid and planId required.');
    const plan = await db.collection('plans').doc(planId).get();
    if (!plan.exists || !(plan.data().priceInr > 0)) {
      throw new HttpsError('failed-precondition', 'Plan missing or has no price.');
    }
    const user = (await db.collection('users').doc(uid).get()).data() || {};
    const auth = Buffer.from(`${RAZORPAY_KEY_ID.value()}:${RAZORPAY_KEY_SECRET.value()}`).toString('base64');
    const r = await fetch('https://api.razorpay.com/v1/payment_links', {
      method: 'POST',
      headers: { Authorization: `Basic ${auth}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({
        amount: Math.round(plan.data().priceInr * 100),
        currency: 'INR',
        description: `LineUp ${plan.data().name} plan`,
        customer: user.userName ? { name: user.userName } : undefined,
        notes: { uid, planId },
        reminder_enable: false,
      }),
    });
    const j = await r.json().catch(() => ({}));
    if (!r.ok) {
      throw new HttpsError('failed-precondition', (j.error && j.error.description) || `Razorpay error ${r.status}`);
    }
    await audit(adminEmail, 'payment_link.create', uid, { planId, linkId: j.id });
    return { url: j.short_url, id: j.id };
  }
);

/** Razorpay -> LineUp. Marks the payment and activates/extends the plan. */
exports.razorpayWebhook = onRequest({ secrets: [RAZORPAY_WEBHOOK_SECRET] }, async (req, res) => {
  const sig = req.get('x-razorpay-signature') || '';
  const expected = crypto.createHmac('sha256', RAZORPAY_WEBHOOK_SECRET.value()).update(req.rawBody).digest('hex');
  const a = Buffer.from(sig);
  const b = Buffer.from(expected);
  if (a.length !== b.length || !crypto.timingSafeEqual(a, b)) return res.sendStatus(401);

  try {
    if (req.body.event === 'payment_link.paid') {
      const link = req.body.payload.payment_link.entity;
      const pay = req.body.payload.payment.entity;
      const { uid, planId } = link.notes || {};
      const payRef = db.collection('payments').doc(pay.id); // idempotent on retries
      if (!(await payRef.get()).exists && uid && planId) {
        const plan = (await db.collection('plans').doc(planId).get()).data() || {};
        await payRef.set({
          uid,
          amountInr: pay.amount / 100,
          method: pay.method || 'razorpay',
          reference: pay.id,
          planId,
          source: 'razorpay',
          createdAt: FieldValue.serverTimestamp(),
        });
        const userRef = db.collection('users').doc(uid);
        const cur = (await userRef.get()).data() || {};
        const base = cur.plan && cur.plan.expiresAt && cur.plan.expiresAt.toMillis() > Date.now()
          ? cur.plan.expiresAt.toMillis()
          : Date.now();
        await userRef.set(
          {
            plan: {
              id: planId,
              name: plan.name || planId,
              expiresAt: Timestamp.fromMillis(base + (plan.intervalDays || 30) * 86400000),
              setAt: FieldValue.serverTimestamp(),
            },
          },
          { merge: true }
        );
        await userRef.collection('notifications').add({
          title: 'Payment received',
          desc: `Your ${plan.name || planId} plan is active.`,
          type: 'profile',
          unread: true,
          createdAt: FieldValue.serverTimestamp(),
        });
      }
    }
  } catch (e) {
    logger.error('Razorpay webhook failed', e);
    await logEvent('error', 'Razorpay webhook failed: ' + (e && e.message), null);
    return res.sendStatus(500); // let Razorpay retry
  }
  res.sendStatus(200);
});

/** A signed-in customer pays for a plan: returns a Razorpay payment link to open. */
exports.createMyPaymentLink = onCall(
  { secrets: [RAZORPAY_KEY_ID, RAZORPAY_KEY_SECRET] },
  async (request) => {
    if (!request.auth) throw new HttpsError('unauthenticated', 'Sign in first.');
    const uid = request.auth.uid;
    const { planId } = request.data || {};
    if (!planId) throw new HttpsError('invalid-argument', 'Pick a plan.');
    const plan = await db.collection('plans').doc(planId).get();
    if (!plan.exists || plan.data().active === false || !(plan.data().priceInr > 0)) {
      throw new HttpsError('failed-precondition', 'This plan is not available.');
    }
    const user = (await db.collection('users').doc(uid).get()).data() || {};
    const auth = Buffer.from(`${RAZORPAY_KEY_ID.value()}:${RAZORPAY_KEY_SECRET.value()}`).toString('base64');
    const r = await fetch('https://api.razorpay.com/v1/payment_links', {
      method: 'POST',
      headers: { Authorization: `Basic ${auth}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({
        amount: Math.round(plan.data().priceInr * 100),
        currency: 'INR',
        description: `LineUp ${plan.data().name} plan`,
        customer: user.userName ? { name: user.userName } : undefined,
        notes: { uid, planId },
        reminder_enable: false,
        callback_url: 'https://app.lineuptech.in/?pay=done',
        callback_method: 'get',
      }),
    });
    const j = await r.json().catch(() => ({}));
    if (!r.ok) {
      throw new HttpsError('failed-precondition', (j.error && j.error.description) || `Razorpay error ${r.status}`);
    }
    return { url: j.short_url };
  }
);
