import api from './client';
import { MaintenanceAlert, PaginationMeta } from '../types';

export const maintenanceAlertsApi = {
  list: async (params?: {
    status?: string;
    vehicle_id?: number;
    page?: number;
    per_page?: number;
  }): Promise<{ alerts: MaintenanceAlert[]; pending_count: number; meta: PaginationMeta }> => {
    const { data } = await api.get('/api/v2/maintenance_alerts', { params });
    return data;
  },

  acknowledge: async (id: number): Promise<{ alert: MaintenanceAlert; message: string }> => {
    const { data } = await api.put(`/api/v2/maintenance_alerts/${id}/acknowledge`);
    return data;
  },

  dismiss: async (id: number): Promise<{ alert: MaintenanceAlert; message: string }> => {
    const { data } = await api.put(`/api/v2/maintenance_alerts/${id}/dismiss`);
    return data;
  },

  checkAlerts: async (): Promise<{ message: string }> => {
    const { data } = await api.post('/api/v2/maintenance_alerts/check');
    return data;
  },
};
