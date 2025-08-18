import { motion } from 'framer-motion';
import { Wrench, Settings, Zap, Shield, Clock, Users, Loader2 } from 'lucide-react';
import { useQuery } from '@tanstack/react-query';
import { apiService } from '../services/api';
import toast from 'react-hot-toast';

const Services = () => {
  // Récupération des services depuis l'API
  const { data: services, isLoading, error } = useQuery({
    queryKey: ['services'],
    queryFn: apiService.getServices,
    staleTime: 5 * 60 * 1000, // 5 minutes
  });

  // Gestion des erreurs
  if (error) {
    toast.error('Erreur lors du chargement des services');
    console.error('Services error:', error);
  }

  // Icônes pour les services
  const getServiceIcon = (category: string) => {
    const icons = {
      entretien: Wrench,
      reparation: Settings,
      optimisation: Zap,
      preparation: Shield,
      controle: Users,
      express: Clock,
    };
    return icons[category as keyof typeof icons] || Wrench;
  };

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
              Nos Services
            </h1>
            <p className="text-xl text-gray-600 max-w-3xl mx-auto">
              Découvrez notre gamme complète de services automobiles, 
              de l'entretien de base à l'optimisation de performance.
            </p>
          </motion.div>
        </div>
      </section>

      {/* Services Grid */}
      <section className="py-20">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          {isLoading ? (
            <div className="flex justify-center items-center py-20">
              <Loader2 className="w-8 h-8 animate-spin text-blue-600" />
              <span className="ml-2 text-gray-600">Chargement des services...</span>
            </div>
          ) : services && services.length > 0 ? (
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
              {services.map((service, index) => {
                const IconComponent = getServiceIcon(service.category);
                return (
                  <motion.div
                    key={service.id}
                    initial={{ opacity: 0, y: 20 }}
                    animate={{ opacity: 1, y: 0 }}
                    transition={{ duration: 0.6, delay: index * 0.1 }}
                    className="card hover:shadow-lg transition-all duration-300 hover:-translate-y-1"
                  >
                    <div className="w-16 h-16 bg-blue-100 rounded-full flex items-center justify-center mb-6">
                      <IconComponent className="w-8 h-8 text-blue-600" />
                    </div>
                    <h3 className="text-2xl font-semibold text-gray-900 mb-3">
                      {service.name}
                    </h3>
                    <p className="text-gray-600 mb-4">
                      {service.description}
                    </p>
                    <div className="flex items-center justify-between">
                      <span className="text-blue-600 font-semibold">
                        {service.price}
                      </span>
                      <button className="btn-primary">
                        Réserver
                      </button>
                    </div>
                  </motion.div>
                );
              })}
            </div>
          ) : (
            <div className="text-center py-20">
              <p className="text-gray-600">Aucun service disponible pour le moment.</p>
            </div>
          )}
        </div>
      </section>

      {/* CTA Section */}
      <section className="bg-blue-600 py-16">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 text-center">
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6 }}
          >
            <h2 className="text-3xl md:text-4xl font-bold text-white mb-4">
              Besoin d'un Service Personnalisé ?
            </h2>
            <p className="text-xl text-blue-100 mb-8 max-w-2xl mx-auto">
              Contactez-nous pour un devis personnalisé ou pour discuter de vos besoins spécifiques.
            </p>
            <button className="bg-white text-blue-600 hover:bg-gray-100 font-semibold py-3 px-8 rounded-lg transition-colors duration-200">
              Nous Contacter
            </button>
          </motion.div>
        </div>
      </section>
    </div>
  );
};

export default Services; 