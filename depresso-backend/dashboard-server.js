const express = require('express');
const path = require('path');

const app = express();
const PORT = 3001;

// Serve the dashboard HTML file
app.use(express.static(__dirname));

app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'dashboard.html'));
});

app.listen(PORT, () => {
    console.log(`📊 Dashboard server running at http://localhost:${PORT}`);
    console.log(`🔗 Open in browser: http://localhost:${PORT}`);
});
