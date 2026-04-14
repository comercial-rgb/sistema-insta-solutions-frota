import React, { useRef, useState, useEffect } from 'react';
import {
  View,
  Text,
  ScrollView,
  StyleSheet,
  Dimensions,
  Image,
  TouchableOpacity,
  Linking,
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { colors, spacing, borderRadius, fontSize, shadows } from '../theme/colors';
import { MobileBanner } from '../types';

const { width: SCREEN_WIDTH } = Dimensions.get('window');
const CARD_WIDTH = SCREEN_WIDTH - spacing.md * 2;
const CARD_MARGIN = spacing.sm;

const TYPE_CONFIG: Record<string, { icon: string; color: string; label: string }> = {
  tip: { icon: 'bulb-outline', color: colors.warning, label: 'Dica' },
  ad: { icon: 'megaphone-outline', color: colors.primary, label: 'Publicidade' },
  instruction: { icon: 'book-outline', color: colors.info, label: 'Instrução' },
  news: { icon: 'newspaper-outline', color: colors.success, label: 'Novidade' },
};

interface Props {
  banners: MobileBanner[];
}

export default function BannerCarousel({ banners }: Props) {
  const scrollRef = useRef<ScrollView>(null);
  const [activeIndex, setActiveIndex] = useState(0);
  const timerRef = useRef<ReturnType<typeof setInterval> | null>(null);

  useEffect(() => {
    if (banners.length <= 1) return;
    timerRef.current = setInterval(() => {
      setActiveIndex((prev) => {
        const next = (prev + 1) % banners.length;
        scrollRef.current?.scrollTo({ x: next * (CARD_WIDTH + CARD_MARGIN), animated: true });
        return next;
      });
    }, 5000);
    return () => {
      if (timerRef.current) clearInterval(timerRef.current);
    };
  }, [banners.length]);

  const handleScroll = (event: any) => {
    const offsetX = event.nativeEvent.contentOffset.x;
    const index = Math.round(offsetX / (CARD_WIDTH + CARD_MARGIN));
    if (index !== activeIndex) {
      setActiveIndex(index);
    }
  };

  const handleDocPress = (url: string | null) => {
    if (url) {
      Linking.openURL(url).catch(() => {});
    }
  };

  if (!banners || banners.length === 0) return null;

  return (
    <View style={styles.container}>
      <ScrollView
        ref={scrollRef}
        horizontal
        pagingEnabled={false}
        snapToInterval={CARD_WIDTH + CARD_MARGIN}
        snapToAlignment="start"
        decelerationRate="fast"
        showsHorizontalScrollIndicator={false}
        onScroll={handleScroll}
        scrollEventThrottle={16}
        contentContainerStyle={styles.scrollContent}
        onScrollBeginDrag={() => {
          if (timerRef.current) clearInterval(timerRef.current);
        }}
      >
        {banners.map((banner, index) => {
          const config = TYPE_CONFIG[banner.type] || TYPE_CONFIG.tip;
          return (
            <TouchableOpacity
              key={banner.id}
              style={[styles.card, { width: CARD_WIDTH }]}
              activeOpacity={banner.document_url ? 0.7 : 1}
              onPress={() => handleDocPress(banner.document_url)}
            >
              {banner.image_url ? (
                <Image source={{ uri: banner.image_url }} style={styles.cardImage} resizeMode="cover" />
              ) : (
                <View style={[styles.cardGradient, { backgroundColor: config.color + '15' }]}>
                  <Ionicons name={config.icon as any} size={40} color={config.color} />
                </View>
              )}
              <View style={styles.cardBody}>
                <View style={styles.cardBadgeRow}>
                  <View style={[styles.typeBadge, { backgroundColor: config.color + '18' }]}>
                    <Ionicons name={config.icon as any} size={12} color={config.color} />
                    <Text style={[styles.typeBadgeText, { color: config.color }]}>{config.label}</Text>
                  </View>
                </View>
                <Text style={styles.cardTitle} numberOfLines={2}>{banner.title}</Text>
                <Text style={styles.cardText} numberOfLines={3}>{banner.text}</Text>
                {banner.document_url && (
                  <View style={styles.linkRow}>
                    <Ionicons name="document-text-outline" size={14} color={colors.primary} />
                    <Text style={styles.linkText}>Ver documento</Text>
                  </View>
                )}
              </View>
            </TouchableOpacity>
          );
        })}
      </ScrollView>

      {/* Dots */}
      {banners.length > 1 && (
        <View style={styles.dotsRow}>
          {banners.map((_, index) => (
            <View
              key={index}
              style={[
                styles.dot,
                index === activeIndex && styles.dotActive,
              ]}
            />
          ))}
        </View>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    marginBottom: spacing.sm,
  },
  scrollContent: {
    paddingHorizontal: spacing.md,
    gap: CARD_MARGIN,
  },
  card: {
    backgroundColor: colors.surface,
    borderRadius: borderRadius.md,
    overflow: 'hidden',
    ...shadows.sm,
  },
  cardImage: {
    width: '100%',
    height: 120,
  },
  cardGradient: {
    height: 90,
    justifyContent: 'center',
    alignItems: 'center',
  },
  cardBody: {
    padding: spacing.md,
  },
  cardBadgeRow: {
    flexDirection: 'row',
    marginBottom: spacing.xs,
  },
  typeBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    paddingHorizontal: spacing.sm,
    paddingVertical: 2,
    borderRadius: borderRadius.full,
  },
  typeBadgeText: {
    fontSize: fontSize.xs,
    fontWeight: '600',
  },
  cardTitle: {
    fontSize: fontSize.md,
    fontWeight: '700',
    color: colors.text,
    marginBottom: 4,
  },
  cardText: {
    fontSize: fontSize.sm,
    color: colors.textSecondary,
    lineHeight: 18,
  },
  linkRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    marginTop: spacing.sm,
  },
  linkText: {
    fontSize: fontSize.xs,
    color: colors.primary,
    fontWeight: '600',
  },
  dotsRow: {
    flexDirection: 'row',
    justifyContent: 'center',
    gap: 6,
    marginTop: spacing.sm,
  },
  dot: {
    width: 6,
    height: 6,
    borderRadius: 3,
    backgroundColor: colors.disabled,
  },
  dotActive: {
    width: 18,
    backgroundColor: colors.primary,
    borderRadius: 3,
  },
});
