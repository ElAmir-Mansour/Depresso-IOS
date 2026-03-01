require('dotenv').config();
const { Pool } = require('pg');

const connectionString = process.env.POSTGRES_URL || process.env.DATABASE_URL;

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
