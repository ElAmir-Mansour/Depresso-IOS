const express = require('express');
const router = express.Router();

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

module.exports = router;
