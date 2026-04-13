import api from './client';
import { MaintenancePlan, MaintenancePlanItem, MaintenancePlanVehicle, MaintenancePlanItemService, PaginationMeta } from '../types';

interface AvailableService {
  id: number;
  name: string;
  category_id: number;
  type: 'peca' | 'servico';
  price: number | null;
}

export const maintenancePlansApi = {
  list: async (params?: {
    active?: boolean;
    page?: number;
    per_page?: number;
  }): Promise<{ plans: MaintenancePlan[]; meta: PaginationMeta }> => {
    const { data } = await api.get('/api/v2/maintenance_plans', { params });
    return data;
  },

  show: async (id: number): Promise<{ plan: MaintenancePlan }> => {
    const { data } = await api.get(`/api/v2/maintenance_plans/${id}`);
    return data;
  },

  create: async (params: {
    name: string;
    description?: string;
    active?: boolean;
    items?: Omit<MaintenancePlanItem, 'id'>[];
  }): Promise<{ plan: MaintenancePlan; message: string }> => {
    const { data } = await api.post('/api/v2/maintenance_plans', params);
    return data;
  },

  update: async (
    id: number,
    params: {
      name?: string;
      description?: string;
      active?: boolean;
      items?: MaintenancePlanItem[];
    }
  ): Promise<{ plan: MaintenancePlan; message: string }> => {
    const { data } = await api.put(`/api/v2/maintenance_plans/${id}`, params);
    return data;
  },

  destroy: async (id: number): Promise<{ message: string }> => {
    const { data } = await api.delete(`/api/v2/maintenance_plans/${id}`);
    return data;
  },

  addVehicles: async (
    id: number,
    vehicleIds: number[]
  ): Promise<{ plan: MaintenancePlan; message: string }> => {
    const { data } = await api.post(`/api/v2/maintenance_plans/${id}/vehicles`, {
      vehicle_ids: vehicleIds,
    });
    return data;
  },

  removeVehicle: async (
    id: number,
    vehicleId: number
  ): Promise<{ plan: MaintenancePlan; message: string }> => {
    const { data } = await api.delete(`/api/v2/maintenance_plans/${id}/vehicles/${vehicleId}`);
    return data;
  },

  availableVehicles: async (
    id: number
  ): Promise<{ vehicles: MaintenancePlanVehicle[] }> => {
    const { data } = await api.get(`/api/v2/maintenance_plans/${id}/available_vehicles`);
    return data;
  },

  addServiceToItem: async (
    planId: number,
    itemId: number,
    params: { service_id: number; quantity?: number; observation?: string }
  ): Promise<{ plan: MaintenancePlan; message: string }> => {
    const { data } = await api.post(
      `/api/v2/maintenance_plans/${planId}/items/${itemId}/services`,
      params
    );
    return data;
  },

  removeServiceFromItem: async (
    planId: number,
    itemId: number,
    serviceId: number
  ): Promise<{ plan: MaintenancePlan; message: string }> => {
    const { data } = await api.delete(
      `/api/v2/maintenance_plans/${planId}/items/${itemId}/services/${serviceId}`
    );
    return data;
  },

  availableServices: async (params?: {
    search?: string;
    category?: 'pecas' | 'servicos';
  }): Promise<{ services: AvailableService[] }> => {
    const { data } = await api.get('/api/v2/maintenance_plans/available_services', { params });
    return data;
  },
};
