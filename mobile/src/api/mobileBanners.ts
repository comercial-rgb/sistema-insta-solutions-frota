import api from './client';
import { MobileBanner } from '../types';

export const mobileBannersApi = {
  list: async (): Promise<{ banners: MobileBanner[] }> => {
    const { data } = await api.get('/api/v2/mobile_banners');
    return data;
  },
};
