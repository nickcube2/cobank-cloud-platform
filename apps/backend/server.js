const express = require('express');
const app = express();
const PORT = process.env.PORT || 3000;

app.get('/api/health', (req, res) => {
  res.json({ status: 'healthy', timestamp: new Date().toISOString() });
});

app.get('/api/info', (req, res) => {
  res.json({ service: 'cobank-backend', version: '1.0.0' });
});

app.listen(PORT, () => {
  console.log(`Backend running on port ${PORT}`);
});
