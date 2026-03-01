require('dotenv').config();
const { Pool } = require('pg');

const connectionString = process.env.POSTGRES_URL || process.env.DATABASE_URL || process.env.PRISMA_DATABASE_URL;

console.log("DB Config Check - Is POSTGRES_URL present?", !!process.env.POSTGRES_URL);
console.log("DB Config Check - Is DATABASE_URL present?", !!process.env.DATABASE_URL);
console.log("DB Config Check - Selected String length:", connectionString ? connectionString.length : 0);

const poolConfig = connectionString
  ? {
      connectionString: connectionString,
      ssl: {
        rejectUnauthorized: false // Required for hosted databases (Vercel, Render, Heroku)
      }
    }
  : {
      user: process.env.DB_USER,
      host: process.env.DB_HOST,
      database: process.env.DB_DATABASE,
      password: process.env.DB_PASSWORD,
      port: process.env.DB_PORT,
    };

const pool = new Pool(poolConfig);

module.exports = pool;
