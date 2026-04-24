require('dotenv').config({ path: require('path').resolve(__dirname, '../../.env') });
const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

// ── inline model imports ──────────────────────────────────────────────────────
const User       = require('../models/User');
const MeterReading = require('../models/MeterReading');
const Bill       = require('../models/Bill');
const Payment    = require('../models/Payment');
const { calculateBill, getDueDate } = require('../services/billingService');

// ── helpers ───────────────────────────────────────────────────────────────────
const log  = (msg) => console.log(`✅  ${msg}`);
const warn = (msg) => console.log(`⚠️   ${msg}`);

// ── dummy client definitions ──────────────────────────────────────────────────
const CLIENTS = [
  {
    name: 'Alice Johnson',
    email: 'alice@example.com',
    password: 'Pass@123',
    phone: '+1-555-0101',
    address: '12 Maple Street, Springfield',
    meterNumber: 'MTR-001',
  },
  {
    name: 'Bob Smith',
    email: 'bob@example.com',
    password: 'Pass@123',
    phone: '+1-555-0102',
    address: '45 Oak Avenue, Shelbyville',
    meterNumber: 'MTR-002',
  },
  {
    name: 'Carol Williams',
    email: 'carol@example.com',
    password: 'Pass@123',
    phone: '+1-555-0103',
    address: '78 Pine Road, Capital City',
    meterNumber: 'MTR-003',
  },
  {
    name: 'David Brown',
    email: 'david@example.com',
    password: 'Pass@123',
    phone: '+1-555-0104',
    address: '99 Cedar Lane, Ogdenville',
    meterNumber: 'MTR-004',
  },
  {
    name: 'Eva Martinez',
    email: 'eva@example.com',
    password: 'Pass@123',
    phone: '+1-555-0105',
    address: '23 Birch Boulevard, North Haverbrook',
    meterNumber: 'MTR-005',
  },
];

// ── monthly readings (last 6 months per client) ───────────────────────────────
// Each row: [ monthsBack, reading ]  — ascending readings
const READING_PATTERNS = {
  'MTR-001': [6, 5, 18, 12, 22, 9],  // units consumed each month
  'MTR-002': [14, 25, 8, 30, 17, 11],
  'MTR-003': [9, 12, 19, 7, 24, 16],
  'MTR-004': [20, 15, 28, 11, 35, 22],
  'MTR-005': [8, 18, 6, 21, 13, 29],
};

function getMonthYear(monthsBack) {
  const d = new Date();
  d.setMonth(d.getMonth() - monthsBack);
  return { month: d.getMonth() + 1, year: d.getFullYear() };
}

// ── main seed ─────────────────────────────────────────────────────────────────
async function seed() {
  const uri = process.env.MONGODB_URI || 'mongodb://127.0.0.1:27017/water_bill_db';
  console.log(`\n🌱  Connecting to ${uri}…`);
  await mongoose.connect(uri);
  console.log('🌱  Connected. Clearing existing data…\n');

  // Wipe collections (keep order to avoid orphan ref issues)
  await Payment.deleteMany({});
  await Bill.deleteMany({});
  await MeterReading.deleteMany({});
  await User.deleteMany({});
  log('Cleared all collections');

  // ── Admin ────────────────────────────────────────────────────────────────
  const admin = await User.create({
    name: 'Super Admin',
    email: 'admin@waterbill.com',
    password: 'Admin@123',
    role: 'admin',
    phone: '+1-555-0000',
    address: 'Head Office, WaterBill Corp',
  });
  log(`Admin created  →  ${admin.email}`);

  // ── Clients ──────────────────────────────────────────────────────────────
  const createdClients = [];
  for (const c of CLIENTS) {
    const client = await User.create({ ...c, role: 'client' });
    createdClients.push(client);
    log(`Client created →  ${client.email}  (${c.meterNumber})`);
  }

  // ── Meter readings + Bills + Payments ────────────────────────────────────
  console.log('\n📊  Generating meter readings, bills and payments…\n');

  for (const client of createdClients) {
    const pattern = READING_PATTERNS[client.meterNumber];
    if (!pattern) continue;

    let cumulativeReading = Math.floor(Math.random() * 500) + 300; // random starting reading

    for (let i = 5; i >= 0; i--) {
      const { month, year } = getMonthYear(i);
      const units   = pattern[5 - i];
      const prevReading = cumulativeReading;
      cumulativeReading += units;

      // ── Meter reading ────────────────────────────────────────────────────
      const mr = await MeterReading.create({
        userId: client._id,
        reading: cumulativeReading,
        previousReading: prevReading,
        month,
        year,
        readingDate: new Date(year, month - 1, 15),
        recordedBy: admin._id,
        notes: `Monthly reading for ${month}/${year}`,
      });

      // ── Bill ─────────────────────────────────────────────────────────────
      const { tariffBreakdown, waterCharges, serviceCharge, taxAmount, totalAmount } =
        calculateBill(mr.unitsConsumed);

      // Bills older than 2 months are paid; newest 2 stay unpaid (for demo)
      const isPaid = i >= 2;
      const dueDate = new Date(year, month - 1 + 1, 5); // 5th of next month

      const bill = await Bill.create({
        userId: client._id,
        meterReadingId: mr._id,
        month,
        year,
        previousReading: prevReading,
        currentReading: cumulativeReading,
        unitsConsumed: mr.unitsConsumed,
        tariffBreakdown,
        waterCharges,
        serviceCharge,
        taxAmount,
        totalAmount,
        dueDate,
        status: isPaid ? 'paid' : 'unpaid',
        paidDate: isPaid ? new Date(year, month - 1 + 1, Math.floor(Math.random() * 25) + 1) : undefined,
        generatedBy: admin._id,
      });

      // ── Payment (only for paid bills) ────────────────────────────────────
      if (isPaid) {
        await Payment.create({
          userId: client._id,
          billId: bill._id,
          amount: totalAmount,
          paymentMethod: ['online', 'card', 'upi', 'cash'][Math.floor(Math.random() * 4)],
          status: 'completed',
          paymentDate: bill.paidDate,
          processedBy: client._id,
        });
      }

      log(`${client.name.padEnd(16)} ${String(month).padStart(2,'0')}/${year} → ${String(units).padStart(3)} units  $${totalAmount.toFixed(2).padStart(7)}  [${isPaid ? 'PAID  ' : 'UNPAID'}]`);
    }
    console.log('');
  }

  // ── Summary ──────────────────────────────────────────────────────────────
  const [users, readings, bills, payments] = await Promise.all([
    User.countDocuments(),
    MeterReading.countDocuments(),
    Bill.countDocuments(),
    Payment.countDocuments(),
  ]);

  console.log('═'.repeat(55));
  console.log('🎉  SEED COMPLETE');
  console.log('═'.repeat(55));
  console.log(`   Users         : ${users}  (1 admin + ${users - 1} clients)`);
  console.log(`   Meter Readings: ${readings}`);
  console.log(`   Bills         : ${bills}`);
  console.log(`   Payments      : ${payments}`);
  console.log('═'.repeat(55));
  console.log('\n🔑  Login credentials:');
  console.log('   Admin   →  admin@waterbill.com  /  Admin@123');
  CLIENTS.forEach(c => console.log(`   Client  →  ${c.email.padEnd(22)} /  Pass@123`));
  console.log('');

  await mongoose.disconnect();
  process.exit(0);
}

seed().catch((err) => {
  console.error('❌  Seed failed:', err.message);
  process.exit(1);
});
