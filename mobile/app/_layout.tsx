import { Stack } from 'expo-router';
import { StatusBar } from 'expo-status-bar';
import { AuthProvider } from '../src/contexts/AuthContext';
import { ClientProvider } from '../src/contexts/ClientContext';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import Toast from 'react-native-toast-message';
import { colors } from '../src/theme/colors';

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      retry: 2,
      staleTime: 5 * 60 * 1000,
    },
  },
});

const stackHeaderOptions = {
  headerShown: true,
  headerStyle: { backgroundColor: colors.primary },
  headerTintColor: '#fff',
  headerTitleStyle: { fontWeight: '600' as const },
  headerBackTitleVisible: false,
};

export default function RootLayout() {
  return (
    <QueryClientProvider client={queryClient}>
      <AuthProvider>
        <ClientProvider>
        <StatusBar style="light" />
        <Stack screenOptions={{ headerShown: false }}>
          <Stack.Screen name="(auth)" />
          <Stack.Screen name="(tabs)" />
          <Stack.Screen name="create-os" options={{ ...stackHeaderOptions, title: 'Nova OS' }} />
          <Stack.Screen name="os-detail/[id]" options={{ ...stackHeaderOptions, title: 'Detalhes da OS' }} />
          <Stack.Screen name="vehicle-detail/[id]" options={{ ...stackHeaderOptions, title: 'Detalhes do Veículo' }} />
          <Stack.Screen name="km-register" options={{ ...stackHeaderOptions, title: 'Registrar KM' }} />
          <Stack.Screen name="report-anomaly" options={{ ...stackHeaderOptions, title: 'Relatar Anomalia' }} />
          <Stack.Screen name="anomalies" options={{ ...stackHeaderOptions, title: 'Anomalias' }} />
          <Stack.Screen name="balances" options={{ ...stackHeaderOptions, title: 'Saldos' }} />
          <Stack.Screen name="notifications" options={{ ...stackHeaderOptions, title: 'Notificações' }} />
          <Stack.Screen name="maintenance-alerts" options={{ ...stackHeaderOptions, title: 'Alertas de Manutenção' }} />
          <Stack.Screen name="contact" options={{ ...stackHeaderOptions, title: 'Contato' }} />
          <Stack.Screen name="admin-users" options={{ ...stackHeaderOptions, title: 'Gerenciar Usuários' }} />
          <Stack.Screen name="vehicle-checklist" options={{ ...stackHeaderOptions, title: 'Checklist Veicular' }} />
          <Stack.Screen name="qr-scan" options={{ ...stackHeaderOptions, title: 'QR Code / NFC' }} />
        </Stack>
        <Toast />
        </ClientProvider>
      </AuthProvider>
    </QueryClientProvider>
  );
}
