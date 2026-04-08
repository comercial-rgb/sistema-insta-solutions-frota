import api from './client';
import { KmRecord, PaginationMeta } from '../types';

export const kmApi = {
  register: async (params: {
    vehicle_id: number;
    km: number;
    origin?: string;
    observation?: string;
  }): Promise<{ km_record: KmRecord; message: string }> => {
    const { data } = await api.post('/api/v2/km_records', params);
    return data;
  },

  history: async (params: {
    vehicle_id: number;
    page?: number;
    per_page?: number;
  }): Promise<{ km_records: KmRecord[]; current_km: number | null; meta: PaginationMeta }> => {
    const { data } = await api.get('/api/v2/km_records', { params });
    return data;
  },
};
