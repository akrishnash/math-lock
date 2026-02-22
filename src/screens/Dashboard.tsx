import React, { useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  TouchableOpacity,
  ScrollView,
  Pressable,
} from 'react-native';
import { Settings } from 'lucide-react-native';
import { colors } from '../theme';

interface AppItem {
  id: string;
  name: string;
  icon: string;
  enabled: boolean;
}

export function Dashboard({
  onStartLockdown,
  onOpenSettings,
}: {
  onStartLockdown: (hours: number, minutes: number, apps: AppItem[]) => void;
  onOpenSettings?: () => void;
}) {
  const [hours, setHours] = useState(2);
  const [minutes, setMinutes] = useState(0);
  const [apps, setApps] = useState<AppItem[]>([
    { id: 'tiktok', name: 'TikTok', icon: '📱', enabled: true },
    { id: 'instagram', name: 'Instagram', icon: '📷', enabled: true },
    { id: 'reddit', name: 'Reddit', icon: '🗨️', enabled: false },
    { id: 'youtube', name: 'YouTube', icon: '▶️', enabled: false },
  ]);

  const toggleApp = (id: string) => {
    setApps((prev) =>
      prev.map((app) => (app.id === id ? { ...app, enabled: !app.enabled } : app))
    );
  };

  const startLockdown = () => {
    const totalSeconds = hours * 3600 + minutes * 60;
    if (totalSeconds === 0) return;
    const enabledApps = apps.filter((a) => a.enabled);
    if (enabledApps.length === 0) return;
    onStartLockdown(hours, minutes, enabledApps);
  };

  const isDisabled = (hours === 0 && minutes === 0) || apps.every((a) => !a.enabled);

  return (
    <View style={styles.container}>
      {/* Top Nav */}
      <View style={styles.topNav}>
        <Text style={styles.title}>MATH-LOCK</Text>
        <TouchableOpacity onPress={onOpenSettings} hitSlop={12}>
          <Settings size={28} strokeWidth={2.5} color={colors.brutalOffWhite} />
        </TouchableOpacity>
      </View>

      <ScrollView style={styles.scroll} contentContainerStyle={styles.scrollContent} showsVerticalScrollIndicator={false}>
        {/* Time Selector */}
        <View style={styles.timeSection}>
          <Text style={styles.label}>LOCK DURATION</Text>
          <View style={styles.timeRow}>
            {/* Hours */}
            <View style={styles.timeColumn}>
              <TouchableOpacity
                style={styles.timeButton}
                onPress={() => setHours((h) => Math.min(23, h + 1))}
              >
                <Text style={styles.timeButtonText}>▲</Text>
              </TouchableOpacity>
              <Text style={styles.timeDisplay}>{String(hours).padStart(2, '0')}</Text>
              <TouchableOpacity
                style={styles.timeButton}
                onPress={() => setHours((h) => Math.max(0, h - 1))}
              >
                <Text style={styles.timeButtonText}>▼</Text>
              </TouchableOpacity>
              <Text style={styles.timeUnit}>HOURS</Text>
            </View>

            <Text style={styles.timeColon}>:</Text>

            {/* Minutes */}
            <View style={styles.timeColumn}>
              <TouchableOpacity
                style={styles.timeButton}
                onPress={() => setMinutes((m) => Math.min(59, m + 5))}
              >
                <Text style={styles.timeButtonText}>▲</Text>
              </TouchableOpacity>
              <Text style={styles.timeDisplay}>{String(minutes).padStart(2, '0')}</Text>
              <TouchableOpacity
                style={styles.timeButton}
                onPress={() => setMinutes((m) => Math.max(0, m - 5))}
              >
                <Text style={styles.timeButtonText}>▼</Text>
              </TouchableOpacity>
              <Text style={styles.timeUnit}>MINUTES</Text>
            </View>
          </View>
        </View>

        {/* Apps to Block */}
        <View style={styles.appsSection}>
          <Text style={styles.appsLabel}>THE ENEMY (Apps to Block)</Text>
          {apps.map((app) => (
            <View key={app.id} style={styles.appCard}>
              <View style={styles.appInfo}>
                <Text style={styles.appIcon}>{app.icon}</Text>
                <Text style={styles.appName}>{app.name}</Text>
              </View>
              <Pressable
                style={[styles.toggle, app.enabled && styles.toggleOn]}
                onPress={() => toggleApp(app.id)}
              >
                <View
                  style={[
                    styles.toggleKnob,
                    app.enabled ? styles.toggleKnobRight : styles.toggleKnobLeft,
                  ]}
                />
              </Pressable>
            </View>
          ))}
        </View>

        {/* Lockdown Button */}
        <Pressable
          style={[styles.lockdownButton, isDisabled && styles.lockdownButtonDisabled]}
          onPress={startLockdown}
          disabled={isDisabled}
        >
          <Text style={[styles.lockdownButtonText, isDisabled && styles.lockdownButtonTextDisabled]}>
            INITIATE LOCKDOWN
          </Text>
        </Pressable>
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.brutalBlack,
  },
  topNav: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    padding: 24,
    borderBottomWidth: 4,
    borderBottomColor: colors.brutalOffWhite,
  },
  title: {
    color: colors.brutalOffWhite,
    fontSize: 20,
    fontFamily: 'SpaceMono_700Bold',
    letterSpacing: -0.5,
  },
  scroll: {
    flex: 1,
  },
  scrollContent: {
    padding: 24,
    paddingBottom: 48,
  },
  timeSection: {
    alignItems: 'center',
    marginBottom: 32,
  },
  label: {
    color: colors.brutalOffWhite,
    fontSize: 14,
    fontFamily: 'Inter_400Regular',
    letterSpacing: 2,
    marginBottom: 16,
  },
  timeRow: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  timeColumn: {
    alignItems: 'center',
  },
  timeButton: {
    width: 64,
    height: 64,
    borderWidth: 4,
    borderColor: colors.brutalOffWhite,
    alignItems: 'center',
    justifyContent: 'center',
  },
  timeButtonText: {
    color: colors.brutalOffWhite,
    fontSize: 20,
  },
  timeDisplay: {
    fontSize: 72,
    color: colors.brutalOffWhite,
    fontFamily: 'SpaceMono_700Bold',
    marginVertical: 16,
  },
  timeUnit: {
    color: colors.brutalOffWhite,
    fontSize: 12,
    fontFamily: 'Inter_400Regular',
  },
  timeColon: {
    fontSize: 72,
    color: colors.brutalOffWhite,
    fontFamily: 'SpaceMono_700Bold',
    marginHorizontal: 16,
    marginBottom: 48,
  },
  appsSection: {
    marginBottom: 24,
  },
  appsLabel: {
    color: colors.brutalOffWhite,
    fontSize: 14,
    fontFamily: 'SpaceMono_700Bold',
    letterSpacing: 2,
    marginBottom: 16,
  },
  appCard: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    padding: 16,
    borderWidth: 4,
    borderColor: colors.brutalOffWhite,
    backgroundColor: colors.brutalDarkGrey,
    marginBottom: 12,
  },
  appInfo: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
  },
  appIcon: {
    fontSize: 24,
    opacity: 0.9,
  },
  appName: {
    color: colors.brutalOffWhite,
    fontSize: 16,
    fontFamily: 'Inter_400Regular',
  },
  toggle: {
    width: 64,
    height: 32,
    borderWidth: 4,
    borderColor: colors.brutalOffWhite,
    backgroundColor: colors.switchBg,
    justifyContent: 'center',
  },
  toggleOn: {
    backgroundColor: colors.brutalAcidGreen,
  },
  toggleKnob: {
    position: 'absolute',
    top: 0,
    bottom: 0,
    width: 24,
    borderWidth: 2,
    borderColor: colors.brutalOffWhite,
    backgroundColor: colors.brutalBlack,
  },
  toggleKnobLeft: { left: 0 },
  toggleKnobRight: { right: 0 },
  lockdownButton: {
    paddingVertical: 24,
    borderWidth: 4,
    borderColor: colors.brutalOffWhite,
    backgroundColor: colors.brutalAcidGreen,
    alignItems: 'center',
    justifyContent: 'center',
  },
  lockdownButtonDisabled: {
    backgroundColor: colors.muted,
    borderColor: colors.borderDisabled,
  },
  lockdownButtonText: {
    color: colors.brutalBlack,
    fontSize: 16,
    fontFamily: 'SpaceMono_700Bold',
  },
  lockdownButtonTextDisabled: {
    color: colors.borderDisabled,
  },
});
