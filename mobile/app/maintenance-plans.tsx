import React, { useState } from 'react';
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
import { maintenancePlansApi } from '../src/api/maintenancePlans';
import { colors, spacing, borderRadius, fontSize, shadows } from '../src/theme/colors';
import { Ionicons } from '@expo/vector-icons';
import { MaintenancePlan } from '../src/types';
import Toast from 'react-native-toast-message';

export default function MaintenancePlansScreen() {
  const queryClient = useQueryClient();

  const { data, fetchNextPage, hasNextPage, isLoading, refetch, isRefetching } =
    useInfiniteQuery({
      queryKey: ['maintenance-plans'],
      queryFn: ({ pageParam = 1 }) => maintenancePlansApi.list({ page: pageParam, per_page: 20 }),
      getNextPageParam: (lastPage) =>
        lastPage.meta.current_page < lastPage.meta.total_pages
          ? lastPage.meta.current_page + 1
          : undefined,
      initialPageParam: 1,
    });

  const deleteMutation = useMutation({
    mutationFn: maintenancePlansApi.destroy,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['maintenance-plans'] });
      Toast.show({ type: 'success', text1: 'Plano excluído com sucesso' });
    },
    onError: () => {
      Toast.show({ type: 'error', text1: 'Erro ao excluir plano' });
    },
  });

  const allPlans = data?.pages.flatMap((p) => p.plans) ?? [];

  const handleDelete = (plan: MaintenancePlan) => {
    Alert.alert(
      'Excluir Plano',
      `Tem certeza que deseja excluir o plano "${plan.name}"?`,
      [
        { text: 'Cancelar', style: 'cancel' },
        { text: 'Excluir', style: 'destructive', onPress: () => deleteMutation.mutate(plan.id) },
      ]
    );
  };

  const renderPlan = ({ item }: { item: MaintenancePlan }) => (
    <TouchableOpacity
      style={styles.card}
      onPress={() => router.push(`/maintenance-plan-detail/${item.id}` as any)}
      activeOpacity={0.7}
    >
      <View style={styles.cardHeader}>
        <View style={styles.cardTitleRow}>
          <Ionicons name="clipboard-outline" size={20} color={colors.primary} />
          <Text style={styles.cardTitle} numberOfLines={1}>{item.name}</Text>
        </View>
        <View style={[styles.statusBadge, { backgroundColor: item.active ? colors.success + '20' : colors.textLight + '20' }]}>
          <Text style={[styles.statusText, { color: item.active ? colors.success : colors.textLight }]}>
            {item.active ? 'Ativo' : 'Inativo'}
          </Text>
        </View>
      </View>

      {item.description ? (
        <Text style={styles.description} numberOfLines={2}>{item.description}</Text>
      ) : null}

      <View style={styles.statsRow}>
        <View style={styles.stat}>
          <Ionicons name="list-outline" size={14} color={colors.textSecondary} />
          <Text style={styles.statText}>{item.items_count} itens</Text>
        </View>
        <View style={styles.stat}>
          <Ionicons name="car-outline" size={14} color={colors.textSecondary} />
          <Text style={styles.statText}>{item.vehicles_count} veículos</Text>
        </View>
      </View>

      <View style={styles.cardActions}>
        <TouchableOpacity
          style={styles.actionBtn}
          onPress={() => router.push(`/maintenance-plan-detail/${item.id}` as any)}
        >
          <Ionicons name="pencil-outline" size={16} color={colors.primary} />
          <Text style={[styles.actionText, { color: colors.primary }]}>Editar</Text>
        </TouchableOpacity>
        <TouchableOpacity
          style={styles.actionBtn}
          onPress={() => handleDelete(item)}
        >
          <Ionicons name="trash-outline" size={16} color={colors.danger} />
          <Text style={[styles.actionText, { color: colors.danger }]}>Excluir</Text>
        </TouchableOpacity>
      </View>
    </TouchableOpacity>
  );

  return (
    <View style={styles.container}>
      <View style={styles.headerActions}>
        <TouchableOpacity
          style={styles.createBtn}
          onPress={() => router.push('/maintenance-plan-detail/new' as any)}
        >
          <Ionicons name="add-circle-outline" size={20} color={colors.surface} />
          <Text style={styles.createBtnText}>Novo Plano</Text>
        </TouchableOpacity>
      </View>

      {isLoading ? (
        <ActivityIndicator size="large" color={colors.primary} style={{ marginTop: spacing.xxl }} />
      ) : (
        <FlatList
          data={allPlans}
          renderItem={renderPlan}
          keyExtractor={(item) => item.id.toString()}
          contentContainerStyle={styles.listContent}
          refreshControl={<RefreshControl refreshing={isRefetching} onRefresh={refetch} />}
          onEndReached={() => hasNextPage && fetchNextPage()}
          ListEmptyComponent={
            <View style={styles.emptyContainer}>
              <Ionicons name="clipboard-outline" size={48} color={colors.textLight} />
              <Text style={styles.emptyText}>Nenhum plano de manutenção</Text>
              <Text style={styles.emptySubtext}>Crie um plano para começar a monitorar seus veículos</Text>
            </View>
          }
        />
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: colors.background },
  headerActions: {
    padding: spacing.md,
    paddingBottom: spacing.xs,
  },
  createBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: colors.primary,
    borderRadius: borderRadius.md,
    paddingVertical: spacing.sm,
    paddingHorizontal: spacing.md,
    gap: spacing.xs,
  },
  createBtnText: {
    color: colors.surface,
    fontSize: fontSize.md,
    fontWeight: '600',
  },
  listContent: { padding: spacing.md, paddingTop: spacing.xs },
  card: {
    backgroundColor: colors.surface,
    borderRadius: borderRadius.md,
    padding: spacing.md,
    marginBottom: spacing.sm,
    ...shadows.sm,
  },
  cardHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: spacing.xs,
  },
  cardTitleRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.xs,
    flex: 1,
  },
  cardTitle: {
    fontSize: fontSize.md,
    fontWeight: '600',
    color: colors.text,
    flex: 1,
  },
  statusBadge: {
    paddingHorizontal: spacing.sm,
    paddingVertical: 2,
    borderRadius: borderRadius.sm,
  },
  statusText: {
    fontSize: fontSize.xs,
    fontWeight: '600',
  },
  description: {
    fontSize: fontSize.sm,
    color: colors.textSecondary,
    marginBottom: spacing.sm,
  },
  statsRow: {
    flexDirection: 'row',
    gap: spacing.md,
    marginBottom: spacing.sm,
  },
  stat: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
  },
  statText: {
    fontSize: fontSize.sm,
    color: colors.textSecondary,
  },
  cardActions: {
    flexDirection: 'row',
    justifyContent: 'flex-end',
    gap: spacing.md,
    borderTopWidth: 1,
    borderTopColor: colors.borderLight,
    paddingTop: spacing.sm,
  },
  actionBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
  },
  actionText: {
    fontSize: fontSize.sm,
    fontWeight: '500',
  },
  emptyContainer: {
    alignItems: 'center',
    justifyContent: 'center',
    paddingTop: spacing.xxl,
  },
  emptyText: {
    fontSize: fontSize.md,
    color: colors.textLight,
    marginTop: spacing.sm,
  },
  emptySubtext: {
    fontSize: fontSize.sm,
    color: colors.textLight,
    marginTop: spacing.xs,
    textAlign: 'center',
  },
});
