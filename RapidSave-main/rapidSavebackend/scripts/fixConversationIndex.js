/**
 * One-time migration: drop the stale unique delivery_id_1 index on conversations.
 * Run once: node scripts/fixConversationIndex.js
 */
require('dotenv').config();
const mongoose = require('mongoose');

async function run() {
  await mongoose.connect(process.env.MONGO_URI);
  const db = mongoose.connection.db;
  const col = db.collection('conversations');

  const indexes = await col.indexes();
  console.log('Current indexes:', indexes.map((i) => i.name));

  const bad = indexes.find((i) => i.name === 'delivery_id_1');
  if (bad) {
    await col.dropIndex('delivery_id_1');
    console.log('Dropped delivery_id_1 index ✓');
  } else {
    console.log('delivery_id_1 index not found — nothing to drop');
  }

  // Let Mongoose recreate the correct sparse index on next app start
  await mongoose.disconnect();
  console.log('Done.');
}

run().catch((err) => { console.error(err); process.exit(1); });
