import React, { useState, useEffect, useRef } from 'react';
import {
  View,
  Text,
  StyleSheet,
  TouchableOpacity,
  Alert,
  ActivityIndicator,
  Platform,
} from 'react-native';
import { router } from 'expo-router';
import { useMutation } from '@tanstack/react-query';
import { qrNfcApi } from '../src/api/qrNfc';
import { colors, spacing, borderRadius, fontSize } from '../src/theme/colors';
import { Ionicons } from '@expo/vector-icons';
import { CameraView, useCameraPermissions } from 'expo-camera';

export default function QrScanScreen() {
  const [mode, setMode] = useState<'qr' | 'nfc'>('qr');
  const [scanned, setScanned] = useState(false);
  const [nfcSupported, setNfcSupported] = useState(false);
  const [nfcReading, setNfcReading] = useState(false);
  const [permission, requestPermission] = useCameraPermissions();

  const mutation = useMutation({
    mutationFn: qrNfcApi.requestService,
    onSuccess: (data) => {
      Alert.alert('Sucesso', `Solicitação de serviço criada!\nOS #${data.order_service_id ?? ''}`, [
        { text: 'Ver OS', onPress: () => router.replace(`/os-detail/${data.order_service_id}`) },
        { text: 'Fechar', onPress: () => router.back() },
      ]);
    },
    onError: (err: any) => {
      const msg = err?.response?.data?.error || 'Não foi possível solicitar o serviço.';
      Alert.alert('Erro', msg);
      setScanned(false);
    },
  });

  // Check NFC support
  useEffect(() => {
    let NfcManager: any;
    try {
      NfcManager = require('react-native-nfc-manager').default;
      NfcManager.isSupported().then((supported: boolean) => setNfcSupported(supported));
    } catch {
      setNfcSupported(false);
    }
  }, []);

  const handleQrScanned = ({ data }: { data: string }) => {
    if (scanned || mutation.isPending) return;
    setScanned(true);

    // Validate token format: VH-{id}-{hash}
    if (!data.match(/^VH-\d+-[a-f0-9]+$/i)) {
      Alert.alert('QR Code Inválido', 'Este QR Code não é de um veículo cadastrado.', [
        { text: 'Tentar novamente', onPress: () => setScanned(false) },
      ]);
      return;
    }

    mutation.mutate({ token: data, method: 'qr_code' });
  };

  const startNfcScan = async () => {
    try {
      const NfcManager = require('react-native-nfc-manager').default;
      const { NfcTech } = require('react-native-nfc-manager');
      setNfcReading(true);
      await NfcManager.requestTechnology(NfcTech.Ndef);
      const tag = await NfcManager.getTag();
      if (tag?.ndefMessage?.[0]) {
        const payload = tag.ndefMessage[0].payload;
        const text = String.fromCharCode(...payload.slice(payload[0] + 1));
        mutation.mutate({ token: text, method: 'nfc' });
      } else {
        Alert.alert('Erro', 'Tag NFC vazia ou não reconhecida.');
      }
      await NfcManager.cancelTechnologyRequest();
    } catch {
      Alert.alert('Erro', 'Falha na leitura NFC.');
    } finally {
      setNfcReading(false);
    }
  };

  if (!permission) return <ActivityIndicator size="large" color={colors.primary} style={{ flex: 1 }} />;

  return (
    <View style={styles.container}>
      <View style={styles.header}>
        <TouchableOpacity onPress={() => router.back()} style={styles.backBtn}>
          <Ionicons name="arrow-back" size={24} color="#FFF" />
        </TouchableOpacity>
        <Text style={styles.headerTitle}>Solicitar Serviço</Text>
      </View>

      {/* Mode Tabs */}
      <View style={styles.tabs}>
        <TouchableOpacity
          style={[styles.tab, mode === 'qr' && styles.tabActive]}
          onPress={() => { setMode('qr'); setScanned(false); }}
        >
          <Ionicons name="qr-code-outline" size={20} color={mode === 'qr' ? '#FFF' : colors.textLight} />
          <Text style={[styles.tabText, mode === 'qr' && styles.tabTextActive]}>QR Code</Text>
        </TouchableOpacity>
        {nfcSupported && (
          <TouchableOpacity
            style={[styles.tab, mode === 'nfc' && styles.tabActive]}
            onPress={() => setMode('nfc')}
          >
            <Ionicons name="wifi-outline" size={20} color={mode === 'nfc' ? '#FFF' : colors.textLight} />
            <Text style={[styles.tabText, mode === 'nfc' && styles.tabTextActive]}>NFC</Text>
          </TouchableOpacity>
        )}
      </View>

      {mode === 'qr' ? (
        <View style={styles.cameraContainer}>
          {!permission.granted ? (
            <View style={styles.centered}>
              <Ionicons name="camera-outline" size={48} color={colors.textLight} />
              <Text style={styles.permText}>Permita o acesso à câmera para escanear QR Codes</Text>
              <TouchableOpacity style={styles.permBtn} onPress={requestPermission}>
                <Text style={styles.permBtnText}>Permitir Câmera</Text>
              </TouchableOpacity>
            </View>
          ) : (
            <>
              <CameraView
                style={StyleSheet.absoluteFillObject}
                barcodeScannerSettings={{ barcodeTypes: ['qr'] }}
                onBarcodeScanned={scanned ? undefined : handleQrScanned}
              />
              {/* Overlay */}
              <View style={styles.overlay}>
                <View style={styles.scanFrame} />
                <Text style={styles.scanHint}>
                  {scanned ? 'Processando...' : 'Aponte a câmera para o QR Code do veículo'}
                </Text>
              </View>
              {scanned && !mutation.isPending && (
                <TouchableOpacity style={styles.rescanBtn} onPress={() => setScanned(false)}>
                  <Text style={styles.rescanBtnText}>Escanear Novamente</Text>
                </TouchableOpacity>
              )}
            </>
          )}
        </View>
      ) : (
        <View style={styles.nfcContainer}>
          <Ionicons name="phone-portrait-outline" size={64} color={colors.primary} />
          <Text style={styles.nfcTitle}>Leitura NFC</Text>
          <Text style={styles.nfcDesc}>
            Aproxime o celular da tag NFC do veículo para solicitar o serviço.
          </Text>
          <TouchableOpacity
            style={[styles.nfcBtn, nfcReading && { opacity: 0.6 }]}
            onPress={startNfcScan}
            disabled={nfcReading || mutation.isPending}
          >
            {nfcReading ? (
              <ActivityIndicator color="#FFF" />
            ) : (
              <>
                <Ionicons name="wifi-outline" size={20} color="#FFF" />
                <Text style={styles.nfcBtnText}>Iniciar Leitura NFC</Text>
              </>
            )}
          </TouchableOpacity>
        </View>
      )}

      {mutation.isPending && (
        <View style={styles.loadingOverlay}>
          <ActivityIndicator size="large" color="#FFF" />
          <Text style={styles.loadingText}>Solicitando serviço...</Text>
        </View>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#000' },
  header: { flexDirection: 'row', alignItems: 'center', padding: spacing.md, paddingTop: spacing.xl },
  backBtn: { marginRight: spacing.sm },
  headerTitle: { fontSize: fontSize.xl, fontWeight: '700', color: '#FFF' },
  tabs: { flexDirection: 'row', paddingHorizontal: spacing.md, gap: spacing.sm, marginBottom: spacing.md },
  tab: { flex: 1, flexDirection: 'row', alignItems: 'center', justifyContent: 'center', gap: spacing.xs, padding: spacing.sm, borderRadius: borderRadius.md, backgroundColor: 'rgba(255,255,255,0.1)' },
  tabActive: { backgroundColor: colors.primary },
  tabText: { fontSize: fontSize.sm, color: colors.textLight },
  tabTextActive: { color: '#FFF', fontWeight: '600' },

  cameraContainer: { flex: 1, overflow: 'hidden' },
  overlay: { ...StyleSheet.absoluteFillObject, alignItems: 'center', justifyContent: 'center' },
  scanFrame: { width: 250, height: 250, borderWidth: 2, borderColor: colors.secondary, borderRadius: borderRadius.md },
  scanHint: { color: '#FFF', fontSize: fontSize.sm, marginTop: spacing.md, textAlign: 'center', paddingHorizontal: spacing.xl },
  rescanBtn: { position: 'absolute', bottom: spacing.xxl, alignSelf: 'center', backgroundColor: colors.primary, paddingHorizontal: spacing.xl, paddingVertical: spacing.md, borderRadius: borderRadius.md },
  rescanBtnText: { color: '#FFF', fontWeight: '700', fontSize: fontSize.md },

  centered: { flex: 1, alignItems: 'center', justifyContent: 'center', padding: spacing.xl },
  permText: { color: '#FFF', fontSize: fontSize.md, textAlign: 'center', marginVertical: spacing.md },
  permBtn: { backgroundColor: colors.primary, paddingHorizontal: spacing.xl, paddingVertical: spacing.md, borderRadius: borderRadius.md },
  permBtnText: { color: '#FFF', fontWeight: '700' },

  nfcContainer: { flex: 1, alignItems: 'center', justifyContent: 'center', padding: spacing.xl },
  nfcTitle: { fontSize: fontSize.xl, fontWeight: '700', color: '#FFF', marginTop: spacing.md },
  nfcDesc: { fontSize: fontSize.md, color: 'rgba(255,255,255,0.7)', textAlign: 'center', marginVertical: spacing.md },
  nfcBtn: { flexDirection: 'row', alignItems: 'center', gap: spacing.sm, backgroundColor: colors.primary, paddingHorizontal: spacing.xl, paddingVertical: spacing.md, borderRadius: borderRadius.md },
  nfcBtnText: { color: '#FFF', fontWeight: '700', fontSize: fontSize.md },

  loadingOverlay: { ...StyleSheet.absoluteFillObject, backgroundColor: 'rgba(0,0,0,0.7)', alignItems: 'center', justifyContent: 'center' },
  loadingText: { color: '#FFF', fontSize: fontSize.md, marginTop: spacing.md },
});
