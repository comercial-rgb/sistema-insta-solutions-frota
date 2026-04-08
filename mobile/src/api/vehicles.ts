import api from './client';
import { Vehicle, VehicleDetail, PaginationMeta } from '../types';

export const vehiclesApi = {
  list: async (params?: {
    page?: number;
    per_page?: number;
    search?: string;
    active?: boolean;
    cost_center_id?: number;
  }): Promise<{ vehicles: Vehicle[]; meta: PaginationMeta }> => {
    const { data } = await api.get('/api/v2/vehicles', { params });
    return data;
  },

  getDetail: async (id: number): Promise<VehicleDetail> => {
    const { data } = await api.get(`/api/v2/vehicles/${id}`);
    return data;
  },
};
