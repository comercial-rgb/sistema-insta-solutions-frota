import api from './client';
import { DashboardData } from '../types';

export const dashboardApi = {
  getData: async (): Promise<DashboardData> => {
    const { data } = await api.get('/api/v2/dashboard');
    return data;
  },
};
