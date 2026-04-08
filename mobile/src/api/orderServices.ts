import api from './client';
import {
  OrderServiceSummary,
  OrderServiceDetail,
  Proposal,
  OrderServiceStatus,
  ProviderServiceType,
  PaginationMeta,
} from '../types';

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
};
