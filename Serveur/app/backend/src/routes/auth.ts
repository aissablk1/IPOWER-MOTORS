import express from 'express';
import { authController } from '../controllers/authController.js';

const router: express.Router = express.Router();

// Routes
router.get('/health', (req: express.Request, res: express.Response) => {
  res.status(200).json({
    success: true,
    message: 'Auth API is working',
  });
});

export default router; 