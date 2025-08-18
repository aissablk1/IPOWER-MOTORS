import express from 'express';
import { body, validationResult } from 'express-validator';
import { contactController } from '../controllers/contactController.js';

const router: express.Router = express.Router();

// Validation middleware
const validateContactForm = [
  body('firstName')
    .trim()
    .isLength({ min: 2, max: 50 })
    .withMessage('Le prénom doit contenir entre 2 et 50 caractères'),
  body('lastName')
    .trim()
    .isLength({ min: 2, max: 50 })
    .withMessage('Le nom doit contenir entre 2 et 50 caractères'),
  body('email')
    .isEmail()
    .normalizeEmail()
    .withMessage('Email invalide'),
  body('phone')
    .optional()
    .matches(/^[\+]?[0-9\s\-\(\)]{10,}$/)
    .withMessage('Numéro de téléphone invalide'),
  body('service')
    .trim()
    .isLength({ min: 1 })
    .withMessage('Veuillez sélectionner un service'),
  body('message')
    .trim()
    .isLength({ min: 10, max: 1000 })
    .withMessage('Le message doit contenir entre 10 et 1000 caractères'),
];

// Check validation result
const handleValidationErrors = (req: any, res: any, next: any) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({
      success: false,
      error: 'Données invalides',
      details: errors.array(),
    });
  }
  next();
};

// Routes
router.post('/', validateContactForm, handleValidationErrors, contactController.submitContact);

router.get('/health', (req, res) => {
  res.status(200).json({
    success: true,
    message: 'Contact API is working',
  });
});

export default router; 