/**
 * Comprehensive API test script  —  idempotent, seeds fresh data before running
 * Run:  node test_apis.js
 */
require('dotenv').config();
const http = require('http');
const { execSync } = require('child_process');

const TS = Date.now(); // unique suffix for this run

// ── helpers ───────────────────────────────────────────────────────────────────
function req(method, path, body, token) {
  return new Promise((resolve, reject) => {
    const payload = body ? JSON.stringify(body) : null;
    const opts = {
      hostname: 'localhost', port: 5000, path, method,
      headers: {
        'Content-Type': 'application/json',
        ...(token ? { Authorization: `Bearer ${token}` } : {}),
        ...(payload ? { 'Content-Length': Buffer.byteLength(payload) } : {}),
      },
    };
    const r = http.request(opts, (res) => {
      let d = '';
      res.on('data', (c) => (d += c));
      res.on('end', () => {
        try { resolve({ status: res.statusCode, body: JSON.parse(d) }); }
        catch { resolve({ status: res.statusCode, body: d }); }
      });
    });
    r.on('error', reject);
    if (payload) r.write(payload);
    r.end();
  });
}

let passed = 0; let failed = 0;

function pass(label, info = '') {
  passed++;
  console.log(`  ✅  ${label}${info ? '  →  ' + info : ''}`);
}
function fail(label, info = '', actual = '') {
  failed++;
  console.log(`  ❌  ${label}${info ? '  →  ' + info : ''}${actual ? '  [got: ' + actual + ']' : ''}`);
}
function check(label, condition, info = '', actual = '') {
  condition ? pass(label, info) : fail(label, info, actual);
  return condition;
}
function section(title) {
  console.log(`\n${'─'.repeat(57)}\n  ${title}\n${'─'.repeat(57)}`);
}

// ── main ──────────────────────────────────────────────────────────────────────
async function run() {
  console.log('\n' + '═'.repeat(57));
  console.log('  🧪  Water Bill API — Full Test Suite');
  console.log('═'.repeat(57));

  // ── 0. FRESH SEED ────────────────────────────────────────────────────────
  section('0. Seeding fresh test data');
  try {
    execSync('node src/utils/seed.js', { cwd: __dirname, stdio: 'pipe' });
    pass('Database seeded with fresh dummy data');
  } catch (e) {
    fail('Seed failed', e.message);
    process.exit(1);
  }

  // ── 1. HEALTH ────────────────────────────────────────────────────────────
  section('1. Health Check');
  const health = await req('GET', '/health');
  check('GET /health  →  200', health.status === 200, health.body?.status);

  // ── 2. AUTH ──────────────────────────────────────────────────────────────
  section('2. Authentication');

  const adminLogin = await req('POST', '/api/auth/login', { email: 'admin@waterbill.com', password: 'Admin@123' });
  check('POST /api/auth/login  (admin valid creds)  →  200', adminLogin.status === 200 && adminLogin.body.success);
  const adminToken = adminLogin.body.token;
  pass('Admin JWT received', `${adminToken?.substring(0, 30)}…`);

  const clientLogin = await req('POST', '/api/auth/login', { email: 'alice@example.com', password: 'Pass@123' });
  check('POST /api/auth/login  (client valid creds)  →  200', clientLogin.status === 200 && clientLogin.body.success);
  const clientToken = clientLogin.body.token;
  const aliceId     = clientLogin.body.user?.id;
  pass('Client Alice JWT received', `id=${aliceId}`);

  const bobLogin = await req('POST', '/api/auth/login', { email: 'bob@example.com', password: 'Pass@123' });
  const bobId = bobLogin.body.user?.id;

  check('POST /api/auth/login  (wrong password)  →  401',
    (await req('POST', '/api/auth/login', { email: 'admin@waterbill.com', password: 'wrongpass' })).status === 401);

  check('POST /api/auth/login  (missing password)  →  400',
    (await req('POST', '/api/auth/login', { email: 'x@x.com' })).status === 400);

  check('POST /api/auth/login  (invalid email format)  →  400',
    (await req('POST', '/api/auth/login', { email: 'notanemail', password: '123456' })).status === 400);

  check('POST /api/auth/login  (empty body)  →  400',
    (await req('POST', '/api/auth/login', {})).status === 400);

  const meAdmin = await req('GET', '/api/auth/me', null, adminToken);
  check('GET /api/auth/me  (admin)  →  200', meAdmin.status === 200 && meAdmin.body.user?.role === 'admin', meAdmin.body.user?.name);

  const meClient = await req('GET', '/api/auth/me', null, clientToken);
  check('GET /api/auth/me  (client)  →  200', meClient.status === 200 && meClient.body.user?.role === 'client', meClient.body.user?.name);

  check('GET /api/auth/me  (no token)  →  401',
    (await req('GET', '/api/auth/me')).status === 401);

  check('GET /api/auth/me  (bad token)  →  401',
    (await req('GET', '/api/auth/me', null, 'bad.token.here')).status === 401);

  // ── 3. USERS ─────────────────────────────────────────────────────────────
  section('3. Users');

  const allUsers = await req('GET', '/api/users', null, adminToken);
  check('GET /api/users  (admin)  →  200', allUsers.status === 200, `total=${allUsers.body.data?.length}`);

  const clientsOnly = await req('GET', '/api/users?role=client', null, adminToken);
  check('GET /api/users?role=client  →  200', clientsOnly.status === 200, `clients=${clientsOnly.body.data?.length}`);

  const searchRes = await req('GET', '/api/users?search=alice', null, adminToken);
  check('GET /api/users?search=alice  →  1 result', searchRes.status === 200 && searchRes.body.data?.length === 1, searchRes.body.data?.[0]?.name);

  check('GET /api/users  (client)  →  403',
    (await req('GET', '/api/users', null, clientToken)).status === 403);

  check('GET /api/users  (no auth)  →  401',
    (await req('GET', '/api/users')).status === 401);

  const stats = await req('GET', '/api/users/dashboard/stats', null, adminToken);
  check('GET /api/users/dashboard/stats  →  200', stats.status === 200,
    `clients=${stats.body.data?.totalClients}, unpaid=${stats.body.data?.unpaidBills}, revenue=$${stats.body.data?.totalRevenue?.toFixed(2)}`);

  const getAlice = await req('GET', `/api/users/${aliceId}`, null, adminToken);
  check(`GET /api/users/${aliceId?.slice(0,8)}…  (admin get client)  →  200`, getAlice.status === 200, getAlice.body.data?.name);

  check('GET /api/users/:other  (client cross-access)  →  403',
    (await req('GET', `/api/users/${bobId}`, null, clientToken)).status === 403);

  // Create new test user with unique email + meter
  const newUserEmail = `testuser_${TS}@example.com`;
  const newMeter     = `MTR-T${TS}`;
  const createUser   = await req('POST', '/api/users',
    { name: 'Test Client', email: newUserEmail, password: 'Test@123', role: 'client', meterNumber: newMeter },
    adminToken);
  check('POST /api/users  (admin creates client)  →  201', createUser.status === 201, createUser.body.data?.email);
  const testUserId = createUser.body.data?._id;

  check('POST /api/users  (client cannot create)  →  403',
    (await req('POST', '/api/users', { name: 'X', email: 'x@x.com', password: 'Test@123' }, clientToken)).status === 403);

  const updateUser = await req('PUT', `/api/users/${testUserId}`, { phone: '+1-800-WATER', address: '1 Test St' }, adminToken);
  check('PUT /api/users/:id  (admin update)  →  200', updateUser.status === 200, updateUser.body.data?.phone);

  // ── 4. METER READINGS ────────────────────────────────────────────────────
  section('4. Meter Readings');

  const aliceReadings = await req('GET', `/api/meter/${aliceId}`, null, adminToken);
  check(`GET /api/meter/${aliceId?.slice(0,8)}…  (alice)  →  200`,
    aliceReadings.status === 200, `readings=${aliceReadings.body.data?.length}`);

  const allReadings = await req('GET', '/api/meter', null, adminToken);
  check('GET /api/meter  (admin all)  →  200', allReadings.status === 200, `total=${allReadings.body.data?.length}`);

  check('GET /api/meter/:userId  (own)  →  200',
    (await req('GET', `/api/meter/${aliceId}`, null, clientToken)).status === 200);

  check('GET /api/meter/:userId  (cross-client)  →  403',
    (await req('GET', `/api/meter/${bobId}`, null, clientToken)).status === 403);

  check('POST /api/meter  (client cannot add)  →  403',
    (await req('POST', '/api/meter', { userId: aliceId, reading: 999, month: 1, year: 2040 }, clientToken)).status === 403);

  check('POST /api/meter  (negative reading)  →  400',
    (await req('POST', '/api/meter', { userId: aliceId, reading: -10, month: 1, year: 2040 }, adminToken)).status === 400);

  // Add reading for the testUser — use a far-future year to avoid conflicts
  const testMonth = 6; const testYear = 2040;
  const addReading = await req('POST', '/api/meter',
    { userId: testUserId, reading: 250, month: testMonth, year: testYear, notes: 'Auto test reading' },
    adminToken);
  check('POST /api/meter  (admin add reading)  →  201',
    addReading.status === 201, `units=${addReading.body.data?.unitsConsumed}`);

  check('POST /api/meter  (duplicate month/year)  →  409',
    (await req('POST', '/api/meter', { userId: testUserId, reading: 260, month: testMonth, year: testYear }, adminToken)).status === 409);

  // ── 5. BILLS ─────────────────────────────────────────────────────────────
  section('5. Bills');

  const aliceBills = await req('GET', `/api/bills/user/${aliceId}`, null, clientToken);
  check('GET /api/bills/user/:userId  (alice own)  →  200',
    aliceBills.status === 200, `count=${aliceBills.body.data?.length}`);

  // Pick any unpaid bill belonging to Alice
  const unpaidAliceBills = aliceBills.body.data?.filter(b => b.status === 'unpaid') || [];
  check('Alice has unpaid bills from seed', unpaidAliceBills.length > 0, `unpaid=${unpaidAliceBills.length}`);
  const unpaidBillId     = unpaidAliceBills[0]?._id || '';
  const unpaidBillAmount = unpaidAliceBills[0]?.totalAmount || 0;
  if (unpaidBillId) pass('Unpaid bill selected', `id=${unpaidBillId.slice(0,8)}…  $${unpaidBillAmount}`);

  const allBills = await req('GET', '/api/bills', null, adminToken);
  check('GET /api/bills  (admin all)  →  200', allBills.status === 200, `total=${allBills.body.data?.length}`);

  const unpaidFilter = await req('GET', '/api/bills?status=unpaid', null, adminToken);
  check('GET /api/bills?status=unpaid  →  200', unpaidFilter.status === 200, `unpaid=${unpaidFilter.body.data?.length}`);

  const singleBill = await req('GET', `/api/bills/${unpaidBillId}`, null, clientToken);
  check('GET /api/bills/:id  (client own)  →  200', singleBill.status === 200, singleBill.body.data?.billNumber);

  check('GET /api/bills/:nonexistent  →  404',
    (await req('GET', '/api/bills/000000000000000000000000', null, adminToken)).status === 404);

  // Generate bill for testUser (reading was added above)
  const genBill = await req('POST', '/api/bills/generate',
    { userId: testUserId, month: testMonth, year: testYear, dueDays: 30 },
    adminToken);
  check('POST /api/bills/generate  (auto-calculates from reading)  →  201',
    genBill.status === 201,
    `$${genBill.body.data?.totalAmount?.toFixed(2)}  ${genBill.body.data?.billNumber}`);
  const testBillId     = genBill.body.data?._id;
  const testBillAmount = genBill.body.data?.totalAmount;

  check('POST /api/bills/generate  (duplicate)  →  409',
    (await req('POST', '/api/bills/generate', { userId: testUserId, month: testMonth, year: testYear }, adminToken)).status === 409);

  check('POST /api/bills/generate  (no reading for period)  →  404',
    (await req('POST', '/api/bills/generate', { userId: testUserId, month: 1, year: 2001 }, adminToken)).status === 404);

  check('POST /api/bills/generate  (client cannot generate)  →  403',
    (await req('POST', '/api/bills/generate', { userId: aliceId, month: 1, year: 2040 }, clientToken)).status === 403);

  // ── 6. PAYMENTS ──────────────────────────────────────────────────────────
  section('6. Payments');

  const makePayment = await req('POST', '/api/payments',
    { billId: unpaidBillId, amount: unpaidBillAmount, paymentMethod: 'online' },
    clientToken);
  check('POST /api/payments  (client pays own bill)  →  201',
    makePayment.status === 201, `txn=${makePayment.body.data?.transactionId}`);

  check('POST /api/payments  (pay already-paid bill)  →  400',
    (await req('POST', '/api/payments', { billId: unpaidBillId, amount: unpaidBillAmount }, clientToken)).status === 400);

  check('POST /api/payments  (wrong amount)  →  400',
    (await req('POST', '/api/payments', { billId: testBillId, amount: 0.01, paymentMethod: 'cash' }, adminToken)).status === 400);

  check('POST /api/payments  (client pays other client bill)  →  403',
    (await req('POST', '/api/payments', { billId: testBillId, amount: testBillAmount, paymentMethod: 'card' }, clientToken)).status === 403);

  const alicePayments = await req('GET', `/api/payments/user/${aliceId}`, null, clientToken);
  check('GET /api/payments/user/:userId  (alice own)  →  200',
    alicePayments.status === 200, `count=${alicePayments.body.data?.length}`);

  check('GET /api/payments/user/:userId  (cross-client)  →  403',
    (await req('GET', `/api/payments/user/${bobId}`, null, clientToken)).status === 403);

  const allPayments = await req('GET', '/api/payments', null, adminToken);
  check('GET /api/payments  (admin all)  →  200', allPayments.status === 200, `total=${allPayments.body.data?.length}`);

  check('GET /api/payments  (client)  →  403',
    (await req('GET', '/api/payments', null, clientToken)).status === 403);

  // Admin pays testUser bill
  const adminPays = await req('POST', '/api/payments',
    { billId: testBillId, amount: testBillAmount, paymentMethod: 'cash' },
    adminToken);
  check('POST /api/payments  (admin records cash payment)  →  201',
    adminPays.status === 201, `txn=${adminPays.body.data?.transactionId}`);

  // ── 7. ROLE-BASED ACCESS CONTROL ─────────────────────────────────────────
  section('7. Role-Based Access Control');

  const rbacCases = [
    ['GET /api/users  (no token)  →  401',       await req('GET', '/api/users'),                                          401],
    ['GET /api/users  (client)  →  403',          await req('GET', '/api/users', null, clientToken),                       403],
    ['POST /api/meter  (client)  →  403',         await req('POST', '/api/meter', { userId: aliceId, reading: 100, month: 1, year: 2040 }, clientToken), 403],
    ['POST /api/bills/generate  (client)  →  403',await req('POST', '/api/bills/generate', { userId: aliceId }, clientToken), 403],
    ['GET /api/users/dashboard/stats  (client)  →  403', await req('GET', '/api/users/dashboard/stats', null, clientToken), 403],
  ];
  for (const [label, res, expected] of rbacCases) {
    check(label, res.status === expected, '', `got ${res.status}`);
  }

  // ── 8. 404 / BAD IDs ────────────────────────────────────────────────────
  section('8. Error Handling & Edge Cases');

  check('GET /nonexistent-route  →  404',
    (await req('GET', '/api/this-does-not-exist')).status === 404);

  check('GET /api/users/bad-object-id  →  400 or 404',
    [400, 404].includes((await req('GET', '/api/users/notanid', null, adminToken)).status));

  check('GET /api/bills/000…  →  404',
    (await req('GET', '/api/bills/000000000000000000000000', null, adminToken)).status === 404);

  check('POST /api/auth/register  (admin protected)  →  401',
    (await req('POST', '/api/auth/register', { name: 'X', email: 'x@x.com', password: 'Test@123' })).status === 401);

  // ── SUMMARY ──────────────────────────────────────────────────────────────
  const total = passed + failed;
  console.log('\n' + '═'.repeat(57));
  console.log(`  Results:  ${passed}/${total} passed  |  ${failed} failed`);
  if (failed === 0) {
    console.log('  🎉  ALL TESTS PASSED — API is fully functional');
  } else {
    console.log(`  ⚠️   ${failed} test(s) failed — check output above`);
  }
  console.log('═'.repeat(57));
  console.log('\n🔑  Credentials to use in Flutter:');
  console.log('   Admin   →  admin@waterbill.com  /  Admin@123');
  console.log('   Client  →  alice@example.com    /  Pass@123');
  console.log(`\n🌐  API Base URL: http://localhost:5000/api\n`);

  process.exit(failed > 0 ? 1 : 0);
}

run().catch((err) => {
  console.error('\n❌  Test runner crashed:', err.message);
  process.exit(1);
});
