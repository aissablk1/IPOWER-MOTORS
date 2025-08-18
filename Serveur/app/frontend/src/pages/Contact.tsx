import { motion } from 'framer-motion';
import { Mail, Phone, MapPin, Clock, Loader2 } from 'lucide-react';
import { useState } from 'react';
import { useMutation, useQuery } from '@tanstack/react-query';
import { apiService, type ContactFormData } from '../services/api';
import toast from 'react-hot-toast';

const Contact = () => {
  const [formData, setFormData] = useState<ContactFormData>({
    firstName: '',
    lastName: '',
    email: '',
    phone: '',
    service: '',
    message: '',
  });

  // Récupération des services pour le formulaire
  const { data: services } = useQuery({
    queryKey: ['services'],
    queryFn: apiService.getServices,
    staleTime: 5 * 60 * 1000,
  });

  // Mutation pour soumettre le formulaire
  const submitMutation = useMutation({
    mutationFn: apiService.submitContact,
    onSuccess: () => {
      toast.success('Message envoyé avec succès !');
      setFormData({
        firstName: '',
        lastName: '',
        email: '',
        phone: '',
        service: '',
        message: '',
      });
    },
    onError: (error) => {
      toast.error('Erreur lors de l\'envoi du message');
      console.error('Contact submission error:', error);
    },
  });

  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement | HTMLSelectElement>) => {
    const { name, value } = e.target;
    setFormData(prev => ({
      ...prev,
      [name]: value,
    }));
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    submitMutation.mutate(formData);
  };
  const contactInfo = [
    {
      icon: Phone,
      title: 'Téléphone',
      content: '+33 1 23 45 67 89',
      description: 'Lun-Ven: 8h-18h',
    },
    {
      icon: Mail,
      title: 'Email',
      content: 'contact@ipower-motors.fr',
      description: 'Réponse sous 24h',
    },
    {
      icon: MapPin,
      title: 'Adresse',
      content: '123 Rue de l\'Automobile',
      description: '75001 Paris, France',
    },
    {
      icon: Clock,
      title: 'Horaires',
      content: 'Lundi - Vendredi',
      description: '8h00 - 18h00',
    },
  ];

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <section className="bg-white py-16">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6 }}
            className="text-center"
          >
            <h1 className="text-4xl md:text-5xl font-bold text-gray-900 mb-6">
              Contactez-Nous
            </h1>
            <p className="text-xl text-gray-600 max-w-3xl mx-auto">
              Notre équipe est à votre disposition pour répondre à toutes vos questions 
              et vous accompagner dans vos projets automobiles.
            </p>
          </motion.div>
        </div>
      </section>

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-20">
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-16">
          {/* Contact Form */}
          <motion.div
            initial={{ opacity: 0, x: -20 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ duration: 0.6 }}
          >
            <div className="card">
              <h2 className="text-2xl font-bold text-gray-900 mb-6">
                Envoyez-nous un message
              </h2>
              <form onSubmit={handleSubmit} className="space-y-6">
                <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                  <div>
                    <label htmlFor="firstName" className="block text-sm font-medium text-gray-700 mb-2">
                      Prénom
                    </label>
                    <input
                      type="text"
                      id="firstName"
                      name="firstName"
                      value={formData.firstName}
                      onChange={handleInputChange}
                      className="input-field"
                      placeholder="Votre prénom"
                      required
                    />
                  </div>
                  <div>
                    <label htmlFor="lastName" className="block text-sm font-medium text-gray-700 mb-2">
                      Nom
                    </label>
                    <input
                      type="text"
                      id="lastName"
                      name="lastName"
                      value={formData.lastName}
                      onChange={handleInputChange}
                      className="input-field"
                      placeholder="Votre nom"
                      required
                    />
                  </div>
                </div>
                
                <div>
                  <label htmlFor="email" className="block text-sm font-medium text-gray-700 mb-2">
                    Email
                  </label>
                  <input
                    type="email"
                    id="email"
                    name="email"
                    value={formData.email}
                    onChange={handleInputChange}
                    className="input-field"
                    placeholder="votre@email.com"
                    required
                  />
                </div>
                
                <div>
                  <label htmlFor="phone" className="block text-sm font-medium text-gray-700 mb-2">
                    Téléphone
                  </label>
                  <input
                    type="tel"
                    id="phone"
                    name="phone"
                    value={formData.phone}
                    onChange={handleInputChange}
                    className="input-field"
                    placeholder="+33 1 23 45 67 89"
                    required
                  />
                </div>
                
                <div>
                  <label htmlFor="service" className="block text-sm font-medium text-gray-700 mb-2">
                    Service souhaité
                  </label>
                  <select 
                    id="service" 
                    name="service"
                    value={formData.service}
                    onChange={handleInputChange}
                    className="input-field"
                    required
                  >
                    <option value="">Sélectionnez un service</option>
                    {services?.map((service) => (
                      <option key={service.id} value={service.id}>
                        {service.name}
                      </option>
                    ))}
                  </select>
                </div>
                
                <div>
                  <label htmlFor="message" className="block text-sm font-medium text-gray-700 mb-2">
                    Message
                  </label>
                  <textarea
                    id="message"
                    name="message"
                    rows={4}
                    value={formData.message}
                    onChange={handleInputChange}
                    className="input-field resize-none"
                    placeholder="Décrivez votre demande..."
                    required
                  />
                </div>
                
                <button 
                  type="submit" 
                  className="btn-primary w-full py-3"
                  disabled={submitMutation.isPending}
                >
                  {submitMutation.isPending ? (
                    <>
                      <Loader2 className="w-4 h-4 animate-spin mr-2" />
                      Envoi en cours...
                    </>
                  ) : (
                    'Envoyer le message'
                  )}
                </button>
              </form>
            </div>
          </motion.div>

          {/* Contact Information */}
          <motion.div
            initial={{ opacity: 0, x: 20 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ duration: 0.6, delay: 0.2 }}
            className="space-y-8"
          >
            <div>
              <h2 className="text-2xl font-bold text-gray-900 mb-6">
                Informations de contact
              </h2>
              <div className="space-y-6">
                {contactInfo.map((info, index) => (
                  <motion.div
                    key={info.title}
                    initial={{ opacity: 0, y: 20 }}
                    animate={{ opacity: 1, y: 0 }}
                    transition={{ duration: 0.6, delay: 0.3 + index * 0.1 }}
                    className="flex items-start space-x-4"
                  >
                    <div className="w-12 h-12 bg-blue-100 rounded-full flex items-center justify-center flex-shrink-0">
                      <info.icon className="w-6 h-6 text-blue-600" />
                    </div>
                    <div>
                      <h3 className="text-lg font-semibold text-gray-900">
                        {info.title}
                      </h3>
                      <p className="text-gray-900 font-medium">
                        {info.content}
                      </p>
                      <p className="text-gray-600 text-sm">
                        {info.description}
                      </p>
                    </div>
                  </motion.div>
                ))}
              </div>
            </div>

            {/* Map Placeholder */}
            <div className="card">
              <h3 className="text-lg font-semibold text-gray-900 mb-4">
                Notre localisation
              </h3>
              <div className="bg-gray-200 rounded-lg h-64 flex items-center justify-center">
                <p className="text-gray-500">
                  Carte interactive à intégrer
                </p>
              </div>
            </div>
          </motion.div>
        </div>
      </div>
    </div>
  );
};

export default Contact; 