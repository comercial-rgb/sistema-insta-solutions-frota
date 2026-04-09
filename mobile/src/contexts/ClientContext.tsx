import React, { createContext, useContext, useState, useEffect } from 'react';
import { useAuth } from './AuthContext';
import { orderServicesApi, OSFormOption } from '../api/orderServices';

interface ClientContextType {
  selectedClientId: number | null;
  selectedClientName: string;
  setSelectedClient: (id: number | null, name: string) => void;
  clients: OSFormOption[];
  isLoadingClients: boolean;
  needsClientSelection: boolean;
}

const ClientContext = createContext<ClientContextType | undefined>(undefined);

export function ClientProvider({ children }: { children: React.ReactNode }) {
  const { isAdmin, isAuthenticated } = useAuth();
  const [selectedClientId, setSelectedClientId] = useState<number | null>(null);
  const [selectedClientName, setSelectedClientName] = useState('');
  const [clients, setClients] = useState<OSFormOption[]>([]);
  const [isLoadingClients, setIsLoadingClients] = useState(false);

  useEffect(() => {
    if (isAdmin && isAuthenticated) {
      setIsLoadingClients(true);
      orderServicesApi
        .getClients()
        .then((res) => setClients(res.clients ?? []))
        .catch(() => setClients([]))
        .finally(() => setIsLoadingClients(false));
    }
  }, [isAdmin, isAuthenticated]);

  const setSelectedClient = (id: number | null, name: string) => {
    setSelectedClientId(id);
    setSelectedClientName(name);
  };

  return (
    <ClientContext.Provider
      value={{
        selectedClientId,
        selectedClientName,
        setSelectedClient,
        clients,
        isLoadingClients,
        needsClientSelection: isAdmin,
      }}
    >
      {children}
    </ClientContext.Provider>
  );
}

export function useClientFilter(): ClientContextType {
  const context = useContext(ClientContext);
  if (!context) {
    throw new Error('useClientFilter deve ser usado dentro de ClientProvider');
  }
  return context;
}
