import express, { Express } from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';

const app: Express = express();
const PORT = 3001;

// Middlewares
app.use(helmet());
app.use(morgan('combined'));
app.use(cors({
  origin: ['http://localhost:3000', 'http://localhost:5173'],
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
    environment: 'development',
  });
});

// Contact endpoint
app.post('/api/contact', (req, res) => {
  try {
    const { firstName, lastName, email, phone, service, message } = req.body;
    
    console.log('New contact form submission:', {
      firstName,
      lastName,
      email,
      phone,
      service,
      message,
      timestamp: new Date().toISOString(),
    });

    res.status(201).json({
      success: true,
      message: 'Votre message a été envoyé avec succès. Nous vous répondrons dans les plus brefs délais.',
      data: {
        id: Date.now().toString(),
        firstName,
        lastName,
        email,
        phone,
        service,
        message,
        submittedAt: new Date().toISOString(),
      },
    });
  } catch (error) {
    console.error('Error submitting contact form:', error);
    res.status(500).json({
      success: false,
      error: 'Erreur lors de l\'envoi du message. Veuillez réessayer.',
    });
  }
});

// Services endpoint
app.get('/api/services', (_req, res) => {
  const services = [
    {
      id: '1',
      name: 'Entretien Général',
      description: 'Vidange, filtres, bougies et révisions complètes selon les préconisations constructeur.',
      price: 'À partir de 89€',
      category: 'entretien',
    },
    {
      id: '2',
      name: 'Réparation Mécanique',
      description: 'Diagnostic et réparation de tous types de pannes mécaniques et électroniques.',
      price: 'Sur devis',
      category: 'reparation',
    },
    {
      id: '3',
      name: 'Optimisation Moteur',
      description: 'Reprogrammation moteur pour améliorer performances et consommation.',
      price: 'À partir de 299€',
      category: 'optimisation',
    },
    {
      id: '4',
      name: 'Préparation Sportive',
      description: 'Modifications pour améliorer les performances et l\'esthétique de votre véhicule.',
      price: 'Sur devis',
      category: 'preparation',
    },
    {
      id: '5',
      name: 'Contrôle Technique',
      description: 'Préparation et passage du contrôle technique avec garantie de réussite.',
      price: 'À partir de 49€',
      category: 'controle',
    },
    {
      id: '6',
      name: 'Service Express',
      description: 'Interventions rapides pour les urgences et dépannages sur site.',
      price: 'Sur devis',
      category: 'urgence',
    },
  ];

  res.status(200).json({
    success: true,
    data: services,
    count: services.length,
  });
});

// Start server
app.listen(PORT, () => {
  console.log(`🚀 IPOWER MOTORS API server running on port ${PORT}`);
  console.log(`📊 Environment: development`);
  console.log(`🔗 Health check: http://localhost:${PORT}/health`);
  console.log(`📝 Contact API: http://localhost:${PORT}/api/contact`);
  console.log(`🔧 Services API: http://localhost:${PORT}/api/services`);
});

export default app; 