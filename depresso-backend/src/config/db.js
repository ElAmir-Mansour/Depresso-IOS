require('dotenv').config();
const { Pool } = require('pg');

const connectionString = process.env.POSTGRES_URL || process.env.DATABASE_URL || process.env.PRISMA_DATABASE_URL;

console.log("DB Config Check - POSTGRES_URL:", !!process.env.POSTGRES_URL);
console.log("DB Config Check - DATABASE_URL:", !!process.env.DATABASE_URL);
console.log("DB Config Check - PRISMA_DATABASE_URL:", !!process.env.PRISMA_DATABASE_URL);
console.log("DB Config Check - Selected connection string:", connectionString ? `${connectionString.substring(0, 30)}...` : 'NONE FOUND');
console.log("DB Config Check - Fallback values:", {
  DB_HOST: process.env.DB_HOST || 'undefined',
  DB_USER: process.env.DB_USER || 'undefined'
});

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
