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
import { anomaliesApi } from '../src/api/anomalies';
import { vehiclesApi } from '../src/api/vehicles';
import { colors, spacing, borderRadius, fontSize, shadows } from '../src/theme/colors';
import { Ionicons } from '@expo/vector-icons';
import * as ImagePicker from 'expo-image-picker';

const SEVERITIES = [
  { value: 'low', label: 'Baixa', color: colors.info },
  { value: 'medium', label: 'Média', color: colors.warning },
  { value: 'high', label: 'Alta', color: colors.danger },
  { value: 'critical', label: 'Crítica', color: '#B71C1C' },
];

const CATEGORIES = [
  { value: 'mecanica', label: 'Mecânica' },
  { value: 'eletrica', label: 'Elétrica' },
  { value: 'pneus', label: 'Pneus' },
  { value: 'funilaria', label: 'Funilaria' },
  { value: 'vidros', label: 'Vidros' },
  { value: 'acessorios', label: 'Acessórios' },
  { value: 'outro', label: 'Outro' },
];

export default function ReportAnomalyScreen() {
  const queryClient = useQueryClient();
  const [vehicleId, setVehicleId] = useState<number | null>(null);
  const [vehicleSearch, setVehicleSearch] = useState('');
  const [showVehiclePicker, setShowVehiclePicker] = useState(false);
  const [title, setTitle] = useState('');
  const [description, setDescription] = useState('');
  const [severity, setSeverity] = useState('medium');
  const [category, setCategory] = useState('mecanica');
  const [photos, setPhotos] = useState<string[]>([]);

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
    mutationFn: anomaliesApi.create,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['anomalies'] });
      Alert.alert('Sucesso', 'Anomalia registrada com sucesso.', [
        { text: 'OK', onPress: () => router.back() },
      ]);
    },
    onError: () => Alert.alert('Erro', 'Não foi possível registrar a anomalia.'),
  });

  const pickImage = async () => {
    const result = await ImagePicker.launchImageLibraryAsync({
      mediaTypes: ['images'],
      quality: 0.7,
      allowsMultipleSelection: true,
    });
    if (!result.canceled) {
      setPhotos((prev) => [...prev, ...result.assets.map((a) => a.uri)].slice(0, 5));
    }
  };

  const handleSubmit = () => {
    if (!vehicleId) return Alert.alert('Atenção', 'Selecione um veículo.');
    if (!title.trim()) return Alert.alert('Atenção', 'Informe o título.');
    if (!description.trim()) return Alert.alert('Atenção', 'Descreva a anomalia.');

    mutation.mutate({ vehicle_id: vehicleId, title, description, severity, category, photos });
  };

  return (
    <ScrollView style={styles.container} contentContainerStyle={styles.content}>

      {/* Vehicle Picker */}
      <Text style={styles.label}>Veículo *</Text>
      <TouchableOpacity
        style={styles.pickerBtn}
        onPress={() => setShowVehiclePicker(true)}
      >
        <Text style={selectedVehicle ? styles.pickerText : styles.pickerPlaceholder}>
          {selectedVehicle ? `${selectedVehicle.board} - ${selectedVehicle.model}` : 'Selecione o veículo'}
        </Text>
        <Ionicons name="chevron-down" size={20} color={colors.textLight} />
      </TouchableOpacity>

      <Modal visible={showVehiclePicker} transparent animationType="slide">
        <KeyboardAvoidingView
          style={{ flex: 1 }}
          behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
        >
          <View style={styles.modalOverlay}>
            <View style={styles.modalContainer}>
            <View style={styles.modalHeader}>
              <Text style={styles.modalTitle}>Selecionar Veículo</Text>
              <TouchableOpacity onPress={() => setShowVehiclePicker(false)}>
                <Ionicons name="close" size={24} color={colors.text} />
              </TouchableOpacity>
            </View>
            <TextInput
              style={styles.searchInput}
              placeholder="Buscar placa ou modelo..."
              value={vehicleSearch}
              onChangeText={setVehicleSearch}
              placeholderTextColor={colors.placeholder}
              autoFocus
            />
            <FlatList
              data={filteredVehicles.slice(0, 100)}
              keyExtractor={(v) => v.id.toString()}
              renderItem={({ item: v }) => (
                <TouchableOpacity
                  style={[styles.pickerOption, v.id === vehicleId && styles.pickerOptionActive]}
                  onPress={() => { setVehicleId(v.id); setShowVehiclePicker(false); setVehicleSearch(''); }}
                >
                  <Text style={styles.pickerOptionText}>{v.board} - {v.model}</Text>
                </TouchableOpacity>
              )}
              ListEmptyComponent={<Text style={styles.pickerEmpty}>Nenhum veículo encontrado</Text>}
              keyboardShouldPersistTaps="handled"
            />
          </View>
        </View>
        </KeyboardAvoidingView>
      </Modal>

      {/* Title */}
      <Text style={styles.label}>Título *</Text>
      <TextInput
        style={styles.input}
        placeholder="Ex: Barulho no motor"
        value={title}
        onChangeText={setTitle}
      />

      {/* Severity */}
      <Text style={styles.label}>Severidade</Text>
      <View style={styles.chipRow}>
        {SEVERITIES.map((s) => (
          <TouchableOpacity
            key={s.value}
            style={[styles.chip, severity === s.value && { backgroundColor: s.color + '20', borderColor: s.color }]}
            onPress={() => setSeverity(s.value)}
          >
            <Text style={[styles.chipText, severity === s.value && { color: s.color }]}>{s.label}</Text>
          </TouchableOpacity>
        ))}
      </View>

      {/* Category */}
      <Text style={styles.label}>Categoria</Text>
      <View style={styles.chipRow}>
        {CATEGORIES.map((c) => (
          <TouchableOpacity
            key={c.value}
            style={[styles.chip, category === c.value && styles.chipActive]}
            onPress={() => setCategory(c.value)}
          >
            <Text style={[styles.chipText, category === c.value && styles.chipTextActive]}>{c.label}</Text>
          </TouchableOpacity>
        ))}
      </View>

      {/* Description */}
      <Text style={styles.label}>Descrição *</Text>
      <TextInput
        style={[styles.input, styles.textArea]}
        placeholder="Descreva a anomalia em detalhes..."
        value={description}
        onChangeText={setDescription}
        multiline
        numberOfLines={4}
      />

      {/* Photos */}
      <Text style={styles.label}>Fotos (máx. 5)</Text>
      <View style={styles.photosRow}>
        {photos.map((uri, i) => (
          <View key={i} style={styles.photoBox}>
            <Image source={{ uri }} style={styles.photoImg} />
            <TouchableOpacity
              style={styles.photoRemove}
              onPress={() => setPhotos((prev) => prev.filter((_, idx) => idx !== i))}
            >
              <Ionicons name="close-circle" size={20} color={colors.danger} />
            </TouchableOpacity>
          </View>
        ))}
        {photos.length < 5 && (
          <TouchableOpacity style={styles.addPhotoBtn} onPress={pickImage}>
            <Ionicons name="camera-outline" size={28} color={colors.textLight} />
          </TouchableOpacity>
        )}
      </View>

      {/* Submit */}
      <TouchableOpacity
        style={[styles.submitBtn, mutation.isPending && styles.submitBtnDisabled]}
        onPress={handleSubmit}
        disabled={mutation.isPending}
      >
        {mutation.isPending ? (
          <ActivityIndicator color="#FFF" />
        ) : (
          <Text style={styles.submitBtnText}>Registrar Anomalia</Text>
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
  input: { backgroundColor: colors.surface, borderRadius: borderRadius.md, padding: spacing.md, fontSize: fontSize.md, color: colors.text, borderWidth: 1, borderColor: colors.border },
  textArea: { minHeight: 100, textAlignVertical: 'top' },
  pickerBtn: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', backgroundColor: colors.surface, borderRadius: borderRadius.md, padding: spacing.md, borderWidth: 1, borderColor: colors.border },
  pickerText: { fontSize: fontSize.md, color: colors.text },
  pickerPlaceholder: { fontSize: fontSize.md, color: colors.textLight },
  modalOverlay: { flex: 1, backgroundColor: 'rgba(0,0,0,0.5)', justifyContent: 'flex-end' },
  modalContainer: { backgroundColor: colors.surface, borderTopLeftRadius: borderRadius.lg, borderTopRightRadius: borderRadius.lg, maxHeight: '70%', padding: spacing.md },
  modalHeader: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginBottom: spacing.sm },
  modalTitle: { fontSize: fontSize.lg, fontWeight: '700', color: colors.text },
  searchInput: { backgroundColor: colors.background, borderRadius: borderRadius.md, padding: spacing.sm, fontSize: fontSize.sm, color: colors.text, marginBottom: spacing.sm },
  pickerEmpty: { textAlign: 'center', color: colors.textLight, padding: spacing.lg },
  pickerOption: { padding: spacing.sm, borderBottomWidth: 0.5, borderBottomColor: colors.border },
  pickerOptionActive: { backgroundColor: colors.primary + '10' },
  pickerOptionText: { fontSize: fontSize.sm, color: colors.text },
  chipRow: { flexDirection: 'row', flexWrap: 'wrap', gap: spacing.xs },
  chip: { paddingHorizontal: spacing.md, paddingVertical: spacing.xs, borderRadius: borderRadius.full, borderWidth: 1, borderColor: colors.border, backgroundColor: colors.surface },
  chipActive: { backgroundColor: colors.primary + '15', borderColor: colors.primary },
  chipText: { fontSize: fontSize.sm, color: colors.textSecondary },
  chipTextActive: { color: colors.primary, fontWeight: '600' },
  photosRow: { flexDirection: 'row', flexWrap: 'wrap', gap: spacing.sm },
  photoBox: { width: 80, height: 80, borderRadius: borderRadius.sm, overflow: 'hidden' },
  photoImg: { width: '100%', height: '100%' },
  photoRemove: { position: 'absolute', top: -4, right: -4 },
  addPhotoBtn: { width: 80, height: 80, borderRadius: borderRadius.sm, borderWidth: 1, borderStyle: 'dashed', borderColor: colors.textLight, alignItems: 'center', justifyContent: 'center' },
  submitBtn: { backgroundColor: colors.primary, borderRadius: borderRadius.md, padding: spacing.md, alignItems: 'center', marginTop: spacing.xl },
  submitBtnDisabled: { opacity: 0.6 },
  submitBtnText: { color: '#FFF', fontSize: fontSize.md, fontWeight: '700' },
});
