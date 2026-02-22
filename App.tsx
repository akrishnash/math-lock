import React, { useState, useEffect, useCallback } from 'react';
import { StatusBar } from 'expo-status-bar';
import { useFonts, SpaceMono_400Regular, SpaceMono_700Bold } from '@expo-google-fonts/space-mono';
import { Inter_400Regular, Inter_500Medium } from '@expo-google-fonts/inter';
import * as SplashScreen from 'expo-splash-screen';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { AppState, AppStateStatus, Platform, Alert } from 'react-native';
import { SafeAreaProvider } from 'react-native-safe-area-context';
import { activateKeepAwakeAsync, deactivateKeepAwake } from 'expo-keep-awake';
import { Dashboard } from './src/screens/Dashboard';
import { Intervention } from './src/screens/Intervention';
import { MathChallenge } from './src/screens/MathChallenge';
import { appBlocking, APP_PACKAGES, APP_PACKAGE_ALIASES } from './src/native/AppBlocking';

const LOCKDOWN_END_KEY = 'lockdownEnd';
const LOCKED_APPS_KEY = 'lockedApps';

type Screen = 'dashboard' | 'intervention' | 'challenge';

SplashScreen.preventAutoHideAsync();

export default function App() {
  const [screen, setScreen] = useState<Screen>('dashboard');
  const [lockdownEnd, setLockdownEnd] = useState<number | null>(null);
  const [timeRemaining, setTimeRemaining] = useState('');

  const [fontsLoaded] = useFonts({
    SpaceMono_400Regular,
    SpaceMono_700Bold,
    Inter_400Regular,
    Inter_500Medium,
  });

  const updateTimer = useCallback((end: number) => {
    const now = Date.now();
    const diff = end - now;
    if (diff <= 0) {
      return false;
    }
    const hours = Math.floor(diff / (1000 * 60 * 60));
    const minutes = Math.floor((diff % (1000 * 60 * 60)) / (1000 * 60));
    const seconds = Math.floor((diff % (1000 * 60)) / 1000);
    setTimeRemaining(`${hours}h ${minutes}m ${seconds}s`);
    return true;
  }, []);

  useEffect(() => {
    const load = async () => {
      const stored = await AsyncStorage.getItem(LOCKDOWN_END_KEY);
      const lockedJson = await AsyncStorage.getItem(LOCKED_APPS_KEY);
      if (stored) {
        const end = parseInt(stored, 10);
        if (end > Date.now()) {
          setLockdownEnd(end);
          setScreen('intervention');
          if (Platform.OS === 'android' && appBlocking && lockedJson) {
            try {
              const apps = JSON.parse(lockedJson) as { id: string }[];
              const packageIds = apps.flatMap((a) => {
              const aliases = APP_PACKAGE_ALIASES[a.id];
              return aliases ?? (APP_PACKAGES[a.id] ? [APP_PACKAGES[a.id]] : []);
            });
              if (packageIds.length > 0) {
                await appBlocking.startBlockingService(packageIds);
              }
            } catch (_) {}
          }
        } else {
          await AsyncStorage.multiRemove([LOCKDOWN_END_KEY, LOCKED_APPS_KEY]);
          if (Platform.OS === 'android' && appBlocking) {
            await appBlocking.stopBlockingService();
          }
        }
      }
    };
    load();
  }, []);

  useEffect(() => {
    if (screen === 'intervention') {
      activateKeepAwakeAsync();
      return () => deactivateKeepAwake();
    }
  }, [screen]);

  const endLockdown = useCallback(async () => {
    if (Platform.OS === 'android' && appBlocking) {
      await appBlocking.stopBlockingService();
    }
    await AsyncStorage.multiRemove([LOCKDOWN_END_KEY, LOCKED_APPS_KEY]);
    setLockdownEnd(null);
    setScreen('dashboard');
  }, []);

  useEffect(() => {
    if (!lockdownEnd || screen !== 'intervention') return;
    const tick = () => {
      if (!updateTimer(lockdownEnd)) {
        endLockdown();
      }
    };
    tick();
    const interval = setInterval(tick, 1000);
    return () => clearInterval(interval);
  }, [lockdownEnd, screen, updateTimer, endLockdown]);

  useEffect(() => {
    if (lockdownEnd && screen === 'intervention') {
      const sub = AppState.addEventListener('change', (state: AppStateStatus) => {
        if (state === 'active') {
          AsyncStorage.getItem(LOCKDOWN_END_KEY).then((stored) => {
            if (stored) {
              const end = parseInt(stored, 10);
              setLockdownEnd(end);
              setScreen('intervention');
            }
          });
        }
      });
      return () => sub.remove();
    }
  }, [lockdownEnd, screen]);

  useEffect(() => {
    if (fontsLoaded) SplashScreen.hideAsync();
  }, [fontsLoaded]);

  const handleStartLockdown = useCallback(
    async (hours: number, minutes: number, apps: { id: string; enabled: boolean }[]) => {
      const totalSeconds = hours * 3600 + minutes * 60;
      const end = Date.now() + totalSeconds * 1000;
      const enabledApps = apps.filter((a) => a.enabled);
      const packageIds = enabledApps.flatMap((a) => {
        const aliases = APP_PACKAGE_ALIASES[a.id];
        return aliases ?? (APP_PACKAGES[a.id] ? [APP_PACKAGES[a.id]] : []);
      });

      if (Platform.OS === 'android' && appBlocking && packageIds.length > 0) {
        const hasPermission = await appBlocking.checkUsagePermission();
        if (!hasPermission) {
          Alert.alert(
            'Usage Access Required',
            'Math Lock needs Usage Access to block apps. Tap OK to open Settings, enable access for Math Lock, then return and try again.',
            [
              { text: 'Cancel', style: 'cancel' },
              { text: 'OK', onPress: () => appBlocking.openUsageAccessSettings() },
            ]
          );
          return;
        }
        await appBlocking.startBlockingService(packageIds);
      }

      await AsyncStorage.setItem(LOCKDOWN_END_KEY, end.toString());
      await AsyncStorage.setItem(LOCKED_APPS_KEY, JSON.stringify(enabledApps));
      setLockdownEnd(end);
      setScreen('intervention');
    },
    []
  );

  const handleOpenSettings = useCallback(() => {
    if (Platform.OS === 'android' && appBlocking) {
      Alert.alert(
        'App Blocking Settings',
        'If Instagram/other apps aren\'t being blocked, ensure these permissions:',
        [
          { text: 'Cancel', style: 'cancel' },
          { text: 'Usage Access', onPress: () => appBlocking.openUsageAccessSettings() },
          { text: 'Battery (Don\'t optimize)', onPress: () => appBlocking.openBatteryOptimizationSettings() },
        ]
      );
    }
  }, []);

  const handleDesperate = useCallback(() => {
    setScreen('challenge');
  }, []);

  const handleMathCorrect = useCallback(async () => {
    await endLockdown();
  }, [endLockdown]);

  const handleAddTime = useCallback(async (minutes: number) => {
    const stored = await AsyncStorage.getItem(LOCKDOWN_END_KEY);
    if (stored) {
      const end = parseInt(stored, 10) + minutes * 60 * 1000;
      await AsyncStorage.setItem(LOCKDOWN_END_KEY, end.toString());
      setLockdownEnd(end);
    }
  }, []);

  if (!fontsLoaded) return null;

  return (
    <SafeAreaProvider>
      <StatusBar style="light" />
      {screen === 'dashboard' && (
        <Dashboard
          onStartLockdown={handleStartLockdown}
          onOpenSettings={handleOpenSettings}
        />
      )}
      {screen === 'intervention' && (
        <Intervention timeRemaining={timeRemaining} onDesperate={handleDesperate} />
      )}
      {screen === 'challenge' && (
        <MathChallenge onCorrect={handleMathCorrect} onAddTime={handleAddTime} />
      )}
    </SafeAreaProvider>
  );
}
