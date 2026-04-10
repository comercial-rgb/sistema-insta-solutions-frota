import api from './client';
import { VehicleChecklist, PaginationMeta } from '../types';

export const checklistsApi = {
  list: async (params?: {
    page?: number;
    per_page?: number;
    vehicle_id?: number;
    status?: string;
  }): Promise<{ vehicle_checklists: VehicleChecklist[]; meta: PaginationMeta }> => {
    const { data } = await api.get('/api/v2/vehicle_checklists', { params });
    return data;
  },

  getDetail: async (id: number): Promise<{ vehicle_checklist: VehicleChecklist }> => {
    const { data } = await api.get(`/api/v2/vehicle_checklists/${id}`);
    return data;
  },

  create: async (formData: FormData): Promise<{ vehicle_checklist: VehicleChecklist; message: string }> => {
    const { data } = await api.post('/api/v2/vehicle_checklists', formData, {
      headers: { 'Content-Type': 'multipart/form-data' },
    });
    return data;
  },
};
