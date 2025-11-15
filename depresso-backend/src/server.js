const app = require('./app');

const port = process.env.PORT || 3000;
const host = '0.0.0.0'; // Listen on all network interfaces

app.listen(port, host, () => {
  console.log(`Server running on ${host}:${port}`);
  console.log(`Access from iPhone using: http://192.168.1.11:${port}`);
});
