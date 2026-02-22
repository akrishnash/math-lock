import { NativeModules, Platform } from 'react-native';

const { AppBlocking } = NativeModules;

if (!AppBlocking && Platform.OS === 'android') {
  console.warn('AppBlocking native module not available (use development build)');
}

export const appBlocking = AppBlocking
  ? {
      checkUsagePermission: (): Promise<boolean> =>
        AppBlocking.checkUsagePermission(),
      openUsageAccessSettings: (): Promise<void> =>
        AppBlocking.openUsageAccessSettings(),
      openBatteryOptimizationSettings: (): Promise<void> =>
        AppBlocking.openBatteryOptimizationSettings(),
      startBlockingService: (packages: string[]): Promise<void> =>
        AppBlocking.startBlockingService(packages),
      stopBlockingService: (): Promise<void> =>
        AppBlocking.stopBlockingService(),
    }
  : null;

/** Maps app IDs from our UI to Android package names (include variants) */
export const APP_PACKAGES: Record<string, string> = {
  tiktok: 'com.zhiliaoapp.musically',
  instagram: 'com.instagram.android',
  reddit: 'com.reddit.frontpage',
  youtube: 'com.google.android.youtube',
};

/** All package variants to block (main + alternate package names) */
export const APP_PACKAGE_ALIASES: Record<string, string[]> = {
  instagram: ['com.instagram.android', 'com.instagram.lite'],
  tiktok: ['com.zhiliaoapp.musically', 'com.ss.android.ugc.trill'],
  reddit: ['com.reddit.frontpage'],
  youtube: ['com.google.android.youtube', 'com.google.android.youtube.tv'],
};
