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
} from 'react-native';
import { router } from 'expo-router';
import { useInfiniteQuery } from '@tanstack/react-query';
import { vehiclesApi } from '../../src/api/vehicles';
import { colors, spacing, borderRadius, fontSize, shadows } from '../../src/theme/colors';
import { Ionicons } from '@expo/vector-icons';
import { Vehicle } from '../../src/types';
import { useResponsiveLayout } from '../../src/hooks/useResponsiveLayout';

export default function VehiclesScreen() {
  const [search, setSearch] = useState('');
  const { listColumns } = useResponsiveLayout();

  const { data, fetchNextPage, hasNextPage, isLoading, refetch, isRefetching, isFetchingNextPage } =
    useInfiniteQuery({
      queryKey: ['vehicles', search],
      queryFn: ({ pageParam = 1 }) =>
        vehiclesApi.list({ page: pageParam, per_page: 20, search: search || undefined }),
      getNextPageParam: (lastPage) => {
        if (lastPage.meta.current_page < lastPage.meta.total_pages) {
          return lastPage.meta.current_page + 1;
        }
        return undefined;
      },
      initialPageParam: 1,
    });

  const allVehicles = data?.pages.flatMap((p) => p.vehicles) ?? [];

  const renderItem = useCallback(
    ({ item }: { item: Vehicle }) => (
      <TouchableOpacity
        style={styles.card}
        onPress={() => router.push(`/vehicle-detail/${item.id}`)}
        activeOpacity={0.7}
      >
        <View style={styles.cardHeader}>
          <View style={styles.plateContainer}>
            <Text style={styles.plateText}>{item.board}</Text>
          </View>
          <View style={[styles.activeBadge, { backgroundColor: item.active ? colors.successLight : colors.dangerLight }]}>
            <Text style={[styles.activeText, { color: item.active ? colors.success : colors.danger }]}>
              {item.active ? 'Ativo' : 'Inativo'}
            </Text>
          </View>
        </View>

        <Text style={styles.vehicleName}>{item.brand} {item.model}</Text>

        <View style={styles.detailsRow}>
          {item.year && (
            <View style={styles.detailChip}>
              <Ionicons name="calendar-outline" size={12} color={colors.textSecondary} />
              <Text style={styles.detailText}>{item.year}</Text>
            </View>
          )}
          {item.color && (
            <View style={styles.detailChip}>
              <Ionicons name="color-palette-outline" size={12} color={colors.textSecondary} />
              <Text style={styles.detailText}>{item.color}</Text>
            </View>
          )}
          {item.fuel_type && (
            <View style={styles.detailChip}>
              <Ionicons name="flash-outline" size={12} color={colors.textSecondary} />
              <Text style={styles.detailText}>{item.fuel_type}</Text>
            </View>
          )}
        </View>

        {item.cost_center && (
          <Text style={styles.costCenter}>
            <Ionicons name="business-outline" size={12} color={colors.textLight} />{' '}
            {item.cost_center}
          </Text>
        )}
      </TouchableOpacity>
    ),
    []
  );

  return (
    <View style={styles.container}>
      <View style={styles.searchBar}>
        <Ionicons name="search-outline" size={18} color={colors.textLight} />
        <TextInput
          style={styles.searchInput}
          placeholder="Buscar por placa, marca ou modelo..."
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

      {isLoading ? (
        <ActivityIndicator size="large" color={colors.primary} style={{ marginTop: spacing.xxl }} />
      ) : (
        <FlatList
          key={`vehicles-${listColumns}`}
          data={allVehicles}
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
              <Ionicons name="car-outline" size={48} color={colors.textLight} />
              <Text style={styles.emptyText}>Nenhum veículo encontrado</Text>
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
    margin: spacing.md,
    paddingHorizontal: spacing.md,
    height: 44,
    borderRadius: borderRadius.md,
    ...shadows.sm,
  },
  searchInput: { flex: 1, marginLeft: spacing.sm, fontSize: fontSize.sm, color: colors.text },
  listContent: { paddingHorizontal: spacing.md, paddingBottom: spacing.xxl },
  card: {
    flex: 1,
    backgroundColor: colors.surface,
    borderRadius: borderRadius.md,
    padding: spacing.md,
    marginBottom: spacing.sm,
    ...shadows.sm,
  },
  cardHeader: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginBottom: spacing.sm },
  plateContainer: {
    backgroundColor: colors.primary + '12',
    paddingHorizontal: spacing.sm,
    paddingVertical: 4,
    borderRadius: borderRadius.sm,
    borderWidth: 1,
    borderColor: colors.primary + '30',
  },
  plateText: { fontSize: fontSize.md, fontWeight: '700', color: colors.primary, letterSpacing: 1 },
  activeBadge: { paddingHorizontal: spacing.sm, paddingVertical: 3, borderRadius: borderRadius.full },
  activeText: { fontSize: fontSize.xs, fontWeight: '600' },
  vehicleName: { fontSize: fontSize.md, fontWeight: '600', color: colors.text, marginBottom: spacing.sm },
  detailsRow: { flexDirection: 'row', gap: spacing.sm, flexWrap: 'wrap', marginBottom: spacing.xs },
  detailChip: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    backgroundColor: colors.surfaceVariant,
    paddingHorizontal: spacing.sm,
    paddingVertical: 3,
    borderRadius: borderRadius.full,
  },
  detailText: { fontSize: fontSize.xs, color: colors.textSecondary },
  costCenter: { fontSize: fontSize.xs, color: colors.textLight, marginTop: spacing.xs },
  emptyContainer: { alignItems: 'center', paddingTop: spacing.xxl },
  emptyText: { fontSize: fontSize.md, color: colors.textLight, marginTop: spacing.sm },
});
