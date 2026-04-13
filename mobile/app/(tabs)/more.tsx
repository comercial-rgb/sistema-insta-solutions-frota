import React from 'react';
import {
  View,
  Text,
  ScrollView,
  StyleSheet,
  TouchableOpacity,
} from 'react-native';
import { router } from 'expo-router';
import { colors, spacing, borderRadius, fontSize, shadows } from '../../src/theme/colors';
import { Ionicons } from '@expo/vector-icons';
import { useAuth } from '../../src/contexts/AuthContext';

interface MenuItem {
  icon: string;
  label: string;
  description: string;
  route: string;
  requiresAdmin?: boolean;
  requiresQrNfc?: boolean;
}

export default function MoreScreen() {
  const { canManageUsers, isMotorista, logout } = useAuth();

  const menuItems: MenuItem[] = [
    { icon: 'wallet-outline', label: 'Saldos', description: 'Consultar saldos e empenhos', route: '/balances' },
    { icon: 'speedometer-outline', label: 'Registrar KM', description: 'Informar quilometragem', route: '/km-register' },
    { icon: 'alert-circle-outline', label: 'Anomalias', description: 'Relatar problemas', route: '/anomalies' },
    { icon: 'clipboard-outline', label: 'Checklist Veicular', description: 'Realizar checklist do veículo', route: '/vehicle-checklist' },
    { icon: 'construct-outline', label: 'Alertas Manutenção', description: 'Plano de manutenção', route: '/maintenance-alerts' },
    { icon: 'clipboard-outline', label: 'Planos de Manutenção', description: 'Criar e gerenciar planos', route: '/maintenance-plans' },
    { icon: 'qr-code-outline', label: 'QR Code / NFC', description: 'Solicitar serviço via QR/NFC', route: '/qr-scan', requiresQrNfc: true },
    { icon: 'notifications-outline', label: 'Notificações', description: 'Central de notificações', route: '/notifications' },
    { icon: 'chatbubble-ellipses-outline', label: 'Contato', description: 'Fale conosco', route: '/contact' },
    { icon: 'people-outline', label: 'Gerenciar Usuários', description: 'Adicionar e gerenciar acessos', route: '/admin-users', requiresAdmin: true },
  ];

  const filteredItems = menuItems.filter((item) => {
    if (item.requiresAdmin && !canManageUsers) return false;
    if (item.requiresQrNfc && isMotorista) return false;
    return true;
  });

  return (
    <ScrollView style={styles.container} contentContainerStyle={styles.content}>
      <Text style={styles.sectionTitle}>Funcionalidades</Text>

      {filteredItems.map((item) => (
        <TouchableOpacity
          key={item.route}
          style={styles.menuItem}
          onPress={() => router.push(item.route as any)}
          activeOpacity={0.7}
        >
          <View style={styles.menuIconContainer}>
            <Ionicons name={item.icon as any} size={22} color={colors.primary} />
          </View>
          <View style={styles.menuTextContainer}>
            <Text style={styles.menuLabel}>{item.label}</Text>
            <Text style={styles.menuDescription}>{item.description}</Text>
          </View>
          <Ionicons name="chevron-forward" size={18} color={colors.textLight} />
        </TouchableOpacity>
      ))}

      <View style={styles.divider} />

      <TouchableOpacity style={styles.logoutButton} onPress={logout}>
        <Ionicons name="log-out-outline" size={22} color={colors.danger} />
        <Text style={styles.logoutText}>Sair da Conta</Text>
      </TouchableOpacity>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: colors.background },
  content: { padding: spacing.md, paddingBottom: spacing.xxl },
  sectionTitle: {
    fontSize: fontSize.lg,
    fontWeight: '600',
    color: colors.text,
    marginBottom: spacing.md,
  },
  menuItem: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.surface,
    borderRadius: borderRadius.md,
    padding: spacing.md,
    marginBottom: spacing.sm,
    ...shadows.sm,
  },
  menuIconContainer: {
    width: 40,
    height: 40,
    borderRadius: borderRadius.sm,
    backgroundColor: colors.primary + '12',
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: spacing.md,
  },
  menuTextContainer: { flex: 1 },
  menuLabel: { fontSize: fontSize.md, fontWeight: '600', color: colors.text },
  menuDescription: { fontSize: fontSize.xs, color: colors.textSecondary, marginTop: 2 },
  divider: { height: 1, backgroundColor: colors.border, marginVertical: spacing.lg },
  logoutButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    padding: spacing.md,
    gap: spacing.sm,
  },
  logoutText: { fontSize: fontSize.md, fontWeight: '600', color: colors.danger },
});
