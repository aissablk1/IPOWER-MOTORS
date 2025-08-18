import express = require('express');

const app = express();
const PORT = 3002;

app.use(express.json());

app.get('/health', (req, res) => {
  res.json({
    success: true,
    message: 'IPOWER MOTORS API is running',
    timestamp: new Date().toISOString(),
  });
});

app.get('/api/services', (req, res) => {
  res.json({
    success: true,
    data: [
      {
        id: '1',
        name: 'Entretien Général',
        description: 'Vidange, filtres, bougies et révisions complètes.',
        price: 'À partir de 89€',
      },
    ],
  });
});

app.listen(PORT, () => {
  console.log(`🚀 Server running on http://localhost:${PORT}`);
  console.log(`🔗 Health check: http://localhost:${PORT}/health`);
}); 