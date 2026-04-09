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
import { router } from 'expo-router';
import { useQuery } from '@tanstack/react-query';
import { balancesApi } from '../src/api/balances';
import { colors, spacing, borderRadius, fontSize, shadows } from '../src/theme/colors';
import { Ionicons } from '@expo/vector-icons';
import { Balance } from '../src/types';

export default function BalancesScreen() {
  const { data, isLoading, refetch, isRefetching } = useQuery({
    queryKey: ['balances'],
    queryFn: () => balancesApi.getBalances(),
  });

  const { data: contractsData } = useQuery({
    queryKey: ['contracts'],
    queryFn: () => balancesApi.getContracts(),
  });

  const balances: Balance[] = data?.balances ?? [];
  const totalBudget = balances.reduce((acc, b) => acc + (b.total_budget ?? 0), 0);
  const totalUsed = balances.reduce((acc, b) => acc + (b.total_used ?? 0), 0);
  const totalAvailable = totalBudget - totalUsed;
  const usagePercent = totalBudget > 0 ? (totalUsed / totalBudget) * 100 : 0;

  const formatCurrency = (v: number) =>
    v.toLocaleString('pt-BR', { style: 'currency', currency: 'BRL' });

  return (
    <ScrollView
      style={styles.container}
      contentContainerStyle={styles.content}
      refreshControl={<RefreshControl refreshing={isRefetching} onRefresh={refetch} />}
    >
      {isLoading ? (
        <ActivityIndicator size="large" color={colors.primary} style={{ marginTop: spacing.xxl }} />
      ) : (
        <>
          {/* Summary Card */}
          <View style={styles.summaryCard}>
            <Text style={styles.summaryTitle}>Resumo Geral</Text>
            <View style={styles.summaryRow}>
              <View style={styles.summaryItem}>
                <Text style={styles.summaryLabel}>Orçamento</Text>
                <Text style={styles.summaryValue}>{formatCurrency(totalBudget)}</Text>
              </View>
              <View style={styles.summaryItem}>
                <Text style={styles.summaryLabel}>Utilizado</Text>
                <Text style={[styles.summaryValue, { color: colors.danger }]}>{formatCurrency(totalUsed)}</Text>
              </View>
              <View style={styles.summaryItem}>
                <Text style={styles.summaryLabel}>Disponível</Text>
                <Text style={[styles.summaryValue, { color: colors.success }]}>{formatCurrency(totalAvailable)}</Text>
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
                      backgroundColor: usagePercent > 80 ? colors.danger : usagePercent > 60 ? colors.warning : colors.success,
                    },
                  ]}
                />
              </View>
              <Text style={styles.progressText}>{usagePercent.toFixed(1)}% utilizado</Text>
            </View>
          </View>

          {/* Contracts */}
          {contractsData?.contracts && contractsData.contracts.length > 0 && (
            <View style={styles.section}>
              <Text style={styles.sectionTitle}>Contratos</Text>
              {contractsData.contracts.map((c: any) => (
                <View key={c.id} style={styles.contractCard}>
                  <View style={styles.contractHeader}>
                    <Ionicons name="document-text-outline" size={18} color={colors.primary} />
                    <Text style={styles.contractName}>{c.name || `Contrato #${c.id}`}</Text>
                  </View>
                  {c.value && (
                    <Text style={styles.contractValue}>{formatCurrency(c.value)}</Text>
                  )}
                </View>
              ))}
            </View>
          )}

          {/* Cost Centers */}
          <View style={styles.section}>
            <Text style={styles.sectionTitle}>Centros de Custo</Text>
            {balances.length === 0 ? (
              <Text style={styles.emptyText}>Nenhum centro de custo encontrado</Text>
            ) : (
              balances.map((b) => <BalanceCard key={b.id} balance={b} formatCurrency={formatCurrency} />)
            )}
          </View>
        </>
      )}
    </ScrollView>
  );
}

function BalanceCard({ balance, formatCurrency }: { balance: Balance; formatCurrency: (v: number) => string }) {
  const [expanded, setExpanded] = React.useState(false);
  const budget = balance.total_budget ?? 0;
  const used = balance.total_used ?? 0;
  const available = budget - used;
  const pct = budget > 0 ? (used / budget) * 100 : 0;

  return (
    <View style={styles.balanceCard}>
      <TouchableOpacity style={styles.balanceHeader} onPress={() => setExpanded(!expanded)}>
        <View style={{ flex: 1 }}>
          <Text style={styles.balanceName}>{balance.name}</Text>
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
            <Text style={styles.detailLabel}>Orçamento</Text>
            <Text style={styles.detailValue}>{formatCurrency(budget)}</Text>
          </View>
          <View style={styles.detailRow}>
            <Text style={styles.detailLabel}>Utilizado</Text>
            <Text style={[styles.detailValue, { color: colors.danger }]}>{formatCurrency(used)}</Text>
          </View>
          <View style={styles.detailRow}>
            <Text style={styles.detailLabel}>Disponível</Text>
            <Text style={[styles.detailValue, { color: colors.success }]}>{formatCurrency(available)}</Text>
          </View>

          {balance.commitments && balance.commitments.length > 0 && (
            <>
              <Text style={styles.commitmentsTitle}>Compromissos</Text>
              {balance.commitments.map((c, i) => (
                <View key={i} style={styles.commitmentRow}>
                  <Text style={styles.commitmentDesc}>{c.description}</Text>
                  <Text style={styles.commitmentValue}>{formatCurrency(c.value)}</Text>
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
  header: { flexDirection: 'row', alignItems: 'center', marginBottom: spacing.lg },
  backBtn: { marginRight: spacing.sm },
  headerTitle: { fontSize: fontSize.xl, fontWeight: '700', color: colors.text },

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
  emptyText: { fontSize: fontSize.sm, color: colors.textLight, textAlign: 'center', padding: spacing.lg },

  contractCard: { backgroundColor: colors.surface, borderRadius: borderRadius.md, padding: spacing.md, marginBottom: spacing.xs, ...shadows.sm },
  contractHeader: { flexDirection: 'row', alignItems: 'center', gap: spacing.xs },
  contractName: { fontSize: fontSize.md, fontWeight: '600', color: colors.text },
  contractValue: { fontSize: fontSize.sm, color: colors.primary, fontWeight: '600', marginTop: 4, marginLeft: 26 },

  balanceCard: { backgroundColor: colors.surface, borderRadius: borderRadius.md, marginBottom: spacing.sm, ...shadows.sm, overflow: 'hidden' },
  balanceHeader: { flexDirection: 'row', alignItems: 'center', padding: spacing.md },
  balanceName: { fontSize: fontSize.md, fontWeight: '600', color: colors.text },
  balanceAvailable: { fontSize: fontSize.sm, color: colors.textSecondary, marginTop: 2 },
  balancePctCircle: { width: 44, height: 44, borderRadius: 22, borderWidth: 2, borderColor: colors.border, alignItems: 'center', justifyContent: 'center', marginRight: spacing.xs },
  balancePctText: { fontSize: fontSize.xs, fontWeight: '700' },
  balanceDetails: { padding: spacing.md, paddingTop: 0, borderTopWidth: 1, borderTopColor: colors.border },
  detailRow: { flexDirection: 'row', justifyContent: 'space-between', paddingVertical: 4 },
  detailLabel: { fontSize: fontSize.sm, color: colors.textSecondary },
  detailValue: { fontSize: fontSize.sm, fontWeight: '600', color: colors.text },
  commitmentsTitle: { fontSize: fontSize.sm, fontWeight: '600', color: colors.text, marginTop: spacing.sm, marginBottom: spacing.xs },
  commitmentRow: { flexDirection: 'row', justifyContent: 'space-between', paddingVertical: 3 },
  commitmentDesc: { fontSize: fontSize.xs, color: colors.textSecondary, flex: 1 },
  commitmentValue: { fontSize: fontSize.xs, fontWeight: '600', color: colors.text },
});
