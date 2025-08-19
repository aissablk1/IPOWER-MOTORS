import express, { Router } from 'express';
import { servicesController } from '../controllers/servicesController.js';

const router: Router = express.Router();

// Routes pour les services
router.post('/', servicesController.createService);
router.get('/', servicesController.getAllServices);
router.get('/:id', servicesController.getServiceById);
router.put('/:id', servicesController.updateService);
router.delete('/:id', servicesController.deleteService);

// Route de santé
router.get('/health', (_req, res) => {
  res.status(200).json({ status: 'OK', service: 'Services API' });
});

export default router; 