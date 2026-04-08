import api from './client';
import { AppNotification, PaginationMeta } from '../types';

export const notificationsApi = {
  list: async (params?: {
    page?: number;
    per_page?: number;
    unread_only?: boolean;
  }): Promise<{ notifications: AppNotification[]; unread_count: number; meta: PaginationMeta }> => {
    const { data } = await api.get('/api/v2/notifications', { params });
    return data;
  },

  markAsRead: async (id: number): Promise<void> => {
    await api.put(`/api/v2/notifications/${id}/read`);
  },

  markAllAsRead: async (): Promise<void> => {
    await api.put('/api/v2/notifications/read_all');
  },
};
