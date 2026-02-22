import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  StyleSheet,
  TouchableOpacity,
  Pressable,
  Dimensions,
} from 'react-native';
import { colors } from '../theme';

interface MathProblem {
  equation: string;
  answer: number;
}

const generateProblem = (): MathProblem => {
  const operations = [
    () => {
      const b = [2, 4, 8, 12][Math.floor(Math.random() * 4)];
      const a = b * (Math.floor(Math.random() * 10) + 5);
      const c = Math.floor(Math.random() * 15) + 5;
      const d = Math.floor(Math.random() * 50) + 10;
      const answer = Math.round((a / b) * c + d);
      return { equation: `(${a} / ${b}) * ${c} + ${d} = ?`, answer };
    },
    () => {
      const a = Math.floor(Math.random() * 15) + 5;
      const b = Math.floor(Math.random() * 12) + 4;
      const c = Math.floor(Math.random() * 30) + 10;
      const d = Math.floor(Math.random() * 25) + 5;
      const answer = a * b - c + d;
      return { equation: `${a} * ${b} - ${c} + ${d} = ?`, answer };
    },
    () => {
      const a = Math.floor(Math.random() * 20) + 10;
      const b = Math.floor(Math.random() * 20) + 10;
      const c = Math.floor(Math.random() * 8) + 3;
      const d = Math.floor(Math.random() * 40) + 20;
      const answer = (a + b) * c - d;
      return { equation: `(${a} + ${b}) * ${c} - ${d} = ?`, answer };
    },
  ];
  const op = operations[Math.floor(Math.random() * operations.length)];
  return op();
};

export function MathChallenge({
  onCorrect,
  onAddTime,
}: {
  onCorrect: () => void;
  onAddTime: (minutes: number) => void;
}) {
  const [problem, setProblem] = useState<MathProblem>(generateProblem);
  const [input, setInput] = useState('');
  const [error, setError] = useState(false);
  const [showError, setShowError] = useState(false);

  useEffect(() => {
    if (error) {
      setShowError(true);
      const t = setTimeout(() => {
        setShowError(false);
        setError(false);
      }, 1000);
      return () => clearTimeout(t);
    }
  }, [error]);

  const handleKeyPress = (key: string) => {
    if (key === 'DEL') {
      setInput((i) => i.slice(0, -1));
    } else if (key === '-' && input === '') {
      setInput('-');
    } else if (key !== '-') {
      setInput((i) => i + key);
    }
  };

  const handleSubmit = () => {
    const userAnswer = parseInt(input, 10);
    if (isNaN(userAnswer) || userAnswer !== problem.answer) {
      onAddTime(5);
      setError(true);
      setInput('');
      setProblem(generateProblem());
    } else {
      onCorrect();
    }
  };

  return (
    <View style={[styles.container, showError && styles.containerError]}>
      {/* Header */}
      <View style={styles.header}>
        <Text style={styles.headerTitle}>PROVE YOU NEED IT.</Text>
      </View>

      <View style={styles.body}>
        {showError && (
          <View style={styles.errorBox}>
            <Text style={styles.errorText}>ACCESS DENIED. +5 MINS ADDED TO TIMER.</Text>
          </View>
        )}

        {/* Problem */}
        <View style={styles.problemBox}>
          <Text style={styles.problemText}>{problem.equation}</Text>
        </View>

        {/* Input */}
        <View style={styles.inputBox}>
          <Text style={styles.inputText}>
            {input}
            <Text style={styles.cursor}>_</Text>
          </Text>
        </View>
      </View>

      {/* Keypad */}
      <View style={styles.keypad}>
        {['7', '8', '9'].map((key) => (
          <TouchableOpacity key={key} style={styles.keypadButton} onPress={() => handleKeyPress(key)} activeOpacity={0.7}>
            <Text style={styles.keypadButtonText}>{key}</Text>
          </TouchableOpacity>
        ))}
        {['4', '5', '6'].map((key) => (
          <TouchableOpacity key={key} style={styles.keypadButton} onPress={() => handleKeyPress(key)} activeOpacity={0.7}>
            <Text style={styles.keypadButtonText}>{key}</Text>
          </TouchableOpacity>
        ))}
        {['1', '2', '3'].map((key) => (
          <TouchableOpacity key={key} style={styles.keypadButton} onPress={() => handleKeyPress(key)} activeOpacity={0.7}>
            <Text style={styles.keypadButtonText}>{key}</Text>
          </TouchableOpacity>
        ))}
        {['-', '0', 'DEL'].map((key) => (
          <TouchableOpacity key={key} style={styles.keypadButton} onPress={() => handleKeyPress(key)} activeOpacity={0.7}>
            <Text style={styles.keypadButtonText}>{key}</Text>
          </TouchableOpacity>
        ))}
      </View>

      {/* Submit */}
      <Pressable
        style={[styles.submitButton, input === '' && styles.submitButtonDisabled]}
        onPress={handleSubmit}
        disabled={input === ''}
      >
        <Text style={[styles.submitButtonText, input === '' && styles.submitButtonTextDisabled]}>
          SUBMIT ANSWER
        </Text>
      </Pressable>
    </View>
  );
}

const { width } = Dimensions.get('window');
const keypadGap = 12;
const keypadPadding = 24;
const keypadButtonSize = (width - keypadPadding * 2 - keypadGap * 2) / 3;

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.brutalBlack,
  },
  containerError: {
    backgroundColor: colors.destructive,
  },
  header: {
    borderBottomWidth: 4,
    borderBottomColor: colors.brutalOffWhite,
    padding: 24,
  },
  headerTitle: {
    fontSize: 24,
    color: colors.brutalOffWhite,
    fontFamily: 'SpaceMono_700Bold',
    letterSpacing: -0.5,
    textAlign: 'center',
  },
  body: {
    flex: 1,
    padding: 24,
  },
  errorBox: {
    marginBottom: 16,
    padding: 16,
    borderWidth: 4,
    borderColor: colors.brutalOffWhite,
    backgroundColor: colors.brutalBlack,
  },
  errorText: {
    color: colors.brutalOffWhite,
    fontSize: 14,
    fontFamily: 'SpaceMono_700Bold',
    textAlign: 'center',
  },
  problemBox: {
    marginBottom: 32,
    padding: 32,
    borderWidth: 4,
    borderColor: colors.brutalOffWhite,
    backgroundColor: colors.brutalDarkGrey,
  },
  problemText: {
    fontSize: 28,
    color: colors.brutalOffWhite,
    fontFamily: 'SpaceMono_700Bold',
    textAlign: 'center',
  },
  inputBox: {
    marginBottom: 32,
    padding: 24,
    borderWidth: 4,
    borderColor: colors.brutalOffWhite,
    backgroundColor: colors.brutalDarkGrey,
    minHeight: 80,
    justifyContent: 'center',
  },
  inputText: {
    fontSize: 40,
    color: colors.brutalAcidGreen,
    fontFamily: 'SpaceMono_700Bold',
    textAlign: 'center',
  },
  cursor: {
    opacity: 0.8,
  },
  keypad: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    paddingHorizontal: 24,
    marginBottom: 16,
    gap: keypadGap,
  },
  keypadButton: {
    width: keypadButtonSize,
    height: 56,
    borderWidth: 4,
    borderColor: colors.brutalOffWhite,
    backgroundColor: colors.brutalDarkGrey,
    alignItems: 'center',
    justifyContent: 'center',
  },
  keypadButtonText: {
    fontSize: 22,
    color: colors.brutalOffWhite,
    fontFamily: 'SpaceMono_700Bold',
  },
  submitButton: {
    marginHorizontal: 24,
    marginBottom: 32,
    paddingVertical: 24,
    borderWidth: 4,
    borderColor: colors.brutalOffWhite,
    backgroundColor: colors.brutalAcidGreen,
    alignItems: 'center',
    justifyContent: 'center',
  },
  submitButtonDisabled: {
    backgroundColor: colors.muted,
    borderColor: colors.borderDisabled,
  },
  submitButtonText: {
    color: colors.brutalBlack,
    fontSize: 16,
    fontFamily: 'SpaceMono_700Bold',
  },
  submitButtonTextDisabled: {
    color: colors.borderDisabled,
  },
});
