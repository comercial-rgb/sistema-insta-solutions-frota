import React, { useState, useCallback } from 'react';
import {
  View,
  Text,
  FlatList,
  StyleSheet,
  TouchableOpacity,
  TextInput,
  RefreshControl,
  ActivityIndicator,
  ScrollView,
} from 'react-native';
import { router } from 'expo-router';
import { useInfiniteQuery } from '@tanstack/react-query';
import { orderServicesApi } from '../../src/api/orderServices';
import { colors, spacing, borderRadius, fontSize, shadows } from '../../src/theme/colors';
import { Ionicons } from '@expo/vector-icons';
import { OrderServiceSummary } from '../../src/types';
import { useAuth } from '../../src/contexts/AuthContext';
import { useClientFilter } from '../../src/contexts/ClientContext';
import ClientSelector from '../../src/components/ClientSelector';
import { useResponsiveLayout } from '../../src/hooks/useResponsiveLayout';

const STATUS_FILTERS = [
  { id: undefined as number | undefined, label: 'Todas', icon: 'list-outline', color: colors.textSecondary },
  { id: 1, label: 'Em Aberto', icon: 'folder-open-outline', color: colors.statusOpen },
  { id: 2, label: 'Aguardando', icon: 'time-outline', color: colors.statusAwaiting },
  { id: 3, label: 'Aprovada', icon: 'checkmark-circle-outline', color: colors.statusApproved },
  { id: 7, label: 'Paga', icon: 'cash-outline', color: colors.statusPaid },
  { id: 8, label: 'Cancelada', icon: 'close-circle-outline', color: colors.statusCancelled },
];

const STATUS_COLORS: Record<string, string> = {
  'Em Cadastro': colors.textLight,
  'Em Aberto': colors.statusOpen,
  'Em aberto': colors.statusOpen,
  'Em Reavaliação': colors.info,
  'Aguardando Avaliação de Proposta': colors.statusAwaiting,
  'Aguardando avaliação de proposta': colors.statusAwaiting,
  'Aguardando Aprovação de Complemento': colors.statusAwaiting,
  Aprovada: colors.statusApproved,
  'Nota Fiscal Inserida': colors.accent,
  'Nota fiscal inserida': colors.accent,
  Autorizada: colors.primaryLight,
  'Aguardando Pagamento': colors.warning,
  'Aguardando pagamento': colors.warning,
  Paga: colors.statusPaid,
  Cancelada: colors.statusCancelled,
};

export default function OrderServicesScreen() {
  const { canApproveOS } = useAuth();
  const { selectedClientId } = useClientFilter();
  const { listColumns } = useResponsiveLayout();
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState<number | undefined>();

  const { data, fetchNextPage, hasNextPage, isLoading, refetch, isRefetching, isFetchingNextPage } =
    useInfiniteQuery({
      queryKey: ['orderServices', search, statusFilter, selectedClientId],
      queryFn: ({ pageParam = 1 }) =>
        orderServicesApi.list({
          page: pageParam,
          per_page: 20,
          search: search || undefined,
          status_id: statusFilter,
          client_id: selectedClientId ?? undefined,
        }),
      getNextPageParam: (lastPage) => {
        if (lastPage.meta.current_page < lastPage.meta.total_pages) {
          return lastPage.meta.current_page + 1;
        }
        return undefined;
      },
      initialPageParam: 1,
    });

  const allOS = data?.pages.flatMap((p) => p.order_services) ?? [];
  const totalCount = data?.pages[0]?.meta?.total_count ?? 0;

  const renderItem = useCallback(
    ({ item }: { item: OrderServiceSummary }) => (
      <TouchableOpacity
        style={styles.card}
        onPress={() => router.push(`/os-detail/${item.id}`)}
        activeOpacity={0.7}
      >
        <View style={styles.cardHeader}>
          <Text style={styles.osCode}>{item.code}</Text>
          <View
            style={[
              styles.statusBadge,
              { backgroundColor: (STATUS_COLORS[item.status] || colors.textLight) + '18' },
            ]}
          >
            <Text
              style={[
                styles.statusText,
                { color: STATUS_COLORS[item.status] || colors.textLight },
              ]}
            >
              {item.status}
            </Text>
          </View>
        </View>

        <View style={styles.cardBody}>
          <View style={styles.infoRow}>
            <Ionicons name="car-outline" size={14} color={colors.textSecondary} />
            <Text style={styles.infoText} numberOfLines={1}>
              {item.vehicle_board} - {item.vehicle_model}
            </Text>
          </View>
          {item.driver && (
            <View style={styles.infoRow}>
              <Ionicons name="person-outline" size={14} color={colors.textSecondary} />
              <Text style={styles.infoText} numberOfLines={1}>{item.driver}</Text>
            </View>
          )}
          {item.cost_center && (
            <View style={styles.infoRow}>
              <Ionicons name="business-outline" size={14} color={colors.textSecondary} />
              <Text style={styles.infoText} numberOfLines={1}>{item.cost_center}</Text>
            </View>
          )}
          {item.type && (
            <View style={styles.infoRow}>
              <Ionicons name="construct-outline" size={14} color={colors.textSecondary} />
              <Text style={styles.infoText}>{item.type}</Text>
            </View>
          )}
        </View>

        <View style={styles.cardFooter}>
          <Text style={styles.dateText}>
            {new Date(item.created_at).toLocaleDateString('pt-BR')}
          </Text>
          {item.provider && <Text style={styles.providerText} numberOfLines={1}>{item.provider}</Text>}
        </View>
        {item.client_name && (
          <Text style={styles.clientText} numberOfLines={1}>
            <Ionicons name="people-outline" size={10} color={colors.textLight} />{' '}
            {item.client_name}
          </Text>
        )}
      </TouchableOpacity>
    ),
    []
  );

  return (
    <View style={styles.container}>
      {/* Client selector for admin */}
      <ClientSelector />

      {/* Search bar */}
      <View style={styles.searchBar}>
        <Ionicons name="search-outline" size={18} color={colors.textLight} />
        <TextInput
          style={styles.searchInput}
          placeholder="Buscar código, placa, motorista..."
          placeholderTextColor={colors.placeholder}
          value={search}
          onChangeText={setSearch}
        />
        {search.length > 0 && (
          <TouchableOpacity onPress={() => setSearch('')}>
            <Ionicons name="close-circle" size={18} color={colors.textLight} />
          </TouchableOpacity>
        )}
      </View>

      {/* Status filter chips */}
      <ScrollView
        horizontal
        showsHorizontalScrollIndicator={false}
        contentContainerStyle={styles.statusRow}
      >
        {STATUS_FILTERS.map((sf) => {
          const active = statusFilter === sf.id;
          return (
            <TouchableOpacity
              key={sf.label}
              style={[styles.statusChip, active && { backgroundColor: (sf.color) + '20', borderColor: sf.color }]}
              onPress={() => setStatusFilter(active ? undefined : sf.id)}
            >
              <Ionicons name={sf.icon as any} size={14} color={active ? sf.color : colors.textLight} />
              <Text style={[styles.statusChipText, active && { color: sf.color, fontWeight: '600' }]}>
                {sf.label}
              </Text>
            </TouchableOpacity>
          );
        })}
      </ScrollView>

      {/* Result count */}
      {!isLoading && (
        <Text style={styles.countText}>{totalCount} OS encontrada{totalCount !== 1 ? 's' : ''}</Text>
      )}

      {/* FAB Nova OS */}
      <TouchableOpacity
        style={styles.fab}
        onPress={() => router.push('/create-os')}
        activeOpacity={0.8}
      >
        <Ionicons name="add" size={28} color={colors.textInverse} />
      </TouchableOpacity>

      {isLoading ? (
        <ActivityIndicator size="large" color={colors.primary} style={{ marginTop: spacing.xxl }} />
      ) : (
        <FlatList
          key={`os-${listColumns}`}
          data={allOS}
          renderItem={renderItem}
          keyExtractor={(item) => item.id.toString()}
          numColumns={listColumns}
          columnWrapperStyle={listColumns > 1 ? { gap: spacing.sm } : undefined}
          contentContainerStyle={styles.listContent}
          refreshControl={<RefreshControl refreshing={isRefetching} onRefresh={refetch} />}
          onEndReached={() => hasNextPage && fetchNextPage()}
          onEndReachedThreshold={0.3}
          ListFooterComponent={
            isFetchingNextPage ? (
              <ActivityIndicator style={{ padding: spacing.md }} color={colors.primary} />
            ) : null
          }
          ListEmptyComponent={
            <View style={styles.emptyContainer}>
              <Ionicons name="document-text-outline" size={48} color={colors.textLight} />
              <Text style={styles.emptyText}>Nenhuma OS encontrada</Text>
            </View>
          }
        />
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: colors.background },
  searchBar: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.surface,
    marginHorizontal: spacing.md,
    marginTop: spacing.sm,
    paddingHorizontal: spacing.md,
    height: 44,
    borderRadius: borderRadius.md,
    ...shadows.sm,
  },
  searchInput: { flex: 1, marginLeft: spacing.sm, fontSize: fontSize.sm, color: colors.text },
  statusRow: {
    paddingHorizontal: spacing.md,
    paddingVertical: spacing.sm,
    gap: spacing.sm,
    alignItems: 'center',
  },
  statusChip: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    paddingHorizontal: spacing.md,
    paddingVertical: 6,
    borderRadius: borderRadius.full,
    backgroundColor: colors.surface,
    borderWidth: 1,
    borderColor: colors.border,
  },
  statusChipText: { fontSize: fontSize.xs, color: colors.textLight },
  countText: {
    fontSize: fontSize.xs,
    color: colors.textLight,
    paddingHorizontal: spacing.md,
    marginBottom: spacing.xs,
  },
  listContent: { paddingHorizontal: spacing.md, paddingBottom: 100 },
  card: {
    flex: 1,
    backgroundColor: colors.surface,
    borderRadius: borderRadius.md,
    padding: spacing.md,
    marginBottom: spacing.sm,
    ...shadows.sm,
  },
  cardHeader: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginBottom: spacing.sm },
  osCode: { fontSize: fontSize.md, fontWeight: '700', color: colors.text },
  statusBadge: { paddingHorizontal: spacing.sm, paddingVertical: 3, borderRadius: borderRadius.full },
  statusText: { fontSize: fontSize.xs, fontWeight: '600' },
  cardBody: { gap: 4, marginBottom: spacing.sm },
  infoRow: { flexDirection: 'row', alignItems: 'center', gap: 6 },
  infoText: { fontSize: fontSize.sm, color: colors.textSecondary, flex: 1 },
  cardFooter: { flexDirection: 'row', justifyContent: 'space-between', borderTopWidth: 1, borderTopColor: colors.borderLight, paddingTop: spacing.sm },
  dateText: { fontSize: fontSize.xs, color: colors.textLight },
  providerText: { fontSize: fontSize.xs, color: colors.primaryLight, fontWeight: '500', flex: 1, textAlign: 'right' },
  clientText: { fontSize: fontSize.xs, color: colors.textLight, marginTop: 4 },
  fab: {
    position: 'absolute',
    right: spacing.md,
    bottom: spacing.lg,
    width: 56,
    height: 56,
    borderRadius: 28,
    backgroundColor: colors.primary,
    justifyContent: 'center',
    alignItems: 'center',
    zIndex: 10,
    ...shadows.lg,
  },
  emptyContainer: { alignItems: 'center', paddingTop: spacing.xxl },
  emptyText: { fontSize: fontSize.md, color: colors.textLight, marginTop: spacing.sm },
});
