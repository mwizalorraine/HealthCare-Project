require('dotenv').config();
const mongoose = require('mongoose');
const User     = require('../models/User');
const connectDB = require('../config/db');

const seed = async () => {
  await connectDB();

  const existing = await User.findOne({ role: 'admin' });
  if (existing) {
    console.log('Admin already exists:', existing.email);
    process.exit(0);
  }

  const admin = await User.create({
    name:          'Super Admin',
    email:         process.env.ADMIN_EMAIL    || 'magnifiqueni01@gmail.com',
    password_hash: process.env.ADMIN_PASSWORD || 'Admin@1234',
    role:          'admin',
    phone:         process.env.ADMIN_PHONE    || '+250780000000',
    email_verified: true,
  });

  console.log('Admin created:', admin.email);
  process.exit(0);
};

seed().catch((err) => {
  console.error(err);
  process.exit(1);
});