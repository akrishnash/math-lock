import React, { useEffect, useState } from 'react';
import { View, Text, StyleSheet, TouchableOpacity } from 'react-native';
import { Lock } from 'lucide-react-native';
import { colors } from '../theme';

export function Intervention({
  timeRemaining,
  onDesperate,
}: {
  timeRemaining: string;
  onDesperate: () => void;
}) {
  return (
    <View style={styles.container}>
      <View style={styles.content}>
        <View style={styles.iconWrap}>
          <Lock size={120} strokeWidth={3} color={colors.brutalOffWhite} />
        </View>

        <Text style={styles.title}>NICE TRY.</Text>

        <Text style={styles.subtitle}>Time remaining:</Text>
        <Text style={styles.timer}>{timeRemaining}</Text>

        <Text style={styles.message}>
          Go do something productive. Read a book. Touch grass. Your choice.
        </Text>
      </View>

      <TouchableOpacity style={styles.desperateButton} onPress={onDesperate} activeOpacity={0.8}>
        <Text style={styles.desperateButtonText}>
          I'm desperate. Let me do math for 60s access.
        </Text>
      </TouchableOpacity>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.brutalBlack,
    padding: 24,
    justifyContent: 'space-between',
  },
  content: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
  iconWrap: {
    marginBottom: 32,
  },
  title: {
    fontSize: 48,
    color: colors.brutalOffWhite,
    fontFamily: 'SpaceMono_700Bold',
    letterSpacing: -1,
    marginBottom: 24,
    textAlign: 'center',
  },
  subtitle: {
    fontSize: 20,
    color: colors.brutalOffWhite,
    fontFamily: 'Inter_400Regular',
    marginBottom: 8,
    textAlign: 'center',
  },
  timer: {
    fontSize: 36,
    color: colors.brutalAcidGreen,
    fontFamily: 'SpaceMono_700Bold',
    marginBottom: 48,
    textAlign: 'center',
  },
  message: {
    fontSize: 16,
    color: colors.mutedForeground,
    fontFamily: 'Inter_400Regular',
    textAlign: 'center',
    maxWidth: 280,
  },
  desperateButton: {
    paddingVertical: 16,
    borderWidth: 2,
    borderColor: colors.borderDisabled,
    backgroundColor: colors.muted,
    alignItems: 'center',
    justifyContent: 'center',
  },
  desperateButtonText: {
    color: colors.mutedForeground,
    fontSize: 14,
    fontFamily: 'Inter_400Regular',
  },
});
