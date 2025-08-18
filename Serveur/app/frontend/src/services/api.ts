import axios from 'axios';

// Configuration de l'API
const API_BASE_URL = 'http://localhost:3001';

// Instance axios configurée
export const api = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
  timeout: 10000,
});

// Types pour les réponses API
export interface ApiResponse<T> {
  success: boolean;
  message: string;
  data?: T;
  timestamp: string;
  environment: string;
}

export interface ContactFormData {
  firstName: string;
  lastName: string;
  email: string;
  phone: string;
  service: string;
  message: string;
}

export interface Service {
  id: string;
  name: string;
  description: string;
  price: string;
  category: string;
  isActive: boolean;
}

// Services API
export const apiService = {
  // Health check
  health: async (): Promise<ApiResponse<any>> => {
    const response = await api.get('/health');
    return response.data;
  },

  // Services
  getServices: async (): Promise<Service[]> => {
    const response = await api.get('/api/services');
    return response.data;
  },

  getServiceById: async (id: string): Promise<Service> => {
    const response = await api.get(`/api/services/${id}`);
    return response.data;
  },

  getServicesByCategory: async (category: string): Promise<Service[]> => {
    const response = await api.get(`/api/services/category/${category}`);
    return response.data;
  },

  // Contact
  submitContact: async (data: ContactFormData): Promise<ApiResponse<any>> => {
    const response = await api.post('/api/contact', data);
    return response.data;
  },
};

// Intercepteurs pour la gestion des erreurs
api.interceptors.response.use(
  (response) => response,
  (error) => {
    console.error('API Error:', error);
    return Promise.reject(error);
  }
);

export default apiService; 