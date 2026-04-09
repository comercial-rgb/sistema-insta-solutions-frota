import api from './client';
import { Balance, BalanceSummary } from '../types';

export const balancesApi = {
  getBalances: async (params?: {
    cost_center_id?: number;
    contract_id?: number;
    client_id?: number;
  }): Promise<{ summary: BalanceSummary; balances: Balance[] }> => {
    const { data } = await api.get('/api/v2/balances', { params });
    return data;
  },

  getContracts: async (params?: {
    client_id?: number;
  }) => {
    const { data } = await api.get('/api/v2/balances/contracts', { params });
    return data;
  },
};
