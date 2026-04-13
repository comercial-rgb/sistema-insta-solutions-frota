import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  ScrollView,
  StyleSheet,
  TouchableOpacity,
  TextInput,
  ActivityIndicator,
  Alert,
  Switch,
  Modal,
  FlatList,
} from 'react-native';
import { router, useLocalSearchParams } from 'expo-router';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { maintenancePlansApi } from '../../src/api/maintenancePlans';
import { colors, spacing, borderRadius, fontSize, shadows } from '../../src/theme/colors';
import { Ionicons } from '@expo/vector-icons';
import { MaintenancePlanItem } from '../../src/types';
import Toast from 'react-native-toast-message';

const PLAN_TYPE_LABELS: Record<string, string> = {
  km: 'Por KM',
  days: 'Por Dias',
  both: 'Ambos',
};

export default function MaintenancePlanDetailScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const isNew = id === 'new';
  const queryClient = useQueryClient();

  const [name, setName] = useState('');
  const [description, setDescription] = useState('');
  const [active, setActive] = useState(true);
  const [items, setItems] = useState<MaintenancePlanItem[]>([]);
  const [saving, setSaving] = useState(false);

  const { data, isLoading } = useQuery({
    queryKey: ['maintenance-plan', id],
    queryFn: () => maintenancePlansApi.show(Number(id)),
    enabled: !isNew && !!id,
  });

  const { data: availableData, refetch: refetchAvailable } = useQuery({
    queryKey: ['available-vehicles', id],
    queryFn: () => maintenancePlansApi.availableVehicles(Number(id)),
    enabled: !isNew && !!id,
  });

  // Service picker state
  const [servicePickerVisible, setServicePickerVisible] = useState(false);
  const [servicePickerItemId, setServicePickerItemId] = useState<number | null>(null);
  const [serviceSearch, setServiceSearch] = useState('');
  const [expandedItem, setExpandedItem] = useState<number | null>(null);

  const { data: servicesData } = useQuery({
    queryKey: ['available-services', serviceSearch],
    queryFn: () => maintenancePlansApi.availableServices({ search: serviceSearch || undefined }),
    enabled: servicePickerVisible,
  });

  const addServiceMutation = useMutation({
    mutationFn: (args: { itemId: number; serviceId: number }) =>
      maintenancePlansApi.addServiceToItem(Number(id), args.itemId, {
        service_id: args.serviceId,
        quantity: 1,
      }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['maintenance-plan', id] });
      Toast.show({ type: 'success', text1: 'Peça/serviço adicionado' });
    },
    onError: () => Toast.show({ type: 'error', text1: 'Erro ao adicionar peça/serviço' }),
  });

  const removeServiceMutation = useMutation({
    mutationFn: (args: { itemId: number; serviceId: number }) =>
      maintenancePlansApi.removeServiceFromItem(Number(id), args.itemId, args.serviceId),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['maintenance-plan', id] });
      Toast.show({ type: 'success', text1: 'Removido' });
    },
  });

  const openServicePicker = (itemId: number) => {
    setServicePickerItemId(itemId);
    setServiceSearch('');
    setServicePickerVisible(true);
  };

  const handleSelectService = (serviceId: number) => {
    if (servicePickerItemId) {
      addServiceMutation.mutate({ itemId: servicePickerItemId, serviceId });
    }
    setServicePickerVisible(false);
  };

  useEffect(() => {
    if (data?.plan) {
      setName(data.plan.name);
      setDescription(data.plan.description || '');
      setActive(data.plan.active);
      setItems(data.plan.items.map((i) => ({ ...i })));
    }
  }, [data]);

  const saveMutation = useMutation({
    mutationFn: async () => {
      if (isNew) {
        return maintenancePlansApi.create({
          name,
          description,
          active,
          items: items.filter((i) => !i._destroy),
        });
      } else {
        return maintenancePlansApi.update(Number(id), {
          name,
          description,
          active,
          items,
        });
      }
    },
    onSuccess: (res) => {
      queryClient.invalidateQueries({ queryKey: ['maintenance-plans'] });
      queryClient.invalidateQueries({ queryKey: ['maintenance-plan', id] });
      Toast.show({ type: 'success', text1: res.message });
      if (isNew) {
        router.replace(`/maintenance-plan-detail/${res.plan.id}` as any);
      }
    },
    onError: () => {
      Toast.show({ type: 'error', text1: 'Erro ao salvar plano' });
    },
  });

  const addVehicleMutation = useMutation({
    mutationFn: (vehicleId: number) => maintenancePlansApi.addVehicles(Number(id), [vehicleId]),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['maintenance-plan', id] });
      refetchAvailable();
      Toast.show({ type: 'success', text1: 'Veículo vinculado' });
    },
  });

  const removeVehicleMutation = useMutation({
    mutationFn: (vehicleId: number) => maintenancePlansApi.removeVehicle(Number(id), vehicleId),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['maintenance-plan', id] });
      refetchAvailable();
      Toast.show({ type: 'success', text1: 'Veículo removido' });
    },
  });

  const handleSave = () => {
    if (!name.trim()) {
      Alert.alert('Atenção', 'Informe o nome do plano');
      return;
    }
    saveMutation.mutate();
  };

  const addItem = () => {
    setItems([
      ...items,
      { name: '', plan_type: 'km', km_interval: null, days_interval: null, km_alert_threshold: null, days_alert_threshold: null, active: true },
    ]);
  };

  const updateItem = (index: number, field: string, value: any) => {
    const updated = [...items];
    (updated[index] as any)[field] = value;
    setItems(updated);
  };

  const removeItem = (index: number) => {
    const updated = [...items];
    if (updated[index].id) {
      updated[index]._destroy = true;
    } else {
      updated.splice(index, 1);
    }
    setItems(updated);
  };

  const handleRemoveVehicle = (vehicleId: number, board: string) => {
    Alert.alert('Remover Veículo', `Remover ${board} deste plano?`, [
      { text: 'Cancelar', style: 'cancel' },
      { text: 'Remover', style: 'destructive', onPress: () => removeVehicleMutation.mutate(vehicleId) },
    ]);
  };

  const cyclePlanType = (index: number) => {
    const types: Array<'km' | 'days' | 'both'> = ['km', 'days', 'both'];
    const current = items[index].plan_type;
    const next = types[(types.indexOf(current) + 1) % types.length];
    updateItem(index, 'plan_type', next);
  };

  if (!isNew && isLoading) {
    return (
      <View style={styles.loadingContainer}>
        <ActivityIndicator size="large" color={colors.primary} />
      </View>
    );
  }

  return (
    <ScrollView style={styles.container} contentContainerStyle={styles.content}>
      <View style={styles.section}>
        <Text style={styles.sectionTitle}>Informações do Plano</Text>
        <View style={styles.field}>
          <Text style={styles.label}>Nome *</Text>
          <TextInput
            style={styles.input}
            value={name}
            onChangeText={setName}
            placeholder="Ex: Revisão Preventiva"
            placeholderTextColor={colors.placeholder}
          />
        </View>
        <View style={styles.field}>
          <Text style={styles.label}>Descrição</Text>
          <TextInput
            style={[styles.input, styles.textArea]}
            value={description}
            onChangeText={setDescription}
            placeholder="Descrição do plano"
            placeholderTextColor={colors.placeholder}
            multiline
            numberOfLines={3}
          />
        </View>
        <View style={styles.switchRow}>
          <Text style={styles.label}>Ativo</Text>
          <Switch value={active} onValueChange={setActive} trackColor={{ true: colors.primary }} />
        </View>
      </View>

      <View style={styles.section}>
        <View style={styles.sectionHeader}>
          <Text style={styles.sectionTitle}>Serviços do Plano</Text>
          <TouchableOpacity style={styles.addItemBtn} onPress={addItem}>
            <Ionicons name="add-circle-outline" size={18} color={colors.primary} />
            <Text style={styles.addItemText}>Adicionar</Text>
          </TouchableOpacity>
        </View>

        {items.filter((i) => !i._destroy).length === 0 && (
          <Text style={styles.emptyItems}>Nenhum serviço adicionado</Text>
        )}

        {items.map((item, index) => {
          if (item._destroy) return null;
          const isExpanded = expandedItem === index;
          return (
            <View key={index} style={styles.itemCard}>
              <TouchableOpacity
                style={styles.itemCardHeader}
                onPress={() => setExpandedItem(isExpanded ? null : index)}
              >
                <View style={{ flex: 1 }}>
                  <Text style={styles.itemCardName} numberOfLines={1}>
                    {item.name || 'Novo serviço'}
                  </Text>
                  <Text style={styles.itemCardMeta}>
                    {item.plan_type === 'km' ? `A cada ${item.km_interval || '?'} km` :
                     item.plan_type === 'days' ? `A cada ${item.days_interval || '?'} dias` :
                     `${item.km_interval || '?'} km / ${item.days_interval || '?'} dias`}
                    {item.services_count ? ` · ${item.services_count} peças/serviços` : ''}
                  </Text>
                </View>
                <Ionicons name={isExpanded ? 'chevron-up' : 'chevron-down'} size={20} color={colors.textSecondary} />
              </TouchableOpacity>

              {isExpanded && (
                <View style={styles.itemCardBody}>
                  <View style={styles.itemHeader}>
                    <TextInput
                      style={[styles.input, { flex: 1 }]}
                      value={item.name}
                      onChangeText={(v) => updateItem(index, 'name', v)}
                      placeholder="Nome do serviço"
                      placeholderTextColor={colors.placeholder}
                    />
                    <TouchableOpacity onPress={() => removeItem(index)} style={styles.removeBtn}>
                      <Ionicons name="trash-outline" size={18} color={colors.danger} />
                    </TouchableOpacity>
                  </View>

                  <TouchableOpacity style={styles.typeBtn} onPress={() => cyclePlanType(index)}>
                    <Text style={styles.typeBtnText}>Tipo: {PLAN_TYPE_LABELS[item.plan_type]}</Text>
                    <Ionicons name="swap-horizontal-outline" size={14} color={colors.primary} />
                  </TouchableOpacity>

                  <View style={styles.itemRow}>
                    {(item.plan_type === 'km' || item.plan_type === 'both') && (
                      <View style={styles.itemField}>
                        <Text style={styles.itemLabel}>Intervalo KM</Text>
                        <TextInput
                          style={styles.itemInput}
                          value={item.km_interval?.toString() || ''}
                          onChangeText={(v) => updateItem(index, 'km_interval', v ? parseInt(v) : null)}
                          keyboardType="numeric"
                          placeholder="10000"
                          placeholderTextColor={colors.placeholder}
                        />
                      </View>
                    )}
                    {(item.plan_type === 'days' || item.plan_type === 'both') && (
                      <View style={styles.itemField}>
                        <Text style={styles.itemLabel}>Intervalo Dias</Text>
                        <TextInput
                          style={styles.itemInput}
                          value={item.days_interval?.toString() || ''}
                          onChangeText={(v) => updateItem(index, 'days_interval', v ? parseInt(v) : null)}
                          keyboardType="numeric"
                          placeholder="180"
                          placeholderTextColor={colors.placeholder}
                        />
                      </View>
                    )}
                  </View>

                  <View style={styles.itemRow}>
                    {(item.plan_type === 'km' || item.plan_type === 'both') && (
                      <View style={styles.itemField}>
                        <Text style={styles.itemLabel}>Alerta KM antes</Text>
                        <TextInput
                          style={styles.itemInput}
                          value={item.km_alert_threshold?.toString() || ''}
                          onChangeText={(v) => updateItem(index, 'km_alert_threshold', v ? parseInt(v) : null)}
                          keyboardType="numeric"
                          placeholder="1000"
                          placeholderTextColor={colors.placeholder}
                        />
                      </View>
                    )}
                    {(item.plan_type === 'days' || item.plan_type === 'both') && (
                      <View style={styles.itemField}>
                        <Text style={styles.itemLabel}>Alerta dias antes</Text>
                        <TextInput
                          style={styles.itemInput}
                          value={item.days_alert_threshold?.toString() || ''}
                          onChangeText={(v) => updateItem(index, 'days_alert_threshold', v ? parseInt(v) : null)}
                          keyboardType="numeric"
                          placeholder="15"
                          placeholderTextColor={colors.placeholder}
                        />
                      </View>
                    )}
                  </View>

                  {/* Pre-configured Peças e Serviços */}
                  {item.id ? (
                    <View style={styles.servicesSection}>
                      <View style={styles.servicesSectionHeader}>
                        <Text style={styles.servicesTitle}>Peças e Serviços</Text>
                        <TouchableOpacity
                          style={styles.addServiceBtn}
                          onPress={() => openServicePicker(item.id!)}
                        >
                          <Ionicons name="add" size={16} color={colors.primary} />
                          <Text style={styles.addServiceBtnText}>Incluir</Text>
                        </TouchableOpacity>
                      </View>

                      {item.services && item.services.length > 0 ? (
                        item.services.map((svc) => (
                          <View key={svc.id} style={styles.serviceRow}>
                            <View style={[
                              styles.serviceBadge,
                              { backgroundColor: svc.service_type === 'peca' ? colors.info + '20' : colors.warning + '20' }
                            ]}>
                              <Text style={[
                                styles.serviceBadgeText,
                                { color: svc.service_type === 'peca' ? colors.info : colors.warning }
                              ]}>
                                {svc.service_type === 'peca' ? 'Peça' : 'Serviço'}
                              </Text>
                            </View>
                            <View style={{ flex: 1 }}>
                              <Text style={styles.serviceName}>{svc.service_name}</Text>
                              <Text style={styles.serviceQty}>Qtd: {svc.quantity}</Text>
                            </View>
                            <TouchableOpacity
                              onPress={() =>
                                Alert.alert('Remover', `Remover "${svc.service_name}"?`, [
                                  { text: 'Cancelar', style: 'cancel' },
                                  {
                                    text: 'Remover',
                                    style: 'destructive',
                                    onPress: () =>
                                      removeServiceMutation.mutate({
                                        itemId: item.id!,
                                        serviceId: svc.service_id,
                                      }),
                                  },
                                ])
                              }
                            >
                              <Ionicons name="close-circle" size={20} color={colors.danger} />
                            </TouchableOpacity>
                          </View>
                        ))
                      ) : (
                        <Text style={styles.noServicesList}>Nenhuma peça/serviço adicionado</Text>
                      )}
                    </View>
                  ) : (
                    <Text style={styles.saveHint}>
                      Salve o plano para adicionar peças e serviços a este item.
                    </Text>
                  )}
                </View>
              )}
            </View>
          );
        })}
      </View>

      {!isNew && data?.plan && (
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Veículos Vinculados</Text>

          {data.plan.vehicles.length === 0 ? (
            <Text style={styles.emptyItems}>Nenhum veículo vinculado</Text>
          ) : (
            data.plan.vehicles.map((v) => (
              <View key={v.id} style={styles.vehicleRow}>
                <View style={styles.vehicleInfo}>
                  <Ionicons name="car-outline" size={16} color={colors.textSecondary} />
                  <Text style={styles.vehicleText}>{v.board} - {v.model}</Text>
                  {v.cost_center && <Text style={styles.vehicleCc}>{v.cost_center}</Text>}
                </View>
                <TouchableOpacity onPress={() => handleRemoveVehicle(v.id, v.board)}>
                  <Ionicons name="close-circle-outline" size={20} color={colors.danger} />
                </TouchableOpacity>
              </View>
            ))
          )}

          {availableData && availableData.vehicles.length > 0 && (
            <View style={styles.addVehicleSection}>
              <Text style={styles.addVehicleTitle}>Adicionar Veículo</Text>
              {availableData.vehicles.slice(0, 20).map((v) => (
                <TouchableOpacity
                  key={v.id}
                  style={styles.availableVehicle}
                  onPress={() => addVehicleMutation.mutate(v.id)}
                >
                  <Text style={styles.availableVehicleText}>{v.board} - {v.model}</Text>
                  <Ionicons name="add-circle-outline" size={20} color={colors.success} />
                </TouchableOpacity>
              ))}
              {availableData.vehicles.length > 20 && (
                <Text style={styles.moreText}>+ {availableData.vehicles.length - 20} veículos disponíveis</Text>
              )}
            </View>
          )}
        </View>
      )}

      <TouchableOpacity
        style={[styles.saveBtn, saveMutation.isPending && styles.saveBtnDisabled]}
        onPress={handleSave}
        disabled={saveMutation.isPending}
      >
        {saveMutation.isPending ? (
          <ActivityIndicator color={colors.surface} />
        ) : (
          <>
            <Ionicons name="checkmark-circle-outline" size={20} color={colors.surface} />
            <Text style={styles.saveBtnText}>{isNew ? 'Criar Plano' : 'Salvar Alterações'}</Text>
          </>
        )}
      </TouchableOpacity>

      <TouchableOpacity style={styles.backBtn} onPress={() => router.back()}>
        <Text style={styles.backBtnText}>Voltar</Text>
      </TouchableOpacity>

      {/* Service Picker Modal */}
      <Modal visible={servicePickerVisible} animationType="slide" transparent>
        <View style={styles.modalOverlay}>
          <View style={styles.modalContainer}>
            <View style={styles.modalHeader}>
              <Text style={styles.modalTitle}>Selecionar Peça/Serviço</Text>
              <TouchableOpacity onPress={() => setServicePickerVisible(false)}>
                <Ionicons name="close" size={24} color={colors.text} />
              </TouchableOpacity>
            </View>
            <TextInput
              style={styles.modalSearch}
              placeholder="Buscar..."
              value={serviceSearch}
              onChangeText={setServiceSearch}
              placeholderTextColor={colors.placeholder}
              autoFocus
            />
            <FlatList
              data={servicesData?.services ?? []}
              keyExtractor={(s) => s.id.toString()}
              renderItem={({ item: svc }) => (
                <TouchableOpacity
                  style={styles.modalItem}
                  onPress={() => handleSelectService(svc.id)}
                >
                  <View style={[
                    styles.serviceBadge,
                    { backgroundColor: svc.type === 'peca' ? colors.info + '20' : colors.warning + '20' }
                  ]}>
                    <Text style={[
                      styles.serviceBadgeText,
                      { color: svc.type === 'peca' ? colors.info : colors.warning }
                    ]}>
                      {svc.type === 'peca' ? 'Peça' : 'Serviço'}
                    </Text>
                  </View>
                  <Text style={styles.modalItemText}>{svc.name}</Text>
                </TouchableOpacity>
              )}
              ListEmptyComponent={<Text style={styles.noServicesList}>Nenhum resultado</Text>}
            />
          </View>
        </View>
      </Modal>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: colors.background },
  content: { padding: spacing.md, paddingBottom: spacing.xxl },
  loadingContainer: { flex: 1, justifyContent: 'center', alignItems: 'center' },
  section: {
    backgroundColor: colors.surface,
    borderRadius: borderRadius.md,
    padding: spacing.md,
    marginBottom: spacing.md,
    ...shadows.sm,
  },
  sectionHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: spacing.sm,
  },
  sectionTitle: {
    fontSize: fontSize.lg,
    fontWeight: '600',
    color: colors.text,
    marginBottom: spacing.sm,
  },
  field: { marginBottom: spacing.sm },
  label: {
    fontSize: fontSize.sm,
    fontWeight: '500',
    color: colors.textSecondary,
    marginBottom: 4,
  },
  input: {
    borderWidth: 1,
    borderColor: colors.borderLight,
    borderRadius: borderRadius.sm,
    padding: spacing.sm,
    fontSize: fontSize.md,
    color: colors.text,
    backgroundColor: colors.background,
  },
  textArea: { minHeight: 80, textAlignVertical: 'top' },
  switchRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginTop: spacing.xs,
  },
  addItemBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
  },
  addItemText: {
    fontSize: fontSize.sm,
    color: colors.primary,
    fontWeight: '500',
  },
  emptyItems: {
    fontSize: fontSize.sm,
    color: colors.textLight,
    textAlign: 'center',
    paddingVertical: spacing.md,
  },
  itemCard: {
    borderRadius: borderRadius.sm,
    marginBottom: spacing.sm,
    borderWidth: 1,
    borderColor: colors.primary + '40',
    overflow: 'hidden',
  },
  itemHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.sm,
    marginBottom: spacing.xs,
  },
  removeBtn: { padding: 4 },
  typeBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    backgroundColor: colors.primary + '10',
    paddingHorizontal: spacing.sm,
    paddingVertical: 4,
    borderRadius: borderRadius.sm,
    alignSelf: 'flex-start',
    marginBottom: spacing.xs,
  },
  typeBtnText: {
    fontSize: fontSize.xs,
    color: colors.primary,
    fontWeight: '500',
  },
  itemRow: {
    flexDirection: 'row',
    gap: spacing.sm,
    marginBottom: spacing.xs,
  },
  itemField: { flex: 1 },
  itemLabel: {
    fontSize: fontSize.xs,
    color: colors.textSecondary,
    marginBottom: 2,
  },
  itemInput: {
    borderWidth: 1,
    borderColor: colors.borderLight,
    borderRadius: borderRadius.sm,
    padding: spacing.xs,
    fontSize: fontSize.sm,
    color: colors.text,
    backgroundColor: colors.surface,
  },
  vehicleRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingVertical: spacing.xs,
    borderBottomWidth: 1,
    borderBottomColor: colors.borderLight,
  },
  vehicleInfo: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.xs,
    flex: 1,
  },
  vehicleText: {
    fontSize: fontSize.sm,
    color: colors.text,
    fontWeight: '500',
  },
  vehicleCc: {
    fontSize: fontSize.xs,
    color: colors.textLight,
    marginLeft: spacing.xs,
  },
  addVehicleSection: {
    marginTop: spacing.md,
    borderTopWidth: 1,
    borderTopColor: colors.borderLight,
    paddingTop: spacing.sm,
  },
  addVehicleTitle: {
    fontSize: fontSize.sm,
    fontWeight: '600',
    color: colors.textSecondary,
    marginBottom: spacing.xs,
  },
  availableVehicle: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingVertical: spacing.xs,
    borderBottomWidth: 1,
    borderBottomColor: colors.borderLight,
  },
  availableVehicleText: {
    fontSize: fontSize.sm,
    color: colors.text,
  },
  moreText: {
    fontSize: fontSize.xs,
    color: colors.textLight,
    textAlign: 'center',
    marginTop: spacing.xs,
  },
  saveBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: colors.primary,
    borderRadius: borderRadius.md,
    paddingVertical: spacing.md,
    gap: spacing.xs,
    marginBottom: spacing.sm,
  },
  saveBtnDisabled: { opacity: 0.6 },
  saveBtnText: {
    color: colors.surface,
    fontSize: fontSize.md,
    fontWeight: '600',
  },
  backBtn: {
    alignItems: 'center',
    paddingVertical: spacing.sm,
  },
  backBtnText: {
    color: colors.textSecondary,
    fontSize: fontSize.md,
  },
  itemCardHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: spacing.sm,
    backgroundColor: colors.primary + '08',
  },
  itemCardName: {
    fontSize: fontSize.md,
    fontWeight: '600',
    color: colors.text,
  },
  itemCardMeta: {
    fontSize: fontSize.xs,
    color: colors.textSecondary,
    marginTop: 2,
  },
  itemCardBody: {
    padding: spacing.sm,
    borderTopWidth: 1,
    borderTopColor: colors.borderLight,
  },
  servicesSection: {
    marginTop: spacing.sm,
    paddingTop: spacing.sm,
    borderTopWidth: 1,
    borderTopColor: colors.borderLight,
  },
  servicesSectionHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: spacing.xs,
  },
  servicesTitle: {
    fontSize: fontSize.sm,
    fontWeight: '600',
    color: colors.text,
  },
  addServiceBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 2,
  },
  addServiceBtnText: {
    color: colors.primary,
    fontSize: fontSize.xs,
    fontWeight: '600',
  },
  serviceRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.xs,
    paddingVertical: 6,
    borderBottomWidth: 1,
    borderBottomColor: colors.borderLight,
  },
  serviceBadge: {
    paddingHorizontal: 6,
    paddingVertical: 2,
    borderRadius: 4,
  },
  serviceBadgeText: {
    fontSize: 10,
    fontWeight: '600',
  },
  serviceName: {
    fontSize: fontSize.sm,
    color: colors.text,
  },
  serviceQty: {
    fontSize: fontSize.xs,
    color: colors.textSecondary,
  },
  noServicesList: {
    color: colors.textLight,
    fontSize: fontSize.xs,
    textAlign: 'center',
    paddingVertical: spacing.sm,
  },
  saveHint: {
    color: colors.textLight,
    fontSize: fontSize.xs,
    fontStyle: 'italic',
    marginTop: spacing.xs,
  },
  modalOverlay: {
    flex: 1,
    backgroundColor: 'rgba(0,0,0,0.5)',
    justifyContent: 'flex-end',
  },
  modalContainer: {
    backgroundColor: colors.surface,
    borderTopLeftRadius: borderRadius.lg,
    borderTopRightRadius: borderRadius.lg,
    maxHeight: '70%',
    padding: spacing.md,
  },
  modalHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: spacing.sm,
  },
  modalTitle: {
    fontSize: fontSize.lg,
    fontWeight: '600',
    color: colors.text,
  },
  modalSearch: {
    borderWidth: 1,
    borderColor: colors.borderLight,
    borderRadius: borderRadius.sm,
    paddingHorizontal: spacing.sm,
    paddingVertical: spacing.xs,
    fontSize: fontSize.md,
    marginBottom: spacing.sm,
    color: colors.text,
  },
  modalItem: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.sm,
    paddingVertical: spacing.sm,
    borderBottomWidth: 1,
    borderBottomColor: colors.borderLight,
  },
  modalItemText: {
    fontSize: fontSize.md,
    color: colors.text,
    flex: 1,
  },
});
