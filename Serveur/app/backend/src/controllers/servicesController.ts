import { Request, Response } from 'express';
import { Service } from '../types/index.js';

// Mock data for services
const mockServices: Service[] = [
  {
    id: '1',
    name: 'Entretien Général',
    description: 'Vidange, filtres, bougies et révisions complètes selon les préconisations constructeur.',
    price: 'À partir de 89€',
    category: 'entretien',
    isActive: true,
    createdAt: new Date(),
    updatedAt: new Date(),
  },
  {
    id: '2',
    name: 'Réparation Mécanique',
    description: 'Diagnostic et réparation de tous types de pannes mécaniques et électroniques.',
    price: 'Sur devis',
    category: 'reparation',
    isActive: true,
    createdAt: new Date(),
    updatedAt: new Date(),
  },
  {
    id: '3',
    name: 'Optimisation Moteur',
    description: 'Reprogrammation moteur pour améliorer performances et consommation.',
    price: 'À partir de 299€',
    category: 'optimisation',
    isActive: true,
    createdAt: new Date(),
    updatedAt: new Date(),
  },
  {
    id: '4',
    name: 'Préparation Sportive',
    description: 'Modifications pour améliorer les performances et l\'esthétique de votre véhicule.',
    price: 'Sur devis',
    category: 'preparation',
    isActive: true,
    createdAt: new Date(),
    updatedAt: new Date(),
  },
  {
    id: '5',
    name: 'Contrôle Technique',
    description: 'Préparation et passage du contrôle technique avec garantie de réussite.',
    price: 'À partir de 49€',
    category: 'controle',
    isActive: true,
    createdAt: new Date(),
    updatedAt: new Date(),
  },
  {
    id: '6',
    name: 'Service Express',
    description: 'Interventions rapides pour les urgences et dépannages sur site.',
    price: 'Sur devis',
    category: 'urgence',
    isActive: true,
    createdAt: new Date(),
    updatedAt: new Date(),
  },
];

export const servicesController = {
  getAllServices: async (req: Request, res: Response) => {
    try {
      const activeServices = mockServices.filter(service => service.isActive);
      
      res.status(200).json({
        success: true,
        data: activeServices,
        count: activeServices.length,
      });
    } catch (error) {
      console.error('Error fetching services:', error);
      res.status(500).json({
        success: false,
        error: 'Erreur lors de la récupération des services.',
      });
    }
  },

  getServiceById: async (req: Request, res: Response) => {
    try {
      const { id } = req.params;
      const service = mockServices.find(s => s.id === id && s.isActive);

      if (!service) {
        return res.status(404).json({
          success: false,
          error: 'Service non trouvé.',
        });
      }

      res.status(200).json({
        success: true,
        data: service,
      });
    } catch (error) {
      console.error('Error fetching service by ID:', error);
      res.status(500).json({
        success: false,
        error: 'Erreur lors de la récupération du service.',
      });
    }
  },

  getServicesByCategory: async (req: Request, res: Response) => {
    try {
      const { category } = req.params;
      const services = mockServices.filter(
        service => service.category === category && service.isActive
      );

      res.status(200).json({
        success: true,
        data: services,
        count: services.length,
        category,
      });
    } catch (error) {
      console.error('Error fetching services by category:', error);
      res.status(500).json({
        success: false,
        error: 'Erreur lors de la récupération des services par catégorie.',
      });
    }
  },
}; 