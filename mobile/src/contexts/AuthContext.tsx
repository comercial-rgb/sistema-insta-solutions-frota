import React, { createContext, useContext, useEffect, useState, useCallback } from 'react';
import { authApi } from '../api/auth';
import { authSessionEvents } from '../api/authSessionEvents';
import { storage } from '../utils/storage';
import { ProfileId } from '../types';

interface AuthState {
  token: string | null;
  userId: number | null;
  profileId: number | null;
  isLoading: boolean;
  isAuthenticated: boolean;
}

interface AuthContextType extends AuthState {
  login: (email: string, password: string) => Promise<void>;
  logout: () => Promise<void>;
  isAdmin: boolean;
  isGestor: boolean;
  isCliente: boolean;
  isAdicional: boolean;
  isFornecedor: boolean;
  isMotorista: boolean;
  canApproveOS: boolean;
  canManageUsers: boolean;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [state, setState] = useState<AuthState>({
    token: null,
    userId: null,
    profileId: null,
    isLoading: true,
    isAuthenticated: false,
  });

  useEffect(() => {
    loadStoredAuth();
  }, []);

  useEffect(() => {
    authSessionEvents.setSessionInvalidListener(() => {
      setState({
        token: null,
        userId: null,
        profileId: null,
        isLoading: false,
        isAuthenticated: false,
      });
    });
    return () => authSessionEvents.setSessionInvalidListener(null);
  }, []);

  const loadStoredAuth = async () => {
    try {
      const token = await storage.getToken();
      const userData = await storage.getUser();

      if (token && userData) {
        const user = JSON.parse(userData);
        const isValid = await authApi.ping();

        if (isValid) {
          setState({
            token,
            userId: user.userId,
            profileId: user.profileId,
            isLoading: false,
            isAuthenticated: true,
          });
          return;
        }
      }
    } catch {
      // Token inválido
    }

    await storage.clear();
    setState({
      token: null,
      userId: null,
      profileId: null,
      isLoading: false,
      isAuthenticated: false,
    });
  };

  const login = useCallback(async (email: string, password: string) => {
    const response = await authApi.login(email, password);

    await storage.setToken(response.token);
    await storage.setUser(
      JSON.stringify({
        userId: response.current_user_id,
        profileId: response.profile_id,
      })
    );

    setState({
      token: response.token,
      userId: response.current_user_id,
      profileId: response.profile_id,
      isLoading: false,
      isAuthenticated: true,
    });
  }, []);

  const logout = useCallback(async () => {
    try {
      await authApi.logout();
    } catch {
      // Ignora erro de logout no servidor
    }

    await storage.clear();
    setState({
      token: null,
      userId: null,
      profileId: null,
      isLoading: false,
      isAuthenticated: false,
    });
  }, []);

  const isAdmin = state.profileId === ProfileId.ADMINISTRADOR;
  const isGestor = state.profileId === ProfileId.GESTOR;
  const isCliente = state.profileId === ProfileId.CLIENTE;
  const isAdicional = state.profileId === ProfileId.ADICIONAL;
  const isFornecedor = state.profileId === ProfileId.FORNECEDOR;
  const isMotorista = state.profileId === ProfileId.MOTORISTA;
  const canApproveOS = [ProfileId.ADMINISTRADOR, ProfileId.GESTOR, ProfileId.ADICIONAL].includes(
    state.profileId as ProfileId
  );
  const canManageUsers = [ProfileId.ADMINISTRADOR, ProfileId.GESTOR, ProfileId.CLIENTE, ProfileId.ADICIONAL].includes(
    state.profileId as ProfileId
  );

  return (
    <AuthContext.Provider
      value={{
        ...state,
        login,
        logout,
        isAdmin,
        isGestor,
        isCliente,
        isAdicional,
        isFornecedor,
        isMotorista,
        canApproveOS,
        canManageUsers,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth(): AuthContextType {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth deve ser usado dentro de AuthProvider');
  }
  return context;
}
