const http = require('http');
const { WebSocketServer } = require('ws');
const app = require('./app');
const liveAiService = require('./services/liveAiService');

const port = process.env.PORT || 3000;
const host = '0.0.0.0'; // Listen on all network interfaces

// Create HTTP server instead of using app.listen directly
const server = http.createServer(app);

// Create WebSocket Server attached to the HTTP server
const wss = new WebSocketServer({ server, path: '/live-session' });

// Handle WebSocket connections for the Live AI Companion
wss.on('connection', (ws, req) => {
    console.log('⚡ Client connected to /live-session WebSocket');
    liveAiService.setupLiveSession(ws);
});

server.listen(port, host, () => {
  console.log(`Server running on ${host}:${port}`);
  console.log(`Access from iPhone using: http://192.168.1.6:${port}`);
  console.log(`WebSocket endpoint: ws://localhost:${port}/live-session`);
});
