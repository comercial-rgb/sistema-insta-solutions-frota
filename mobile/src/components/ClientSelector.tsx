import React, { useState } from 'react';
import {
  View,
  Text,
  TouchableOpacity,
  Modal,
  FlatList,
  TextInput,
  StyleSheet,
  KeyboardAvoidingView,
  Platform,
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { colors, spacing, borderRadius, fontSize, shadows } from '../theme/colors';
import { useClientFilter } from '../contexts/ClientContext';

export default function ClientSelector() {
  const { selectedClientId, selectedClientName, setSelectedClient, clients, needsClientSelection } =
    useClientFilter();
  const [visible, setVisible] = useState(false);
  const [search, setSearch] = useState('');

  if (!needsClientSelection) return null;

  const filtered = clients.filter((c) =>
    c.name.toLowerCase().includes(search.toLowerCase())
  );

  return (
    <View style={s.wrapper}>
      <TouchableOpacity style={s.selector} onPress={() => setVisible(true)}>
        <Ionicons name="business" size={16} color={selectedClientId ? colors.primary : colors.textLight} />
        <Text
          style={[s.selectorText, !selectedClientId && { color: colors.placeholder }]}
          numberOfLines={1}
        >
          {selectedClientId ? selectedClientName : 'Selecionar Cliente'}
        </Text>
        {selectedClientId ? (
          <TouchableOpacity
            onPress={() => { setSelectedClient(null, ''); }}
            hitSlop={{ top: 8, bottom: 8, left: 8, right: 8 }}
          >
            <Ionicons name="close-circle" size={18} color={colors.textLight} />
          </TouchableOpacity>
        ) : (
          <Ionicons name="chevron-down" size={16} color={colors.textLight} />
        )}
      </TouchableOpacity>

      <Modal visible={visible} animationType="slide" transparent>
        <KeyboardAvoidingView
          style={s.overlay}
          behavior={Platform.OS === 'ios' ? 'padding' : undefined}
        >
          <View style={s.modal}>
            <View style={s.modalHeader}>
              <Text style={s.modalTitle}>Selecionar Cliente</Text>
              <TouchableOpacity onPress={() => { setVisible(false); setSearch(''); }}>
                <Ionicons name="close" size={24} color={colors.text} />
              </TouchableOpacity>
            </View>
            <TextInput
              style={s.searchInput}
              placeholder="Buscar cliente..."
              placeholderTextColor={colors.placeholder}
              value={search}
              onChangeText={setSearch}
              autoFocus
              returnKeyType="search"
            />
            <FlatList
              data={filtered}
              keyExtractor={(item) => String(item.id)}
              keyboardShouldPersistTaps="handled"
              keyboardDismissMode="on-drag"
              renderItem={({ item }) => (
                <TouchableOpacity
                  style={[s.item, item.id === selectedClientId && s.itemSelected]}
                  onPress={() => {
                    setSelectedClient(item.id, item.name);
                    setVisible(false);
                    setSearch('');
                  }}
                >
                  <Text
                    style={[s.itemText, item.id === selectedClientId && s.itemTextSelected]}
                  >
                    {item.name}
                  </Text>
                  {item.id === selectedClientId && (
                    <Ionicons name="checkmark" size={18} color={colors.primary} />
                  )}
                </TouchableOpacity>
              )}
              ListEmptyComponent={
                <Text style={s.empty}>Nenhum cliente encontrado</Text>
              }
            />
          </View>
        </KeyboardAvoidingView>
      </Modal>
    </View>
  );
}

const s = StyleSheet.create({
  wrapper: {
    paddingHorizontal: spacing.md,
    paddingTop: spacing.sm,
  },
  selector: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.surface,
    borderRadius: borderRadius.md,
    paddingHorizontal: spacing.md,
    height: 40,
    gap: spacing.sm,
    borderWidth: 1,
    borderColor: colors.primary + '30',
    ...shadows.sm,
  },
  selectorText: {
    flex: 1,
    fontSize: fontSize.sm,
    color: colors.text,
    fontWeight: '500',
  },
  overlay: {
    flex: 1,
    backgroundColor: 'rgba(0,0,0,0.5)',
    justifyContent: 'flex-end',
  },
  modal: {
    backgroundColor: colors.surface,
    borderTopLeftRadius: borderRadius.xl,
    borderTopRightRadius: borderRadius.xl,
    maxHeight: '70%',
    paddingBottom: spacing.xxl,
  },
  modalHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    padding: spacing.md,
    borderBottomWidth: 1,
    borderBottomColor: colors.borderLight,
  },
  modalTitle: {
    fontSize: fontSize.lg,
    fontWeight: '700',
    color: colors.text,
  },
  searchInput: {
    margin: spacing.md,
    backgroundColor: colors.surfaceVariant,
    borderRadius: borderRadius.md,
    paddingHorizontal: spacing.md,
    height: 44,
    fontSize: fontSize.sm,
    color: colors.text,
  },
  item: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: spacing.md,
    paddingVertical: spacing.md,
    borderBottomWidth: 1,
    borderBottomColor: colors.borderLight,
  },
  itemSelected: {
    backgroundColor: colors.primary + '08',
  },
  itemText: {
    flex: 1,
    fontSize: fontSize.sm,
    color: colors.text,
  },
  itemTextSelected: {
    color: colors.primary,
    fontWeight: '600',
  },
  empty: {
    textAlign: 'center',
    color: colors.textLight,
    padding: spacing.lg,
    fontSize: fontSize.sm,
  },
});
