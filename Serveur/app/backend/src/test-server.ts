import express from 'express';

const app = express();
const PORT = 3002;

app.get('/health', (_req, res) => {
  res.json({
    success: true,
    message: 'Test server is running',
    timestamp: new Date().toISOString(),
  });
});

app.listen(PORT, () => {
  console.log(`🚀 Test server running on http://localhost:${PORT}`);
  console.log(`🔗 Health check: http://localhost:${PORT}/health`);
}); 