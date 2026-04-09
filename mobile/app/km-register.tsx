import React, { useState } from 'react';
import {
  View,
  Text,
  ScrollView,
  StyleSheet,
  TouchableOpacity,
  TextInput,
  ActivityIndicator,
} from 'react-native';
import { router, useLocalSearchParams } from 'expo-router';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { kmApi } from '../src/api/km';
import { vehiclesApi } from '../src/api/vehicles';
import { colors, spacing, borderRadius, fontSize, shadows } from '../src/theme/colors';
import { Ionicons } from '@expo/vector-icons';
import Toast from 'react-native-toast-message';

export default function KmRegisterScreen() {
  const params = useLocalSearchParams<{ vehicle_id?: string; vehicle_board?: string }>();
  const queryClient = useQueryClient();

  const [selectedVehicleId, setSelectedVehicleId] = useState<number | null>(
    params.vehicle_id ? Number(params.vehicle_id) : null
  );
  const [km, setKm] = useState('');
  const [observation, setObservation] = useState('');
  const [showPicker, setShowPicker] = useState(false);
  const [search, setSearch] = useState('');

  const { data: vehiclesData } = useQuery({
    queryKey: ['vehicles-km', search],
    queryFn: () => vehiclesApi.list({ search: search || undefined, per_page: 50, active: true }),
  });

  const { data: kmData } = useQuery({
    queryKey: ['km-history', selectedVehicleId],
    queryFn: () => kmApi.history({ vehicle_id: selectedVehicleId!, per_page: 5 }),
    enabled: !!selectedVehicleId,
  });

  const selectedVehicle = vehiclesData?.vehicles?.find((v) => v.id === selectedVehicleId);

  const registerMutation = useMutation({
    mutationFn: kmApi.register,
    onSuccess: (res) => {
      Toast.show({ type: 'success', text1: 'KM registrado!', text2: `${res.km_record.km.toLocaleString()} km` });
      queryClient.invalidateQueries({ queryKey: ['km-history'] });
      queryClient.invalidateQueries({ queryKey: ['vehicle-detail'] });
      queryClient.invalidateQueries({ queryKey: ['dashboard'] });
      setKm('');
      setObservation('');
    },
    onError: (err: any) => {
      Toast.show({
        type: 'error',
        text1: 'Erro ao registrar KM',
        text2: err?.response?.data?.error || 'Verifique os dados',
      });
    },
  });

  const handleSubmit = () => {
    if (!selectedVehicleId) {
      Toast.show({ type: 'error', text1: 'Selecione um veículo' });
      return;
    }
    if (!km || parseInt(km, 10) <= 0) {
      Toast.show({ type: 'error', text1: 'Informe um KM válido' });
      return;
    }

    registerMutation.mutate({
      vehicle_id: selectedVehicleId,
      km: parseInt(km, 10),
      origin: params.vehicle_id ? 'vehicle_page' : 'manual',
      observation: observation.trim() || undefined,
    });
  };

  return (
    <ScrollView style={styles.container} contentContainerStyle={styles.content}>


      {/* Veículo */}
      <Text style={styles.label}>Veículo *</Text>
      <TouchableOpacity style={styles.picker} onPress={() => setShowPicker(!showPicker)}>
        <Ionicons name="car-outline" size={18} color={colors.textSecondary} />
        <Text style={[styles.pickerText, !selectedVehicle && { color: colors.placeholder }]}>
          {selectedVehicle ? `${selectedVehicle.board} - ${selectedVehicle.brand} ${selectedVehicle.model}` : 'Selecione'}
        </Text>
        <Ionicons name={showPicker ? 'chevron-up' : 'chevron-down'} size={18} color={colors.textLight} />
      </TouchableOpacity>

      {showPicker && (
        <View style={styles.pickerList}>
          <TextInput
            style={styles.pickerSearch}
            placeholder="Buscar..."
            value={search}
            onChangeText={setSearch}
            placeholderTextColor={colors.placeholder}
          />
          {vehiclesData?.vehicles?.map((v) => (
            <TouchableOpacity
              key={v.id}
              style={[styles.pickerItem, v.id === selectedVehicleId && styles.pickerItemSelected]}
              onPress={() => { setSelectedVehicleId(v.id); setShowPicker(false); }}
            >
              <Text style={styles.pickerItemPlate}>{v.board}</Text>
              <Text style={styles.pickerItemModel}>{v.brand} {v.model}</Text>
            </TouchableOpacity>
          ))}
        </View>
      )}

      {/* KM Atual */}
      {kmData?.current_km && (
        <View style={styles.currentKmCard}>
          <Ionicons name="speedometer" size={24} color={colors.primary} />
          <View>
            <Text style={styles.currentKmLabel}>KM Atual</Text>
            <Text style={styles.currentKmValue}>{kmData.current_km.toLocaleString()} km</Text>
          </View>
        </View>
      )}

      {/* Novo KM */}
      <Text style={styles.label}>Novo KM *</Text>
      <View style={styles.inputContainer}>
        <Ionicons name="speedometer-outline" size={18} color={colors.textSecondary} />
        <TextInput
          style={styles.input}
          placeholder={kmData?.current_km ? `Mínimo: ${kmData.current_km.toLocaleString()}` : 'Ex: 45000'}
          value={km}
          onChangeText={setKm}
          keyboardType="numeric"
          placeholderTextColor={colors.placeholder}
        />
        <Text style={styles.inputSuffix}>km</Text>
      </View>

      {/* Observação */}
      <Text style={styles.label}>Observação (opcional)</Text>
      <TextInput
        style={styles.textArea}
        placeholder="Ex: Abastecimento no posto..."
        value={observation}
        onChangeText={setObservation}
        multiline
        numberOfLines={3}
        textAlignVertical="top"
        placeholderTextColor={colors.placeholder}
      />

      {/* Botão */}
      <TouchableOpacity
        style={[styles.submitBtn, registerMutation.isPending && { opacity: 0.7 }]}
        onPress={handleSubmit}
        disabled={registerMutation.isPending}
      >
        {registerMutation.isPending ? (
          <ActivityIndicator color="#fff" />
        ) : (
          <>
            <Ionicons name="checkmark-circle" size={20} color="#fff" />
            <Text style={styles.submitBtnText}>Registrar KM</Text>
          </>
        )}
      </TouchableOpacity>

      {/* Histórico recente */}
      {kmData?.km_records && kmData.km_records.length > 0 && (
        <View style={styles.historySection}>
          <Text style={styles.sectionTitle}>Últimos Registros</Text>
          {kmData.km_records.map((record) => (
            <View key={record.id} style={styles.historyRow}>
              <View style={styles.historyDot} />
              <View style={styles.historyInfo}>
                <Text style={styles.historyKm}>{record.km.toLocaleString()} km</Text>
                <Text style={styles.historyMeta}>
                  {record.user_name} • {record.origin} •{' '}
                  {new Date(record.created_at).toLocaleDateString('pt-BR')}
                </Text>
              </View>
            </View>
          ))}
        </View>
      )}
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: colors.background },
  content: { padding: spacing.md, paddingBottom: spacing.xxl },
  header: { flexDirection: 'row', alignItems: 'center', marginBottom: spacing.lg },
  backBtn: { marginRight: spacing.sm },
  headerTitle: { fontSize: fontSize.xl, fontWeight: '700', color: colors.text },
  label: { fontSize: fontSize.sm, fontWeight: '600', color: colors.text, marginBottom: spacing.xs, marginTop: spacing.md },
  picker: {
    flexDirection: 'row', alignItems: 'center', backgroundColor: colors.surface,
    borderRadius: borderRadius.md, padding: spacing.md, gap: spacing.sm, ...shadows.sm,
  },
  pickerText: { flex: 1, fontSize: fontSize.sm, color: colors.text },
  pickerList: { backgroundColor: colors.surface, borderRadius: borderRadius.md, marginTop: spacing.xs, maxHeight: 200, ...shadows.md },
  pickerSearch: { borderBottomWidth: 1, borderBottomColor: colors.borderLight, padding: spacing.sm, fontSize: fontSize.sm, color: colors.text },
  pickerItem: { flexDirection: 'row', padding: spacing.sm, borderBottomWidth: 1, borderBottomColor: colors.borderLight, gap: spacing.sm },
  pickerItemSelected: { backgroundColor: colors.primary + '10' },
  pickerItemPlate: { fontSize: fontSize.sm, fontWeight: '700', color: colors.primary },
  pickerItemModel: { fontSize: fontSize.sm, color: colors.textSecondary },
  currentKmCard: {
    flexDirection: 'row', alignItems: 'center', gap: spacing.md, backgroundColor: colors.primary + '10',
    borderRadius: borderRadius.md, padding: spacing.md, marginTop: spacing.md,
  },
  currentKmLabel: { fontSize: fontSize.xs, color: colors.textSecondary },
  currentKmValue: { fontSize: fontSize.lg, fontWeight: '700', color: colors.primary },
  inputContainer: {
    flexDirection: 'row', alignItems: 'center', backgroundColor: colors.surface,
    borderRadius: borderRadius.md, paddingHorizontal: spacing.md, height: 48, gap: spacing.sm, ...shadows.sm,
  },
  input: { flex: 1, fontSize: fontSize.sm, color: colors.text },
  inputSuffix: { fontSize: fontSize.sm, color: colors.textLight },
  textArea: {
    backgroundColor: colors.surface, borderRadius: borderRadius.md, padding: spacing.md,
    fontSize: fontSize.sm, color: colors.text, minHeight: 80, ...shadows.sm,
  },
  submitBtn: {
    flexDirection: 'row', alignItems: 'center', justifyContent: 'center', gap: spacing.sm,
    backgroundColor: colors.primary, borderRadius: borderRadius.md, height: 52, marginTop: spacing.xl,
  },
  submitBtnText: { color: '#fff', fontSize: fontSize.lg, fontWeight: '700' },
  historySection: { marginTop: spacing.xl },
  sectionTitle: { fontSize: fontSize.md, fontWeight: '600', color: colors.text, marginBottom: spacing.sm },
  historyRow: { flexDirection: 'row', alignItems: 'flex-start', marginBottom: spacing.sm },
  historyDot: { width: 8, height: 8, borderRadius: 4, backgroundColor: colors.primary, marginTop: 5, marginRight: spacing.sm },
  historyInfo: { flex: 1 },
  historyKm: { fontSize: fontSize.sm, fontWeight: '600', color: colors.text },
  historyMeta: { fontSize: fontSize.xs, color: colors.textLight },
});
