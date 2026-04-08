export const colors = {
  primary: '#1E3A5F',
  primaryLight: '#2E5A8F',
  primaryDark: '#0E2A4F',
  secondary: '#F5A623',
  secondaryLight: '#FFD180',
  accent: '#00BCD4',

  success: '#4CAF50',
  successLight: '#E8F5E8',
  warning: '#FF9800',
  warningLight: '#FFF3E0',
  danger: '#F44336',
  dangerLight: '#FFEBEE',
  info: '#2196F3',
  infoLight: '#E3F2FD',

  background: '#F5F7FA',
  surface: '#FFFFFF',
  surfaceVariant: '#F0F2F5',
  card: '#FFFFFF',

  text: '#1A1A2E',
  textSecondary: '#6B7280',
  textLight: '#9CA3AF',
  textInverse: '#FFFFFF',

  border: '#E5E7EB',
  borderLight: '#F3F4F6',
  divider: '#E0E0E0',

  disabled: '#D1D5DB',
  placeholder: '#9CA3AF',
  overlay: 'rgba(0, 0, 0, 0.5)',

  // Status OS
  statusOpen: '#2196F3',
  statusApproved: '#4CAF50',
  statusAwaiting: '#FF9800',
  statusPaid: '#8BC34A',
  statusCancelled: '#F44336',
  statusInProgress: '#03A9F4',
} as const;

export const spacing = {
  xs: 4,
  sm: 8,
  md: 16,
  lg: 24,
  xl: 32,
  xxl: 48,
} as const;

export const borderRadius = {
  sm: 6,
  md: 12,
  lg: 16,
  xl: 24,
  full: 9999,
} as const;

export const fontSize = {
  xs: 11,
  sm: 13,
  md: 15,
  lg: 17,
  xl: 20,
  xxl: 24,
  xxxl: 32,
} as const;

export const shadows = {
  sm: {
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.08,
    shadowRadius: 2,
    elevation: 1,
  },
  md: {
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.12,
    shadowRadius: 4,
    elevation: 3,
  },
  lg: {
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.15,
    shadowRadius: 8,
    elevation: 5,
  },
} as const;
