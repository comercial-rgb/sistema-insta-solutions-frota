import React from 'react';
import {
  View,
  Text,
  FlatList,
  StyleSheet,
  TouchableOpacity,
  RefreshControl,
  ActivityIndicator,
  Alert,
} from 'react-native';
import { router } from 'expo-router';
import { useInfiniteQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { maintenanceAlertsApi } from '../src/api/maintenanceAlerts';
import { colors, spacing, borderRadius, fontSize, shadows } from '../src/theme/colors';
import { Ionicons } from '@expo/vector-icons';
import { MaintenanceAlert } from '../src/types';
import { useAuth } from '../src/contexts/AuthContext';

const STATUS_CONFIG: Record<string, { color: string; label: string }> = {
  pending: { color: colors.warning, label: 'Pendente' },
  acknowledged: { color: colors.info, label: 'Ciente' },
  completed: { color: colors.success, label: 'Concluído' },
  dismissed: { color: colors.textLight, label: 'Dispensado' },
};

export default function MaintenanceAlertsScreen() {
  const queryClient = useQueryClient();
  const { isAdmin, isGestor, isAdicional } = useAuth();
  const canCreateOs = isAdmin || isGestor || isAdicional;

  const { data, fetchNextPage, hasNextPage, isLoading, refetch, isRefetching } =
    useInfiniteQuery({
      queryKey: ['maintenance-alerts'],
      queryFn: ({ pageParam = 1 }) => maintenanceAlertsApi.list({ page: pageParam, per_page: 20 }),
      getNextPageParam: (lastPage) =>
        lastPage.meta.current_page < lastPage.meta.total_pages ? lastPage.meta.current_page + 1 : undefined,
      initialPageParam: 1,
    });

  const acknowledgeMutation = useMutation({
    mutationFn: maintenanceAlertsApi.acknowledge,
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['maintenance-alerts'] }),
  });

  const dismissMutation = useMutation({
    mutationFn: maintenanceAlertsApi.dismiss,
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['maintenance-alerts'] }),
  });

  const createOsMutation = useMutation({
    mutationFn: maintenanceAlertsApi.createOs,
    onSuccess: (data) => {
      queryClient.invalidateQueries({ queryKey: ['maintenance-alerts'] });
      Alert.alert('OS Criada', `OS criada com sucesso! ID: ${data.order_service_id}`);
    },
    onError: (error: any) => {
      Alert.alert('Erro', error?.response?.data?.message || 'Não foi possível criar a OS.');
    },
  });

  const allAlerts = data?.pages.flatMap((p) => p.alerts) ?? [];

  const handleAcknowledge = (id: number) => {
    acknowledgeMutation.mutate(id);
  };

  const handleDismiss = (id: number) => {
    Alert.alert('Dispensar Alerta', 'Tem certeza que deseja dispensar este alerta?', [
      { text: 'Cancelar', style: 'cancel' },
      { text: 'Dispensar', onPress: () => dismissMutation.mutate(id) },
    ]);
  };

  const handleCreateOs = (id: number) => {
    Alert.alert(
      'Confirmar Abertura de OS',
      'Deseja criar uma Ordem de Serviço a partir deste alerta? Os itens do plano serão incluídos automaticamente.',
      [
        { text: 'Cancelar', style: 'cancel' },
        { text: 'Criar OS', onPress: () => createOsMutation.mutate(id) },
      ]
    );
  };

  return (
    <View style={styles.container}>


      {isLoading ? (
        <ActivityIndicator size="large" color={colors.primary} style={{ marginTop: spacing.xxl }} />
      ) : (
        <FlatList
          data={allAlerts}
          renderItem={({ item }) => (
            <AlertCard
              alert={item}
              onAcknowledge={handleAcknowledge}
              onDismiss={handleDismiss}
              onCreateOs={canCreateOs ? handleCreateOs : undefined}
            />
          )}
          keyExtractor={(item) => item.id.toString()}
          contentContainerStyle={styles.listContent}
          refreshControl={<RefreshControl refreshing={isRefetching} onRefresh={refetch} />}
          onEndReached={() => hasNextPage && fetchNextPage()}
          ListEmptyComponent={
            <View style={styles.emptyContainer}>
              <Ionicons name="shield-checkmark-outline" size={48} color={colors.textLight} />
              <Text style={styles.emptyText}>Nenhum alerta de manutenção</Text>
            </View>
          }
        />
      )}
    </View>
  );
}

function AlertCard({
  alert,
  onAcknowledge,
  onDismiss,
  onCreateOs,
}: {
  alert: MaintenanceAlert;
  onAcknowledge: (id: number) => void;
  onDismiss: (id: number) => void;
  onCreateOs?: (id: number) => void;
}) {
  const status = STATUS_CONFIG[alert.status] ?? STATUS_CONFIG.pending;
  const isKm = alert.alert_type === 'km';
  const isPending = alert.status === 'pending';

  return (
    <View style={[styles.card, isPending && styles.cardPending]}>
      <View style={styles.cardHeader}>
        <View style={[styles.typeIcon, { backgroundColor: isKm ? colors.info + '15' : colors.warning + '15' }]}>
          <Ionicons
            name={isKm ? 'speedometer-outline' : 'calendar-outline'}
            size={20}
            color={isKm ? colors.info : colors.warning}
          />
        </View>
        <View style={{ flex: 1 }}>
          <Text style={styles.alertMessage}>{alert.message}</Text>
          <Text style={styles.vehicleInfo}>
            {alert.vehicle_board} • {isKm ? 'Por KM' : 'Por Dias'}
          </Text>
        </View>
        <View style={[styles.statusBadge, { backgroundColor: status.color + '18' }]}>
          <Text style={[styles.statusText, { color: status.color }]}>{status.label}</Text>
        </View>
      </View>

      {/* Details */}
      <View style={styles.detailsRow}>
        {alert.current_km != null && (
          <View style={styles.detailItem}>
            <Text style={styles.detailLabel}>KM Atual</Text>
            <Text style={styles.detailValue}>{alert.current_km.toLocaleString('pt-BR')}</Text>
          </View>
        )}
        {alert.target_km != null && (
          <View style={styles.detailItem}>
            <Text style={styles.detailLabel}>KM Alvo</Text>
            <Text style={styles.detailValue}>{alert.target_km.toLocaleString('pt-BR')}</Text>
          </View>
        )}
        {alert.target_date && (
          <View style={styles.detailItem}>
            <Text style={styles.detailLabel}>Data Alvo</Text>
            <Text style={styles.detailValue}>
              {new Date(alert.target_date).toLocaleDateString('pt-BR')}
            </Text>
          </View>
        )}
      </View>

      {/* Actions */}
      {isPending && (
        <View style={styles.actionsRow}>
          <TouchableOpacity style={styles.ackBtn} onPress={() => onAcknowledge(alert.id)}>
            <Ionicons name="checkmark-circle-outline" size={16} color={colors.info} />
            <Text style={styles.ackBtnText}>Ciente</Text>
          </TouchableOpacity>
          {onCreateOs && (
            <TouchableOpacity style={styles.createOsBtn} onPress={() => onCreateOs(alert.id)}>
              <Ionicons name="construct-outline" size={16} color={colors.success} />
              <Text style={styles.createOsBtnText}>Criar OS</Text>
            </TouchableOpacity>
          )}
          <TouchableOpacity style={styles.dismissBtn} onPress={() => onDismiss(alert.id)}>
            <Ionicons name="close-circle-outline" size={16} color={colors.textLight} />
            <Text style={styles.dismissBtnText}>Dispensar</Text>
          </TouchableOpacity>
        </View>
      )}
      {alert.status === 'completed' && alert.order_service_id && (
        <View style={styles.actionsRow}>
          <View style={styles.ackBtn}>
            <Ionicons name="checkmark-done-circle-outline" size={16} color={colors.success} />
            <Text style={[styles.ackBtnText, { color: colors.success }]}>OS #{alert.order_service_id} aberta</Text>
          </View>
        </View>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: colors.background },
  header: { flexDirection: 'row', alignItems: 'center', padding: spacing.md },
  backBtn: { marginRight: spacing.sm },
  headerTitle: { fontSize: fontSize.xl, fontWeight: '700', color: colors.text, flex: 1 },

  listContent: { paddingHorizontal: spacing.md, paddingBottom: spacing.xxl },
  card: { backgroundColor: colors.surface, borderRadius: borderRadius.md, padding: spacing.md, marginBottom: spacing.sm, ...shadows.sm },
  cardPending: { borderLeftWidth: 3, borderLeftColor: colors.warning },

  cardHeader: { flexDirection: 'row', alignItems: 'flex-start', gap: spacing.sm },
  typeIcon: { width: 36, height: 36, borderRadius: 18, alignItems: 'center', justifyContent: 'center' },
  alertMessage: { fontSize: fontSize.sm, fontWeight: '600', color: colors.text, flex: 1 },
  vehicleInfo: { fontSize: fontSize.xs, color: colors.textSecondary, marginTop: 2 },
  statusBadge: { paddingHorizontal: spacing.sm, paddingVertical: 2, borderRadius: borderRadius.full },
  statusText: { fontSize: fontSize.xs, fontWeight: '600' },

  detailsRow: { flexDirection: 'row', marginTop: spacing.sm, gap: spacing.md },
  detailItem: {},
  detailLabel: { fontSize: fontSize.xs, color: colors.textLight },
  detailValue: { fontSize: fontSize.sm, fontWeight: '600', color: colors.text },

  actionsRow: { flexDirection: 'row', gap: spacing.md, marginTop: spacing.sm, paddingTop: spacing.sm, borderTopWidth: 1, borderTopColor: colors.border },
  ackBtn: { flexDirection: 'row', alignItems: 'center', gap: 4 },
  ackBtnText: { fontSize: fontSize.sm, color: colors.info, fontWeight: '600' },
  createOsBtn: { flexDirection: 'row', alignItems: 'center', gap: 4 },
  createOsBtnText: { fontSize: fontSize.sm, color: colors.success, fontWeight: '600' },
  dismissBtn: { flexDirection: 'row', alignItems: 'center', gap: 4 },
  dismissBtnText: { fontSize: fontSize.sm, color: colors.textLight },

  emptyContainer: { alignItems: 'center', paddingTop: spacing.xxl },
  emptyText: { fontSize: fontSize.md, color: colors.textLight, marginTop: spacing.sm },
});
