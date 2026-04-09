import { useWindowDimensions } from 'react-native';

export function useResponsiveLayout() {
  const { width } = useWindowDimensions();
  const isTablet = width >= 768;
  const isLargePhone = width >= 414;

  return {
    width,
    isTablet,
    isLargePhone,
    listColumns: isTablet ? 2 : 1,
    dashActionColumns: isTablet ? 6 : isLargePhone ? 4 : 3,
    dashActionWidth: isTablet ? `${100 / 6}%` : isLargePhone ? '23%' : '31%',
    contentMaxWidth: isTablet ? 900 : undefined,
    barWidth: isTablet ? 42 : 28,
  };
}
