import api from './client';
import { Balance, BalanceSummary } from '../types';

export const balancesApi = {
  list: async (params?: {
    cost_center_id?: number;
    contract_id?: number;
  }): Promise<{ summary: BalanceSummary; balances: Balance[] }> => {
    const { data } = await api.get('/api/v2/balances', { params });
    return data;
  },

  contracts: async () => {
    const { data } = await api.get('/api/v2/balances/contracts');
    return data;
  },
};
