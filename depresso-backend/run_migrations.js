const fs = require('fs');
const path = require('path');
const pool = require('./src/config/db');

async function migrate() {
    const client = await pool.connect();
    try {
        console.log('Starting migrations...');
        await client.query('BEGIN');
        
        // Create migrations table
        await client.query(`
            CREATE TABLE IF NOT EXISTS Migrations (
                id SERIAL PRIMARY KEY,
                filename TEXT UNIQUE NOT NULL,
                run_at TIMESTAMPTZ DEFAULT NOW()
            );
        `);

        // Get files
        const migrationDir = path.join(__dirname, 'migrations');
        const files = fs.readdirSync(migrationDir).filter(f => f.endsWith('.sql')).sort();

        // Get executed migrations
        const { rows: executed } = await client.query('SELECT filename FROM Migrations');
        const executedSet = new Set(executed.map(r => r.filename));

        for (const file of files) {
            if (!executedSet.has(file)) {
                console.log(`Running migration: ${file}`);
                const filePath = path.join(migrationDir, file);
                const sql = fs.readFileSync(filePath, 'utf8');
                
                // Simple split by semicolon if needed, but pg usually handles multi-statement if simple.
                // For safety with complex scripts, we run as one block.
                await client.query(sql);
                
                await client.query('INSERT INTO Migrations (filename) VALUES ($1)', [file]);
                console.log(`Completed: ${file}`);
            } else {
                console.log(`Skipping (already run): ${file}`);
            }
        }

        await client.query('COMMIT');
        console.log('All migrations applied successfully.');
    } catch (error) {
        await client.query('ROLLBACK');
        console.error('Migration failed:', error);
        process.exit(1);
    } finally {
        client.release();
        await pool.end();
    }
}

migrate();
