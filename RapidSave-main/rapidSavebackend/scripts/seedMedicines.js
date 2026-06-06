require('dotenv').config();
const mongoose  = require('mongoose');
const Medicine  = require('../models/Medicine');
const connectDB = require('../config/db');

const medicines = [
  { name: 'Paracetamol',     generic_name: 'Acetaminophen',   category: 'Analgesic',    unit: 'tablet',  manufacturer: 'Generic' },
  { name: 'Amoxicillin',     generic_name: 'Amoxicillin',     category: 'Antibiotic',   unit: 'capsule', manufacturer: 'Generic' },
  { name: 'Metformin',       generic_name: 'Metformin HCl',   category: 'Antidiabetic', unit: 'tablet',  manufacturer: 'Generic' },
  { name: 'Amlodipine',      generic_name: 'Amlodipine',      category: 'Antihypertensive', unit: 'tablet', manufacturer: 'Generic' },
  { name: 'ORS Sachets',     generic_name: 'Oral Rehydration Salts', category: 'Rehydration', unit: 'sachet', manufacturer: 'Generic' },
  { name: 'Omeprazole',      generic_name: 'Omeprazole',      category: 'Antacid',      unit: 'capsule', manufacturer: 'Generic' },
  { name: 'Artemether',      generic_name: 'Artemether/Lumefantrine', category: 'Antimalarial', unit: 'tablet', manufacturer: 'Generic' },
  { name: 'Cotrimoxazole',   generic_name: 'Trimethoprim/Sulfamethoxazole', category: 'Antibiotic', unit: 'tablet', manufacturer: 'Generic' },
  { name: 'Ibuprofen',       generic_name: 'Ibuprofen',       category: 'Analgesic',    unit: 'tablet',  manufacturer: 'Generic' },
  { name: 'Cetirizine',      generic_name: 'Cetirizine HCl',  category: 'Antihistamine', unit: 'tablet', manufacturer: 'Generic' },
];

const seed = async () => {
  await connectDB();
  await Medicine.deleteMany({});
  await Medicine.insertMany(medicines);
  console.log(`${medicines.length} medicines seeded`);
  process.exit(0);
};

seed().catch((err) => {
  console.error(err);
  process.exit(1);
});