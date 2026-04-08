import api from './client';
import { Anomaly, PaginationMeta } from '../types';

export const anomaliesApi = {
  list: async (params?: {
    page?: number;
    per_page?: number;
    status?: string;
    severity?: string;
    vehicle_id?: number;
  }): Promise<{ anomalies: Anomaly[]; meta: PaginationMeta }> => {
    const { data } = await api.get('/api/v2/anomalies', { params });
    return data;
  },

  getDetail: async (id: number): Promise<{ anomaly: Anomaly }> => {
    const { data } = await api.get(`/api/v2/anomalies/${id}`);
    return data;
  },

  create: async (params: {
    vehicle_id: number;
    title: string;
    description: string;
    severity?: string;
    category?: string;
  }): Promise<{ anomaly: Anomaly; message: string }> => {
    const { data } = await api.post('/api/v2/anomalies', params);
    return data;
  },

  updateStatus: async (
    id: number,
    params: { status?: string; resolution_notes?: string }
  ): Promise<{ anomaly: Anomaly; message: string }> => {
    const { data } = await api.put(`/api/v2/anomalies/${id}`, params);
    return data;
  },
};
