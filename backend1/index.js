const express = require('express');
const app = express();

app.get('/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date() });
});

app.listen(3000, () => {
  console.log('Backend запущен на порту 3000');
});
