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
import { router } from 'expo-router';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { orderServicesApi } from '../src/api/orderServices';
import { vehiclesApi } from '../src/api/vehicles';
import { colors, spacing, borderRadius, fontSize, shadows } from '../src/theme/colors';
import { Ionicons } from '@expo/vector-icons';
import Toast from 'react-native-toast-message';
import { Vehicle, ProviderServiceType } from '../src/types';

export default function CreateOSScreen() {
  const queryClient = useQueryClient();
  const [vehicleId, setVehicleId] = useState<number | null>(null);
  const [serviceTypeId, setServiceTypeId] = useState<number | null>(null);
  const [details, setDetails] = useState('');
  const [km, setKm] = useState('');
  const [driver, setDriver] = useState('');
  const [showVehiclePicker, setShowVehiclePicker] = useState(false);
  const [vehicleSearch, setVehicleSearch] = useState('');

  const { data: vehiclesData } = useQuery({
    queryKey: ['vehicles-picker', vehicleSearch],
    queryFn: () => vehiclesApi.list({ search: vehicleSearch || undefined, per_page: 50, active: true }),
  });

  const { data: serviceTypesData } = useQuery({
    queryKey: ['service-types'],
    queryFn: orderServicesApi.getServiceTypes,
  });

  const selectedVehicle = vehiclesData?.vehicles?.find((v) => v.id === vehicleId);
  const serviceTypes = serviceTypesData?.service_types ?? [];

  const createMutation = useMutation({
    mutationFn: orderServicesApi.create,
    onSuccess: (res) => {
      Toast.show({ type: 'success', text1: 'OS criada!', text2: res.order_service.code });
      queryClient.invalidateQueries({ queryKey: ['orderServices'] });
      queryClient.invalidateQueries({ queryKey: ['dashboard'] });
      router.back();
    },
    onError: (err: any) => {
      Toast.show({
        type: 'error',
        text1: 'Erro ao criar OS',
        text2: err?.response?.data?.error || 'Tente novamente',
      });
    },
  });

  const handleSubmit = () => {
    if (!vehicleId) {
      Toast.show({ type: 'error', text1: 'Selecione um veículo' });
      return;
    }
    if (!serviceTypeId) {
      Toast.show({ type: 'error', text1: 'Selecione o tipo de serviço' });
      return;
    }
    if (!details.trim()) {
      Toast.show({ type: 'error', text1: 'Descreva o serviço necessário' });
      return;
    }

    createMutation.mutate({
      vehicle_id: vehicleId,
      provider_service_type_id: serviceTypeId,
      details: details.trim(),
      km: km ? parseInt(km, 10) : undefined,
      driver: driver.trim() || undefined,
    });
  };

  return (
    <ScrollView style={styles.container} contentContainerStyle={styles.content}>
      <View style={styles.header}>
        <TouchableOpacity onPress={() => router.back()} style={styles.backBtn}>
          <Ionicons name="arrow-back" size={24} color={colors.primary} />
        </TouchableOpacity>
        <Text style={styles.headerTitle}>Nova Ordem de Serviço</Text>
      </View>

      {/* Veículo */}
      <Text style={styles.label}>Veículo *</Text>
      <TouchableOpacity
        style={styles.picker}
        onPress={() => setShowVehiclePicker(!showVehiclePicker)}
      >
        <Ionicons name="car-outline" size={18} color={colors.textSecondary} />
        <Text style={[styles.pickerText, !selectedVehicle && { color: colors.placeholder }]}>
          {selectedVehicle
            ? `${selectedVehicle.board} - ${selectedVehicle.brand} ${selectedVehicle.model}`
            : 'Selecione o veículo'}
        </Text>
        <Ionicons name={showVehiclePicker ? 'chevron-up' : 'chevron-down'} size={18} color={colors.textLight} />
      </TouchableOpacity>

      {showVehiclePicker && (
        <View style={styles.pickerList}>
          <TextInput
            style={styles.pickerSearch}
            placeholder="Buscar por placa..."
            value={vehicleSearch}
            onChangeText={setVehicleSearch}
            placeholderTextColor={colors.placeholder}
          />
          {vehiclesData?.vehicles?.map((v) => (
            <TouchableOpacity
              key={v.id}
              style={[styles.pickerItem, v.id === vehicleId && styles.pickerItemSelected]}
              onPress={() => {
                setVehicleId(v.id);
                setShowVehiclePicker(false);
              }}
            >
              <Text style={styles.pickerItemPlate}>{v.board}</Text>
              <Text style={styles.pickerItemModel}>
                {v.brand} {v.model}
              </Text>
            </TouchableOpacity>
          ))}
        </View>
      )}

      {/* Tipo de Serviço */}
      <Text style={styles.label}>Tipo de Serviço *</Text>
      <View style={styles.chipContainer}>
        {serviceTypes.map((st: ProviderServiceType) => (
          <TouchableOpacity
            key={st.id}
            style={[styles.chip, st.id === serviceTypeId && styles.chipSelected]}
            onPress={() => setServiceTypeId(st.id)}
          >
            <Text style={[styles.chipText, st.id === serviceTypeId && styles.chipTextSelected]}>
              {st.name}
            </Text>
          </TouchableOpacity>
        ))}
      </View>

      {/* KM */}
      <Text style={styles.label}>Quilometragem Atual</Text>
      <View style={styles.inputContainer}>
        <Ionicons name="speedometer-outline" size={18} color={colors.textSecondary} />
        <TextInput
          style={styles.input}
          placeholder="Ex: 45000"
          value={km}
          onChangeText={setKm}
          keyboardType="numeric"
          placeholderTextColor={colors.placeholder}
        />
        <Text style={styles.inputSuffix}>km</Text>
      </View>

      {/* Motorista */}
      <Text style={styles.label}>Motorista</Text>
      <View style={styles.inputContainer}>
        <Ionicons name="person-outline" size={18} color={colors.textSecondary} />
        <TextInput
          style={styles.input}
          placeholder="Nome do motorista"
          value={driver}
          onChangeText={setDriver}
          placeholderTextColor={colors.placeholder}
        />
      </View>

      {/* Detalhes */}
      <Text style={styles.label}>Descrição do Serviço *</Text>
      <TextInput
        style={styles.textArea}
        placeholder="Descreva o serviço necessário, defeitos observados, etc..."
        value={details}
        onChangeText={setDetails}
        multiline
        numberOfLines={5}
        textAlignVertical="top"
        placeholderTextColor={colors.placeholder}
      />

      {/* Botão */}
      <TouchableOpacity
        style={[styles.submitBtn, createMutation.isPending && { opacity: 0.7 }]}
        onPress={handleSubmit}
        disabled={createMutation.isPending}
      >
        {createMutation.isPending ? (
          <ActivityIndicator color="#fff" />
        ) : (
          <>
            <Ionicons name="checkmark-circle" size={20} color="#fff" />
            <Text style={styles.submitBtnText}>Criar OS</Text>
          </>
        )}
      </TouchableOpacity>
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
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.surface,
    borderRadius: borderRadius.md,
    padding: spacing.md,
    gap: spacing.sm,
    ...shadows.sm,
  },
  pickerText: { flex: 1, fontSize: fontSize.sm, color: colors.text },
  pickerList: {
    backgroundColor: colors.surface,
    borderRadius: borderRadius.md,
    marginTop: spacing.xs,
    maxHeight: 250,
    ...shadows.md,
  },
  pickerSearch: {
    borderBottomWidth: 1,
    borderBottomColor: colors.borderLight,
    padding: spacing.sm,
    fontSize: fontSize.sm,
    color: colors.text,
  },
  pickerItem: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: spacing.sm,
    borderBottomWidth: 1,
    borderBottomColor: colors.borderLight,
    gap: spacing.sm,
  },
  pickerItemSelected: { backgroundColor: colors.primary + '10' },
  pickerItemPlate: { fontSize: fontSize.sm, fontWeight: '700', color: colors.primary },
  pickerItemModel: { fontSize: fontSize.sm, color: colors.textSecondary },
  chipContainer: { flexDirection: 'row', flexWrap: 'wrap', gap: spacing.sm },
  chip: {
    paddingHorizontal: spacing.md,
    paddingVertical: spacing.sm,
    borderRadius: borderRadius.full,
    backgroundColor: colors.surfaceVariant,
    borderWidth: 1,
    borderColor: colors.border,
  },
  chipSelected: { backgroundColor: colors.primary, borderColor: colors.primary },
  chipText: { fontSize: fontSize.sm, color: colors.textSecondary },
  chipTextSelected: { color: '#fff', fontWeight: '600' },
  inputContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.surface,
    borderRadius: borderRadius.md,
    paddingHorizontal: spacing.md,
    height: 48,
    gap: spacing.sm,
    ...shadows.sm,
  },
  input: { flex: 1, fontSize: fontSize.sm, color: colors.text },
  inputSuffix: { fontSize: fontSize.sm, color: colors.textLight },
  textArea: {
    backgroundColor: colors.surface,
    borderRadius: borderRadius.md,
    padding: spacing.md,
    fontSize: fontSize.sm,
    color: colors.text,
    minHeight: 120,
    ...shadows.sm,
  },
  submitBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: spacing.sm,
    backgroundColor: colors.primary,
    borderRadius: borderRadius.md,
    height: 52,
    marginTop: spacing.xl,
  },
  submitBtnText: { color: '#fff', fontSize: fontSize.lg, fontWeight: '700' },
});
