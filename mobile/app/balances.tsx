import React from 'react';
import {
  View,
  Text,
  ScrollView,
  StyleSheet,
  TouchableOpacity,
  RefreshControl,
  ActivityIndicator,
} from 'react-native';
import { useQuery } from '@tanstack/react-query';
import { balancesApi } from '../src/api/balances';
import { colors, spacing, borderRadius, fontSize, shadows } from '../src/theme/colors';
import { Ionicons } from '@expo/vector-icons';
import { Balance, Commitment } from '../src/types';
import ClientSelector from '../src/components/ClientSelector';
import { useClientFilter } from '../src/contexts/ClientContext';

export default function BalancesScreen() {
  const { selectedClientId } = useClientFilter();

  const { data, isLoading, refetch, isRefetching } = useQuery({
    queryKey: ['balances', selectedClientId],
    queryFn: () =>
      balancesApi.getBalances(selectedClientId ? { client_id: selectedClientId } : undefined),
  });

  const { data: contractsData } = useQuery({
    queryKey: ['contracts', selectedClientId],
    queryFn: () =>
      balancesApi.getContracts(selectedClientId ? { client_id: selectedClientId } : undefined),
  });

  const balances: Balance[] = data?.balances ?? [];
  const summary = data?.summary;
  const totalBudget = summary?.total_budget ?? 0;
  const totalCommitted = summary?.total_committed ?? 0;
  const totalConsumed = summary?.total_consumed ?? 0;
  const totalAvailable = summary?.total_available ?? 0;
  const usagePercent = totalCommitted > 0 ? (totalConsumed / totalCommitted) * 100 : 0;

  const formatCurrency = (v: number) =>
    v.toLocaleString('pt-BR', { style: 'currency', currency: 'BRL' });

  return (
    <ScrollView
      style={styles.container}
      contentContainerStyle={styles.content}
      refreshControl={<RefreshControl refreshing={isRefetching} onRefresh={refetch} />}
    >
      <ClientSelector />

      {isLoading ? (
        <ActivityIndicator size="large" color={colors.primary} style={{ marginTop: spacing.xxl }} />
      ) : (
        <>
          {/* Summary Card */}
          <View style={[styles.summaryCard, { marginTop: spacing.md }]}>
            <Text style={styles.summaryTitle}>Resumo Geral</Text>
            <View style={styles.summaryRow}>
              <View style={styles.summaryItem}>
                <Text style={styles.summaryLabel}>Empenhado</Text>
                <Text style={styles.summaryValue}>{formatCurrency(totalCommitted)}</Text>
              </View>
              <View style={styles.summaryItem}>
                <Text style={styles.summaryLabel}>Consumido</Text>
                <Text style={[styles.summaryValue, { color: '#FF6B6B' }]}>{formatCurrency(totalConsumed)}</Text>
              </View>
              <View style={styles.summaryItem}>
                <Text style={styles.summaryLabel}>Disponível</Text>
                <Text style={[styles.summaryValue, { color: '#51CF66' }]}>{formatCurrency(totalAvailable)}</Text>
              </View>
            </View>

            {/* Progress bar */}
            <View style={styles.progressContainer}>
              <View style={styles.progressBar}>
                <View
                  style={[
                    styles.progressFill,
                    {
                      width: `${Math.min(usagePercent, 100)}%`,
                      backgroundColor: usagePercent > 80 ? '#FF6B6B' : usagePercent > 60 ? colors.warning : '#51CF66',
                    },
                  ]}
                />
              </View>
              <Text style={styles.progressText}>{usagePercent.toFixed(1)}% consumido</Text>
            </View>
          </View>

          {/* Contracts */}
          {contractsData?.contracts && contractsData.contracts.length > 0 && (
            <View style={styles.section}>
              <Text style={styles.sectionTitle}>Contratos</Text>
              {contractsData.contracts.map((c: any) => {
                const totalValue = c.total_value ?? 0;
                const usedValue = c.used_value ?? 0;
                const availableValue = c.available_value ?? (totalValue - usedValue);
                const pct = totalValue > 0 ? (usedValue / totalValue) * 100 : 0;
                return (
                  <View key={c.id} style={styles.contractCard}>
                    <View style={styles.contractHeader}>
                      <Ionicons name="document-text-outline" size={18} color={colors.primary} />
                      <Text style={styles.contractName} numberOfLines={1}>
                        {c.name || c.number || `Contrato #${c.id}`}
                      </Text>
                      {c.active !== undefined && (
                        <View style={[styles.contractBadge, { backgroundColor: c.active ? '#E8F5E9' : '#FFEBEE' }]}>
                          <Text style={{ fontSize: fontSize.xs, color: c.active ? colors.success : colors.danger }}>
                            {c.active ? 'Ativo' : 'Inativo'}
                          </Text>
                        </View>
                      )}
                    </View>
                    <View style={styles.contractDetails}>
                      <View style={styles.detailRow}>
                        <Text style={styles.detailLabel}>Valor total</Text>
                        <Text style={styles.detailValue}>{formatCurrency(totalValue)}</Text>
                      </View>
                      <View style={styles.detailRow}>
                        <Text style={styles.detailLabel}>Empenhado</Text>
                        <Text style={[styles.detailValue, { color: colors.danger }]}>{formatCurrency(usedValue)}</Text>
                      </View>
                      <View style={styles.detailRow}>
                        <Text style={styles.detailLabel}>Disponível</Text>
                        <Text style={[styles.detailValue, { color: colors.success }]}>{formatCurrency(availableValue)}</Text>
                      </View>
                      <View style={styles.progressBar}>
                        <View style={[styles.progressFill, { width: `${Math.min(pct, 100)}%`, backgroundColor: pct > 80 ? colors.danger : colors.primary }]} />
                      </View>
                      {c.commitments_count != null && (
                        <Text style={styles.contractMeta}>{c.commitments_count} empenho{c.commitments_count !== 1 ? 's' : ''}</Text>
                      )}
                    </View>
                  </View>
                );
              })}
            </View>
          )}

          {/* Cost Centers */}
          <View style={styles.section}>
            <Text style={styles.sectionTitle}>
              Centros de Custo ({balances.length})
            </Text>
            {balances.length === 0 ? (
              <View style={styles.emptyContainer}>
                <Ionicons name="wallet-outline" size={40} color={colors.textLight} />
                <Text style={styles.emptyText}>Nenhum centro de custo encontrado</Text>
              </View>
            ) : (
              balances.map((b) => (
                <BalanceCard
                  key={b.cost_center.id}
                  balance={b}
                  formatCurrency={formatCurrency}
                />
              ))
            )}
          </View>
        </>
      )}
    </ScrollView>
  );
}

function BalanceCard({ balance, formatCurrency }: { balance: Balance; formatCurrency: (v: number) => string }) {
  const [expanded, setExpanded] = React.useState(false);
  const committed = balance.total_committed ?? 0;
  const consumed = balance.total_consumed ?? 0;
  const available = balance.available ?? 0;
  const pct = committed > 0 ? (consumed / committed) * 100 : 0;

  return (
    <View style={styles.balanceCard}>
      <TouchableOpacity style={styles.balanceHeader} onPress={() => setExpanded(!expanded)}>
        <View style={{ flex: 1 }}>
          <Text style={styles.balanceName}>{balance.cost_center.name}</Text>
          <Text style={styles.balanceAvailable}>
            Disponível: <Text style={{ color: colors.success, fontWeight: '700' }}>{formatCurrency(available)}</Text>
          </Text>
        </View>
        <View style={styles.balancePctCircle}>
          <Text style={[styles.balancePctText, { color: pct > 80 ? colors.danger : colors.primary }]}>
            {pct.toFixed(0)}%
          </Text>
        </View>
        <Ionicons name={expanded ? 'chevron-up' : 'chevron-down'} size={20} color={colors.textLight} />
      </TouchableOpacity>

      {expanded && (
        <View style={styles.balanceDetails}>
          <View style={styles.detailRow}>
            <Text style={styles.detailLabel}>Empenhado</Text>
            <Text style={styles.detailValue}>{formatCurrency(committed)}</Text>
          </View>
          <View style={styles.detailRow}>
            <Text style={styles.detailLabel}>Cancelado</Text>
            <Text style={[styles.detailValue, { color: colors.textLight }]}>{formatCurrency(balance.total_cancelled ?? 0)}</Text>
          </View>
          <View style={styles.detailRow}>
            <Text style={styles.detailLabel}>Consumido</Text>
            <Text style={[styles.detailValue, { color: colors.danger }]}>{formatCurrency(consumed)}</Text>
          </View>
          <View style={styles.detailRow}>
            <Text style={styles.detailLabel}>Disponível</Text>
            <Text style={[styles.detailValue, { color: colors.success }]}>{formatCurrency(available)}</Text>
          </View>

          {balance.commitments && balance.commitments.length > 0 && (
            <>
              <Text style={styles.commitmentsTitle}>Empenhos</Text>
              {balance.commitments.map((c: Commitment) => (
                <View key={c.id} style={styles.commitmentRow}>
                  <View style={{ flex: 1 }}>
                    <Text style={styles.commitmentDesc}>
                      {c.number || `Empenho #${c.id}`}
                    </Text>
                    {(c as any).category?.name && (
                      <Text style={styles.commitmentContract}>{(c as any).category.name}</Text>
                    )}
                    {c.contract && (
                      <Text style={styles.commitmentContract}>
                        {c.contract.name || c.contract.number}
                      </Text>
                    )}
                  </View>
                  <View style={{ alignItems: 'flex-end' }}>
                    <Text style={styles.commitmentValue}>{formatCurrency(c.value ?? 0)}</Text>
                    {(c as any).consumed != null && (
                      <Text style={[styles.commitmentContract, { color: colors.danger }]}>
                        -{formatCurrency((c as any).consumed)}
                      </Text>
                    )}
                    {(c as any).available != null && (
                      <Text style={[styles.commitmentContract, { color: colors.success, fontWeight: '700' }]}>
                        {formatCurrency((c as any).available)}
                      </Text>
                    )}
                    {(c.cancelled ?? 0) > 0 && (
                      <Text style={styles.commitmentCancelled}>Cancelado: {formatCurrency(c.cancelled)}</Text>
                    )}
                  </View>
                </View>
              ))}
            </>
          )}
        </View>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: colors.background },
  content: { padding: spacing.md, paddingBottom: spacing.xxl },

  summaryCard: { backgroundColor: colors.primary, borderRadius: borderRadius.lg, padding: spacing.lg, marginBottom: spacing.lg },
  summaryTitle: { fontSize: fontSize.md, fontWeight: '600', color: '#FFF', marginBottom: spacing.md },
  summaryRow: { flexDirection: 'row', justifyContent: 'space-between' },
  summaryItem: { alignItems: 'center', flex: 1 },
  summaryLabel: { fontSize: fontSize.xs, color: 'rgba(255,255,255,0.7)', marginBottom: 2 },
  summaryValue: { fontSize: fontSize.md, fontWeight: '700', color: '#FFF' },
  progressContainer: { marginTop: spacing.md },
  progressBar: { height: 6, borderRadius: 3, backgroundColor: 'rgba(255,255,255,0.2)' },
  progressFill: { height: '100%', borderRadius: 3 },
  progressText: { fontSize: fontSize.xs, color: 'rgba(255,255,255,0.7)', marginTop: 4, textAlign: 'right' },

  section: { marginBottom: spacing.lg },
  sectionTitle: { fontSize: fontSize.lg, fontWeight: '600', color: colors.text, marginBottom: spacing.sm },
  emptyContainer: { alignItems: 'center', padding: spacing.xl },
  emptyText: { fontSize: fontSize.sm, color: colors.textLight, textAlign: 'center', marginTop: spacing.sm },

  contractCard: { backgroundColor: colors.surface, borderRadius: borderRadius.md, padding: spacing.md, marginBottom: spacing.xs, ...shadows.sm },
  contractHeader: { flexDirection: 'row', alignItems: 'center', gap: spacing.xs },
  contractName: { fontSize: fontSize.md, fontWeight: '600', color: colors.text, flex: 1 },
  contractBadge: { paddingHorizontal: 8, paddingVertical: 2, borderRadius: borderRadius.sm },
  contractDetails: { marginTop: spacing.xs, marginLeft: 26 },
  contractValue: { fontSize: fontSize.sm, color: colors.primary, fontWeight: '600' },
  contractMeta: { fontSize: fontSize.xs, color: colors.textLight, marginTop: 2 },

  balanceCard: { backgroundColor: colors.surface, borderRadius: borderRadius.md, marginBottom: spacing.sm, ...shadows.sm, overflow: 'hidden' },
  balanceHeader: { flexDirection: 'row', alignItems: 'center', padding: spacing.md },
  balanceName: { fontSize: fontSize.md, fontWeight: '600', color: colors.text },
  balanceAvailable: { fontSize: fontSize.sm, color: colors.textSecondary, marginTop: 2 },
  balancePctCircle: { width: 44, height: 44, borderRadius: 22, borderWidth: 2, borderColor: colors.border, alignItems: 'center', justifyContent: 'center', marginRight: spacing.xs },
  balancePctText: { fontSize: fontSize.xs, fontWeight: '700' },
  balanceDetails: { padding: spacing.md, paddingTop: spacing.sm, borderTopWidth: 1, borderTopColor: colors.border },
  detailRow: { flexDirection: 'row', justifyContent: 'space-between', paddingVertical: 4 },
  detailLabel: { fontSize: fontSize.sm, color: colors.textSecondary },
  detailValue: { fontSize: fontSize.sm, fontWeight: '600', color: colors.text },
  commitmentsTitle: { fontSize: fontSize.sm, fontWeight: '600', color: colors.text, marginTop: spacing.sm, marginBottom: spacing.xs },
  commitmentRow: { flexDirection: 'row', justifyContent: 'space-between', paddingVertical: 4, borderBottomWidth: 1, borderBottomColor: colors.borderLight },
  commitmentDesc: { fontSize: fontSize.sm, color: colors.text, fontWeight: '500' },
  commitmentContract: { fontSize: fontSize.xs, color: colors.textLight, marginTop: 1 },
  commitmentValue: { fontSize: fontSize.sm, fontWeight: '600', color: colors.primary },
  commitmentCancelled: { fontSize: fontSize.xs, color: colors.danger, marginTop: 1 },
});
