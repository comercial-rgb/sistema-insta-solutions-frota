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
import { router } from 'expo-router';
import { useInfiniteQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { notificationsApi } from '../src/api/notifications';
import { colors, spacing, borderRadius, fontSize, shadows } from '../src/theme/colors';
import { Ionicons } from '@expo/vector-icons';
import { AppNotification } from '../src/types';

const ICON_MAP: Record<string, string> = {
  os: 'construct-outline',
  vehicle: 'car-outline',
  alert: 'warning-outline',
  anomaly: 'alert-circle-outline',
  balance: 'wallet-outline',
  default: 'notifications-outline',
};

export default function NotificationsScreen() {
  const queryClient = useQueryClient();

  const { data, fetchNextPage, hasNextPage, isLoading, refetch, isRefetching } =
    useInfiniteQuery({
      queryKey: ['notifications'],
      queryFn: ({ pageParam = 1 }) => notificationsApi.list({ page: pageParam, per_page: 30 }),
      getNextPageParam: (lastPage) =>
        lastPage.meta.current_page < lastPage.meta.total_pages ? lastPage.meta.current_page + 1 : undefined,
      initialPageParam: 1,
    });

  const markReadMutation = useMutation({
    mutationFn: notificationsApi.markAsRead,
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['notifications'] }),
  });

  const markAllReadMutation = useMutation({
    mutationFn: notificationsApi.markAllAsRead,
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['notifications'] }),
  });

  const allNotifications = data?.pages.flatMap((p) => p.notifications) ?? [];
  const unreadCount = allNotifications.filter((n) => !n.read).length;

  const handlePress = (notification: AppNotification) => {
    if (!notification.read) {
      markReadMutation.mutate(notification.id);
    }
    // Navigate based on type
    if (notification.resource_type === 'OrderService' && notification.resource_id) {
      router.push(`/os-detail/${notification.resource_id}`);
    } else if (notification.resource_type === 'Vehicle' && notification.resource_id) {
      router.push(`/vehicle-detail/${notification.resource_id}`);
    }
  };

  const formatTime = (dateStr: string) => {
    const date = new Date(dateStr);
    const now = new Date();
    const diffMs = now.getTime() - date.getTime();
    const diffMins = Math.floor(diffMs / 60000);
    if (diffMins < 1) return 'agora';
    if (diffMins < 60) return `${diffMins}min`;
    const diffHours = Math.floor(diffMins / 60);
    if (diffHours < 24) return `${diffHours}h`;
    const diffDays = Math.floor(diffHours / 24);
    if (diffDays < 7) return `${diffDays}d`;
    return date.toLocaleDateString('pt-BR', { day: '2-digit', month: '2-digit' });
  };

  return (
    <View style={styles.container}>
      <View style={styles.header}>
        <TouchableOpacity onPress={() => router.back()} style={styles.backBtn}>
          <Ionicons name="arrow-back" size={24} color={colors.primary} />
        </TouchableOpacity>
        <Text style={styles.headerTitle}>Notificações</Text>
        {unreadCount > 0 && (
          <TouchableOpacity
            style={styles.markAllBtn}
            onPress={() => markAllReadMutation.mutate()}
            disabled={markAllReadMutation.isPending}
          >
            <Text style={styles.markAllText}>Marcar todas</Text>
          </TouchableOpacity>
        )}
      </View>

      {unreadCount > 0 && (
        <View style={styles.unreadBar}>
          <Text style={styles.unreadText}>{unreadCount} não lida{unreadCount > 1 ? 's' : ''}</Text>
        </View>
      )}

      {isLoading ? (
        <ActivityIndicator size="large" color={colors.primary} style={{ marginTop: spacing.xxl }} />
      ) : (
        <FlatList
          data={allNotifications}
          renderItem={({ item }) => (
            <TouchableOpacity
              style={[styles.notifCard, !item.read && styles.notifCardUnread]}
              onPress={() => handlePress(item)}
              activeOpacity={0.7}
            >
              <View style={[styles.iconCircle, !item.read && styles.iconCircleUnread]}>
                <Ionicons
                  name={(ICON_MAP[item.category ?? 'default'] || ICON_MAP.default) as any}
                  size={20}
                  color={!item.read ? colors.primary : colors.textLight}
                />
              </View>
              <View style={styles.notifBody}>
                <Text style={[styles.notifTitle, !item.read && styles.notifTitleUnread]}>
                  {item.title}
                </Text>
                <Text style={styles.notifMessage} numberOfLines={2}>{item.message}</Text>
                <Text style={styles.notifTime}>{formatTime(item.created_at)}</Text>
              </View>
              {!item.read && <View style={styles.unreadDot} />}
            </TouchableOpacity>
          )}
          keyExtractor={(item) => item.id.toString()}
          contentContainerStyle={styles.listContent}
          refreshControl={<RefreshControl refreshing={isRefetching} onRefresh={refetch} />}
          onEndReached={() => hasNextPage && fetchNextPage()}
          ListEmptyComponent={
            <View style={styles.emptyContainer}>
              <Ionicons name="notifications-off-outline" size={48} color={colors.textLight} />
              <Text style={styles.emptyText}>Nenhuma notificação</Text>
            </View>
          }
        />
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: colors.background },
  header: { flexDirection: 'row', alignItems: 'center', padding: spacing.md },
  backBtn: { marginRight: spacing.sm },
  headerTitle: { fontSize: fontSize.xl, fontWeight: '700', color: colors.text, flex: 1 },
  markAllBtn: { paddingHorizontal: spacing.sm },
  markAllText: { fontSize: fontSize.sm, color: colors.primary, fontWeight: '600' },

  unreadBar: { backgroundColor: colors.primary + '10', paddingVertical: spacing.xs, paddingHorizontal: spacing.md },
  unreadText: { fontSize: fontSize.xs, color: colors.primary, fontWeight: '600' },

  listContent: { paddingHorizontal: spacing.md, paddingBottom: spacing.xxl },
  notifCard: { flexDirection: 'row', alignItems: 'flex-start', backgroundColor: colors.surface, borderRadius: borderRadius.md, padding: spacing.md, marginBottom: spacing.xs },
  notifCardUnread: { backgroundColor: colors.primary + '06', borderLeftWidth: 3, borderLeftColor: colors.primary },
  iconCircle: { width: 40, height: 40, borderRadius: 20, backgroundColor: colors.background, alignItems: 'center', justifyContent: 'center', marginRight: spacing.sm },
  iconCircleUnread: { backgroundColor: colors.primary + '15' },
  notifBody: { flex: 1 },
  notifTitle: { fontSize: fontSize.sm, fontWeight: '500', color: colors.text },
  notifTitleUnread: { fontWeight: '700' },
  notifMessage: { fontSize: fontSize.xs, color: colors.textSecondary, marginTop: 2, lineHeight: 16 },
  notifTime: { fontSize: fontSize.xs, color: colors.textLight, marginTop: 4 },
  unreadDot: { width: 8, height: 8, borderRadius: 4, backgroundColor: colors.primary, marginTop: 6 },

  emptyContainer: { alignItems: 'center', paddingTop: spacing.xxl },
  emptyText: { fontSize: fontSize.md, color: colors.textLight, marginTop: spacing.sm },
});
