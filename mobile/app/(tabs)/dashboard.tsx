import React from 'react';
import {
  View,
  Text,
  ScrollView,
  StyleSheet,
  TouchableOpacity,
  RefreshControl,
  ActivityIndicator,
  Image,
} from 'react-native';
import { router } from 'expo-router';
import { useQuery } from '@tanstack/react-query';
import { dashboardApi } from '../../src/api/dashboard';
import { mobileBannersApi } from '../../src/api/mobileBanners';
import { colors, spacing, borderRadius, fontSize, shadows } from '../../src/theme/colors';
import { Ionicons } from '@expo/vector-icons';
import { useAuth } from '../../src/contexts/AuthContext';
import { useResponsiveLayout } from '../../src/hooks/useResponsiveLayout';
import BannerCarousel from '../../src/components/BannerCarousel';

export default function DashboardScreen() {
  const { canApproveOS, canManageUsers } = useAuth();
  const { dashActionWidth, barWidth, isTablet } = useResponsiveLayout();

  const { data, isLoading, refetch, isRefetching } = useQuery({
    queryKey: ['dashboard'],
    queryFn: dashboardApi.getData,
  });

  const { data: bannersData } = useQuery({
    queryKey: ['mobile-banners'],
    queryFn: mobileBannersApi.list,
    staleTime: 5 * 60 * 1000,
  });

  const banners = bannersData?.banners ?? [];

  if (isLoading) {
    return (
      <View style={styles.loadingContainer}>
        <ActivityIndicator size="large" color={colors.primary} />
      </View>
    );
  }

  const summary = data?.summary;
  const userName = data?.user?.name?.split(' ')[0] || 'Usuário';

  return (
    <ScrollView
      style={styles.container}
      contentContainerStyle={styles.contentContainer}
      refreshControl={<RefreshControl refreshing={isRefetching} onRefresh={refetch} />}
    >
      {/* Header com logo */}
      <View style={styles.headerBanner}>
        <Image
          source={require('../../assets/images/logo-horizontal-branco.png')}
          style={styles.headerLogo}
          resizeMode="contain"
        />
      </View>

      {/* Header de boas-vindas */}
      <View style={styles.welcomeSection}>
        <Text style={styles.greeting}>Olá, {userName}!</Text>
        <Text style={styles.greetingSub}>Resumo da sua frota</Text>
      </View>

      {/* Carrossel de Publicidade / Dicas */}
      {banners.length > 0 && <BannerCarousel banners={banners} />}

      {/* Cards de resumo */}
      <View style={styles.cardsRow}>
        <DashCard
          icon="document-text"
          label="OS Abertas"
          value={summary?.os_open ?? 0}
          color={colors.statusOpen}
          onPress={() => router.push('/(tabs)/order-services')}
        />
        <DashCard
          icon="time"
          label="Aguardando"
          value={summary?.os_awaiting_approval ?? 0}
          color={colors.statusAwaiting}
          onPress={() => router.push('/(tabs)/order-services')}
        />
      </View>

      <View style={styles.cardsRow}>
        <DashCard
          icon="checkmark-circle"
          label="Aprovadas"
          value={summary?.os_approved ?? 0}
          color={colors.statusApproved}
          onPress={() => router.push('/(tabs)/order-services')}
        />
        <DashCard
          icon="car"
          label="Veículos"
          value={summary?.vehicles_count ?? 0}
          color={colors.primary}
          onPress={() => router.push('/(tabs)/vehicles')}
        />
      </View>

      <View style={styles.cardsRow}>
        <DashCard
          icon="warning"
          label="Anomalias"
          value={summary?.anomalies_open ?? 0}
          color={colors.danger}
          onPress={() => router.push('/anomalies')}
        />
        <DashCard
          icon="notifications"
          label="Alertas Manut."
          value={summary?.pending_maintenance_alerts ?? 0}
          color={colors.warning}
          onPress={() => router.push('/maintenance-alerts')}
        />
      </View>

      {/* Ações rápidas */}
      <Text style={styles.sectionTitle}>Ações Rápidas</Text>
      <View style={styles.actionsGrid}>
        <ActionButton
          icon="add-circle-outline"
          label="Nova OS"
          onPress={() => router.push('/create-os')}
          widthPct={dashActionWidth}
        />
        <ActionButton
          icon="speedometer-outline"
          label="Registrar KM"
          onPress={() => router.push('/km-register')}
          widthPct={dashActionWidth}
        />
        <ActionButton
          icon="alert-circle-outline"
          label="Relatar Anomalia"
          onPress={() => router.push('/report-anomaly')}
          widthPct={dashActionWidth}
        />
        <ActionButton
          icon="wallet-outline"
          label="Saldos"
          onPress={() => router.push('/balances')}
          widthPct={dashActionWidth}
        />
        {data?.user?.qr_nfc_enabled && (
          <ActionButton
            icon="qr-code-outline"
            label="QR / NFC"
            onPress={() => router.push('/qr-scan')}
            widthPct={dashActionWidth}
          />
        )}
        {canApproveOS && (
          <ActionButton
            icon="checkmark-done-outline"
            label="Aprovar OS"
            onPress={() => router.push('/(tabs)/order-services')}
            widthPct={dashActionWidth}
          />
        )}
        {canManageUsers && (
          <ActionButton
            icon="people-outline"
            label="Usuários"
            onPress={() => router.push('/admin-users')}
            widthPct={dashActionWidth}
          />
        )}
        <ActionButton
          icon="chatbubble-outline"
          label="Contato"
          onPress={() => router.push('/contact')}
          widthPct={dashActionWidth}
        />
      </View>

      {/* OS por mês */}
      {data?.os_by_month && data.os_by_month.length > 0 && (
        <View style={styles.chartCard}>
          <Text style={styles.chartTitle}>OS por Mês (últimos 6 meses)</Text>
          <View style={styles.barChart}>
            {data.os_by_month.map((item) => {
              const maxCount = Math.max(...data.os_by_month.map((i) => i.count), 1);
              const height = (item.count / maxCount) * 100;
              return (
                <View key={item.month} style={styles.barContainer}>
                  <Text style={styles.barValue}>{item.count}</Text>
                  <View style={[styles.bar, { height: Math.max(height, 4), width: barWidth }]} />
                  <Text style={styles.barLabel}>{item.month.slice(5)}</Text>
                </View>
              );
            })}
          </View>
        </View>
      )}

      {/* Resumo financeiro */}
      <View style={styles.summaryCard}>
        <Text style={styles.chartTitle}>Resumo Geral</Text>
        <View style={styles.summaryRow}>
          <SummaryItem label="Total OS" value={summary?.total_os ?? 0} />
          <SummaryItem label="Pagas" value={summary?.os_paid ?? 0} color={colors.success} />
          <SummaryItem label="Canceladas" value={summary?.os_cancelled ?? 0} color={colors.danger} />
        </View>
      </View>
    </ScrollView>
  );
}

function DashCard({
  icon,
  label,
  value,
  color,
  onPress,
}: {
  icon: string;
  label: string;
  value: number;
  color: string;
  onPress: () => void;
}) {
  return (
    <TouchableOpacity style={styles.dashCard} onPress={onPress} activeOpacity={0.7}>
      <View style={[styles.dashCardIcon, { backgroundColor: color + '15' }]}>
        <Ionicons name={icon as any} size={22} color={color} />
      </View>
      <Text style={styles.dashCardValue}>{value}</Text>
      <Text style={styles.dashCardLabel}>{label}</Text>
    </TouchableOpacity>
  );
}

function ActionButton({
  icon,
  label,
  onPress,
  widthPct,
}: {
  icon: string;
  label: string;
  onPress: () => void;
  widthPct: string;
}) {
  return (
    <TouchableOpacity style={[styles.actionButton, { width: widthPct as any }]} onPress={onPress} activeOpacity={0.7}>
      <Ionicons name={icon as any} size={24} color={colors.primary} />
      <Text style={styles.actionLabel}>{label}</Text>
    </TouchableOpacity>
  );
}

function SummaryItem({
  label,
  value,
  color,
}: {
  label: string;
  value: number;
  color?: string;
}) {
  return (
    <View style={styles.summaryItem}>
      <Text style={[styles.summaryValue, color ? { color } : {}]}>{value}</Text>
      <Text style={styles.summaryLabel}>{label}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: colors.background },
  contentContainer: { paddingBottom: spacing.xxl },
  loadingContainer: { flex: 1, justifyContent: 'center', alignItems: 'center' },
  headerBanner: {
    backgroundColor: colors.primary,
    paddingVertical: spacing.lg,
    paddingHorizontal: spacing.md,
    alignItems: 'center',
    borderBottomLeftRadius: borderRadius.lg,
    borderBottomRightRadius: borderRadius.lg,
    marginBottom: spacing.sm,
  },
  headerLogo: {
    width: 200,
    height: 40,
  },
  welcomeSection: { marginBottom: spacing.lg, paddingHorizontal: spacing.md },
  greeting: { fontSize: fontSize.xxl, fontWeight: '700', color: colors.text },
  greetingSub: { fontSize: fontSize.md, color: colors.textSecondary, marginTop: 2 },
  cardsRow: { flexDirection: 'row', gap: spacing.sm, marginBottom: spacing.sm, paddingHorizontal: spacing.md },
  dashCard: {
    flex: 1,
    backgroundColor: colors.surface,
    borderRadius: borderRadius.md,
    padding: spacing.md,
    ...shadows.sm,
  },
  dashCardIcon: {
    width: 40,
    height: 40,
    borderRadius: borderRadius.sm,
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: spacing.sm,
  },
  dashCardValue: { fontSize: fontSize.xxl, fontWeight: '700', color: colors.text },
  dashCardLabel: { fontSize: fontSize.xs, color: colors.textSecondary, marginTop: 2 },
  sectionTitle: {
    fontSize: fontSize.lg,
    fontWeight: '600',
    color: colors.text,
    marginTop: spacing.lg,
    marginBottom: spacing.sm,
    paddingHorizontal: spacing.md,
  },
  actionsGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: spacing.sm,
    paddingHorizontal: spacing.md,
  },
  actionButton: {
    backgroundColor: colors.surface,
    borderRadius: borderRadius.md,
    padding: spacing.md,
    alignItems: 'center',
    justifyContent: 'center',
    minHeight: 80,
    ...shadows.sm,
  },
  actionLabel: {
    fontSize: fontSize.xs,
    color: colors.textSecondary,
    marginTop: spacing.xs,
    textAlign: 'center',
  },
  chartCard: {
    backgroundColor: colors.surface,
    borderRadius: borderRadius.md,
    padding: spacing.md,
    marginTop: spacing.lg,
    marginHorizontal: spacing.md,
    ...shadows.sm,
  },
  chartTitle: { fontSize: fontSize.md, fontWeight: '600', color: colors.text, marginBottom: spacing.md },
  barChart: {
    flexDirection: 'row',
    alignItems: 'flex-end',
    justifyContent: 'space-around',
    height: 130,
  },
  barContainer: { alignItems: 'center', flex: 1 },
  bar: {
    backgroundColor: colors.primary,
    borderRadius: borderRadius.sm,
    minHeight: 4,
  },
  barValue: { fontSize: fontSize.xs, color: colors.textSecondary, marginBottom: 4 },
  barLabel: { fontSize: fontSize.xs, color: colors.textLight, marginTop: 4 },
  summaryCard: {
    backgroundColor: colors.surface,
    borderRadius: borderRadius.md,
    padding: spacing.md,
    marginTop: spacing.md,
    marginHorizontal: spacing.md,
    ...shadows.sm,
  },
  summaryRow: { flexDirection: 'row', justifyContent: 'space-around' },
  summaryItem: { alignItems: 'center' },
  summaryValue: { fontSize: fontSize.xl, fontWeight: '700', color: colors.text },
  summaryLabel: { fontSize: fontSize.xs, color: colors.textSecondary, marginTop: 2 },
});
