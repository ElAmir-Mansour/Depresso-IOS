const express = require('express');
const router = express.Router();
const pool = require('../../config/db');

router.get('/env-check', (req, res) => {
  res.json({
    hasPostgresUrl: !!process.env.POSTGRES_URL,
    hasDatabaseUrl: !!process.env.DATABASE_URL,
    hasPrismaDatabaseUrl: !!process.env.PRISMA_DATABASE_URL,
    hasDbHost: !!process.env.DB_HOST,
    dbHostValue: process.env.DB_HOST || 'not set',
    connectionStringLength: (process.env.POSTGRES_URL || process.env.DATABASE_URL || process.env.PRISMA_DATABASE_URL || '').length
  });
});

router.get('/db-test', async (req, res) => {
  try {
    const result = await pool.query('SELECT NOW() as time, version() as version');
    res.json({ 
      status: 'connected', 
      time: result.rows[0].time,
      version: result.rows[0].version.substring(0, 50) + '...'
    });
  } catch (error) {
    res.status(500).json({ 
      status: 'error', 
      message: error.message,
      code: error.code 
    });
  }
});

module.exports = router;
