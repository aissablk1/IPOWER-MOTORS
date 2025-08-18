import { motion } from 'framer-motion';
import { Car, Shield, Zap, Users } from 'lucide-react';

const Home = () => {
  const features = [
    {
      icon: Car,
      title: 'Services Automobiles',
      description: 'Entretien, réparation et optimisation de votre véhicule avec des techniciens experts.',
    },
    {
      icon: Shield,
      title: 'Garantie Qualité',
      description: 'Tous nos services sont garantis avec des pièces d\'origine et une expertise certifiée.',
    },
    {
      icon: Zap,
      title: 'Performance',
      description: 'Améliorez les performances de votre véhicule avec nos solutions personnalisées.',
    },
    {
      icon: Users,
      title: 'Service Client',
      description: 'Une équipe dédiée à votre satisfaction avec un accompagnement personnalisé.',
    },
  ];

  return (
    <div className="min-h-screen bg-gradient-to-br from-gray-50 to-gray-100">
      {/* Hero Section */}
      <section className="relative overflow-hidden bg-white">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-24">
          <div className="text-center">
            <motion.h1
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.6 }}
              className="text-4xl md:text-6xl font-bold text-gray-900 mb-6"
            >
              IPOWER MOTORS
            </motion.h1>
            <motion.p
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.6, delay: 0.2 }}
              className="text-xl text-gray-600 mb-8 max-w-3xl mx-auto"
            >
              Votre partenaire de confiance pour l'entretien et l'optimisation de votre véhicule.
              Expertise, qualité et performance au service de votre mobilité.
            </motion.p>
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.6, delay: 0.4 }}
              className="flex flex-col sm:flex-row gap-4 justify-center"
            >
              <button className="btn-primary text-lg px-8 py-3">
                Nos Services
              </button>
              <button className="btn-secondary text-lg px-8 py-3">
                Nous Contacter
              </button>
            </motion.div>
          </div>
        </div>
      </section>

      {/* Features Section */}
      <section className="py-20 bg-white">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center mb-16">
            <h2 className="text-3xl md:text-4xl font-bold text-gray-900 mb-4">
              Pourquoi Choisir IPOWER MOTORS ?
            </h2>
            <p className="text-xl text-gray-600 max-w-2xl mx-auto">
              Découvrez les avantages qui font de nous votre partenaire de confiance
            </p>
          </div>
          
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-8">
            {features.map((feature, index) => (
              <motion.div
                key={feature.title}
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ duration: 0.6, delay: index * 0.1 }}
                className="card text-center hover:shadow-lg transition-shadow duration-300"
              >
                <div className="w-16 h-16 bg-primary-100 rounded-full flex items-center justify-center mx-auto mb-4">
                  <feature.icon className="w-8 h-8 text-primary-600" />
                </div>
                <h3 className="text-xl font-semibold text-gray-900 mb-2">
                  {feature.title}
                </h3>
                <p className="text-gray-600">
                  {feature.description}
                </p>
              </motion.div>
            ))}
          </div>
        </div>
      </section>
    </div>
  );
};

export default Home; 