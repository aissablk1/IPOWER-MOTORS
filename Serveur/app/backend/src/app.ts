import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import compression from 'compression';
import rateLimit from 'express-rate-limit';
import dotenv from 'dotenv';

// Import routes
import contactRoutes from './routes/contact.js';
import servicesRoutes from './routes/services.js';
import authRoutes from './routes/auth.js';

// Import middlewares
import { errorHandler } from './middlewares/errorHandler.js';
import { notFound } from './middlewares/notFound.js';

// Load environment variables
dotenv.config();

const app: express.Application = express();

// Rate limiting
const limiter = rateLimit({
  windowMs: parseInt(process.env['RATE_LIMIT_WINDOW_MS'] || '900000'), // 15 minutes
  max: parseInt(process.env['RATE_LIMIT_MAX_REQUESTS'] || '100'), // limit each IP to 100 requests per windowMs
  message: {
    error: 'Too many requests from this IP, please try again later.',
  },
});

// Middlewares
app.use(helmet());
app.use(compression());
app.use(morgan('combined'));
app.use(limiter);
app.use(cors({
  origin: process.env['ALLOWED_ORIGINS']?.split(',') || ['http://localhost:3000'],
  credentials: true,
}));
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Health check endpoint
app.get('/health', (_req, res) => {
  res.status(200).json({
    success: true,
    message: 'IPOWER MOTORS API is running',
    timestamp: new Date().toISOString(),
    environment: process.env['NODE_ENV'],
  });
});

// API Routes
app.use('/api/contact', contactRoutes);
app.use('/api/services', servicesRoutes);
app.use('/api/auth', authRoutes);

// Error handling middlewares (must be last)
app.use(notFound);
app.use(errorHandler);

export default app; 