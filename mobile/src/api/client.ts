import axios, { AxiosInstance, InternalAxiosRequestConfig } from 'axios';
import Toast from 'react-native-toast-message';
import { storage } from '../utils/storage';
import { authSessionEvents } from './authSessionEvents';

const BASE_URL = __DEV__
  ? (process.env.EXPO_PUBLIC_API_URL ?? 'http://localhost:3000')
  : 'https://app.frotainstasolutions.com.br';

const api: AxiosInstance = axios.create({
  baseURL: BASE_URL,
  timeout: 30000,
  headers: {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  },
});

// Interceptor para adicionar token de autenticação
api.interceptors.request.use(
  async (config: InternalAxiosRequestConfig) => {
    const token = await storage.getToken();
    if (token) {
      config.headers.Authorization = token;
    }
    return config;
  },
  (error) => Promise.reject(error)
);

// Interceptor para tratamento de erros
api.interceptors.response.use(
  (response) => response,
  async (error) => {
    const status = error.response?.status;
    if (status === 401) {
      await storage.clear();
      authSessionEvents.notifySessionInvalid();
    }
    if (status === 429) {
      Toast.show({
        type: 'error',
        text1: 'Limite de tentativas',
        text2: 'Aguarde um minuto e tente novamente.',
      });
    }
    return Promise.reject(error);
  }
);

export default api;
