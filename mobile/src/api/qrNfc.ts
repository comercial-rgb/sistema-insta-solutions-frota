import api from './client';

export const qrNfcApi = {
  requestService: async (params: {
    token: string;
    provider_service_type_id: number;
    details: string;
    km?: number;
    driver?: string;
  }) => {
    const { data } = await api.post('/api/v2/qr_nfc/request_service', params);
    return data;
  },

  generateToken: async (vehicleId: number) => {
    const { data } = await api.post('/api/v2/qr_nfc/generate_token', {
      vehicle_id: vehicleId,
    });
    return data;
  },

  getStatus: async (): Promise<{ enabled: boolean }> => {
    const { data } = await api.get('/api/v2/qr_nfc/status');
    return data;
  },
};
