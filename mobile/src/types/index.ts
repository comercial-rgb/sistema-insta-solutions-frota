// ===== USER & AUTH =====
export interface User {
  id: number;
  name: string;
  email: string;
  profile_id: number;
  client_id: number | null;
  cpf?: string;
  cnpj?: string;
  phone?: string;
  cellphone?: string;
  fantasy_name?: string;
  department?: string;
  registration?: string;
  is_blocked: boolean;
  os_blocked: boolean;
  needs_km: boolean;
  require_vehicle_photos: boolean;
  qr_nfc_enabled: boolean;
  state?: string;
  city?: string;
  created_at: string;
  updated_at?: string;
}

export interface AuthResponse {
  status: string;
  token: string;
  profile_id: number;
  current_user_id: number;
}

export enum ProfileId {
  ADMINISTRADOR = 1,
  USUARIO = 2,
  CLIENTE = 3,
  GESTOR = 4,
  ADICIONAL = 5,
  FORNECEDOR = 6,
}

// ===== VEHICLE =====
export interface Vehicle {
  id: number;
  board: string;
  brand: string;
  model: string;
  year: string;
  color?: string;
  renavam?: string;
  chassi?: string;
  market_value?: number;
  acquisition_date?: string;
  active: boolean;
  fuel_type?: string;
  vehicle_type?: string;
  cost_center?: string;
  sub_unit?: string;
  model_year?: string;
}

export interface VehicleDetail {
  vehicle: Vehicle;
  current_km: number | null;
  km_history: KmRecord[];
  pending_alerts: MaintenanceAlertSummary[];
  recent_os: OrderServiceSummary[];
  consumed_values?: {
    maintenance: { total: number; count: number };
    fuel: { total: number; count: number };
  };
}

// ===== KM =====
export interface KmRecord {
  id: number;
  km: number;
  origin: string;
  observation?: string;
  user_name: string;
  order_service_code?: string;
  created_at: string;
  date?: string;
  user?: string;
}

// ===== ORDER SERVICE =====
export interface OrderServiceSummary {
  id: number;
  code: string;
  status: string;
  status_id: number;
  vehicle_board?: string;
  vehicle_model?: string;
  driver?: string;
  km?: number;
  type?: string;
  type_id?: number;
  provider?: string;
  client_name?: string;
  cost_center?: string;
  created_at: string;
  updated_at: string;
}

export interface OrderServiceDetail {
  id: number;
  code: string;
  status: string;
  status_id: number;
  vehicle: {
    id: number;
    board: string;
    brand: string;
    model: string;
    year: string;
  };
  driver?: string;
  km?: number;
  details: string;
  type?: string;
  type_id?: number;
  provider?: { id: number; name: string } | null;
  service_type?: string;
  commitment?: { id: number; number: string } | null;
  maintenance_plan?: { id: number; name: string } | null;
  cancel_justification?: string;
  origin_type?: string;
  created_at: string;
  updated_at: string;
}

export interface Proposal {
  id: number;
  code: string;
  status: string;
  status_id: number;
  provider?: { id: number; name: string } | null;
  total_value: number;
  total_discount: number;
  is_complement: boolean;
  pending_approval: boolean;
  pending_authorization: boolean;
  items: ProposalItem[];
  created_at: string;
}

export interface ProposalItem {
  id: number;
  service_name: string;
  quantity: number;
  unit_value: number;
  total_value: number;
  discount: number;
}

export interface OrderServiceStatus {
  id: number;
  name: string;
}

export interface ProviderServiceType {
  id: number;
  name: string;
}

// ===== DASHBOARD =====
export interface DashboardData {
  summary: {
    total_os: number;
    os_open: number;
    os_approved: number;
    os_awaiting_approval: number;
    os_paid: number;
    os_cancelled: number;
    vehicles_count: number;
    anomalies_open: number;
    pending_maintenance_alerts: number;
  };
  os_by_month: { month: string; count: number }[];
  os_values_by_type: { type: string; value: number }[];
  user: {
    id: number;
    name: string;
    email: string;
    profile_id: number;
    client_id: number;
    qr_nfc_enabled: boolean;
  };
}

// ===== ANOMALY =====
export interface Anomaly {
  id: number;
  title: string;
  description: string;
  severity: 'low' | 'medium' | 'high' | 'critical';
  status: 'open' | 'in_progress' | 'resolved' | 'closed';
  category?: string;
  vehicle_board?: string;
  vehicle_model?: string;
  user_name: string;
  created_at: string;
  has_photos: boolean;
  cost_center?: string;
  resolved_at?: string;
  resolved_by?: string;
  resolution_notes?: string;
  photos?: string[];
}

// ===== BALANCE =====
export interface Balance {
  cost_center: { id: number; name: string };
  budget_value: number;
  total_committed: number;
  total_cancelled: number;
  total_consumed: number;
  available: number;
  commitments: Commitment[];
}

export interface Commitment {
  id: number;
  number: string;
  value: number;
  cancelled: number;
  contract?: { id: number; name: string; number: string } | null;
}

export interface BalanceSummary {
  total_budget: number;
  total_committed: number;
  total_consumed: number;
  total_available: number;
}

// ===== MAINTENANCE ALERT =====
export interface MaintenanceAlert {
  id: number;
  alert_type: 'km' | 'days';
  status: string;
  message: string;
  current_km?: number;
  target_km?: number;
  target_date?: string;
  vehicle: {
    id: number;
    board: string;
    model: string;
  };
  plan_item?: {
    id: number;
    name: string;
    plan_type: string;
  } | null;
  acknowledged_at?: string;
  created_at: string;
}

export interface MaintenanceAlertSummary {
  id: number;
  message: string;
  alert_type: string;
  target_km?: number;
  target_date?: string;
}

// ===== NOTIFICATION =====
export interface AppNotification {
  id: number;
  title: string;
  message: string;
  is_important: boolean;
  read: boolean;
  created_at: string;
}

// ===== PAGINATION =====
export interface PaginationMeta {
  current_page: number;
  total_pages: number;
  total_count: number;
}

export interface PaginatedResponse<T> {
  data: T[];
  meta: PaginationMeta;
}

// ===== CONTACT =====
export interface ContactInfo {
  company: string;
  email: string;
  phone: string;
  whatsapp: string;
  address: string;
  hours: string;
}
