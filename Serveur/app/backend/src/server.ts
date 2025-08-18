import { createServer } from 'http';
import { Server } from 'socket.io';
import dotenv from 'dotenv';
import app from './app.js';

// Load environment variables
dotenv.config();

const server = createServer(app);
const io = new Server(server, {
  cors: {
    origin: process.env['ALLOWED_ORIGINS']?.split(',') || ['http://localhost:3000'],
    methods: ['GET', 'POST'],
  },
});

const PORT = process.env['PORT'] || 3001;

// Socket.io connection handling
io.on('connection', (socket) => {
  console.log('Client connected:', socket.id);

  socket.on('disconnect', () => {
    console.log('Client disconnected:', socket.id);
  });

  // Handle real-time notifications
  socket.on('join-room', (room) => {
    socket.join(room);
    console.log(`Client ${socket.id} joined room: ${room}`);
  });

  socket.on('leave-room', (room) => {
    socket.leave(room);
    console.log(`Client ${socket.id} left room: ${room}`);
  });
});

// Start server
server.listen(PORT, () => {
  console.log(`🚀 IPOWER MOTORS API server running on port ${PORT}`);
  console.log(`📊 Environment: ${process.env['NODE_ENV']}`);
  console.log(`🔗 Health check: http://localhost:${PORT}/health`);
});

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('SIGTERM received, shutting down gracefully');
  server.close(() => {
    console.log('Process terminated');
  });
});

process.on('SIGINT', () => {
  console.log('SIGINT received, shutting down gracefully');
  server.close(() => {
    console.log('Process terminated');
  });
});

export { app, io }; 