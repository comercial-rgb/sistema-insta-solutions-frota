import api from './client';
import { AuthResponse } from '../types';

export const authApi = {
  login: async (email: string, password: string): Promise<AuthResponse> => {
    const { data } = await api.post('/api/v1/auth/login', { email, password });
    return data;
  },

  logout: async (): Promise<void> => {
    await api.post('/api/v1/auth/logout');
  },

  ping: async (): Promise<boolean> => {
    try {
      await api.get('/api/v1/auth/ping');
      return true;
    } catch {
      return false;
    }
  },

  recoverPassword: async (email: string) => {
    const { data } = await api.post('/api/v1/auth/recover_pass', { email });
    return data;
  },
};
