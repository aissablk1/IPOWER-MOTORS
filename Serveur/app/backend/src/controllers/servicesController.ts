import { Request, Response } from 'express';

export const servicesController = {
  createService: async (req: Request, res: Response) => {
    try {
      const { name, description, price, category } = req.body;
      
      // TODO: Implémenter la logique de création de service
      if (!name || !description || !price || !category) {
        return res.status(400).json({ error: 'Tous les champs sont requis' });
      }
      
      // Simulation de création
      const newService = {
        id: Date.now().toString(),
        name,
        description,
        price: parseFloat(price),
        category,
        createdAt: new Date().toISOString()
      };
      
      return res.status(201).json({ 
        message: 'Service créé avec succès',
        service: newService
      });
    } catch (error) {
      return res.status(500).json({ error: 'Erreur serveur' });
    }
  },

  getAllServices: async (_req: Request, res: Response) => {
    try {
      // TODO: Implémenter la logique de récupération des services
      const mockServices = [
        {
          id: '1',
          name: 'Vidange moteur',
          description: 'Vidange complète du moteur avec filtre à huile',
          price: 89.99,
          category: 'Entretien',
          createdAt: new Date().toISOString()
        },
        {
          id: '2',
          name: 'Remplacement plaquettes',
          description: 'Remplacement des plaquettes de frein avant',
          price: 129.99,
          category: 'Freinage',
          createdAt: new Date().toISOString()
        }
      ];
      
      return res.status(200).json({ services: mockServices });
    } catch (error) {
      return res.status(500).json({ error: 'Erreur serveur' });
    }
  },

  getServiceById: async (req: Request, res: Response) => {
    try {
      const { id } = req.params;
      
      // TODO: Implémenter la logique de récupération par ID
      if (!id) {
        return res.status(400).json({ error: 'ID du service requis' });
      }
      
      // Simulation de récupération
      const mockService = {
        id,
        name: 'Vidange moteur',
        description: 'Vidange complète du moteur avec filtre à huile',
        price: 89.99,
        category: 'Entretien',
        createdAt: new Date().toISOString()
      };
      
      return res.status(200).json({ service: mockService });
    } catch (error) {
      return res.status(500).json({ error: 'Erreur serveur' });
    }
  },

  updateService: async (req: Request, res: Response) => {
    try {
      const { id } = req.params;
      const { name, description, price, category } = req.body;
      
      // TODO: Implémenter la logique de mise à jour
      if (!id) {
        return res.status(400).json({ error: 'ID du service requis' });
      }
      
      // Simulation de mise à jour
      const updatedService = {
        id,
        name: name || 'Vidange moteur',
        description: description || 'Vidange complète du moteur avec filtre à huile',
        price: price ? parseFloat(price) : 89.99,
        category: category || 'Entretien',
        updatedAt: new Date().toISOString()
      };
      
      return res.status(200).json({ 
        message: 'Service mis à jour avec succès',
        service: updatedService
      });
    } catch (error) {
      return res.status(500).json({ error: 'Erreur serveur' });
    }
  },

  deleteService: async (req: Request, res: Response) => {
    try {
      const { id } = req.params;
      
      // TODO: Implémenter la logique de suppression
      if (!id) {
        return res.status(400).json({ error: 'ID du service requis' });
      }
      
      // Simulation de suppression
      return res.status(200).json({ 
        message: 'Service supprimé avec succès',
        deletedId: id
      });
    } catch (error) {
      return res.status(500).json({ error: 'Erreur serveur' });
    }
  }
}; 