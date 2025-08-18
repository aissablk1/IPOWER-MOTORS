import express from 'express';
import { servicesController } from '../controllers/servicesController.js';

const router = express.Router();

// Routes
router.get('/', servicesController.getAllServices);
router.get('/:id', servicesController.getServiceById);
router.get('/category/:category', servicesController.getServicesByCategory);

router.get('/health', (req, res) => {
  res.status(200).json({
    success: true,
    message: 'Services API is working',
  });
});

export default router; 