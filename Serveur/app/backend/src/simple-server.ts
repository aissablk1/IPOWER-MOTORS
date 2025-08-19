import express from 'express';

const app = express();
const port = process.env.PORT || 3000;

app.get('/health', (_req, res) => {
  res.send('OK');
});

app.get('/api/services', (_req, res) => {
  res.json([
    { id: 1, name: 'Service A' },
    { id: 2, name: 'Service B' },
  ]);
});

app.listen(port, () => {
  console.log(`Simple server listening at http://localhost:${port}`);
}); 