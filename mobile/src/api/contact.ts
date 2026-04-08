import api from './client';
import { ContactInfo } from '../types';

export const contactApi = {
  send: async (params: {
    subject: string;
    message: string;
    category?: string;
  }): Promise<{ message: string }> => {
    const { data } = await api.post('/api/v2/contact', params);
    return data;
  },

  getInfo: async (): Promise<ContactInfo> => {
    const { data } = await api.get('/api/v2/contact/info');
    return data;
  },
};
