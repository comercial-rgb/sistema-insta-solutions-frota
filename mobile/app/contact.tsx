import React, { useState } from 'react';
import {
  View,
  Text,
  ScrollView,
  StyleSheet,
  TouchableOpacity,
  TextInput,
  Alert,
  ActivityIndicator,
  Linking,
} from 'react-native';
import { router } from 'expo-router';
import { useQuery, useMutation } from '@tanstack/react-query';
import { contactApi } from '../src/api/contact';
import { colors, spacing, borderRadius, fontSize, shadows } from '../src/theme/colors';
import { Ionicons } from '@expo/vector-icons';

export default function ContactScreen() {
  const [subject, setSubject] = useState('');
  const [message, setMessage] = useState('');

  const { data: infoData, isLoading } = useQuery({
    queryKey: ['contact-info'],
    queryFn: () => contactApi.getInfo(),
  });

  const sendMutation = useMutation({
    mutationFn: contactApi.send,
    onSuccess: () => {
      Alert.alert('Mensagem Enviada', 'Sua mensagem foi enviada com sucesso. Retornaremos em breve.');
      setSubject('');
      setMessage('');
    },
    onError: () => Alert.alert('Erro', 'Não foi possível enviar a mensagem.'),
  });

  const info = infoData?.contact;

  const handleSend = () => {
    if (!subject.trim()) return Alert.alert('Atenção', 'Informe o assunto.');
    if (!message.trim()) return Alert.alert('Atenção', 'Escreva sua mensagem.');
    sendMutation.mutate({ subject, message });
  };

  return (
    <ScrollView style={styles.container} contentContainerStyle={styles.content}>
      {isLoading ? (
        <ActivityIndicator size="large" color={colors.primary} style={{ marginTop: spacing.xxl }} />
      ) : (
        <>
          {/* Company Info */}
          {info && (
            <View style={styles.infoCard}>
              <Text style={styles.companyName}>{info.company_name || 'Insta Solutions'}</Text>

              {info.phone && (
                <TouchableOpacity
                  style={styles.infoRow}
                  onPress={() => Linking.openURL(`tel:${info.phone}`)}
                >
                  <Ionicons name="call-outline" size={18} color={colors.primary} />
                  <Text style={styles.infoText}>{info.phone}</Text>
                </TouchableOpacity>
              )}

              {info.email && (
                <TouchableOpacity
                  style={styles.infoRow}
                  onPress={() => Linking.openURL(`mailto:${info.email}`)}
                >
                  <Ionicons name="mail-outline" size={18} color={colors.primary} />
                  <Text style={styles.infoText}>{info.email}</Text>
                </TouchableOpacity>
              )}

              {info.whatsapp && (
                <TouchableOpacity
                  style={styles.infoRow}
                  onPress={() => Linking.openURL(`https://wa.me/${info.whatsapp.replace(/\D/g, '')}`)}
                >
                  <Ionicons name="logo-whatsapp" size={18} color="#25D366" />
                  <Text style={styles.infoText}>{info.whatsapp}</Text>
                </TouchableOpacity>
              )}

              {info.address && (
                <View style={styles.infoRow}>
                  <Ionicons name="location-outline" size={18} color={colors.primary} />
                  <Text style={styles.infoText}>{info.address}</Text>
                </View>
              )}

              {info.business_hours && (
                <View style={styles.infoRow}>
                  <Ionicons name="time-outline" size={18} color={colors.primary} />
                  <Text style={styles.infoText}>{info.business_hours}</Text>
                </View>
              )}
            </View>
          )}

          {/* Contact Form */}
          <View style={styles.formCard}>
            <Text style={styles.formTitle}>Enviar Mensagem</Text>

            <Text style={styles.label}>Assunto</Text>
            <TextInput
              style={styles.input}
              placeholder="Assunto da mensagem"
              value={subject}
              onChangeText={setSubject}
            />

            <Text style={styles.label}>Mensagem</Text>
            <TextInput
              style={[styles.input, styles.textArea]}
              placeholder="Escreva sua mensagem..."
              value={message}
              onChangeText={setMessage}
              multiline
              numberOfLines={5}
            />

            <TouchableOpacity
              style={[styles.sendBtn, sendMutation.isPending && { opacity: 0.6 }]}
              onPress={handleSend}
              disabled={sendMutation.isPending}
            >
              {sendMutation.isPending ? (
                <ActivityIndicator color="#FFF" />
              ) : (
                <>
                  <Ionicons name="send-outline" size={18} color="#FFF" />
                  <Text style={styles.sendBtnText}>Enviar</Text>
                </>
              )}
            </TouchableOpacity>
          </View>
        </>
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

  infoCard: { backgroundColor: colors.surface, borderRadius: borderRadius.lg, padding: spacing.lg, marginBottom: spacing.lg, ...shadows.sm },
  companyName: { fontSize: fontSize.lg, fontWeight: '700', color: colors.primary, marginBottom: spacing.md },
  infoRow: { flexDirection: 'row', alignItems: 'center', gap: spacing.sm, marginBottom: spacing.sm },
  infoText: { fontSize: fontSize.sm, color: colors.text },

  formCard: { backgroundColor: colors.surface, borderRadius: borderRadius.lg, padding: spacing.lg, ...shadows.sm },
  formTitle: { fontSize: fontSize.lg, fontWeight: '600', color: colors.text, marginBottom: spacing.md },
  label: { fontSize: fontSize.sm, fontWeight: '600', color: colors.text, marginBottom: spacing.xs, marginTop: spacing.sm },
  input: { backgroundColor: colors.background, borderRadius: borderRadius.md, padding: spacing.md, fontSize: fontSize.md, color: colors.text, borderWidth: 1, borderColor: colors.border },
  textArea: { minHeight: 120, textAlignVertical: 'top' },
  sendBtn: { flexDirection: 'row', alignItems: 'center', justifyContent: 'center', gap: spacing.sm, backgroundColor: colors.primary, borderRadius: borderRadius.md, padding: spacing.md, marginTop: spacing.lg },
  sendBtnText: { color: '#FFF', fontSize: fontSize.md, fontWeight: '700' },
});
