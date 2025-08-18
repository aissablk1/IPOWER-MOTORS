import { Request, Response } from 'express';
import { ContactForm } from '../types/index.js';

export const contactController = {
  submitContact: async (req: Request, res: Response) => {
    try {
      const contactData: ContactForm = req.body;

      // Log the contact form submission
      console.log('New contact form submission:', {
        ...contactData,
        timestamp: new Date().toISOString(),
        ip: req.ip,
      });

      // TODO: Save to database
      // TODO: Send email notification
      // TODO: Send confirmation email to user

      // For now, just return success
      res.status(201).json({
        success: true,
        message: 'Votre message a été envoyé avec succès. Nous vous répondrons dans les plus brefs délais.',
        data: {
          id: Date.now().toString(), // Temporary ID
          ...contactData,
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
  },
}; 