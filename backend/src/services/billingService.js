/**
 * Tiered water tariff calculation
 *
 * Tier 1:  0 - 10 units  → $2.00/unit
 * Tier 2: 11 - 20 units  → $3.00/unit
 * Tier 3: 21+    units   → $4.50/unit
 * Service charge: $5.00 flat
 * Tax: 5% on water charges
 */

const TARIFF = [
  { tier: 'Tier 1 (0-10 units)', max: 10, rate: 2.0 },
  { tier: 'Tier 2 (11-20 units)', max: 20, rate: 3.0 },
  { tier: 'Tier 3 (21+ units)', max: Infinity, rate: 4.5 },
];

const SERVICE_CHARGE = 5.0;
const TAX_RATE = 0.05;

const calculateBill = (unitsConsumed) => {
  let remaining = unitsConsumed;
  let waterCharges = 0;
  const breakdown = [];
  let previousMax = 0;

  for (const tier of TARIFF) {
    if (remaining <= 0) break;

    const tierCapacity = tier.max === Infinity ? remaining : tier.max - previousMax;
    const unitsInTier = Math.min(remaining, tierCapacity);

    if (unitsInTier > 0) {
      const amount = parseFloat((unitsInTier * tier.rate).toFixed(2));
      waterCharges += amount;
      breakdown.push({
        tier: tier.tier,
        units: unitsInTier,
        rate: tier.rate,
        amount,
      });
    }

    remaining -= unitsInTier;
    previousMax = tier.max;
  }

  waterCharges = parseFloat(waterCharges.toFixed(2));
  const taxAmount = parseFloat((waterCharges * TAX_RATE).toFixed(2));
  const totalAmount = parseFloat((waterCharges + SERVICE_CHARGE + taxAmount).toFixed(2));

  return {
    tariffBreakdown: breakdown,
    waterCharges,
    serviceCharge: SERVICE_CHARGE,
    taxAmount,
    totalAmount,
  };
};

const getDueDate = (dueDays = 30) => {
  const due = new Date();
  due.setDate(due.getDate() + dueDays);
  return due;
};

module.exports = { calculateBill, getDueDate };
