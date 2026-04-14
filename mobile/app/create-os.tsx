import React, { useState, useMemo } from 'react';
import {
  View,
  Text,
  ScrollView,
  StyleSheet,
  TouchableOpacity,
  TextInput,
  ActivityIndicator,
  Modal,
  FlatList,
  Platform,
} from 'react-native';
import { router } from 'expo-router';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { orderServicesApi } from '../src/api/orderServices';
import { vehiclesApi } from '../src/api/vehicles';
import { colors, spacing, borderRadius, fontSize, shadows } from '../src/theme/colors';
import { Ionicons } from '@expo/vector-icons';
import Toast from 'react-native-toast-message';
import { Vehicle } from '../src/types';
import { useAuth } from '../src/contexts/AuthContext';
import { useClientFilter } from '../src/contexts/ClientContext';

const OS_TYPE_COTACOES = 1;
const OS_TYPE_DIAGNOSTICO = 2;
const OS_TYPE_REQUISICAO = 3;

function SearchablePicker({
  visible, onClose, onSelect, title, items, searchPlaceholder, renderItem: customRender,
}: {
  visible: boolean; onClose: () => void; onSelect: (item: any) => void;
  title: string; items: any[]; searchPlaceholder?: string;
  renderItem?: (item: any) => React.ReactNode;
}) {
  const [search, setSearch] = useState('');
  const filtered = useMemo(() => {
    if (!search) return items.slice(0, 100);
    const q = search.toLowerCase();
    return items.filter((item) => {
      const label = item.name || item.board || '';
      const extra = item.brand ? `${item.brand} ${item.model}` : '';
      return label.toLowerCase().includes(q) || extra.toLowerCase().includes(q);
    }).slice(0, 100);
  }, [items, search]);
  return (
    <Modal visible={visible} animationType="slide" transparent>
      <View style={pk.overlay}>
        <View style={pk.container}>
          <View style={pk.header}>
            <Text style={pk.title}>{title}</Text>
            <TouchableOpacity onPress={() => { onClose(); setSearch(''); }}>
              <Ionicons name="close" size={24} color={colors.text} />
            </TouchableOpacity>
          </View>
          <TextInput
            style={pk.searchInput} placeholder={searchPlaceholder || 'Buscar...'}
            value={search} onChangeText={setSearch} placeholderTextColor={colors.placeholder} autoFocus
          />
          <FlatList
            data={filtered} keyExtractor={(item) => String(item.id)}
            renderItem={({ item }) => (
              <TouchableOpacity style={pk.item} onPress={() => { onSelect(item); onClose(); setSearch(''); }}>
                {customRender ? customRender(item) : <Text style={pk.itemText}>{item.name || item.board}</Text>}
              </TouchableOpacity>
            )}
            ListEmptyComponent={<Text style={pk.empty}>Nenhum resultado</Text>}
          />
        </View>
      </View>
    </Modal>
  );
}

export default function CreateOSScreen() {
  const queryClient = useQueryClient();
  const { isAdmin, isGestor, isAdicional } = useAuth();
  const { selectedClientId, selectedClientName } = useClientFilter();

  const [clientId, setClientId] = useState<number | null>(selectedClientId);
  const [clientName, setClientName] = useState(selectedClientName);
  const [vehicleId, setVehicleId] = useState<number | null>(null);
  const [serviceTypeId, setServiceTypeId] = useState<number | null>(null);
  const [serviceTypeName, setServiceTypeName] = useState('');
  const [osTypeId, setOsTypeId] = useState<number>(OS_TYPE_COTACOES);
  const [details, setDetails] = useState('');
  const [km, setKm] = useState('');
  const [driver, setDriver] = useState('');
  const [maintenancePlanId, setMaintenancePlanId] = useState<number | null>(null);
  const [maintenancePlanName, setMaintenancePlanName] = useState('');
  const [commitmentId, setCommitmentId] = useState<number | null>(null);
  const [commitmentName, setCommitmentName] = useState('');
  const [commitmentPartsId, setCommitmentPartsId] = useState<number | null>(null);
  const [commitmentPartsName, setCommitmentPartsName] = useState('');
  const [commitmentServicesId, setCommitmentServicesId] = useState<number | null>(null);
  const [commitmentServicesName, setCommitmentServicesName] = useState('');
  const [managerId, setManagerId] = useState<number | null>(null);
  const [managerName, setManagerName] = useState('');
  const [providerId, setProviderId] = useState<number | null>(null);
  const [providerName, setProviderName] = useState('');
  const [serviceGroupId, setServiceGroupId] = useState<number | null>(null);
  const [serviceGroupName, setServiceGroupName] = useState('');

  const [activePicker, setActivePicker] = useState<string | null>(null);

  const { data: vehiclesData, isLoading: vehiclesLoading } = useQuery({
    queryKey: ['vehicles-picker', clientId],
    queryFn: () => vehiclesApi.list({ per_page: 500, active: true, client_id: clientId ?? undefined }),
  });
  const { data: serviceTypesData } = useQuery({ queryKey: ['service-types'], queryFn: orderServicesApi.getServiceTypes });
  const { data: osTypesData } = useQuery({ queryKey: ['os-types'], queryFn: orderServicesApi.getOSTypes });
  const { data: maintenancePlansData } = useQuery({ queryKey: ['maintenance-plans'], queryFn: orderServicesApi.getMaintenancePlans });
  const { data: commitmentsData } = useQuery({ queryKey: ['commitments'], queryFn: orderServicesApi.getCommitments });
  const { data: clientsData } = useQuery({ queryKey: ['clients'], queryFn: orderServicesApi.getClients, enabled: isAdmin });
  const { data: managersData } = useQuery({ queryKey: ['managers'], queryFn: orderServicesApi.getManagers });
  const { data: providersData } = useQuery({ queryKey: ['providers'], queryFn: orderServicesApi.getProviders, enabled: osTypeId === OS_TYPE_DIAGNOSTICO });
  const { data: serviceGroupsData } = useQuery({ queryKey: ['service-groups'], queryFn: orderServicesApi.getServiceGroups, enabled: osTypeId === OS_TYPE_REQUISICAO });

  const vehicles = vehiclesData?.vehicles ?? [];
  const selectedVehicle = vehicles.find((v) => v.id === vehicleId);
  const serviceTypes = serviceTypesData?.service_types ?? [];
  const osTypes = osTypesData?.os_types ?? [];
  const maintenancePlans = maintenancePlansData?.maintenance_plans ?? [];
  const commitments = commitmentsData?.commitments ?? [];
  const clients = clientsData?.clients ?? [];
  const managers = managersData?.managers ?? [];
  const providers = providersData?.providers ?? [];
  const serviceGroups = serviceGroupsData?.service_groups ?? [];

  const createMutation = useMutation({
    mutationFn: orderServicesApi.create,
    onSuccess: (res) => {
      Toast.show({ type: 'success', text1: 'OS criada!', text2: res.order_service.code });
      queryClient.invalidateQueries({ queryKey: ['orderServices'] });
      queryClient.invalidateQueries({ queryKey: ['dashboard'] });
      router.back();
    },
    onError: (err: any) => {
      Toast.show({ type: 'error', text1: 'Erro ao criar OS', text2: err?.response?.data?.error || 'Tente novamente' });
    },
  });

  const handleSubmit = () => {
    if (isAdmin && !clientId) return Toast.show({ type: 'error', text1: 'Selecione o cliente' });
    if (!vehicleId) return Toast.show({ type: 'error', text1: 'Selecione um veículo' });
    if (!serviceTypeId) return Toast.show({ type: 'error', text1: 'Selecione o tipo de serviço' });
    if (!details.trim()) return Toast.show({ type: 'error', text1: 'Descreva o serviço necessário' });
    if (osTypeId === OS_TYPE_DIAGNOSTICO && !providerId) return Toast.show({ type: 'error', text1: 'Selecione o fornecedor' });

    const params: any = {
      vehicle_id: vehicleId,
      provider_service_type_id: serviceTypeId,
      order_service_type_id: osTypeId,
      details: details.trim(),
      km: km ? parseInt(km, 10) : undefined,
      driver: driver.trim() || undefined,
    };
    if (isAdmin && clientId) params.client_id = clientId;
    if (managerId) params.manager_id = managerId;
    if (maintenancePlanId) params.maintenance_plan_id = maintenancePlanId;
    if (commitmentId) params.commitment_id = commitmentId;
    if (commitmentPartsId) params.commitment_parts_id = commitmentPartsId;
    if (commitmentServicesId) params.commitment_services_id = commitmentServicesId;
    if (providerId) params.provider_id = providerId;
    if (serviceGroupId) params.service_group_id = serviceGroupId;
    createMutation.mutate(params);
  };

  const PF = ({ label, value, placeholder, pickerKey, icon, required }: {
    label: string; value: string; placeholder: string; pickerKey: string; icon?: string; required?: boolean;
  }) => (
    <>
      <Text style={s.label}>{label} {required && <Text style={s.req}>*</Text>}</Text>
      <TouchableOpacity style={s.picker} onPress={() => setActivePicker(pickerKey)}>
        {icon && <Ionicons name={icon as any} size={18} color={colors.textSecondary} />}
        <Text style={[s.pickerText, !value && { color: colors.placeholder }]}>{value || placeholder}</Text>
        <View style={s.pickerBtn}>
          <Ionicons name="search-outline" size={16} color={colors.primary} />
        </View>
      </TouchableOpacity>
    </>
  );

  const defaultOsTypes = [{ id: 1, name: 'Cotações' }, { id: 2, name: 'Diagnóstico' }, { id: 3, name: 'Requisição' }];

  return (
    <ScrollView style={s.container} contentContainerStyle={s.content} keyboardShouldPersistTaps="handled">
      {/* Cliente (Admin) */}
      {isAdmin && (
        <>
          <PF label="Cliente" value={clientName} placeholder="Selecione o cliente" pickerKey="client" icon="business-outline" required />
          <SearchablePicker visible={activePicker === 'client'} onClose={() => setActivePicker(null)}
            title="Selecionar Cliente" items={clients} searchPlaceholder="Buscar cliente..."
            onSelect={(i) => { setClientId(i.id); setClientName(i.name); setVehicleId(null); }}
          />
        </>
      )}

      {/* Veículo */}
      <PF label="Veículo" value={selectedVehicle ? `${selectedVehicle.board} - ${selectedVehicle.brand} ${selectedVehicle.model}` : ''} placeholder="Selecione o veículo" pickerKey="vehicle" icon="car-outline" required />
      <SearchablePicker visible={activePicker === 'vehicle'} onClose={() => setActivePicker(null)}
        title="Selecionar Veículo" items={vehicles} searchPlaceholder="Buscar placa, marca ou modelo..."
        onSelect={(i: Vehicle) => setVehicleId(i.id)}
        renderItem={(i: Vehicle) => (
          <View>
            <Text style={s.vpPlate}>{i.board}</Text>
            <Text style={s.vpModel}>{i.brand} {i.model} {i.year}</Text>
            {i.cost_center && <Text style={s.vpCC}>{i.cost_center}</Text>}
          </View>
        )}
      />

      {/* Tipo de Serviço */}
      <PF label="Tipo de Serviço" value={serviceTypeName} placeholder="Selecione o tipo de serviço" pickerKey="serviceType" icon="construct-outline" required />
      <SearchablePicker visible={activePicker === 'serviceType'} onClose={() => setActivePicker(null)}
        title="Tipo de Serviço" items={serviceTypes} searchPlaceholder="Buscar tipo de serviço..."
        onSelect={(i) => { setServiceTypeId(i.id); setServiceTypeName(i.name); }}
      />

      {/* Tipo de OS */}
      <Text style={s.label}>Tipo de OS <Text style={s.req}>*</Text></Text>
      <View style={s.chipRow}>
        {(osTypes.length > 0 ? osTypes : defaultOsTypes).map((ot) => (
          <TouchableOpacity key={ot.id} style={[s.chip, ot.id === osTypeId && s.chipSel]} onPress={() => setOsTypeId(ot.id)}>
            <Text style={[s.chipText, ot.id === osTypeId && s.chipTextSel]}>{ot.name}</Text>
          </TouchableOpacity>
        ))}
      </View>

      {/* Fornecedor (Diagnóstico) */}
      {osTypeId === OS_TYPE_DIAGNOSTICO && (
        <>
          <PF label="Fornecedor" value={providerName} placeholder="Selecione o fornecedor" pickerKey="provider" icon="storefront-outline" required />
          <SearchablePicker visible={activePicker === 'provider'} onClose={() => setActivePicker(null)}
            title="Selecionar Fornecedor" items={providers} searchPlaceholder="Buscar fornecedor..."
            onSelect={(i) => { setProviderId(i.id); setProviderName(i.name); }}
          />
        </>
      )}

      {/* Grupo de Serviço (Requisição) */}
      {osTypeId === OS_TYPE_REQUISICAO && serviceGroups.length > 0 && (
        <>
          <PF label="Grupo de Serviço" value={serviceGroupName} placeholder="Selecione o grupo" pickerKey="serviceGroup" icon="layers-outline" />
          <SearchablePicker visible={activePicker === 'serviceGroup'} onClose={() => setActivePicker(null)}
            title="Grupo de Serviço" items={serviceGroups}
            onSelect={(i) => { setServiceGroupId(i.id); setServiceGroupName(i.name); }}
          />
        </>
      )}

      {/* Gestor */}
      {(isAdmin || isGestor || isAdicional) && managers.length > 0 && (
        <>
          <PF label="Gestor Responsável" value={managerName} placeholder="Selecione o gestor" pickerKey="manager" icon="person-outline" />
          <SearchablePicker visible={activePicker === 'manager'} onClose={() => setActivePicker(null)}
            title="Selecionar Gestor" items={managers} searchPlaceholder="Buscar gestor..."
            onSelect={(i) => { setManagerId(i.id); setManagerName(i.name); }}
          />
        </>
      )}

      {/* Plano de Manutenção */}
      {maintenancePlans.length > 0 && (
        <>
          <PF label="Plano de Manutenção" value={maintenancePlanName} placeholder="Selecione (opcional)" pickerKey="maintenance" icon="clipboard-outline" />
          <SearchablePicker visible={activePicker === 'maintenance'} onClose={() => setActivePicker(null)}
            title="Plano de Manutenção" items={maintenancePlans}
            onSelect={(i) => { setMaintenancePlanId(i.id); setMaintenancePlanName(i.name); }}
          />
        </>
      )}

      {/* KM */}
      <Text style={s.label}>Quilometragem Atual</Text>
      <View style={s.inputRow}>
        <Ionicons name="speedometer-outline" size={18} color={colors.textSecondary} />
        <TextInput style={s.input} placeholder="Ex: 45000" value={km} onChangeText={setKm} keyboardType="numeric" placeholderTextColor={colors.placeholder} />
        <Text style={s.inputSuffix}>km</Text>
      </View>

      {/* Motorista */}
      <Text style={s.label}>Motorista</Text>
      <View style={s.inputRow}>
        <Ionicons name="person-outline" size={18} color={colors.textSecondary} />
        <TextInput style={s.input} placeholder="Nome do motorista" value={driver} onChangeText={setDriver} placeholderTextColor={colors.placeholder} />
      </View>

      {/* Descrição */}
      <Text style={s.label}>Descrição do Serviço <Text style={s.req}>*</Text></Text>
      <TextInput style={s.textArea} placeholder="Descreva o serviço necessário, defeitos observados, etc..." value={details} onChangeText={setDetails} multiline numberOfLines={5} textAlignVertical="top" placeholderTextColor={colors.placeholder} />

      {/* Empenhos */}
      {commitments.length > 0 && (
        <View style={s.commitSection}>
          <Text style={s.sectionTitle}>Empenhos (Orçamento)</Text>

          <PF label="Empenho Geral" value={commitmentName} placeholder="Selecione (opcional)" pickerKey="commit" icon="wallet-outline" />
          <SearchablePicker visible={activePicker === 'commit'} onClose={() => setActivePicker(null)}
            title="Empenho Geral" items={commitments}
            onSelect={(i) => { setCommitmentId(i.id); setCommitmentName(i.name || i.number || `#${i.id}`); }}
          />

          <PF label="Empenho Peças" value={commitmentPartsName} placeholder="Selecione (opcional)" pickerKey="commitParts" icon="cog-outline" />
          <SearchablePicker visible={activePicker === 'commitParts'} onClose={() => setActivePicker(null)}
            title="Empenho de Peças" items={commitments}
            onSelect={(i) => { setCommitmentPartsId(i.id); setCommitmentPartsName(i.name || i.number || `#${i.id}`); }}
          />

          <PF label="Empenho Serviços" value={commitmentServicesName} placeholder="Selecione (opcional)" pickerKey="commitServices" icon="construct-outline" />
          <SearchablePicker visible={activePicker === 'commitServices'} onClose={() => setActivePicker(null)}
            title="Empenho de Serviços" items={commitments}
            onSelect={(i) => { setCommitmentServicesId(i.id); setCommitmentServicesName(i.name || i.number || `#${i.id}`); }}
          />
        </View>
      )}

      {/* Submit */}
      <TouchableOpacity style={[s.submitBtn, createMutation.isPending && { opacity: 0.7 }]} onPress={handleSubmit} disabled={createMutation.isPending}>
        {createMutation.isPending ? <ActivityIndicator color="#fff" /> : (
          <><Ionicons name="checkmark-circle" size={20} color="#fff" /><Text style={s.submitText}>Criar OS</Text></>
        )}
      </TouchableOpacity>
    </ScrollView>
  );
}

const pk = StyleSheet.create({
  overlay: { flex: 1, backgroundColor: 'rgba(0,0,0,0.5)', justifyContent: 'flex-end' },
  container: { backgroundColor: colors.surface, borderTopLeftRadius: borderRadius.lg, borderTopRightRadius: borderRadius.lg, maxHeight: '80%', padding: spacing.md },
  header: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginBottom: spacing.sm },
  title: { fontSize: fontSize.lg, fontWeight: '700', color: colors.text },
  searchInput: { backgroundColor: colors.background, borderRadius: borderRadius.md, padding: spacing.sm, fontSize: fontSize.sm, color: colors.text, marginBottom: spacing.sm },
  item: { paddingVertical: spacing.md, borderBottomWidth: 1, borderBottomColor: colors.borderLight },
  itemText: { fontSize: fontSize.sm, color: colors.text },
  empty: { textAlign: 'center', color: colors.textLight, padding: spacing.lg },
});

const s = StyleSheet.create({
  container: { flex: 1, backgroundColor: colors.background },
  content: { padding: spacing.md, paddingBottom: spacing.xxl },
  label: { fontSize: fontSize.sm, fontWeight: '600', color: colors.text, marginBottom: spacing.xs, marginTop: spacing.md },
  req: { color: colors.danger },
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
  pickerBtn: {
    width: 32,
    height: 32,
    borderRadius: borderRadius.full,
    backgroundColor: colors.primary + '12',
    justifyContent: 'center',
    alignItems: 'center',
  },
  chipRow: { flexDirection: 'row', flexWrap: 'wrap', gap: spacing.sm },
  chip: {
    paddingHorizontal: spacing.md,
    paddingVertical: spacing.sm,
    borderRadius: borderRadius.full,
    backgroundColor: colors.surfaceVariant,
    borderWidth: 1,
    borderColor: colors.border,
  },
  chipSel: { backgroundColor: colors.primary, borderColor: colors.primary },
  chipText: { fontSize: fontSize.sm, color: colors.textSecondary },
  chipTextSel: { color: '#fff', fontWeight: '600' },
  inputRow: {
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
  commitSection: { marginTop: spacing.lg, borderTopWidth: 1, borderTopColor: colors.borderLight, paddingTop: spacing.md },
  sectionTitle: { fontSize: fontSize.md, fontWeight: '700', color: colors.text, marginBottom: spacing.xs },
  vpPlate: { fontSize: fontSize.sm, fontWeight: '700', color: colors.primary },
  vpModel: { fontSize: fontSize.xs, color: colors.textSecondary },
  vpCC: { fontSize: fontSize.xs, color: colors.textLight, marginTop: 2 },
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
  submitText: { color: '#fff', fontSize: fontSize.lg, fontWeight: '700' },
});
