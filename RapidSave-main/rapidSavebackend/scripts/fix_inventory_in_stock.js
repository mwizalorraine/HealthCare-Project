/**
 * One-time migration: set in_stock = (quantity > 0) for all inventory records.
 *
 * Run once with:
 *   node scripts/fix_inventory_in_stock.js
 */

const mongoose = require('mongoose');
require('dotenv').config();

async function run() {
  await mongoose.connect(process.env.MONGODB_URI || process.env.MONGO_URI);
  console.log('Connected to MongoDB');

  const inStockResult = await mongoose.connection.collection('inventories').updateMany(
    { quantity: { $gt: 0 } },
    { $set: { in_stock: true } }
  );
  console.log(`Set in_stock=true  for ${inStockResult.modifiedCount} records`);

  const outOfStockResult = await mongoose.connection.collection('inventories').updateMany(
    { quantity: { $lte: 0 } },
    { $set: { in_stock: false } }
  );
  console.log(`Set in_stock=false for ${outOfStockResult.modifiedCount} records`);

  await mongoose.disconnect();
  console.log('Done.');
}

run().catch(err => { console.error(err); process.exit(1); });
