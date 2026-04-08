import api from './client';
import { User, PaginationMeta } from '../types';

export const adminUsersApi = {
  list: async (params?: {
    page?: number;
    per_page?: number;
    profile_id?: number;
    search?: string;
  }): Promise<{ users: User[]; meta: PaginationMeta }> => {
    const { data } = await api.get('/api/v2/admin/users', { params });
    return data;
  },

  getDetail: async (id: number): Promise<{ user: User }> => {
    const { data } = await api.get(`/api/v2/admin/users/${id}`);
    return data;
  },

  create: async (params: {
    name: string;
    email: string;
    profile_id: number;
    password: string;
    cpf?: string;
    cnpj?: string;
    phone?: string;
    cellphone?: string;
    fantasy_name?: string;
    department?: string;
    registration?: string;
  }): Promise<{ user: User; message: string }> => {
    const { data } = await api.post('/api/v2/admin/users', params);
    return data;
  },

  update: async (
    id: number,
    params: Partial<User>
  ): Promise<{ user: User; message: string }> => {
    const { data } = await api.put(`/api/v2/admin/users/${id}`, params);
    return data;
  },

  toggleBlock: async (id: number): Promise<{ user: User; message: string }> => {
    const { data } = await api.put(`/api/v2/admin/users/${id}/toggle_block`);
    return data;
  },

  getProfiles: async () => {
    const { data } = await api.get('/api/v2/admin/profiles');
    return data;
  },
};
