import React from 'react';
import {
  View,
  Text,
  ScrollView,
  StyleSheet,
  TouchableOpacity,
  ActivityIndicator,
  Alert,
} from 'react-native';
import { useLocalSearchParams, router } from 'expo-router';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { orderServicesApi } from '../../src/api/orderServices';
import { colors, spacing, borderRadius, fontSize, shadows } from '../../src/theme/colors';
import { Ionicons } from '@expo/vector-icons';
import { useAuth } from '../../src/contexts/AuthContext';
import Toast from 'react-native-toast-message';
import { Proposal } from '../../src/types';

export default function OSDetailScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const { canApproveOS } = useAuth();
  const queryClient = useQueryClient();

  const { data, isLoading, isError, error, refetch } = useQuery({
    queryKey: ['os-detail', id],
    queryFn: () => orderServicesApi.getDetail(Number(id)),
    enabled: !!id && Number(id) > 0,
    retry: 2,
  });

  const approveMutation = useMutation({
    mutationFn: () => orderServicesApi.approve(Number(id)),
    onSuccess: (res) => {
      Toast.show({ type: 'success', text1: res.message });
      queryClient.invalidateQueries({ queryKey: ['os-detail', id] });
      queryClient.invalidateQueries({ queryKey: ['orderServices'] });
      queryClient.invalidateQueries({ queryKey: ['dashboard'] });
    },
    onError: (err: any) => {
      Toast.show({ type: 'error', text1: 'Erro', text2: err?.response?.data?.error || 'Erro ao aprovar' });
    },
  });

  const rejectMutation = useMutation({
    mutationFn: (justification: string) => orderServicesApi.reject(Number(id), justification),
    onSuccess: (res) => {
      Toast.show({ type: 'success', text1: res.message });
      queryClient.invalidateQueries({ queryKey: ['os-detail', id] });
      queryClient.invalidateQueries({ queryKey: ['orderServices'] });
    },
    onError: (err: any) => {
      Toast.show({ type: 'error', text1: 'Erro', text2: err?.response?.data?.error || 'Erro ao rejeitar' });
    },
  });

  const handleApprove = () => {
    Alert.alert('Aprovar OS', 'Confirma a aprovação desta OS?', [
      { text: 'Cancelar', style: 'cancel' },
      { text: 'Aprovar', onPress: () => approveMutation.mutate() },
    ]);
  };

  const handleReject = () => {
    Alert.prompt(
      'Rejeitar OS',
      'Informe a justificativa:',
      [
        { text: 'Cancelar', style: 'cancel' },
        { text: 'Rejeitar', style: 'destructive', onPress: (text) => text && rejectMutation.mutate(text) },
      ],
      'plain-text'
    );
  };

  if (isLoading) {
    return (
      <View style={styles.loadingContainer}>
        <ActivityIndicator size="large" color={colors.primary} />
      </View>
    );
  }

  const os = data?.order_service;
  const proposals = data?.proposals ?? [];

  if (!os) {
    return (
      <View style={styles.loadingContainer}>
        <Ionicons name="alert-circle-outline" size={48} color={colors.textLight} />
        <Text style={{ color: colors.textLight, marginTop: spacing.sm, fontSize: fontSize.md, textAlign: 'center', paddingHorizontal: spacing.lg }}>
          {isError ? `Erro ao carregar OS #${id}` : 'OS não encontrada'}
        </Text>
        {isError && error && (
          <Text style={{ color: colors.textLight, marginTop: spacing.xs, fontSize: fontSize.xs, textAlign: 'center' }}>
            {(error as any)?.response?.status === 401
              ? 'Sessão expirada. Faça login novamente.'
              : (error as any)?.response?.data?.error || 'Verifique sua conexão e tente novamente.'}
          </Text>
        )}
        <View style={{ flexDirection: 'row', gap: spacing.sm, marginTop: spacing.md }}>
          <TouchableOpacity
            style={{ paddingHorizontal: spacing.lg, paddingVertical: spacing.sm, backgroundColor: colors.primary, borderRadius: borderRadius.md }}
            onPress={() => refetch()}
          >
            <Text style={{ color: '#fff', fontWeight: '600' }}>Tentar novamente</Text>
          </TouchableOpacity>
          <TouchableOpacity
            style={{ paddingHorizontal: spacing.lg, paddingVertical: spacing.sm, backgroundColor: colors.border, borderRadius: borderRadius.md }}
            onPress={() => router.back()}
          >
            <Text style={{ color: colors.text, fontWeight: '600' }}>Voltar</Text>
          </TouchableOpacity>
        </View>
      </View>
    );
  }

  const isAwaitingApproval = os.status === 'Aguardando Avaliação de Proposta';

  return (
    <ScrollView style={styles.container} contentContainerStyle={styles.content}>
      {/* Status */}
      <View style={styles.statusCard}>
        <Text style={styles.statusLabel}>Status</Text>
        <Text style={styles.statusValue}>{os.status}</Text>
      </View>

      {/* Veículo */}
      <View style={styles.section}>
        <Text style={styles.sectionTitle}>Veículo</Text>
        <View style={styles.infoCard}>
          <InfoRow icon="car" label="Placa" value={os.vehicle?.board} />
          <InfoRow icon="speedometer" label="Marca/Modelo" value={`${os.vehicle?.brand} ${os.vehicle?.model}`} />
          <InfoRow icon="calendar" label="Ano" value={os.vehicle?.year} />
          {os.km && <InfoRow icon="analytics" label="KM" value={`${os.km.toLocaleString()} km`} />}
          {os.driver && <InfoRow icon="person" label="Motorista" value={os.driver} />}
        </View>
      </View>

      {/* Detalhes */}
      <View style={styles.section}>
        <Text style={styles.sectionTitle}>Detalhes</Text>
        <View style={styles.infoCard}>
          {os.type && <InfoRow icon="construct" label="Tipo" value={os.type} />}
          {os.service_type && <InfoRow icon="build" label="Serviço" value={os.service_type} />}
          {os.provider && <InfoRow icon="storefront" label="Fornecedor" value={os.provider.name} />}
          {os.commitment && <InfoRow icon="wallet" label="Empenho" value={os.commitment.number} />}
          <InfoRow icon="time" label="Criado em" value={new Date(os.created_at).toLocaleString('pt-BR')} />
          {os.origin_type && <InfoRow icon="phone-portrait" label="Origem" value={os.origin_type} />}
        </View>
      </View>

      {/* Descrição */}
      {os.details && (
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Descrição</Text>
          <View style={styles.infoCard}>
            <Text style={styles.detailsText}>{os.details}</Text>
          </View>
        </View>
      )}

      {/* Justificativa cancelamento */}
      {os.cancel_justification && (
        <View style={styles.section}>
          <Text style={[styles.sectionTitle, { color: colors.danger }]}>Justificativa Cancelamento</Text>
          <View style={[styles.infoCard, { borderLeftWidth: 3, borderLeftColor: colors.danger }]}>
            <Text style={styles.detailsText}>{os.cancel_justification}</Text>
          </View>
        </View>
      )}

      {/* Propostas */}
      {proposals.length > 0 && (
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Propostas ({proposals.length})</Text>
          {proposals.map((proposal) => (
            <ProposalCard key={proposal.id} proposal={proposal} />
          ))}
        </View>
      )}

      {/* Ações */}
      {canApproveOS && isAwaitingApproval && (
        <View style={styles.actionsContainer}>
          <TouchableOpacity
            style={[styles.actionBtn, styles.approveBtn]}
            onPress={handleApprove}
            disabled={approveMutation.isPending}
          >
            <Ionicons name="checkmark-circle" size={20} color="#fff" />
            <Text style={styles.actionBtnText}>Aprovar</Text>
          </TouchableOpacity>
          <TouchableOpacity
            style={[styles.actionBtn, styles.rejectBtn]}
            onPress={handleReject}
            disabled={rejectMutation.isPending}
          >
            <Ionicons name="close-circle" size={20} color="#fff" />
            <Text style={styles.actionBtnText}>Rejeitar</Text>
          </TouchableOpacity>
        </View>
      )}
    </ScrollView>
  );
}

function InfoRow({ icon, label, value }: { icon: string; label: string; value?: string }) {
  if (!value) return null;
  return (
    <View style={styles.infoRow}>
      <Ionicons name={`${icon}-outline` as any} size={16} color={colors.textSecondary} />
      <Text style={styles.infoLabel}>{label}:</Text>
      <Text style={styles.infoValue}>{value}</Text>
    </View>
  );
}

function ProposalCard({ proposal }: { proposal: Proposal }) {
  return (
    <View style={styles.proposalCard}>
      <View style={styles.proposalHeader}>
        <Text style={styles.proposalCode}>{proposal.code}</Text>
        <Text style={styles.proposalStatus}>{proposal.status}</Text>
      </View>
      {proposal.provider && (
        <Text style={styles.proposalProvider}>{proposal.provider.name}</Text>
      )}
      <View style={styles.proposalValues}>
        <Text style={styles.proposalTotal}>
          R$ {(proposal.total_value || 0).toLocaleString('pt-BR', { minimumFractionDigits: 2 })}
        </Text>
        {proposal.total_discount > 0 && (
          <Text style={styles.proposalDiscount}>
            Desconto: R$ {proposal.total_discount.toLocaleString('pt-BR', { minimumFractionDigits: 2 })}
          </Text>
        )}
      </View>
      {proposal.items.length > 0 && (
        <View style={styles.proposalItems}>
          {proposal.items.map((item) => (
            <View key={item.id} style={styles.proposalItem}>
              <Text style={styles.itemName}>{item.service_name}</Text>
              <Text style={styles.itemValue}>
                {item.quantity}x R$ {item.unit_value.toLocaleString('pt-BR', { minimumFractionDigits: 2 })}
              </Text>
            </View>
          ))}
        </View>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: colors.background },
  content: { padding: spacing.md, paddingBottom: spacing.xxl },
  loadingContainer: { flex: 1, justifyContent: 'center', alignItems: 'center' },
  header: { flexDirection: 'row', alignItems: 'center', marginBottom: spacing.md },
  backBtn: { marginRight: spacing.sm },
  headerTitle: { fontSize: fontSize.xl, fontWeight: '700', color: colors.text },
  statusCard: {
    backgroundColor: colors.primary,
    borderRadius: borderRadius.md,
    padding: spacing.md,
    marginBottom: spacing.md,
  },
  statusLabel: { fontSize: fontSize.xs, color: 'rgba(255,255,255,0.7)' },
  statusValue: { fontSize: fontSize.lg, fontWeight: '700', color: '#fff', marginTop: 2 },
  section: { marginBottom: spacing.md },
  sectionTitle: { fontSize: fontSize.md, fontWeight: '600', color: colors.text, marginBottom: spacing.sm },
  infoCard: {
    backgroundColor: colors.surface,
    borderRadius: borderRadius.md,
    padding: spacing.md,
    gap: spacing.sm,
    ...shadows.sm,
  },
  infoRow: { flexDirection: 'row', alignItems: 'center', gap: spacing.sm },
  infoLabel: { fontSize: fontSize.sm, color: colors.textSecondary, minWidth: 90 },
  infoValue: { fontSize: fontSize.sm, color: colors.text, fontWeight: '500', flex: 1 },
  detailsText: { fontSize: fontSize.sm, color: colors.text, lineHeight: 20 },
  proposalCard: {
    backgroundColor: colors.surface,
    borderRadius: borderRadius.md,
    padding: spacing.md,
    marginBottom: spacing.sm,
    ...shadows.sm,
  },
  proposalHeader: { flexDirection: 'row', justifyContent: 'space-between', marginBottom: spacing.xs },
  proposalCode: { fontSize: fontSize.sm, fontWeight: '700', color: colors.text },
  proposalStatus: { fontSize: fontSize.xs, color: colors.primaryLight, fontWeight: '500' },
  proposalProvider: { fontSize: fontSize.sm, color: colors.textSecondary, marginBottom: spacing.sm },
  proposalValues: { flexDirection: 'row', justifyContent: 'space-between', marginBottom: spacing.sm },
  proposalTotal: { fontSize: fontSize.md, fontWeight: '700', color: colors.success },
  proposalDiscount: { fontSize: fontSize.xs, color: colors.warning },
  proposalItems: { borderTopWidth: 1, borderTopColor: colors.borderLight, paddingTop: spacing.sm },
  proposalItem: { flexDirection: 'row', justifyContent: 'space-between', paddingVertical: 2 },
  itemName: { fontSize: fontSize.xs, color: colors.textSecondary, flex: 1 },
  itemValue: { fontSize: fontSize.xs, color: colors.text, fontWeight: '500' },
  actionsContainer: { flexDirection: 'row', gap: spacing.md, marginTop: spacing.md },
  actionBtn: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: spacing.sm,
    height: 48,
    borderRadius: borderRadius.md,
  },
  approveBtn: { backgroundColor: colors.success },
  rejectBtn: { backgroundColor: colors.danger },
  actionBtnText: { color: '#fff', fontSize: fontSize.md, fontWeight: '600' },
});
