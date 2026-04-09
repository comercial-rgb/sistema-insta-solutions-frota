import React from 'react';
import {
  View,
  Text,
  FlatList,
  StyleSheet,
  TouchableOpacity,
  RefreshControl,
  ActivityIndicator,
} from 'react-native';
import { router, Stack } from 'expo-router';
import { useInfiniteQuery } from '@tanstack/react-query';
import { anomaliesApi } from '../src/api/anomalies';
import { colors, spacing, borderRadius, fontSize, shadows } from '../src/theme/colors';
import { Ionicons } from '@expo/vector-icons';
import { Anomaly } from '../src/types';

const SEVERITY_CONFIG = {
  low: { color: colors.info, label: 'Baixa', icon: 'information-circle' },
  medium: { color: colors.warning, label: 'Média', icon: 'alert-circle' },
  high: { color: colors.danger, label: 'Alta', icon: 'warning' },
  critical: { color: '#B71C1C', label: 'Crítica', icon: 'flame' },
};

const STATUS_CONFIG = {
  open: { color: colors.statusOpen, label: 'Aberta' },
  in_progress: { color: colors.statusInProgress, label: 'Em Andamento' },
  resolved: { color: colors.success, label: 'Resolvida' },
  closed: { color: colors.textLight, label: 'Fechada' },
};

export default function AnomaliesScreen() {
  const { data, fetchNextPage, hasNextPage, isLoading, refetch, isRefetching } =
    useInfiniteQuery({
      queryKey: ['anomalies'],
      queryFn: ({ pageParam = 1 }) => anomaliesApi.list({ page: pageParam, per_page: 20 }),
      getNextPageParam: (lastPage) =>
        lastPage.meta.current_page < lastPage.meta.total_pages ? lastPage.meta.current_page + 1 : undefined,
      initialPageParam: 1,
    });

  const allAnomalies = data?.pages.flatMap((p) => p.anomalies) ?? [];

  return (
    <View style={styles.container}>
      <Stack.Screen
        options={{
          headerRight: () => (
            <TouchableOpacity onPress={() => router.push('/report-anomaly')} style={{ marginRight: spacing.sm }}>
              <Ionicons name="add-circle-outline" size={26} color="#fff" />
            </TouchableOpacity>
          ),
        }}
      />

      {isLoading ? (
        <ActivityIndicator size="large" color={colors.primary} style={{ marginTop: spacing.xxl }} />
      ) : (
        <FlatList
          data={allAnomalies}
          renderItem={({ item }) => <AnomalyCard item={item} />}
          keyExtractor={(item) => item.id.toString()}
          contentContainerStyle={styles.listContent}
          refreshControl={<RefreshControl refreshing={isRefetching} onRefresh={refetch} />}
          onEndReached={() => hasNextPage && fetchNextPage()}
          ListEmptyComponent={
            <View style={styles.emptyContainer}>
              <Ionicons name="checkmark-circle-outline" size={48} color={colors.textLight} />
              <Text style={styles.emptyText}>Nenhuma anomalia registrada</Text>
            </View>
          }
        />
      )}
    </View>
  );
}

function AnomalyCard({ item }: { item: Anomaly }) {
  const severity = SEVERITY_CONFIG[item.severity];
  const status = STATUS_CONFIG[item.status];

  return (
    <TouchableOpacity style={styles.card} activeOpacity={0.7}>
      <View style={styles.cardHeader}>
        <View style={styles.severityBadge}>
          <Ionicons name={severity.icon as any} size={16} color={severity.color} />
          <Text style={[styles.severityText, { color: severity.color }]}>{severity.label}</Text>
        </View>
        <View style={[styles.statusBadge, { backgroundColor: status.color + '18' }]}>
          <Text style={[styles.statusText, { color: status.color }]}>{status.label}</Text>
        </View>
      </View>
      <Text style={styles.title}>{item.title}</Text>
      <Text style={styles.description} numberOfLines={2}>{item.description}</Text>
      <View style={styles.cardFooter}>
        <Text style={styles.vehicleText}>
          <Ionicons name="car-outline" size={12} color={colors.textLight} /> {item.vehicle_board}
        </Text>
        <Text style={styles.dateText}>{new Date(item.created_at).toLocaleDateString('pt-BR')}</Text>
      </View>
    </TouchableOpacity>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: colors.background },
  listContent: { paddingHorizontal: spacing.md, paddingTop: spacing.sm, paddingBottom: spacing.xxl },
  card: { backgroundColor: colors.surface, borderRadius: borderRadius.md, padding: spacing.md, marginBottom: spacing.sm, ...shadows.sm },
  cardHeader: { flexDirection: 'row', justifyContent: 'space-between', marginBottom: spacing.sm },
  severityBadge: { flexDirection: 'row', alignItems: 'center', gap: 4 },
  severityText: { fontSize: fontSize.xs, fontWeight: '600' },
  statusBadge: { paddingHorizontal: spacing.sm, paddingVertical: 2, borderRadius: borderRadius.full },
  statusText: { fontSize: fontSize.xs, fontWeight: '600' },
  title: { fontSize: fontSize.md, fontWeight: '600', color: colors.text, marginBottom: 4 },
  description: { fontSize: fontSize.sm, color: colors.textSecondary, lineHeight: 18, marginBottom: spacing.sm },
  cardFooter: { flexDirection: 'row', justifyContent: 'space-between' },
  vehicleText: { fontSize: fontSize.xs, color: colors.textLight },
  dateText: { fontSize: fontSize.xs, color: colors.textLight },
  emptyContainer: { alignItems: 'center', paddingTop: spacing.xxl },
  emptyText: { fontSize: fontSize.md, color: colors.textLight, marginTop: spacing.sm },
});
