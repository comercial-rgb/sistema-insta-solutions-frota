import React, { useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  TouchableOpacity,
  TextInput,
  ScrollView,
  ActivityIndicator,
  Alert,
  Image,
  Modal,
  FlatList,
  KeyboardAvoidingView,
  Platform,
} from 'react-native';
import { router } from 'expo-router';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { checklistsApi } from '../src/api/checklists';
import { vehiclesApi } from '../src/api/vehicles';
import { colors, spacing, borderRadius, fontSize, shadows } from '../src/theme/colors';
import { Ionicons } from '@expo/vector-icons';
import * as ImagePicker from 'expo-image-picker';
import { ChecklistCategory, ChecklistCondition, VehicleChecklistItem } from '../src/types';

const CATEGORIES: { value: ChecklistCategory; label: string }[] = [
  { value: 'motor', label: 'Motor' },
  { value: 'freios', label: 'Freios' },
  { value: 'pneus', label: 'Pneus' },
  { value: 'eletrica', label: 'Elétrica' },
  { value: 'carroceria', label: 'Carroceria' },
  { value: 'interior', label: 'Interior' },
  { value: 'luzes', label: 'Luzes' },
  { value: 'fluidos', label: 'Fluídos' },
  { value: 'documentacao', label: 'Documentação' },
  { value: 'outros', label: 'Outros' },
];

const CONDITIONS: { value: ChecklistCondition; label: string; color: string; icon: string }[] = [
  { value: 'ok', label: 'OK', color: colors.success, icon: 'checkmark-circle' },
  { value: 'attention', label: 'Atenção', color: colors.warning, icon: 'alert-circle' },
  { value: 'critical', label: 'Crítico', color: colors.danger, icon: 'close-circle' },
  { value: 'na', label: 'N/A', color: colors.textLight, icon: 'remove-circle' },
];

interface ChecklistItemState {
  category: ChecklistCategory;
  item_name: string;
  condition: ChecklistCondition;
  observation: string;
  has_anomaly: boolean;
}

const DEFAULT_ITEMS: ChecklistItemState[] = [
  { category: 'motor', item_name: 'Nível de óleo', condition: 'ok', observation: '', has_anomaly: false },
  { category: 'motor', item_name: 'Correia do motor', condition: 'ok', observation: '', has_anomaly: false },
  { category: 'motor', item_name: 'Ruídos anormais', condition: 'ok', observation: '', has_anomaly: false },
  { category: 'freios', item_name: 'Pastilhas de freio', condition: 'ok', observation: '', has_anomaly: false },
  { category: 'freios', item_name: 'Discos de freio', condition: 'ok', observation: '', has_anomaly: false },
  { category: 'freios', item_name: 'Freio de mão', condition: 'ok', observation: '', has_anomaly: false },
  { category: 'pneus', item_name: 'Pneu dianteiro esquerdo', condition: 'ok', observation: '', has_anomaly: false },
  { category: 'pneus', item_name: 'Pneu dianteiro direito', condition: 'ok', observation: '', has_anomaly: false },
  { category: 'pneus', item_name: 'Pneu traseiro esquerdo', condition: 'ok', observation: '', has_anomaly: false },
  { category: 'pneus', item_name: 'Pneu traseiro direito', condition: 'ok', observation: '', has_anomaly: false },
  { category: 'pneus', item_name: 'Estepe', condition: 'ok', observation: '', has_anomaly: false },
  { category: 'eletrica', item_name: 'Bateria', condition: 'ok', observation: '', has_anomaly: false },
  { category: 'eletrica', item_name: 'Alternador', condition: 'ok', observation: '', has_anomaly: false },
  { category: 'carroceria', item_name: 'Pintura externa', condition: 'ok', observation: '', has_anomaly: false },
  { category: 'carroceria', item_name: 'Amassados/riscos', condition: 'ok', observation: '', has_anomaly: false },
  { category: 'carroceria', item_name: 'Para-choques', condition: 'ok', observation: '', has_anomaly: false },
  { category: 'interior', item_name: 'Bancos', condition: 'ok', observation: '', has_anomaly: false },
  { category: 'interior', item_name: 'Painel', condition: 'ok', observation: '', has_anomaly: false },
  { category: 'interior', item_name: 'Ar condicionado', condition: 'ok', observation: '', has_anomaly: false },
  { category: 'luzes', item_name: 'Faróis', condition: 'ok', observation: '', has_anomaly: false },
  { category: 'luzes', item_name: 'Lanternas traseiras', condition: 'ok', observation: '', has_anomaly: false },
  { category: 'luzes', item_name: 'Luz de freio', condition: 'ok', observation: '', has_anomaly: false },
  { category: 'luzes', item_name: 'Setas', condition: 'ok', observation: '', has_anomaly: false },
  { category: 'fluidos', item_name: 'Água do radiador', condition: 'ok', observation: '', has_anomaly: false },
  { category: 'fluidos', item_name: 'Fluido de freio', condition: 'ok', observation: '', has_anomaly: false },
  { category: 'fluidos', item_name: 'Limpador para-brisa', condition: 'ok', observation: '', has_anomaly: false },
  { category: 'documentacao', item_name: 'CRLV em dia', condition: 'ok', observation: '', has_anomaly: false },
  { category: 'documentacao', item_name: 'Triângulo / Macaco', condition: 'ok', observation: '', has_anomaly: false },
];

export default function VehicleChecklistScreen() {
  const queryClient = useQueryClient();
  const [vehicleId, setVehicleId] = useState<number | null>(null);
  const [vehicleSearch, setVehicleSearch] = useState('');
  const [showVehiclePicker, setShowVehiclePicker] = useState(false);
  const [currentKm, setCurrentKm] = useState('');
  const [generalNotes, setGeneralNotes] = useState('');
  const [photos, setPhotos] = useState<string[]>([]);
  const [items, setItems] = useState<ChecklistItemState[]>(DEFAULT_ITEMS.map((i) => ({ ...i })));
  const [activeCategory, setActiveCategory] = useState<ChecklistCategory>('motor');
  const [expandedItem, setExpandedItem] = useState<number | null>(null);

  const { data: vehiclesData } = useQuery({
    queryKey: ['vehicles-all'],
    queryFn: () => vehiclesApi.list({ page: 1, per_page: 100 }),
  });

  const vehicles = vehiclesData?.vehicles ?? [];
  const selectedVehicle = vehicles.find((v) => v.id === vehicleId);
  const filteredVehicles = vehicles.filter(
    (v) =>
      v.board?.toLowerCase().includes(vehicleSearch.toLowerCase()) ||
      v.model?.toLowerCase().includes(vehicleSearch.toLowerCase())
  );

  const mutation = useMutation({
    mutationFn: checklistsApi.create,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['checklists'] });
      Alert.alert('Sucesso', 'Checklist registrado com sucesso!', [
        { text: 'OK', onPress: () => router.back() },
      ]);
    },
    onError: () => Alert.alert('Erro', 'Não foi possível registrar o checklist.'),
  });

  const pickImage = async () => {
    const result = await ImagePicker.launchImageLibraryAsync({
      mediaTypes: ['images'],
      quality: 0.7,
      allowsMultipleSelection: true,
      selectionLimit: 10 - photos.length,
    });
    if (!result.canceled) {
      setPhotos((prev) => [...prev, ...result.assets.map((a) => a.uri)].slice(0, 10));
    }
  };

  const takePhoto = async () => {
    const permission = await ImagePicker.requestCameraPermissionsAsync();
    if (!permission.granted) {
      Alert.alert('Permissão necessária', 'Precisamos de acesso à câmera.');
      return;
    }
    const result = await ImagePicker.launchCameraAsync({ quality: 0.7 });
    if (!result.canceled) {
      setPhotos((prev) => [...prev, result.assets[0].uri].slice(0, 10));
    }
  };

  const updateItem = (index: number, field: keyof ChecklistItemState, value: any) => {
    setItems((prev) => {
      const updated = [...prev];
      updated[index] = { ...updated[index], [field]: value };
      if (field === 'condition') {
        updated[index].has_anomaly = value === 'attention' || value === 'critical';
      }
      return updated;
    });
  };

  const categoryItems = items
    .map((item, idx) => ({ ...item, originalIndex: idx }))
    .filter((item) => item.category === activeCategory);

  const anomalyCount = items.filter((i) => i.has_anomaly).length;

  const handleSubmit = () => {
    if (!vehicleId) {
      Alert.alert('Atenção', 'Selecione um veículo.');
      return;
    }

    const formData = new FormData();
    formData.append('vehicle_id', String(vehicleId));
    if (currentKm) formData.append('current_km', currentKm);
    if (generalNotes) formData.append('general_notes', generalNotes);

    items.forEach((item, idx) => {
      formData.append(`items[${idx}][category]`, item.category);
      formData.append(`items[${idx}][item_name]`, item.item_name);
      formData.append(`items[${idx}][condition]`, item.condition);
      formData.append(`items[${idx}][has_anomaly]`, String(item.has_anomaly));
      if (item.observation) formData.append(`items[${idx}][observation]`, item.observation);
    });

    photos.forEach((uri, idx) => {
      formData.append('photos[]', {
        uri,
        name: `checklist_photo_${idx}.jpg`,
        type: 'image/jpeg',
      } as any);
    });

    mutation.mutate(formData);
  };

  return (
    <KeyboardAvoidingView style={{ flex: 1 }} behavior={Platform.OS === 'ios' ? 'padding' : undefined}>
      <ScrollView style={styles.container} contentContainerStyle={styles.content} keyboardShouldPersistTaps="handled">
        {/* Vehicle Picker */}
        <Text style={styles.label}>Veículo *</Text>
        <TouchableOpacity style={styles.pickerButton} onPress={() => setShowVehiclePicker(true)}>
          <Ionicons name="car-outline" size={20} color={colors.primary} />
          <Text style={[styles.pickerText, !selectedVehicle && { color: colors.textLight }]}>
            {selectedVehicle ? `${selectedVehicle.board} - ${selectedVehicle.model}` : 'Selecionar veículo'}
          </Text>
          <Ionicons name="chevron-down" size={18} color={colors.textLight} />
        </TouchableOpacity>

        {/* KM */}
        <Text style={styles.label}>KM Atual</Text>
        <TextInput
          style={styles.input}
          placeholder="Quilometragem atual"
          value={currentKm}
          onChangeText={setCurrentKm}
          keyboardType="numeric"
          placeholderTextColor={colors.textLight}
        />

        {/* Category Tabs */}
        <Text style={styles.sectionTitle}>Itens do Checklist</Text>
        {anomalyCount > 0 && (
          <View style={styles.anomalyBanner}>
            <Ionicons name="warning" size={18} color={colors.danger} />
            <Text style={styles.anomalyBannerText}>{anomalyCount} anomalia(s) detectada(s)</Text>
          </View>
        )}

        <ScrollView horizontal showsHorizontalScrollIndicator={false} style={{ flexGrow: 0 }} contentContainerStyle={styles.categoryTabs}>
          {CATEGORIES.map((cat) => {
            const catAnomalies = items.filter((i) => i.category === cat.value && i.has_anomaly).length;
            return (
              <TouchableOpacity
                key={cat.value}
                style={[styles.categoryTab, activeCategory === cat.value && styles.categoryTabActive]}
                onPress={() => setActiveCategory(cat.value)}
              >
                <Text style={[styles.categoryTabText, activeCategory === cat.value && styles.categoryTabTextActive]}>
                  {cat.label}
                </Text>
                {catAnomalies > 0 && (
                  <View style={styles.categoryBadge}>
                    <Text style={styles.categoryBadgeText}>{catAnomalies}</Text>
                  </View>
                )}
              </TouchableOpacity>
            );
          })}
        </ScrollView>

        {/* Checklist Items for Active Category */}
        {categoryItems.map((item) => (
          <View key={item.originalIndex} style={[styles.itemCard, item.has_anomaly && styles.itemCardAnomaly]}>
            <TouchableOpacity
              style={styles.itemHeader}
              onPress={() => setExpandedItem(expandedItem === item.originalIndex ? null : item.originalIndex)}
            >
              <Text style={styles.itemName}>{item.item_name}</Text>
              <View style={styles.itemConditionRow}>
                {CONDITIONS.map((cond) => (
                  <TouchableOpacity
                    key={cond.value}
                    style={[
                      styles.conditionChip,
                      item.condition === cond.value && { backgroundColor: cond.color + '20', borderColor: cond.color },
                    ]}
                    onPress={() => updateItem(item.originalIndex, 'condition', cond.value)}
                  >
                    <Ionicons
                      name={cond.icon as any}
                      size={16}
                      color={item.condition === cond.value ? cond.color : colors.textLight}
                    />
                    <Text
                      style={[
                        styles.conditionText,
                        item.condition === cond.value && { color: cond.color, fontWeight: '600' },
                      ]}
                    >
                      {cond.label}
                    </Text>
                  </TouchableOpacity>
                ))}
              </View>
            </TouchableOpacity>
            {expandedItem === item.originalIndex && (
              <View style={styles.itemExpanded}>
                <TextInput
                  style={styles.observationInput}
                  placeholder="Observação (opcional)"
                  value={item.observation}
                  onChangeText={(text) => updateItem(item.originalIndex, 'observation', text)}
                  multiline
                  placeholderTextColor={colors.textLight}
                />
              </View>
            )}
          </View>
        ))}

        {/* Photos */}
        <Text style={[styles.sectionTitle, { marginTop: spacing.lg }]}>Fotos ({photos.length}/10)</Text>
        <View style={styles.photoRow}>
          {photos.map((uri, idx) => (
            <View key={idx} style={styles.photoThumb}>
              <Image source={{ uri }} style={styles.photoImage} />
              <TouchableOpacity style={styles.photoRemove} onPress={() => setPhotos((p) => p.filter((_, i) => i !== idx))}>
                <Ionicons name="close-circle" size={20} color={colors.danger} />
              </TouchableOpacity>
            </View>
          ))}
          {photos.length < 10 && (
            <>
              <TouchableOpacity style={styles.addPhotoBtn} onPress={pickImage}>
                <Ionicons name="images-outline" size={24} color={colors.primary} />
                <Text style={styles.addPhotoText}>Galeria</Text>
              </TouchableOpacity>
              <TouchableOpacity style={styles.addPhotoBtn} onPress={takePhoto}>
                <Ionicons name="camera-outline" size={24} color={colors.primary} />
                <Text style={styles.addPhotoText}>Câmera</Text>
              </TouchableOpacity>
            </>
          )}
        </View>

        {/* General Notes */}
        <Text style={styles.label}>Notas Gerais</Text>
        <TextInput
          style={[styles.input, { height: 80, textAlignVertical: 'top' }]}
          placeholder="Observações gerais do checklist"
          value={generalNotes}
          onChangeText={setGeneralNotes}
          multiline
          placeholderTextColor={colors.textLight}
        />

        {/* Submit */}
        <TouchableOpacity
          style={[styles.submitButton, mutation.isPending && { opacity: 0.6 }]}
          onPress={handleSubmit}
          disabled={mutation.isPending}
        >
          {mutation.isPending ? (
            <ActivityIndicator color="#fff" />
          ) : (
            <>
              <Ionicons name="checkmark-done" size={20} color="#fff" />
              <Text style={styles.submitText}>Enviar Checklist</Text>
            </>
          )}
        </TouchableOpacity>
      </ScrollView>

      {/* Vehicle Picker Modal */}
      <Modal visible={showVehiclePicker} animationType="slide" transparent>
        <KeyboardAvoidingView style={{ flex: 1 }} behavior={Platform.OS === 'ios' ? 'padding' : undefined}>
          <View style={styles.modalOverlay}>
            <View style={styles.modalContainer}>
              <View style={styles.modalHeader}>
                <Text style={styles.modalTitle}>Selecionar Veículo</Text>
                <TouchableOpacity onPress={() => setShowVehiclePicker(false)}>
                  <Ionicons name="close" size={24} color={colors.text} />
                </TouchableOpacity>
              </View>
              <TextInput
                style={styles.modalSearch}
                placeholder="Buscar por placa ou modelo..."
                value={vehicleSearch}
                onChangeText={setVehicleSearch}
                placeholderTextColor={colors.textLight}
                autoFocus
              />
              <FlatList
                data={filteredVehicles}
                keyExtractor={(item) => String(item.id)}
                keyboardShouldPersistTaps="handled"
                renderItem={({ item }) => (
                  <TouchableOpacity
                    style={[styles.vehicleItem, vehicleId === item.id && styles.vehicleItemSelected]}
                    onPress={() => {
                      setVehicleId(item.id);
                      setShowVehiclePicker(false);
                      setVehicleSearch('');
                    }}
                  >
                    <Text style={styles.vehiclePlate}>{item.board}</Text>
                    <Text style={styles.vehicleModel}>{item.model} {item.brand}</Text>
                  </TouchableOpacity>
                )}
                ListEmptyComponent={<Text style={styles.emptyText}>Nenhum veículo encontrado</Text>}
              />
            </View>
          </View>
        </KeyboardAvoidingView>
      </Modal>
    </KeyboardAvoidingView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: colors.background },
  content: { padding: spacing.md, paddingBottom: spacing.xxl },
  label: { fontSize: fontSize.sm, fontWeight: '600', color: colors.text, marginBottom: spacing.xs, marginTop: spacing.md },
  sectionTitle: { fontSize: fontSize.lg, fontWeight: '700', color: colors.text, marginBottom: spacing.sm, marginTop: spacing.md },
  input: {
    backgroundColor: colors.surface,
    borderRadius: borderRadius.md,
    padding: spacing.md,
    fontSize: fontSize.md,
    color: colors.text,
    borderWidth: 1,
    borderColor: colors.border,
  },
  pickerButton: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.surface,
    borderRadius: borderRadius.md,
    padding: spacing.md,
    borderWidth: 1,
    borderColor: colors.border,
    gap: spacing.sm,
  },
  pickerText: { flex: 1, fontSize: fontSize.md, color: colors.text },
  anomalyBanner: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.danger + '15',
    borderRadius: borderRadius.sm,
    padding: spacing.sm,
    marginBottom: spacing.sm,
    gap: spacing.xs,
  },
  anomalyBannerText: { fontSize: fontSize.sm, color: colors.danger, fontWeight: '600' },
  categoryTabs: { paddingVertical: spacing.xs, gap: spacing.xs },
  categoryTab: {
    paddingHorizontal: spacing.md,
    paddingVertical: spacing.xs,
    borderRadius: borderRadius.full,
    backgroundColor: colors.surface,
    borderWidth: 1,
    borderColor: colors.border,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
  },
  categoryTabActive: { backgroundColor: colors.primary + '15', borderColor: colors.primary },
  categoryTabText: { fontSize: fontSize.xs, color: colors.textSecondary },
  categoryTabTextActive: { color: colors.primary, fontWeight: '600' },
  categoryBadge: {
    backgroundColor: colors.danger,
    borderRadius: 8,
    minWidth: 16,
    height: 16,
    justifyContent: 'center',
    alignItems: 'center',
    paddingHorizontal: 4,
  },
  categoryBadgeText: { fontSize: 10, color: '#fff', fontWeight: '700' },
  itemCard: {
    backgroundColor: colors.surface,
    borderRadius: borderRadius.md,
    marginTop: spacing.sm,
    borderWidth: 1,
    borderColor: colors.border,
    ...shadows.sm,
  },
  itemCardAnomaly: { borderColor: colors.danger, borderWidth: 1.5 },
  itemHeader: { padding: spacing.md },
  itemName: { fontSize: fontSize.md, fontWeight: '600', color: colors.text, marginBottom: spacing.sm },
  itemConditionRow: { flexDirection: 'row', gap: spacing.xs, flexWrap: 'wrap' },
  conditionChip: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: spacing.sm,
    paddingVertical: 4,
    borderRadius: borderRadius.full,
    borderWidth: 1,
    borderColor: colors.border,
    gap: 4,
  },
  conditionText: { fontSize: fontSize.xs, color: colors.textSecondary },
  itemExpanded: { paddingHorizontal: spacing.md, paddingBottom: spacing.md },
  observationInput: {
    backgroundColor: colors.background,
    borderRadius: borderRadius.sm,
    padding: spacing.sm,
    fontSize: fontSize.sm,
    color: colors.text,
    borderWidth: 1,
    borderColor: colors.border,
    minHeight: 60,
    textAlignVertical: 'top',
  },
  photoRow: { flexDirection: 'row', flexWrap: 'wrap', gap: spacing.sm },
  photoThumb: { width: 80, height: 80, borderRadius: borderRadius.sm, overflow: 'hidden' },
  photoImage: { width: '100%', height: '100%' },
  photoRemove: { position: 'absolute', top: -4, right: -4 },
  addPhotoBtn: {
    width: 80,
    height: 80,
    borderRadius: borderRadius.sm,
    borderWidth: 1,
    borderColor: colors.border,
    borderStyle: 'dashed',
    justifyContent: 'center',
    alignItems: 'center',
  },
  addPhotoText: { fontSize: 10, color: colors.primary, marginTop: 2 },
  submitButton: {
    flexDirection: 'row',
    backgroundColor: colors.primary,
    borderRadius: borderRadius.md,
    padding: spacing.md,
    justifyContent: 'center',
    alignItems: 'center',
    marginTop: spacing.xl,
    gap: spacing.sm,
  },
  submitText: { fontSize: fontSize.md, fontWeight: '700', color: '#fff' },
  // Modal
  modalOverlay: { flex: 1, backgroundColor: 'rgba(0,0,0,0.5)', justifyContent: 'flex-end' },
  modalContainer: {
    backgroundColor: colors.surface,
    borderTopLeftRadius: borderRadius.lg,
    borderTopRightRadius: borderRadius.lg,
    maxHeight: '70%',
    padding: spacing.md,
  },
  modalHeader: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginBottom: spacing.md },
  modalTitle: { fontSize: fontSize.lg, fontWeight: '700', color: colors.text },
  modalSearch: {
    backgroundColor: colors.background,
    borderRadius: borderRadius.md,
    padding: spacing.md,
    fontSize: fontSize.md,
    color: colors.text,
    borderWidth: 1,
    borderColor: colors.border,
    marginBottom: spacing.sm,
  },
  vehicleItem: {
    padding: spacing.md,
    borderBottomWidth: 1,
    borderBottomColor: colors.border,
  },
  vehicleItemSelected: { backgroundColor: colors.primary + '10' },
  vehiclePlate: { fontSize: fontSize.md, fontWeight: '700', color: colors.text },
  vehicleModel: { fontSize: fontSize.sm, color: colors.textSecondary },
  emptyText: { textAlign: 'center', padding: spacing.lg, color: colors.textLight },
});
