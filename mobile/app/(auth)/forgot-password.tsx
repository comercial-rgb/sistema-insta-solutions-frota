import React, { useState } from 'react';
import {
  View,
  Text,
  TextInput,
  TouchableOpacity,
  StyleSheet,
  KeyboardAvoidingView,
  Platform,
  ActivityIndicator,
} from 'react-native';
import { router } from 'expo-router';
import { authApi } from '../../src/api/auth';
import { colors, spacing, borderRadius, fontSize } from '../../src/theme/colors';
import { Ionicons } from '@expo/vector-icons';
import Toast from 'react-native-toast-message';

export default function ForgotPasswordScreen() {
  const [email, setEmail] = useState('');
  const [loading, setLoading] = useState(false);
  const [sent, setSent] = useState(false);

  const handleRecover = async () => {
    if (!email.trim()) {
      Toast.show({ type: 'error', text1: 'Informe seu email' });
      return;
    }

    setLoading(true);
    try {
      await authApi.recoverPassword(email.trim());
      setSent(true);
      Toast.show({ type: 'success', text1: 'Email de recuperação enviado' });
    } catch {
      Toast.show({
        type: 'error',
        text1: 'Erro ao enviar',
        text2: 'Verifique a conexão e tente novamente.',
      });
    } finally {
      setLoading(false);
    }
  };

  return (
    <KeyboardAvoidingView
      style={styles.container}
      behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
    >
      <View style={styles.content}>
        <TouchableOpacity style={styles.backButton} onPress={() => router.back()}>
          <Ionicons name="arrow-back" size={24} color={colors.textInverse} />
        </TouchableOpacity>

        <Text style={styles.title}>Recuperar Senha</Text>
        <Text style={styles.description}>
          Informe seu email cadastrado e enviaremos instruções para redefinir sua senha.
        </Text>

        {sent ? (
          <View style={styles.successBox}>
            <Ionicons name="checkmark-circle" size={48} color={colors.success} />
            <Text style={styles.successText}>
              Email enviado! Verifique sua caixa de entrada.
            </Text>
            <TouchableOpacity style={styles.button} onPress={() => router.back()}>
              <Text style={styles.buttonText}>Voltar ao Login</Text>
            </TouchableOpacity>
          </View>
        ) : (
          <>
            <View style={styles.inputContainer}>
              <Ionicons name="mail-outline" size={20} color={colors.textLight} style={styles.inputIcon} />
              <TextInput
                style={styles.input}
                placeholder="Seu email"
                placeholderTextColor={colors.placeholder}
                value={email}
                onChangeText={setEmail}
                keyboardType="email-address"
                autoCapitalize="none"
              />
            </View>

            <TouchableOpacity
              style={[styles.button, loading && styles.buttonDisabled]}
              onPress={handleRecover}
              disabled={loading}
            >
              {loading ? (
                <ActivityIndicator color={colors.text} />
              ) : (
                <Text style={styles.buttonText}>Enviar</Text>
              )}
            </TouchableOpacity>
          </>
        )}
      </View>
    </KeyboardAvoidingView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: colors.primary },
  content: { flex: 1, justifyContent: 'center', paddingHorizontal: spacing.xl },
  backButton: { position: 'absolute', top: 60, left: 0 },
  title: { fontSize: fontSize.xxl, fontWeight: '700', color: colors.textInverse, marginBottom: spacing.sm },
  description: { fontSize: fontSize.md, color: 'rgba(255,255,255,0.7)', marginBottom: spacing.xl, lineHeight: 22 },
  inputContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: 'rgba(255,255,255,0.12)',
    borderRadius: borderRadius.md,
    paddingHorizontal: spacing.md,
    height: 52,
    marginBottom: spacing.md,
  },
  inputIcon: { marginRight: spacing.sm },
  input: { flex: 1, color: colors.textInverse, fontSize: fontSize.md },
  button: {
    backgroundColor: colors.secondary,
    borderRadius: borderRadius.md,
    height: 52,
    justifyContent: 'center',
    alignItems: 'center',
  },
  buttonDisabled: { opacity: 0.7 },
  buttonText: { color: colors.text, fontSize: fontSize.lg, fontWeight: '700' },
  successBox: { alignItems: 'center', gap: spacing.md },
  successText: { color: colors.textInverse, fontSize: fontSize.md, textAlign: 'center', lineHeight: 22 },
});
