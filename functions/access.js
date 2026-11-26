// Shared helpers: audit log, platform config, and "may this account use the
// service right now?" Kept separate from admin.js so it exports no triggers.
const { HttpsError } = require('firebase-functions/v2/https');
const admin = require('firebase-admin');

const db = admin.firestore();
const { FieldValue } = admin.firestore;

async function audit(adminEmail, action, targetUid, details) {
  await db.collection('auditLogs').add({
    admin: adminEmail,
    action,
    targetUid: targetUid || null,
    details: details || {},
    createdAt: FieldValue.serverTimestamp(),
  });
}

let cfgCache = { at: 0, data: {} };
async function getConfig() {
  if (Date.now() - cfgCache.at < 60000) return cfgCache.data;
  const s = await db.collection('config').doc('platform').get();
  cfgCache = { at: Date.now(), data: s.data() || {} };
  return cfgCache.data;
}
function clearConfigCache() {
  cfgCache = { at: 0, data: {} };
}

/**
 * Whether a user's account may use the service right now.
 * - suspended -> no
 * - no status + platform requires approval -> no (pending)
 * - plan present and expired -> no
 */
async function accessDecision(userData) {
  const cfg = await getConfig();
  const status = userData.status || (cfg.requireApproval ? 'pending' : 'active');
  if (status !== 'active') return { allowed: false, reason: `Account ${status}.` };
  const exp = userData.plan && userData.plan.expiresAt;
  if (exp && exp.toMillis && exp.toMillis() < Date.now()) {
    return { allowed: false, reason: 'Your plan has expired. Contact LineUp to renew.' };
  }
  return { allowed: true };
}

/** Records a platform problem so admins can see it in the admin page. */
async function logEvent(level, message, details) {
  try {
    await db.collection('systemEvents').add({
      level,
      message: String(message).slice(0, 500),
      details: details ? JSON.parse(JSON.stringify(details)) : null,
      createdAt: FieldValue.serverTimestamp(),
    });
  } catch (_) {
    /* never let logging break a request */
  }
}



// Dedicated admin login accounts (email + password, created by hand in the
// Firebase console). Keep in sync with isAdmin() in firestore.rules.
// Only password sign-ins count, so a Google/phone login can never be admin.
const ADMIN_EMAILS = ['control@lineuptech.admin'];

function assertAdmin(request) {
  const t = request.auth && request.auth.token;
  const viaPassword = t && t.firebase && t.firebase.sign_in_provider === 'password';
  if (!t || !viaPassword || !ADMIN_EMAILS.includes(t.email)) {
    throw new HttpsError('permission-denied', 'Admins only.');
  }
  return t.email;
}

module.exports = { audit, getConfig, clearConfigCache, accessDecision, logEvent, assertAdmin };
