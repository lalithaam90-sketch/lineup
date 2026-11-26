import { initializeApp } from 'https://www.gstatic.com/firebasejs/11.0.2/firebase-app.js';
import {
  getAuth, signInWithEmailAndPassword, onAuthStateChanged, signOut,
} from 'https://www.gstatic.com/firebasejs/11.0.2/firebase-auth.js';
import {
  getFirestore, collection, query, orderBy, limit, getDocs,
} from 'https://www.gstatic.com/firebasejs/11.0.2/firebase-firestore.js';
import { getFunctions, httpsCallable } from 'https://www.gstatic.com/firebasejs/11.0.2/firebase-functions.js';

const app = initializeApp({
  apiKey: 'AIzaSyB2iIUXqYmew7vioxGkwI80vlk38yumIq8',
  authDomain: 'lineup-32c58.firebaseapp.com',
  projectId: 'lineup-32c58',
  appId: '1:1010886601242:web:281866364db8f544307fa3',
});
const auth = getAuth(app);
const db = getFirestore(app);
const fns = getFunctions(app, 'us-central1');
const call = (name, data) => httpsCallable(fns, name)(data || {}).then((r) => r.data);

// ---- tiny helpers (all user data goes through esc() / textContent) ---------
const $ = (s) => document.querySelector(s);
const esc = (v) => String(v ?? '').replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
const fmtDate = (ms) => (ms ? new Date(ms).toLocaleString() : '-');
const tsMs = (t) => (t && t.toMillis ? t.toMillis() : null);
const inr = (n) => '₹' + Number(n || 0).toLocaleString('en-IN');
function toast(msg) {
  const t = $('#toast');
  t.textContent = msg;
  t.style.display = 'block';
  clearTimeout(toast.tm);
  toast.tm = setTimeout(() => (t.style.display = 'none'), 3500);
}
async function guard(fn) {
  try {
    return await fn();
  } catch (e) {
    toast(e.message || String(e));
    console.error(e);
  }
}

// ---- auth ----------------------------------------------------------------
$('#loginForm').onsubmit = (e) => {  e.preventDefault();  $('#loginErr').textContent = '';  signInWithEmailAndPassword(auth, $('#email').value.trim(), $('#password').value)    .then(() => ($('#password').value = ''))    .catch(() => ($('#loginErr').textContent = 'Wrong email or password.'));};
$('#signout').onclick = () => signOut(auth);

const TABS = ['Dashboard', 'Users', 'Plans', 'Payments', 'Audit log', 'Settings'];
let tab = 'Dashboard';

onAuthStateChanged(auth, async (user) => {
  if (!user) {
    $('#app').classList.add('hidden');
    $('#login').classList.remove('hidden');
    return;
  }
  try {
    await call('adminStats'); // server-side admin check
  } catch (e) {
    $('#loginErr').textContent = `${user.email} is not an authorised admin.`;
    await signOut(auth);
    return;
  }
  $('#loginErr').textContent = '';
  $('#login').classList.add('hidden');
  $('#app').classList.remove('hidden');
  $('#who').textContent = user.email;
  renderNav();
  show(tab);
});

function renderNav() {
  const nav = $('#nav');
  nav.innerHTML = '';
  TABS.forEach((t) => {
    const b = document.createElement('button');
    b.textContent = t;
    b.className = t === tab ? 'on' : '';
    b.onclick = () => {
      tab = t;
      renderNav();
      show(t);
    };
    nav.appendChild(b);
  });
}

function show(t) {
  const v = $('#view');
  v.innerHTML = '<p class="muted">Loading…</p>';
  guard(() => ({ Dashboard, Users, Plans, Payments, 'Audit log': Audit, Settings })[t](v));
}

// ---- Dashboard -----------------------------------------------------------
async function Dashboard(v) {
  const [s, ev] = await Promise.all([
    call('adminStats'),
    getDocs(query(collection(db, 'systemEvents'), orderBy('createdAt', 'desc'), limit(20))),
  ]);
  const stat = (n, l, go) => `<div class="card stat click" role="button" tabindex="0" data-go="${esc(go)}"><b>${esc(n)}</b><span>${esc(l)}</span></div>`;
  v.innerHTML = `
    <div class="grid">
      ${stat(s.total, 'Users', 'users:')}${stat(s.suspended, 'Suspended', 'users:suspended')}${stat(s.waba, 'WhatsApp connected', 'users:wa')}
      ${stat(s.ig, 'Instagram connected', 'users:ig')}${stat(s.bots, 'Bots', 'bots')}${stat(s.leads, 'Leads', 'leads')}
      ${stat(s.payments, 'Payments', 'payments')}${stat(inr(s.revenue30d), 'Revenue (30 days)', 'payments')}
    </div>
    <div class="card"><h2>Recent platform errors</h2>
    <div class="wrap"><table><tr><th>When</th><th>Level</th><th>Message</th></tr>
    ${ev.docs.map((d) => { const e = d.data(); return `<tr class="click ev"><td>${esc(fmtDate(tsMs(e.createdAt)))}</td><td>${esc(e.level)}</td><td>${esc(e.message)}<div class="muted hidden" style="white-space:pre-wrap">${esc(JSON.stringify(e.details || {}, null, 2))}</div></td></tr>`; }).join('') || '<tr><td colspan="3" class="muted">No errors recorded.</td></tr>'}
    </table></div></div>`;
}

// ---- Users ---------------------------------------------------------------
let usersCache = null;
async function Users(v, preset = '') {
  const res = await call('adminListUsers');
  usersCache = res.users;
  v.innerHTML = `
    <div class="card">
      <div class="row">
        <input id="q" placeholder="Search name, business, phone, email, uid" style="flex:1;min-width:200px">
        <select id="f"><option value="">All statuses</option><option>active</option><option>pending</option><option>suspended</option><option value="wa">WhatsApp connected</option><option value="ig">Instagram connected</option></select>
        <span class="muted" id="count"></span>
      </div>
      <div class="wrap"><table id="ut"></table></div>
    </div>
    <div id="detail"></div>`;
  const draw = () => {
    const q = $('#q').value.toLowerCase();
    const f = $('#f').value;
    const rows = usersCache.filter((u) =>
      (!f || (f === 'wa' ? u.whatsapp : f === 'ig' ? u.instagram : u.status === f)) &&
      (!q || [u.name, u.business, u.phone, u.email, u.uid].some((x) => String(x || '').toLowerCase().includes(q))));
    $('#count').textContent = `${rows.length} of ${usersCache.length}`;
    $('#ut').innerHTML = `<tr><th>User</th><th>Business</th><th>Status</th><th>Plan</th><th>Channels</th><th>Joined</th></tr>` +
      rows.map((u) => `<tr class="click" data-uid="${esc(u.uid)}">
        <td>${esc(u.name || u.phone || u.email || u.uid)}<div class="muted">${esc(u.phone || u.email || '')}</div></td>
        <td>${esc(u.business)}</td>
        <td><span class="pill ${esc(u.status)}">${esc(u.status)}</span>${u.disabled ? ' <span class="muted">(login off)</span>' : ''}</td>
        <td>${esc(u.planId || '-')}${u.planExpiresAt ? `<div class="muted">until ${esc(new Date(u.planExpiresAt).toLocaleDateString())}</div>` : ''}</td>
        <td>${u.whatsapp ? 'WhatsApp ' : ''}${u.instagram ? 'Instagram' : ''}${!u.whatsapp && !u.instagram ? '-' : ''}</td>
        <td>${esc(fmtDate(u.createdAt))}</td></tr>`).join('');
    document.querySelectorAll('#ut tr.click').forEach((r) => (r.onclick = () => guard(() => UserDetail(r.dataset.uid))));
  };
  $('#f').value = preset;
  $('#q').oninput = draw;
  $('#f').onchange = draw;
  draw();
}

async function UserDetail(uid) {
  const [d, plansSnap] = await Promise.all([
    call('adminGetUser', { uid }),
    getDocs(collection(db, 'plans')),
  ]);
  const u = usersCache.find((x) => x.uid === uid) || { uid };
  const p = d.profile || {};
  const plans = plansSnap.docs.map((x) => ({ id: x.id, ...x.data() }));
  const box = $('#detail');
  box.innerHTML = `
  <div class="card">
    <div class="row"><h2 style="margin:0;flex:1">${esc(u.name || u.phone || u.email || uid)}</h2>
      <span class="pill ${esc(u.status)}">${esc(u.status)}</span></div>
    <p class="muted">uid ${esc(uid)} · ${esc(u.phone || '')} ${esc(u.email || '')} · business: ${esc(p.businessName || '-')} · website: ${esc(p.website || '-')} · GST: ${esc(p.gst || '-')}</p>
    <p>WhatsApp: ${p.wabaConnected ? `connected (${esc(p.wabaPhoneNumber || '')}, ${esc(p.wabaBusinessName || '')})` : 'not connected'}
       · Instagram: ${p.igConnected ? `connected (${esc(p.igAccount || '')})` : 'not connected'}
       · Bots: ${d.bots.length} · Leads shown: ${d.leads.length}</p>
    ${p.statusReason ? `<p class="muted">Last status reason: ${esc(p.statusReason)}</p>` : ''}

    <h3>Account</h3>
    <div class="row">
      <input id="reason" placeholder="Reason (optional)" style="flex:1;min-width:160px">
      <button class="btn primary" id="approve">Approve / enable</button>
      <button class="btn danger" id="suspend">Suspend</button>
    </div>

    <h3>Plan</h3>
    <div class="row">
      <select id="plan"><option value="">No plan</option>${plans.map((x) => `<option value="${esc(x.id)}" ${p.plan && p.plan.id === x.id ? 'selected' : ''}>${esc(x.name)} (${inr(x.priceInr)})</option>`).join('')}</select>
      <input id="exp" type="date" value="${p.plan && p.plan.expiresAt ? esc(new Date(p.plan.expiresAt).toISOString().slice(0, 10)) : ''}">
      <button class="btn" id="setplan">Save plan</button>
    </div>

    <h3>Record payment</h3>
    <div class="row">
      <input id="amt" type="number" min="1" placeholder="Amount ₹" style="width:110px">
      <select id="method"><option>upi</option><option>bank</option><option>cash</option><option>other</option></select>
      <input id="ref" placeholder="Reference / txn id">
      <input id="days" type="number" min="0" placeholder="Extend plan (days)" style="width:150px">
      <button class="btn" id="pay">Record</button>
      <button class="btn" id="plink">Create Razorpay link</button>
    </div>
    <div id="linkOut" class="muted"></div>

    <h3>Message the user (shows in their app)</h3>
    <div class="row"><input id="ntitle" placeholder="Title" style="flex:1"><input id="ndesc" placeholder="Message" style="flex:2;min-width:200px"><button class="btn" id="notify">Send</button></div>

    <h3>Internal note</h3>
    <textarea id="note" rows="2">${esc(p.adminNote || '')}</textarea>
    <div class="row"><button class="btn" id="savenote">Save note</button></div>

    <h3>Bots (${d.bots.length})</h3>
    <div class="wrap"><table><tr><th>Name</th><th>Role</th><th>Active</th><th>Conversations</th></tr>
      ${d.bots.map((b) => `<tr><td>${esc(b.name)}</td><td>${esc(b.role)}</td><td>${b.active ? 'yes' : 'no'}</td><td>${esc(b.totalConversations || 0)}</td></tr>`).join('') || '<tr><td colspan="4" class="muted">None</td></tr>'}</table></div>

    <h3>Recent leads</h3>
    <div class="wrap"><table><tr><th>Name</th><th>Contact</th><th>Channel</th><th>Intent</th><th>When</th></tr>
      ${d.leads.map((l) => `<tr><td>${esc(l.name)}</td><td>${esc(l.contact)}</td><td>${esc(l.channel)}</td><td>${esc(l.intent)}</td><td>${esc(fmtDate(l.createdAt))}</td></tr>`).join('') || '<tr><td colspan="5" class="muted">None</td></tr>'}</table></div>

    <h3>Recent conversations</h3>
    <div class="wrap"><table><tr><th>Contact</th><th>Channel</th><th>Last message</th><th>Updated</th></tr>
      ${d.conversations.map((c) => `<tr><td>${esc(c.contactName || c.contactId)}</td><td>${esc(c.channel)}</td><td>${esc(c.lastMessage)}</td><td>${esc(fmtDate(c.updatedAt))}</td></tr>`).join('') || '<tr><td colspan="4" class="muted">None</td></tr>'}</table></div>

    <h3>Payments</h3>
    <div class="wrap"><table><tr><th>When</th><th>Amount</th><th>Method</th><th>Plan</th><th>Ref</th></tr>
      ${d.payments.map((x) => `<tr><td>${esc(fmtDate(x.createdAt))}</td><td>${inr(x.amountInr)}</td><td>${esc(x.method)}</td><td>${esc(x.planId || '-')}</td><td>${esc(x.reference || '')}</td></tr>`).join('') || '<tr><td colspan="5" class="muted">None</td></tr>'}</table></div>

    <h3>Danger zone</h3>
    <div class="row"><input id="delc" placeholder="Type the uid to confirm" style="flex:1;min-width:220px"><button class="btn danger" id="del">Delete user and all data</button></div>
  </div>`;
  box.scrollIntoView({ behavior: 'smooth' });

  const refresh = async () => { await Users($('#view')); UserDetail(uid); };
  $('#approve').onclick = () => guard(async () => { await call('adminSetUserStatus', { uid, status: 'active', reason: $('#reason').value }); toast('Account active'); await refresh(); });
  $('#suspend').onclick = () => guard(async () => { await call('adminSetUserStatus', { uid, status: 'suspended', reason: $('#reason').value }); toast('Account suspended'); await refresh(); });
  $('#setplan').onclick = () => guard(async () => { await call('adminSetPlan', { uid, planId: $('#plan').value, expiresAt: $('#exp').value || null }); toast('Plan saved'); await refresh(); });
  $('#pay').onclick = () => guard(async () => {
    await call('adminRecordPayment', { uid, amountInr: $('#amt').value, method: $('#method').value, reference: $('#ref').value, planId: $('#plan').value || null, extendDays: $('#days').value });
    toast('Payment recorded'); await refresh();
  });
  $('#plink').onclick = () => guard(async () => {
    if (!$('#plan').value) return toast('Pick a plan first');
    const r = await call('adminCreatePaymentLink', { uid, planId: $('#plan').value });
    $('#linkOut').innerHTML = `Payment link: <a href="${esc(r.url)}" target="_blank" rel="noopener">${esc(r.url)}</a>`;
  });
  $('#notify').onclick = () => guard(async () => { await call('adminSendNotification', { uid, title: $('#ntitle').value, desc: $('#ndesc').value }); toast('Sent'); });
  $('#savenote').onclick = () => guard(async () => { await call('adminSetNote', { uid, note: $('#note').value }); toast('Note saved'); });
  $('#del').onclick = () => guard(async () => {
    if (!confirm('Permanently delete this user, their data and login? This cannot be undone.')) return;
    await call('adminDeleteUser', { uid, confirm: $('#delc').value.trim() });
    toast('User deleted'); $('#detail').innerHTML = ''; Users($('#view'));
  });
}

// ---- Plans ---------------------------------------------------------------
async function Plans(v) {
  const snap = await getDocs(collection(db, 'plans'));
  const plans = snap.docs.map((d) => ({ id: d.id, ...d.data() }));
  v.innerHTML = `
    <div class="card"><h2>Plans</h2>
    <div class="wrap"><table><tr><th>Id</th><th>Name</th><th>Price</th><th>Days</th><th>Max bots</th><th>Max conversations</th><th>Active</th><th></th></tr>
    ${plans.map((p) => `<tr class="click" data-edit="${esc(p.id)}"><td>${esc(p.id)}</td><td>${esc(p.name)}</td><td>${inr(p.priceInr)}</td><td>${esc(p.intervalDays)}</td><td>${esc(p.maxBots || '-')}</td><td>${esc(p.maxConversations || '-')}</td><td>${p.active === false ? 'no' : 'yes'}</td><td><button class="btn" data-edit="${esc(p.id)}">Edit</button></td></tr>`).join('') || '<tr><td colspan="8" class="muted">No plans yet.</td></tr>'}
    </table></div></div>
    <div class="card"><h2 id="ph">New plan</h2>
      <div class="row">
        <input id="pid" placeholder="id (e.g. pro)"><input id="pname" placeholder="Name">
        <input id="pprice" type="number" min="0" placeholder="Price ₹"><input id="pdays" type="number" min="1" placeholder="Days (30)">
        <input id="pbots" type="number" min="0" placeholder="Max bots"><input id="pconv" type="number" min="0" placeholder="Max conversations">
        <label><input id="pactive" type="checkbox" checked> Active</label>
        <button class="btn primary" id="psave">Save plan</button>
      </div>
      <p class="muted">Limits are recorded on the plan; account access is enforced on plan expiry and suspension.</p>
    </div>`;
  v.querySelectorAll('[data-edit]').forEach((b) => (b.onclick = () => {
    const p = plans.find((x) => x.id === b.dataset.edit);
    $('#ph').textContent = `Edit plan ${p.id}`;
    $('#pid').value = p.id; $('#pname').value = p.name; $('#pprice').value = p.priceInr;
    $('#pdays').value = p.intervalDays; $('#pbots').value = p.maxBots; $('#pconv').value = p.maxConversations;
    $('#pactive').checked = p.active !== false;
  }));
  $('#psave').onclick = () => guard(async () => {
    await call('adminSavePlan', { id: $('#pid').value, name: $('#pname').value, priceInr: $('#pprice').value, intervalDays: $('#pdays').value, maxBots: $('#pbots').value, maxConversations: $('#pconv').value, active: $('#pactive').checked });
    toast('Plan saved'); show('Plans');
  });
}

// ---- Payments & audit ------------------------------------------------------
async function Payments(v) {
  const snap = await getDocs(query(collection(db, 'payments'), orderBy('createdAt', 'desc'), limit(200)));
  v.innerHTML = `<div class="card"><h2>Payments</h2><div class="wrap"><table>
    <tr><th>When</th><th>User</th><th>Amount</th><th>Method</th><th>Plan</th><th>Source</th><th>Ref</th></tr>
    ${snap.docs.map((d) => { const p = d.data(); return `<tr class="click" data-open="${esc(p.uid)}"><td>${esc(fmtDate(tsMs(p.createdAt)))}</td><td>${esc(p.uid)}</td><td>${inr(p.amountInr)}</td><td>${esc(p.method)}</td><td>${esc(p.planId || '-')}</td><td>${esc(p.source)}</td><td>${esc(p.reference || '')}</td></tr>`; }).join('') || '<tr><td colspan="7" class="muted">No payments yet.</td></tr>'}
    </table></div></div>`;
}
async function Audit(v) {
  const snap = await getDocs(query(collection(db, 'auditLogs'), orderBy('createdAt', 'desc'), limit(200)));
  v.innerHTML = `<div class="card"><h2>Audit log</h2><div class="wrap"><table>
    <tr><th>When</th><th>Admin</th><th>Action</th><th>Target</th><th>Details</th></tr>
    ${snap.docs.map((d) => { const a = d.data(); return `<tr class="${a.targetUid ? 'click' : ''}" data-open="${esc(a.targetUid || '')}"><td>${esc(fmtDate(tsMs(a.createdAt)))}</td><td>${esc(a.admin)}</td><td>${esc(a.action)}</td><td>${esc(a.targetUid || '')}</td><td class="muted">${esc(JSON.stringify(a.details || {}))}</td></tr>`; }).join('') || '<tr><td colspan="5" class="muted">Nothing yet.</td></tr>'}
    </table></div></div>`;
}

// ---- Settings (onboarding) -------------------------------------------------
async function Settings(v) {
  const res = await call('adminListUsers');
  v.innerHTML = `<div class="card"><h2>Onboarding</h2>
    <label><input type="checkbox" id="appr" ${res.requireApproval ? 'checked' : ''}>
      Require admin approval for new accounts</label>
    <p class="muted">When on, new sign-ups are <b>pending</b>: their bots won't reply and WhatsApp tools are blocked until you approve them in Users. Turning this on first marks all current accounts as active, so nobody already using the app is locked out.</p>
    <button class="btn primary" id="save">Save</button></div>`;
  $('#save').onclick = () => guard(async () => { await call('adminSetConfig', { requireApproval: $('#appr').checked }); toast('Saved'); });
}

// ---- navigation helpers: every card/row that points at something is clickable
function go(code) {
  const [t, arg] = code.split(':');
  if (t === 'users') {
    tab = 'Users';
    renderNav();
    guard(() => Users($('#view'), arg || ''));
  } else if (t === 'payments') {
    tab = 'Payments';
    renderNav();
    show('Payments');
  } else if (t === 'bots' || t === 'leads') {
    guard(() => GroupList($('#view'), t));
  }
}

async function openUser(uid) {
  tab = 'Users';
  renderNav();
  await Users($('#view'));
  await UserDetail(uid);
}

async function GroupList(v, kind) {
  v.innerHTML = '<p class="muted">Loading…</p>';
  const { items } = await call('adminListGroup', { kind });
  const head = kind === 'bots'
    ? '<tr><th>Bot</th><th>Owner</th><th>Role</th><th>Active</th><th>Conversations</th><th>Created</th></tr>'
    : '<tr><th>Lead</th><th>Owner</th><th>Channel</th><th>Intent</th><th>Tag</th><th>When</th></tr>';
  const row = (x) => kind === 'bots'
    ? `<td>${esc(x.name)}</td><td>${esc(x.owner)}</td><td>${esc(x.role)}</td><td>${x.active ? 'yes' : 'no'}</td><td>${esc(x.totalConversations || 0)}</td><td>${esc(fmtDate(x.createdAt))}</td>`
    : `<td>${esc(x.name)}<div class="muted">${esc(x.contact)}</div></td><td>${esc(x.owner)}</td><td>${esc(x.channel)}</td><td>${esc(x.intent)}</td><td>${esc(x.tag)}</td><td>${esc(fmtDate(x.createdAt))}</td>`;
  v.innerHTML = `<div class="card"><div class="row"><button class="btn" id="back">← Dashboard</button>
    <h2 style="margin:0">${kind === 'bots' ? 'Bots' : 'Leads'} (latest ${items.length})</h2></div>
    <div class="wrap"><table>${head}${items.map((x) => `<tr class="click" data-open="${esc(x.uid)}">${row(x)}</tr>`).join('') || '<tr><td colspan="6" class="muted">None yet.</td></tr>'}</table></div>
    <p class="muted">Click a row to open its owner.</p></div>`;
  $('#back').onclick = () => { tab = 'Dashboard'; renderNav(); show('Dashboard'); };
}

$('#view').addEventListener('click', (e) => {
  const g = e.target.closest('[data-go]');
  if (g) return go(g.dataset.go);
  const o = e.target.closest('[data-open]');
  if (o && o.dataset.open) return void guard(() => openUser(o.dataset.open));
  const ev = e.target.closest('tr.ev');
  if (ev) ev.querySelector('div')?.classList.toggle('hidden');
});
$('#view').addEventListener('keydown', (e) => {
  if (e.key !== 'Enter' && e.key !== ' ') return;
  const g = e.target.closest('[data-go]');
  if (g) { e.preventDefault(); go(g.dataset.go); }
});
