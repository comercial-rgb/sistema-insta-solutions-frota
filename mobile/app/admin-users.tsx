import React, { useState } from 'react';
import {
  View,
  Text,
  FlatList,
  StyleSheet,
  TouchableOpacity,
  RefreshControl,
  ActivityIndicator,
  TextInput,
  Alert,
  Modal,
  ScrollView,
  KeyboardAvoidingView,
  Platform,
} from 'react-native';
import { router, Stack } from 'expo-router';
import { useInfiniteQuery, useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { adminUsersApi } from '../src/api/adminUsers';
import { colors, spacing, borderRadius, fontSize, shadows } from '../src/theme/colors';
import { Ionicons } from '@expo/vector-icons';

const PROFILE_LABELS: Record<number, string> = {
  1: 'Administrador',
  3: 'Cliente',
  4: 'Gestor',
  5: 'Adicional',
  6: 'Fornecedor',
  7: 'Motorista',
};

const PROFILE_COLORS: Record<number, string> = {
  1: colors.danger,
  3: colors.info,
  4: colors.success,
  5: colors.warning,
  6: '#9C27B0',
  7: '#00ACC1',
};

export default function AdminUsersScreen() {
  const queryClient = useQueryClient();
  const [search, setSearch] = useState('');
  const [filterProfile, setFilterProfile] = useState<number | null>(null);
  const [showCreateModal, setShowCreateModal] = useState(false);

  const { data, fetchNextPage, hasNextPage, isLoading, refetch, isRefetching } =
    useInfiniteQuery({
      queryKey: ['admin-users', search, filterProfile],
      queryFn: ({ pageParam = 1 }) =>
        adminUsersApi.list({ page: pageParam, per_page: 20, search, profile_id: filterProfile ?? undefined }),
      getNextPageParam: (lastPage) =>
        lastPage.meta.current_page < lastPage.meta.total_pages ? lastPage.meta.current_page + 1 : undefined,
      initialPageParam: 1,
    });

  const { data: profilesData } = useQuery({
    queryKey: ['profiles'],
    queryFn: () => adminUsersApi.getProfiles(),
  });

  const toggleBlockMutation = useMutation({
    mutationFn: adminUsersApi.toggleBlock,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['admin-users'] });
    },
    onError: () => Alert.alert('Erro', 'Não foi possível alterar o status do usuário.'),
  });

  const allUsers = data?.pages.flatMap((p) => p.users) ?? [];

  const handleToggleBlock = (user: any) => {
    const action = user.is_blocked ? 'desbloquear' : 'bloquear';
    Alert.alert(
      'Confirmar',
      `Deseja ${action} o usuário ${user.name}?`,
      [
        { text: 'Cancelar', style: 'cancel' },
        { text: 'Confirmar', onPress: () => toggleBlockMutation.mutate(user.id) },
      ]
    );
  };

  return (
    <View style={styles.container}>
      <Stack.Screen
        options={{
          headerRight: () => (
            <TouchableOpacity onPress={() => setShowCreateModal(true)} style={{ marginRight: spacing.sm }}>
              <Ionicons name="person-add-outline" size={24} color="#fff" />
            </TouchableOpacity>
          ),
        }}
      />

      {/* Search */}
      <View style={styles.searchContainer}>
        <Ionicons name="search-outline" size={18} color={colors.textLight} />
        <TextInput
          style={styles.searchInput}
          placeholder="Buscar por nome ou email..."
          value={search}
          onChangeText={setSearch}
        />
        {search.length > 0 && (
          <TouchableOpacity onPress={() => setSearch('')}>
            <Ionicons name="close-circle" size={18} color={colors.textLight} />
          </TouchableOpacity>
        )}
      </View>

      {/* Profile Filters */}
      <ScrollView horizontal showsHorizontalScrollIndicator={false} style={{ flexGrow: 0 }} contentContainerStyle={styles.filtersRow}>
        <TouchableOpacity
          style={[styles.filterChip, !filterProfile && styles.filterChipActive]}
          onPress={() => setFilterProfile(null)}
        >
          <Text style={[styles.filterChipText, !filterProfile && styles.filterChipTextActive]}>Todos</Text>
        </TouchableOpacity>
        {[1, 3, 4, 5, 6, 7].map((pid) => (
          <TouchableOpacity
            key={pid}
            style={[styles.filterChip, filterProfile === pid && { backgroundColor: PROFILE_COLORS[pid] + '18', borderColor: PROFILE_COLORS[pid] }]}
            onPress={() => setFilterProfile(filterProfile === pid ? null : pid)}
          >
            <Text style={[styles.filterChipText, filterProfile === pid && { color: PROFILE_COLORS[pid] }]}>
              {PROFILE_LABELS[pid]}
            </Text>
          </TouchableOpacity>
        ))}
      </ScrollView>

      {isLoading ? (
        <ActivityIndicator size="large" color={colors.primary} style={{ marginTop: spacing.xxl }} />
      ) : (
        <FlatList
          data={allUsers}
          renderItem={({ item }) => (
            <View style={styles.userCard}>
              <View style={styles.userAvatar}>
                <Text style={styles.userAvatarText}>{(item.name ?? 'U').charAt(0).toUpperCase()}</Text>
              </View>
              <View style={styles.userInfo}>
                <Text style={styles.userName}>{item.name}</Text>
                <Text style={styles.userEmail}>{item.email}</Text>
                <View style={styles.userMeta}>
                  <View style={[styles.profileBadge, { backgroundColor: (PROFILE_COLORS[item.profile_id] ?? colors.textLight) + '18' }]}>
                    <Text style={[styles.profileBadgeText, { color: PROFILE_COLORS[item.profile_id] ?? colors.textLight }]}>
                      {PROFILE_LABELS[item.profile_id] ?? `Perfil ${item.profile_id}`}
                    </Text>
                  </View>
                  {item.is_blocked && (
                    <View style={styles.blockedBadge}>
                      <Ionicons name="lock-closed" size={10} color={colors.danger} />
                      <Text style={styles.blockedText}>Bloqueado</Text>
                    </View>
                  )}
                </View>
              </View>
              <TouchableOpacity
                style={styles.actionBtn}
                onPress={() => handleToggleBlock(item)}
              >
                <Ionicons
                  name={item.is_blocked ? 'lock-open-outline' : 'lock-closed-outline'}
                  size={20}
                  color={item.is_blocked ? colors.success : colors.danger}
                />
              </TouchableOpacity>
            </View>
          )}
          keyExtractor={(item) => item.id.toString()}
          contentContainerStyle={styles.listContent}
          refreshControl={<RefreshControl refreshing={isRefetching} onRefresh={refetch} />}
          onEndReached={() => hasNextPage && fetchNextPage()}
          ListEmptyComponent={
            <View style={styles.emptyContainer}>
              <Ionicons name="people-outline" size={48} color={colors.textLight} />
              <Text style={styles.emptyText}>Nenhum usuário encontrado</Text>
            </View>
          }
        />
      )}

      {/* Create User Modal */}
      <CreateUserModal
        visible={showCreateModal}
        onClose={() => setShowCreateModal(false)}
        profiles={profilesData?.profiles ?? []}
      />
    </View>
  );
}

function CreateUserModal({ visible, onClose, profiles }: { visible: boolean; onClose: () => void; profiles: any[] }) {
  const queryClient = useQueryClient();
  const [name, setName] = useState('');
  const [email, setEmail] = useState('');
  const [profileId, setProfileId] = useState<number>(7);

  const mutation = useMutation({
    mutationFn: adminUsersApi.create,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['admin-users'] });
      Alert.alert('Sucesso', 'Usuário criado com sucesso. Senha enviada por email.');
      resetAndClose();
    },
    onError: (err: any) => {
      const msg = err?.response?.data?.error || 'Não foi possível criar o usuário.';
      Alert.alert('Erro', msg);
    },
  });

  const resetAndClose = () => {
    setName('');
    setEmail('');
    setProfileId(3);
    onClose();
  };

  const handleCreate = () => {
    if (!name.trim()) return Alert.alert('Atenção', 'Informe o nome.');
    if (!email.trim()) return Alert.alert('Atenção', 'Informe o email.');
    mutation.mutate({ name, email, profile_id: profileId });
  };

  return (
    <Modal visible={visible} transparent animationType="slide">
      <KeyboardAvoidingView
        style={modalStyles.overlay}
        behavior={Platform.OS === 'ios' ? 'padding' : undefined}
      >
        <ScrollView
          contentContainerStyle={{ flexGrow: 1, justifyContent: 'flex-end' }}
          keyboardShouldPersistTaps="handled"
        >
          <View style={modalStyles.container}>
            <View style={modalStyles.header}>
              <Text style={modalStyles.title}>Novo Usuário</Text>
              <TouchableOpacity onPress={resetAndClose}>
                <Ionicons name="close" size={24} color={colors.textLight} />
              </TouchableOpacity>
            </View>

            <Text style={modalStyles.label}>Nome</Text>
            <TextInput
              style={modalStyles.input}
              placeholder="Nome completo"
              value={name}
              onChangeText={setName}
            />

            <Text style={modalStyles.label}>Email</Text>
            <TextInput
              style={modalStyles.input}
              placeholder="email@exemplo.com"
              value={email}
              onChangeText={setEmail}
              keyboardType="email-address"
              autoCapitalize="none"
            />

            <Text style={modalStyles.label}>Perfil</Text>
            <View style={modalStyles.chipRow}>
              {[1, 3, 4, 5, 6, 7].map((pid) => (
                <TouchableOpacity
                  key={pid}
                  style={[
                    modalStyles.chip,
                    profileId === pid && { backgroundColor: PROFILE_COLORS[pid] + '20', borderColor: PROFILE_COLORS[pid] },
                  ]}
                  onPress={() => setProfileId(pid)}
                >
                  <Text style={[modalStyles.chipText, profileId === pid && { color: PROFILE_COLORS[pid], fontWeight: '600' }]}>
                    {PROFILE_LABELS[pid]}
                  </Text>
                </TouchableOpacity>
              ))}
            </View>

            <TouchableOpacity
              style={[modalStyles.createBtn, mutation.isPending && { opacity: 0.6 }]}
              onPress={handleCreate}
              disabled={mutation.isPending}
            >
              {mutation.isPending ? (
                <ActivityIndicator color="#FFF" />
              ) : (
                <Text style={modalStyles.createBtnText}>Criar Usuário</Text>
              )}
            </TouchableOpacity>
          </View>
        </ScrollView>
      </KeyboardAvoidingView>
    </Modal>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: colors.background },

  searchContainer: { flexDirection: 'row', alignItems: 'center', backgroundColor: colors.surface, marginHorizontal: spacing.md, paddingHorizontal: spacing.md, borderRadius: borderRadius.md, borderWidth: 1, borderColor: colors.border, marginBottom: spacing.sm, marginTop: spacing.sm },
  searchInput: { flex: 1, paddingVertical: spacing.sm, paddingHorizontal: spacing.xs, fontSize: fontSize.sm, color: colors.text },

  filtersRow: { paddingHorizontal: spacing.md, paddingBottom: spacing.sm, gap: spacing.xs, alignItems: 'center' },
  filterChip: { paddingHorizontal: spacing.md, paddingVertical: spacing.xs, borderRadius: borderRadius.full, borderWidth: 1, borderColor: colors.border, backgroundColor: colors.surface },
  filterChipActive: { backgroundColor: colors.primary + '15', borderColor: colors.primary },
  filterChipText: { fontSize: fontSize.xs, color: colors.textSecondary },
  filterChipTextActive: { color: colors.primary, fontWeight: '600' },

  listContent: { paddingHorizontal: spacing.md, paddingBottom: spacing.xxl },
  userCard: { flexDirection: 'row', alignItems: 'center', backgroundColor: colors.surface, borderRadius: borderRadius.md, padding: spacing.md, marginBottom: spacing.xs, ...shadows.sm },
  userAvatar: { width: 44, height: 44, borderRadius: 22, backgroundColor: colors.primary + '15', alignItems: 'center', justifyContent: 'center', marginRight: spacing.sm },
  userAvatarText: { fontSize: fontSize.lg, fontWeight: '700', color: colors.primary },
  userInfo: { flex: 1 },
  userName: { fontSize: fontSize.md, fontWeight: '600', color: colors.text },
  userEmail: { fontSize: fontSize.xs, color: colors.textSecondary, marginTop: 1 },
  userMeta: { flexDirection: 'row', gap: spacing.xs, marginTop: 4 },
  profileBadge: { paddingHorizontal: spacing.sm, paddingVertical: 1, borderRadius: borderRadius.full },
  profileBadgeText: { fontSize: 10, fontWeight: '600' },
  blockedBadge: { flexDirection: 'row', alignItems: 'center', gap: 2, paddingHorizontal: spacing.sm, paddingVertical: 1, borderRadius: borderRadius.full, backgroundColor: colors.danger + '15' },
  blockedText: { fontSize: 10, color: colors.danger, fontWeight: '600' },
  actionBtn: { padding: spacing.sm },

  emptyContainer: { alignItems: 'center', paddingTop: spacing.xxl },
  emptyText: { fontSize: fontSize.md, color: colors.textLight, marginTop: spacing.sm },
});

const modalStyles = StyleSheet.create({
  overlay: { flex: 1, backgroundColor: 'rgba(0,0,0,0.5)', justifyContent: 'flex-end' },
  container: { backgroundColor: colors.surface, borderTopLeftRadius: borderRadius.lg, borderTopRightRadius: borderRadius.lg, padding: spacing.lg, paddingBottom: spacing.xxl },
  header: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginBottom: spacing.lg },
  title: { fontSize: fontSize.lg, fontWeight: '700', color: colors.text },
  label: { fontSize: fontSize.sm, fontWeight: '600', color: colors.text, marginBottom: spacing.xs, marginTop: spacing.md },
  input: { backgroundColor: colors.background, borderRadius: borderRadius.md, padding: spacing.md, fontSize: fontSize.md, color: colors.text, borderWidth: 1, borderColor: colors.border },
  chipRow: { flexDirection: 'row', flexWrap: 'wrap', gap: spacing.xs },
  chip: { paddingHorizontal: spacing.md, paddingVertical: spacing.xs, borderRadius: borderRadius.full, borderWidth: 1, borderColor: colors.border },
  chipText: { fontSize: fontSize.sm, color: colors.textSecondary },
  createBtn: { backgroundColor: colors.primary, borderRadius: borderRadius.md, padding: spacing.md, alignItems: 'center', marginTop: spacing.xl },
  createBtnText: { color: '#FFF', fontSize: fontSize.md, fontWeight: '700' },
});
