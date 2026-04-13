import React from 'react';
import {
  View,
  Text,
  ScrollView,
  StyleSheet,
  TouchableOpacity,
  ActivityIndicator,
} from 'react-native';
import { useLocalSearchParams, router } from 'expo-router';
import { useQuery } from '@tanstack/react-query';
import { vehiclesApi } from '../../src/api/vehicles';
import { colors, spacing, borderRadius, fontSize, shadows } from '../../src/theme/colors';
import { Ionicons } from '@expo/vector-icons';

const formatCurrency = (v: number) =>
  v.toLocaleString('pt-BR', { style: 'currency', currency: 'BRL' });

export default function VehicleDetailScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();

  const { data, isLoading, isError, refetch } = useQuery({
    queryKey: ['vehicle-detail', id],
    queryFn: () => vehiclesApi.getDetail(Number(id)),
    enabled: !!id,
    retry: 1,
  });

  if (isLoading) {
    return (
      <View style={styles.loadingContainer}>
        <ActivityIndicator size="large" color={colors.primary} />
      </View>
    );
  }

  const v = data?.vehicle;
  if (!v) {
    return (
      <View style={styles.loadingContainer}>
        <Ionicons name="alert-circle-outline" size={48} color={colors.textLight} />
        <Text style={{ color: colors.textLight, marginTop: spacing.sm, fontSize: fontSize.md }}>
          {isError ? 'Erro ao carregar veículo' : 'Veículo não encontrado'}
        </Text>
        <TouchableOpacity
          style={{ marginTop: spacing.md, paddingHorizontal: spacing.lg, paddingVertical: spacing.sm, backgroundColor: colors.primary, borderRadius: borderRadius.md }}
          onPress={() => refetch()}
        >
          <Text style={{ color: '#fff', fontWeight: '600' }}>Tentar novamente</Text>
        </TouchableOpacity>
      </View>
    );
  }

  const maintenanceValues = data?.consumed_values?.maintenance;
  const fuelValues = data?.consumed_values?.fuel;

  return (
    <ScrollView style={styles.container} contentContainerStyle={styles.content}>
      {/* Placa destaque */}
      <View style={styles.plateCard}>
        <Text style={styles.plateBig}>{v.board}</Text>
        <Text style={styles.vehicleNameBig}>{v.brand} {v.model}</Text>
        <View style={styles.kmContainer}>
          <Ionicons name="speedometer" size={20} color={colors.secondary} />
          <Text style={styles.kmValue}>
            {data?.current_km ? `${data.current_km.toLocaleString()} km` : 'KM não registrado'}
          </Text>
        </View>
      </View>

      {/* Ações rápidas */}
      <View style={styles.quickActions}>
        <TouchableOpacity
          style={styles.quickBtn}
          onPress={() => router.push({ pathname: '/km-register', params: { vehicle_id: v.id.toString(), vehicle_board: v.board } })}
        >
          <Ionicons name="speedometer-outline" size={20} color={colors.primary} />
          <Text style={styles.quickBtnText}>Registrar KM</Text>
        </TouchableOpacity>
        <TouchableOpacity
          style={styles.quickBtn}
          onPress={() => router.push({ pathname: '/create-os', params: { vehicle_id: v.id.toString() } })}
        >
          <Ionicons name="add-circle-outline" size={20} color={colors.primary} />
          <Text style={styles.quickBtnText}>Nova OS</Text>
        </TouchableOpacity>
        <TouchableOpacity
          style={styles.quickBtn}
          onPress={() => router.push({ pathname: '/report-anomaly', params: { vehicle_id: v.id.toString() } })}
        >
          <Ionicons name="alert-outline" size={20} color={colors.primary} />
          <Text style={styles.quickBtnText}>Anomalia</Text>
        </TouchableOpacity>
      </View>

      {/* Valores consumidos */}
      <View style={styles.valuesRow}>
        <View style={[styles.valueCard, { borderLeftColor: colors.primary }]}>
          <View style={styles.valueCardHeader}>
            <Ionicons name="construct" size={18} color={colors.primary} />
            <Text style={styles.valueCardTitle}>Manutenção</Text>
          </View>
          <Text style={styles.valueCardAmount}>
            {formatCurrency(maintenanceValues?.total ?? 0)}
          </Text>
          <Text style={styles.valueCardCount}>
            {maintenanceValues?.count ?? 0} OS
          </Text>
        </View>

        <View style={[styles.valueCard, { borderLeftColor: colors.secondary }]}>
          <View style={styles.valueCardHeader}>
            <Ionicons name="flame" size={18} color={colors.secondary} />
            <Text style={styles.valueCardTitle}>Combustível</Text>
          </View>
          <Text style={styles.valueCardAmount}>
            {formatCurrency(fuelValues?.total ?? 0)}
          </Text>
          <Text style={styles.valueCardCount}>
            {fuelValues?.count ?? 0} abastecimento{(fuelValues?.count ?? 0) !== 1 ? 's' : ''}
          </Text>
        </View>
      </View>

      {/* Info do veículo */}
      <View style={styles.section}>
        <Text style={styles.sectionTitle}>Informações</Text>
        <View style={styles.infoCard}>
          <InfoRow label="Ano" value={v.year} />
          <InfoRow label="Ano Modelo" value={v.model_year} />
          <InfoRow label="Cor" value={v.color} />
          <InfoRow label="Combustível" value={v.fuel_type} />
          <InfoRow label="Tipo" value={v.vehicle_type} />
          <InfoRow label="Renavam" value={v.renavam} />
          <InfoRow label="Chassi" value={v.chassi} />
          <InfoRow label="Centro de Custo" value={v.cost_center} wrap />
          <InfoRow label="Sub-Unidade" value={v.sub_unit} wrap />
          {v.market_value && (
            <InfoRow
              label="Valor Mercado"
              value={`R$ ${v.market_value.toLocaleString('pt-BR', { minimumFractionDigits: 2 })}`}
            />
          )}
        </View>
      </View>

      {/* Histórico KM */}
      {data?.km_history && data.km_history.length > 0 && (
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Histórico de KM</Text>
          {data.km_history.map((record) => (
            <View key={record.id} style={styles.kmRow}>
              <View style={styles.kmDot} />
              <View style={styles.kmInfo}>
                <Text style={styles.kmRowValue}>{record.km.toLocaleString()} km</Text>
                <Text style={styles.kmRowMeta}>
                  {record.user || record.user_name} • {record.origin} •{' '}
                  {new Date(record.date || record.created_at).toLocaleDateString('pt-BR')}
                </Text>
              </View>
            </View>
          ))}
        </View>
      )}

      {/* Alertas pendentes */}
      {data?.pending_alerts && data.pending_alerts.length > 0 && (
        <View style={styles.section}>
          <Text style={[styles.sectionTitle, { color: colors.warning }]}>
            Alertas de Manutenção
          </Text>
          {data.pending_alerts.map((alert) => (
            <View key={alert.id} style={styles.alertCard}>
              <Ionicons name="warning" size={18} color={colors.warning} />
              <Text style={styles.alertText}>{alert.message}</Text>
            </View>
          ))}
        </View>
      )}

      {/* OS recentes */}
      {data?.recent_os && data.recent_os.length > 0 && (
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>OS Recentes</Text>
          {data.recent_os.map((os) => (
            <TouchableOpacity
              key={os.id}
              style={styles.osRow}
              onPress={() => router.push(`/os-detail/${os.id}`)}
            >
              <Text style={styles.osCode}>{os.code}</Text>
              <Text style={styles.osStatus}>{os.status}</Text>
              <Ionicons name="chevron-forward" size={16} color={colors.textLight} />
            </TouchableOpacity>
          ))}
        </View>
      )}
    </ScrollView>
  );
}

function InfoRow({ label, value, wrap }: { label: string; value?: string | null; wrap?: boolean }) {
  if (!value) return null;
  return (
    <View style={styles.infoRow}>
      <Text style={styles.infoLabel}>{label}</Text>
      <Text style={[styles.infoValue, wrap && { flexShrink: 1 }]} numberOfLines={wrap ? 3 : 1}>
        {value}
      </Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: colors.background },
  content: { padding: spacing.md, paddingBottom: spacing.xxl },
  loadingContainer: { flex: 1, justifyContent: 'center', alignItems: 'center' },
  plateCard: {
    backgroundColor: colors.primary,
    borderRadius: borderRadius.lg,
    padding: spacing.lg,
    alignItems: 'center',
    marginBottom: spacing.md,
  },
  plateBig: { fontSize: 32, fontWeight: '800', color: '#fff', letterSpacing: 2 },
  vehicleNameBig: { fontSize: fontSize.lg, color: 'rgba(255,255,255,0.8)', marginTop: spacing.xs },
  kmContainer: { flexDirection: 'row', alignItems: 'center', gap: spacing.sm, marginTop: spacing.md },
  kmValue: { fontSize: fontSize.lg, fontWeight: '700', color: colors.secondary },
  quickActions: { flexDirection: 'row', gap: spacing.sm, marginBottom: spacing.md },
  quickBtn: {
    flex: 1,
    backgroundColor: colors.surface,
    borderRadius: borderRadius.md,
    padding: spacing.sm,
    alignItems: 'center',
    justifyContent: 'center',
    minHeight: 60,
    ...shadows.sm,
  },
  quickBtnText: { fontSize: fontSize.xs, color: colors.textSecondary, marginTop: 4, textAlign: 'center' },
  valuesRow: { flexDirection: 'row', gap: spacing.sm, marginBottom: spacing.md },
  valueCard: {
    flex: 1,
    backgroundColor: colors.surface,
    borderRadius: borderRadius.md,
    padding: spacing.md,
    borderLeftWidth: 3,
    ...shadows.sm,
  },
  valueCardHeader: { flexDirection: 'row', alignItems: 'center', gap: spacing.xs, marginBottom: spacing.sm },
  valueCardTitle: { fontSize: fontSize.xs, fontWeight: '600', color: colors.textSecondary },
  valueCardAmount: { fontSize: fontSize.lg, fontWeight: '700', color: colors.text },
  valueCardCount: { fontSize: fontSize.xs, color: colors.textLight, marginTop: 2 },
  section: { marginBottom: spacing.md },
  sectionTitle: { fontSize: fontSize.md, fontWeight: '600', color: colors.text, marginBottom: spacing.sm },
  infoCard: { backgroundColor: colors.surface, borderRadius: borderRadius.md, padding: spacing.md, ...shadows.sm },
  infoRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    paddingVertical: 6,
    borderBottomWidth: 1,
    borderBottomColor: colors.borderLight,
  },
  infoLabel: { fontSize: fontSize.sm, color: colors.textSecondary, minWidth: 100 },
  infoValue: { fontSize: fontSize.sm, color: colors.text, fontWeight: '500', flex: 1, textAlign: 'right' },
  kmRow: { flexDirection: 'row', alignItems: 'flex-start', marginBottom: spacing.sm },
  kmDot: {
    width: 10,
    height: 10,
    borderRadius: 5,
    backgroundColor: colors.primary,
    marginTop: 4,
    marginRight: spacing.sm,
  },
  kmInfo: { flex: 1 },
  kmRowValue: { fontSize: fontSize.sm, fontWeight: '600', color: colors.text },
  kmRowMeta: { fontSize: fontSize.xs, color: colors.textLight },
  alertCard: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.sm,
    backgroundColor: colors.warningLight,
    borderRadius: borderRadius.md,
    padding: spacing.sm,
    marginBottom: spacing.xs,
  },
  alertText: { flex: 1, fontSize: fontSize.sm, color: colors.text },
  osRow: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.surface,
    borderRadius: borderRadius.md,
    padding: spacing.sm,
    marginBottom: spacing.xs,
    ...shadows.sm,
  },
  osCode: { fontSize: fontSize.sm, fontWeight: '600', color: colors.text, flex: 1 },
  osStatus: { fontSize: fontSize.xs, color: colors.primaryLight, marginRight: spacing.sm },
});
