import api from './client';
import {
  OrderServiceSummary,
  OrderServiceDetail,
  Proposal,
  OrderServiceStatus,
  ProviderServiceType,
  PaginationMeta,
} from '../types';

export interface OSFormOption {
  id: number;
  name: string;
  number?: string;
}

export const orderServicesApi = {
  list: async (params?: {
    page?: number;
    per_page?: number;
    status_id?: number;
    vehicle_id?: number;
    search?: string;
  }): Promise<{ order_services: OrderServiceSummary[]; meta: PaginationMeta }> => {
    const { data } = await api.get('/api/v2/order_services', { params });
    return data;
  },

  getDetail: async (
    id: number
  ): Promise<{ order_service: OrderServiceDetail; proposals: Proposal[] }> => {
    const { data } = await api.get(`/api/v2/order_services/${id}`);
    return data;
  },

  create: async (params: {
    vehicle_id: number;
    provider_service_type_id: number;
    details: string;
    km?: number;
    driver?: string;
    order_service_type_id?: number;
    maintenance_plan_id?: number;
    commitment_id?: number;
    commitment_parts_id?: number;
    commitment_services_id?: number;
    client_id?: number;
    manager_id?: number;
    provider_id?: number;
    service_group_id?: number;
  }): Promise<{ order_service: OrderServiceDetail; message: string }> => {
    const { data } = await api.post('/api/v2/order_services', {
      ...params,
      origin_type: 'mobile',
    });
    return data;
  },

  approve: async (
    id: number
  ): Promise<{ order_service: OrderServiceDetail; message: string }> => {
    const { data } = await api.put(`/api/v2/order_services/${id}/approve`);
    return data;
  },

  reject: async (
    id: number,
    justification: string
  ): Promise<{ order_service: OrderServiceDetail; message: string }> => {
    const { data } = await api.put(`/api/v2/order_services/${id}/reject`, {
      justification,
    });
    return data;
  },

  getStatuses: async (): Promise<{ statuses: OrderServiceStatus[] }> => {
    const { data } = await api.get('/api/v2/order_services/statuses/all');
    return data;
  },

  getServiceTypes: async (): Promise<{ service_types: ProviderServiceType[] }> => {
    const { data } = await api.get('/api/v2/order_services/service_types/all');
    return data;
  },

  getOSTypes: async (): Promise<{ os_types: OSFormOption[] }> => {
    const { data } = await api.get('/api/v2/order_services/os_types/all');
    return data;
  },

  getMaintenancePlans: async (): Promise<{ maintenance_plans: OSFormOption[] }> => {
    const { data } = await api.get('/api/v2/order_services/maintenance_plans/all');
    return data;
  },

  getCommitments: async (): Promise<{ commitments: OSFormOption[] }> => {
    const { data } = await api.get('/api/v2/order_services/commitments/all');
    return data;
  },

  getClients: async (): Promise<{ clients: OSFormOption[] }> => {
    const { data } = await api.get('/api/v2/order_services/clients/all');
    return data;
  },

  getManagers: async (): Promise<{ managers: OSFormOption[] }> => {
    const { data } = await api.get('/api/v2/order_services/managers/all');
    return data;
  },

  getServiceGroups: async (): Promise<{ service_groups: OSFormOption[] }> => {
    const { data } = await api.get('/api/v2/order_services/service_groups/all');
    return data;
  },

  getProviders: async (): Promise<{ providers: OSFormOption[] }> => {
    const { data } = await api.get('/api/v2/order_services/providers/all');
    return data;
  },
};
