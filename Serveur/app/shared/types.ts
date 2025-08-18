// Types partagés entre frontend et backend IPOWER MOTORS

// Types de base
export interface BaseEntity {
  id: string;
  created_at: string;
  updated_at: string;
}

// Types d'utilisateur
export interface User extends BaseEntity {
  email: string;
  first_name: string;
  last_name: string;
  role: UserRole;
  phone?: string;
  is_active: boolean;
  email_verified: boolean;
  last_login?: string;
}

export type UserRole = 'admin' | 'manager' | 'user';

// Types de client
export interface Client extends BaseEntity {
  user_id?: string;
  company_name?: string;
  siret?: string;
  address?: string;
  city?: string;
  postal_code?: string;
  country: string;
  phone?: string;
  email?: string;
  notes?: string;
}

// Types de véhicule
export interface Vehicle extends BaseEntity {
  client_id: string;
  license_plate: string;
  brand?: string;
  model?: string;
  year?: number;
  vin?: string;
  color?: string;
  mileage?: number;
  fuel_type?: string;
  transmission?: string;
  engine_size?: string;
  notes?: string;
}

// Types de service
export interface Service extends BaseEntity {
  name: string;
  description?: string;
  category?: string;
  base_price?: number;
  duration_minutes?: number;
  is_active: boolean;
}

// Types de rendez-vous
export interface Appointment extends BaseEntity {
  client_id: string;
  vehicle_id: string;
  service_id?: string;
  scheduled_date: string;
  duration_minutes: number;
  status: AppointmentStatus;
  notes?: string;
  technician_notes?: string;
  total_price?: number;
}

export type AppointmentStatus = 'scheduled' | 'confirmed' | 'in_progress' | 'completed' | 'cancelled';

// Types de facture
export interface Invoice extends BaseEntity {
  appointment_id?: string;
  client_id: string;
  invoice_number: string;
  issue_date: string;
  due_date: string;
  status: InvoiceStatus;
  subtotal: number;
  tax_rate: number;
  tax_amount: number;
  total_amount: number;
  notes?: string;
}

export type InvoiceStatus = 'draft' | 'sent' | 'paid' | 'overdue' | 'cancelled';

// Types d'élément de facture
export interface InvoiceItem extends BaseEntity {
  invoice_id: string;
  service_id?: string;
  description: string;
  quantity: number;
  unit_price: number;
  total_price: number;
}

// Types de document
export interface Document extends BaseEntity {
  client_id?: string;
  vehicle_id?: string;
  appointment_id?: string;
  filename: string;
  original_filename: string;
  file_path: string;
  file_size: number;
  mime_type?: string;
  document_type?: string;
  description?: string;
  uploaded_by?: string;
}

// Types de notification
export interface Notification extends BaseEntity {
  user_id: string;
  title: string;
  message: string;
  type: NotificationType;
  is_read: boolean;
  read_at?: string;
}

export type NotificationType = 'info' | 'success' | 'warning' | 'error';

// Types d'API
export interface ApiResponse<T> {
  success: boolean;
  data?: T;
  message?: string;
  error?: string;
  pagination?: PaginationInfo;
}

export interface PaginationInfo {
  page: number;
  limit: number;
  total: number;
  total_pages: number;
}

// Types de filtres
export interface AppointmentFilter {
  client_id?: string;
  vehicle_id?: string;
  status?: AppointmentStatus;
  start_date?: string;
  end_date?: string;
  page?: number;
  limit?: number;
}

export interface ClientFilter {
  search?: string;
  city?: string;
  company_name?: string;
  page?: number;
  limit?: number;
}

// Types de statistiques
export interface DashboardStats {
  total_clients: number;
  total_vehicles: number;
  total_appointments: number;
  total_revenue: number;
  appointments_today: number;
  appointments_this_week: number;
  pending_invoices: number;
  recent_activities: ActivityLog[];
}

export interface ActivityLog {
  id: string;
  action: string;
  entity_type: string;
  entity_id: string;
  user_id?: string;
  details?: Record<string, any>;
  created_at: string;
}

// Types d'authentification
export interface LoginRequest {
  email: string;
  password: string;
}

export interface LoginResponse {
  user: User;
  token: string;
  refresh_token: string;
  expires_in: number;
}

export interface RefreshTokenRequest {
  refresh_token: string;
}

export interface ChangePasswordRequest {
  current_password: string;
  new_password: string;
}

// Types de validation
export interface ValidationError {
  field: string;
  message: string;
}

export interface ValidationResult {
  isValid: boolean;
  errors: ValidationError[];
}

// Types d'export
export interface ExportOptions {
  format: 'csv' | 'pdf' | 'excel';
  filters?: Record<string, any>;
  fields?: string[];
}

// Types de configuration
export interface AppConfig {
  app_name: string;
  app_version: string;
  environment: string;
  api_url: string;
  cdn_url: string;
  features: {
    enable_notifications: boolean;
    enable_file_upload: boolean;
    enable_advanced_search: boolean;
  };
}
