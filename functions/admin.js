// Admin back-office functions for LineUp. Every callable here re-checks that
// the caller is an admin on the server; the admin web app is not trusted.
const { onCall, HttpsError } = require('firebase-functions/v2/https');
const admin = require('firebase-admin');

const { audit, getConfig, clearConfigCache, assertAdmin } = require('./access');

const db = admin.firestore();
const { FieldValue, Timestamp } = admin.firestore;



function need(v, msg) {
  if (v === undefined || v === null || v === '') throw new HttpsError('invalid-argument', msg);
  return v;
}

const ms = (t) => (t && t.toMillis ? t.toMillis() : null);

// ---- Platform config & access decisions (also used by the message backend) --

// ---- Callables -------------------------------------------------------------

exports.adminListUsers = onCall(async (request) => {
  assertAdmin(request);
  const cfg = await getConfig();
  const authUsers = new Map();
  let page;
  do {
    const res = await admin.auth().listUsers(1000, page);
    res.users.forEach((u) => authUsers.set(u.uid, u));
    page = res.pageToken;
  } while (page && authUsers.size < 5000);
  const docs = await db.collection('users').get();
  const byUid = new Map(docs.docs.map((d) => [d.id, d.data()]));

  const users = [...authUsers.values()].map((u) => {
    const d = byUid.get(u.uid) || {};
    return {
      uid: u.uid,
      phone: u.phoneNumber || null,
      email: u.email || d.userEmail || null,
      disabled: u.disabled,
      createdAt: Date.parse(u.metadata.creationTime) || null,
      lastSignIn: Date.parse(u.metadata.lastSignInTime) || null,
      name: d.userName || '',
      business: d.businessName || '',
      status: d.status || (cfg.requireApproval ? 'pending' : 'active'),
      planId: (d.plan && d.plan.id) || null,
      planExpiresAt: d.plan && d.plan.expiresAt ? ms(d.plan.expiresAt) : null,
      whatsapp: !!d.wabaConnected,
      instagram: !!d.igConnected,
    };
  });
  users.sort((a, b) => (b.createdAt || 0) - (a.createdAt || 0));
  return { users, requireApproval: !!cfg.requireApproval };
});

exports.adminGetUser = onCall(async (request) => {
  assertAdmin(request);
  const uid = need(request.data && request.data.uid, 'uid required');
  const ref = db.collection('users').doc(uid);
  const [doc, bots, leads, convos, notifs, pays] = await Promise.all([
    ref.get(),
    ref.collection('bots').get(),
    ref.collection('leads').orderBy('createdAt', 'desc').limit(25).get(),
    ref.collection('conversations').orderBy('updatedAt', 'desc').limit(25).get(),
    ref.collection('notifications').orderBy('createdAt', 'desc').limit(10).get(),
    db.collection('payments').where('uid', '==', uid).orderBy('createdAt', 'desc').limit(25).get(),
  ]);
  const d = doc.data() || {};
  // Never return secrets to the browser.
  delete d.wabaAccessToken;
  delete d.igAccessToken;
  const clean = (o) => JSON.parse(JSON.stringify(o, (k, v) => (v && v._seconds !== undefined ? v._seconds * 1000 : v)));
  const rows = (snap) => snap.docs.map((x) => clean({ id: x.id, ...x.data() }));
  return clean({
    profile: d,
    bots: rows(bots),
    leads: rows(leads),
    conversations: rows(convos),
    notifications: rows(notifs),
    payments: rows(pays),
  });
});

exports.adminSetUserStatus = onCall(async (request) => {
  const who = assertAdmin(request);
  const { uid, status, reason } = request.data || {};
  need(uid, 'uid required');
  if (!['active', 'suspended'].includes(status)) throw new HttpsError('invalid-argument', 'Bad status.');
  await db.collection('users').doc(uid).set(
    { status, statusReason: reason || null, statusChangedAt: FieldValue.serverTimestamp() },
    { merge: true }
  );
  await admin.auth().updateUser(uid, { disabled: status === 'suspended' });
  if (status === 'suspended') await admin.auth().revokeRefreshTokens(uid);
  await audit(who, `user.${status === 'active' ? 'approve_or_enable' : 'suspend'}`, uid, { reason: reason || null });
  return { ok: true };
});

exports.adminSetPlan = onCall(async (request) => {
  const who = assertAdmin(request);
  const { uid, planId, expiresAt } = request.data || {};
  need(uid, 'uid required');
  const ref = db.collection('users').doc(uid);
  if (!planId) {
    await ref.set({ plan: FieldValue.delete() }, { merge: true });
    await audit(who, 'plan.remove', uid, {});
    return { ok: true };
  }
  const plan = await db.collection('plans').doc(planId).get();
  if (!plan.exists) throw new HttpsError('not-found', 'Plan not found.');
  const exp = expiresAt ? Timestamp.fromDate(new Date(expiresAt)) : null;
  await ref.set(
    { plan: { id: planId, name: plan.data().name, expiresAt: exp, setAt: FieldValue.serverTimestamp() } },
    { merge: true }
  );
  await audit(who, 'plan.set', uid, { planId, expiresAt: expiresAt || null });
  return { ok: true };
});

exports.adminSavePlan = onCall(async (request) => {
  const who = assertAdmin(request);
  const p = request.data || {};
  const id = String(need(p.id, 'Plan id required')).toLowerCase().replace(/[^a-z0-9_-]/g, '');
  if (!id) throw new HttpsError('invalid-argument', 'Plan id invalid.');
  const data = {
    name: String(need(p.name, 'Name required')),
    priceInr: Number(p.priceInr) || 0,
    intervalDays: Number(p.intervalDays) || 30,
    maxBots: Number(p.maxBots) || 0,
    maxConversations: Number(p.maxConversations) || 0,
    active: p.active !== false,
    updatedAt: FieldValue.serverTimestamp(),
  };
  await db.collection('plans').doc(id).set(data, { merge: true });
  await audit(who, 'plan.save', null, { id, ...data, updatedAt: undefined });
  return { ok: true, id };
});

exports.adminRecordPayment = onCall(async (request) => {
  const who = assertAdmin(request);
  const { uid, amountInr, method, reference, planId, extendDays, note } = request.data || {};
  need(uid, 'uid required');
  const amount = Number(amountInr);
  if (!(amount > 0)) throw new HttpsError('invalid-argument', 'Amount must be positive.');
  const pay = await db.collection('payments').add({
    uid,
    amountInr: amount,
    method: method || 'manual',
    reference: reference || null,
    planId: planId || null,
    note: note || null,
    source: 'admin',
    recordedBy: who,
    createdAt: FieldValue.serverTimestamp(),
  });
  if (planId && Number(extendDays) > 0) {
    const plan = await db.collection('plans').doc(planId).get();
    if (!plan.exists) throw new HttpsError('not-found', 'Plan not found.');
    const ref = db.collection('users').doc(uid);
    const cur = (await ref.get()).data() || {};
    const base = cur.plan && cur.plan.expiresAt && cur.plan.expiresAt.toMillis() > Date.now()
      ? cur.plan.expiresAt.toMillis()
      : Date.now();
    await ref.set(
      {
        plan: {
          id: planId,
          name: plan.data().name,
          expiresAt: Timestamp.fromMillis(base + Number(extendDays) * 86400000),
          setAt: FieldValue.serverTimestamp(),
        },
      },
      { merge: true }
    );
  }
  await audit(who, 'payment.record', uid, { amountInr: amount, paymentId: pay.id, planId: planId || null });
  return { ok: true, id: pay.id };
});

exports.adminSendNotification = onCall(async (request) => {
  const who = assertAdmin(request);
  const { uid, title, desc } = request.data || {};
  need(uid, 'uid required');
  await db.collection('users').doc(uid).collection('notifications').add({
    title: String(need(title, 'Title required')),
    desc: String(desc || ''),
    type: 'profile',
    unread: true,
    createdAt: FieldValue.serverTimestamp(),
  });
  await audit(who, 'notify', uid, { title });
  return { ok: true };
});

exports.adminSetNote = onCall(async (request) => {
  const who = assertAdmin(request);
  const { uid, note } = request.data || {};
  need(uid, 'uid required');
  await db.collection('users').doc(uid).set({ adminNote: String(note || '') }, { merge: true });
  await audit(who, 'note', uid, {});
  return { ok: true };
});

exports.adminSetConfig = onCall(async (request) => {
  const who = assertAdmin(request);
  const { requireApproval } = request.data || {};
  if (requireApproval) {
    // Don't lock out people who are already using the app: mark every
    // existing account that has no status as active before switching on.
    const all = await db.collection('users').get();
    const missing = all.docs.filter((d) => !d.data().status);
    for (let i = 0; i < missing.length; i += 400) {
      const batch = db.batch();
      missing.slice(i, i + 400).forEach((d) => batch.set(d.ref, { status: 'active' }, { merge: true }));
      await batch.commit();
    }
  }
  await db.collection('config').doc('platform').set({ requireApproval: !!requireApproval }, { merge: true });
  clearConfigCache();
  await audit(who, 'config.set', null, { requireApproval: !!requireApproval });
  return { ok: true };
});

exports.adminDeleteUser = onCall(async (request) => {
  const who = assertAdmin(request);
  const { uid, confirm } = request.data || {};
  need(uid, 'uid required');
  if (confirm !== uid) throw new HttpsError('failed-precondition', 'Type the uid to confirm deletion.');
  await db.recursiveDelete(db.collection('users').doc(uid));
  try {
    await admin.auth().deleteUser(uid);
  } catch (e) {
    if (e.code !== 'auth/user-not-found') throw e;
  }
  await audit(who, 'user.delete', uid, {});
  return { ok: true };
});

exports.adminStats = onCall(async (request) => {
  assertAdmin(request);
  const c = async (q) => (await q.count().get()).data().count;
  const users = db.collection('users');
  const [total, suspended, waba, ig, bots, leads, payments] = await Promise.all([
    c(users),
    c(users.where('status', '==', 'suspended')),
    c(users.where('wabaConnected', '==', true)),
    c(users.where('igConnected', '==', true)),
    c(db.collectionGroup('bots')),
    c(db.collectionGroup('leads')),
    c(db.collection('payments')),
  ]);
  const since = Timestamp.fromMillis(Date.now() - 30 * 86400000);
  const recent = await db.collection('payments').where('createdAt', '>=', since).get();
  const revenue30d = recent.docs.reduce((s, d) => s + (d.data().amountInr || 0), 0);
  return { total, suspended, waba, ig, bots, leads, payments, revenue30d };
});


/** Recent bots or leads across all users (admin list views). */
exports.adminListGroup = onCall(async (request) => {
  assertAdmin(request);
  const kind = request.data && request.data.kind;
  if (!['bots', 'leads'].includes(kind)) throw new HttpsError('invalid-argument', 'Bad kind.');
  const snap = await db.collectionGroup(kind).orderBy('createdAt', 'desc').limit(200).get();
  const uids = [...new Set(snap.docs.map((d) => d.ref.parent.parent.id))];
  const owners = new Map();
  for (let i = 0; i < uids.length; i += 30) {
    const docs = await db.getAll(...uids.slice(i, i + 30).map((u) => db.collection('users').doc(u)));
    docs.forEach((d) => owners.set(d.id, d.data() || {}));
  }
  const items = snap.docs.map((d) => {
    const uid = d.ref.parent.parent.id;
    const o = owners.get(uid) || {};
    const data = d.data();
    return {
      id: d.id,
      uid,
      owner: o.businessName || o.userName || uid,
      ...data,
      createdAt: data.createdAt && data.createdAt.toMillis ? data.createdAt.toMillis() : null,
    };
  });
  return { items };
});
