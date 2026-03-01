import { useState, useEffect } from "react";
import { useNavigate } from "react-router";
import type { AppSettings } from "./Settings";

interface MathProblem {
  equation: string;
  answer: number;
}

const defaultSettings: AppSettings = {
  questionTopic: 'mixed',
  difficulty: 'medium',
  penaltyMinutes: 5,
  rewardSeconds: 60,
  accentColor: 'pink',
  enableSounds: false,
  enableVibration: true,
};

const generateArithmeticProblem = (difficulty: string): MathProblem => {
  if (difficulty === 'easy') {
    const a = Math.floor(Math.random() * 20) + 5;
    const b = Math.floor(Math.random() * 20) + 5;
    const answer = a + b;
    return { equation: `${a} + ${b} = ?`, answer };
  } else if (difficulty === 'medium') {
    const b = [2, 4, 5, 8, 10][Math.floor(Math.random() * 5)];
    const a = b * (Math.floor(Math.random() * 10) + 5);
    const c = Math.floor(Math.random() * 15) + 5;
    const d = Math.floor(Math.random() * 30) + 10;
    const answer = (a / b) * c + d;
    return { equation: `(${a} / ${b}) * ${c} + ${d} = ?`, answer };
  } else {
    const a = Math.floor(Math.random() * 25) + 15;
    const b = Math.floor(Math.random() * 15) + 8;
    const c = Math.floor(Math.random() * 12) + 5;
    const d = Math.floor(Math.random() * 40) + 20;
    const answer = a * b - c * d;
    return { equation: `${a} * ${b} - ${c} * ${d} = ?`, answer };
  }
};

const generateAlgebraProblem = (difficulty: string): MathProblem => {
  if (difficulty === 'easy') {
    const x = Math.floor(Math.random() * 15) + 5;
    const b = Math.floor(Math.random() * 20) + 5;
    const answer = x;
    return { equation: `x + ${b} = ${x + b}, x = ?`, answer };
  } else if (difficulty === 'medium') {
    const x = Math.floor(Math.random() * 12) + 3;
    const a = Math.floor(Math.random() * 8) + 2;
    const b = Math.floor(Math.random() * 20) + 5;
    const answer = x;
    return { equation: `${a}x + ${b} = ${a * x + b}, x = ?`, answer };
  } else {
    const x = Math.floor(Math.random() * 15) + 5;
    const a = Math.floor(Math.random() * 6) + 3;
    const b = Math.floor(Math.random() * 10) + 5;
    const c = Math.floor(Math.random() * 15) + 10;
    const answer = x;
    return { equation: `${a}x - ${b} = ${a * x - b}, x = ?`, answer };
  }
};

const generateGeometryProblem = (difficulty: string): MathProblem => {
  if (difficulty === 'easy') {
    const side = Math.floor(Math.random() * 10) + 5;
    const answer = side * side;
    return { equation: `Area of square (side=${side}) = ?`, answer };
  } else if (difficulty === 'medium') {
    const length = Math.floor(Math.random() * 12) + 5;
    const width = Math.floor(Math.random() * 10) + 4;
    const answer = 2 * (length + width);
    return { equation: `Perimeter of rectangle (L=${length}, W=${width}) = ?`, answer };
  } else {
    const radius = Math.floor(Math.random() * 8) + 3;
    const answer = Math.round(Math.PI * radius * radius);
    return { equation: `Area of circle (r=${radius}, π≈3.14) = ?`, answer };
  }
};

const generateProblem = (topic: string, difficulty: string): MathProblem => {
  if (topic === 'arithmetic') {
    return generateArithmeticProblem(difficulty);
  } else if (topic === 'algebra') {
    return generateAlgebraProblem(difficulty);
  } else if (topic === 'geometry') {
    return generateGeometryProblem(difficulty);
  } else {
    // Mixed - random selection
    const topics = ['arithmetic', 'algebra', 'geometry'];
    const randomTopic = topics[Math.floor(Math.random() * topics.length)];
    return generateProblem(randomTopic, difficulty);
  }
};

const colorMap = {
  pink: '#FF006E',
  cyan: '#00F5FF',
  purple: '#B537FF',
  yellow: '#FFD60A',
  green: '#39FF14',
};

export function MathChallenge() {
  const navigate = useNavigate();
  const [settings, setSettings] = useState<AppSettings>(defaultSettings);
  const [problem, setProblem] = useState<MathProblem>(() => generateProblem('mixed', 'medium'));
  const [input, setInput] = useState("");
  const [error, setError] = useState(false);
  const [showError, setShowError] = useState(false);

  useEffect(() => {
    const saved = localStorage.getItem('mathLockSettings');
    if (saved) {
      const loadedSettings = JSON.parse(saved);
      setSettings(loadedSettings);
      setProblem(generateProblem(loadedSettings.questionTopic, loadedSettings.difficulty));
    }
  }, []);

  useEffect(() => {
    if (error) {
      setShowError(true);
      
      // Vibration feedback
      if (settings.enableVibration && 'vibrate' in navigator) {
        navigator.vibrate([200, 100, 200]);
      }
      
      const timer = setTimeout(() => {
        setShowError(false);
        setError(false);
      }, 1000);
      return () => clearTimeout(timer);
    }
  }, [error, settings.enableVibration]);

  const handleKeyPress = (key: string) => {
    if (key === "DEL") {
      setInput(input.slice(0, -1));
    } else if (key === "-" && input === "") {
      setInput("-");
    } else if (key !== "-") {
      setInput(input + key);
    }
  };

  const handleSubmit = () => {
    const userAnswer = parseInt(input);
    
    if (isNaN(userAnswer) || userAnswer !== problem.answer) {
      // Wrong answer - add penalty minutes to timer
      const lockdownEnd = localStorage.getItem('lockdownEnd');
      if (lockdownEnd) {
        const newEnd = parseInt(lockdownEnd) + (settings.penaltyMinutes * 60 * 1000);
        localStorage.setItem('lockdownEnd', newEnd.toString());
      }
      
      setError(true);
      setInput("");
      setProblem(generateProblem(settings.questionTopic, settings.difficulty));
    } else {
      // Correct answer - grant reward seconds of access
      if (settings.enableVibration && 'vibrate' in navigator) {
        navigator.vibrate(500);
      }
      
      localStorage.removeItem('lockdownEnd');
      localStorage.removeItem('lockedApps');
      
      // Set a temporary unlock
      const tempEnd = Date.now() + (settings.rewardSeconds * 1000);
      localStorage.setItem('tempUnlock', tempEnd.toString());
      
      navigate('/');
    }
  };

  const accentColor = colorMap[settings.accentColor];

  return (
    <div className={`min-h-screen flex flex-col max-w-md mx-auto transition-colors duration-200 ${
      showError ? 'bg-[#ff1744]' : 'bg-[#0a0a0f]'
    }`}>
      {/* Header */}
      <div className="border-b-4 border-[#F0F0F0] p-6">
        <h2 
          className="text-2xl text-[#F0F0F0] tracking-tight text-center"
          style={{ fontFamily: 'var(--font-mono)' }}
        >
          PROVE YOU NEED IT.
        </h2>
      </div>

      <div className="flex-1 flex flex-col p-6">
        {/* Error Message */}
        {showError && (
          <div 
            className="mb-4 p-4 border-4 border-[#F0F0F0] bg-[#0a0a0f] text-[#F0F0F0] text-center animate-pulse"
            style={{ fontFamily: 'var(--font-mono)' }}
          >
            ACCESS DENIED. +{settings.penaltyMinutes} MINS ADDED TO TIMER.
          </div>
        )}

        {/* Problem Display */}
        <div className="flex-1 flex items-center justify-center">
          <div className="w-full">
            <div className="mb-8 p-8 border-4 border-[#F0F0F0] bg-[#16161d]">
              <div 
                className="text-3xl text-[#F0F0F0] text-center break-words"
                style={{ fontFamily: 'var(--font-mono)' }}
              >
                {problem.equation}
              </div>
            </div>

            {/* Input Field */}
            <div className="mb-8 p-6 border-4 border-[#F0F0F0] bg-[#16161d]">
              <div 
                className="text-5xl text-center min-h-[60px] flex items-center justify-center tabular-nums"
                style={{ fontFamily: 'var(--font-mono)', color: accentColor }}
              >
                {input}
                <span className="animate-pulse ml-1">_</span>
              </div>
            </div>
          </div>
        </div>

        {/* Numeric Keypad */}
        <div className="grid grid-cols-3 gap-3 mb-4">
          {['7', '8', '9', '4', '5', '6', '1', '2', '3', '-', '0', 'DEL'].map((key) => (
            <button
              key={key}
              onClick={() => handleKeyPress(key)}
              className="h-16 border-4 border-[#F0F0F0] bg-[#16161d] text-[#F0F0F0] hover:text-[#0a0a0f] transition-colors text-2xl"
              style={{ 
                fontFamily: 'var(--font-mono)',
                backgroundColor: key === 'DEL' ? '#16161d' : undefined
              }}
              onMouseEnter={(e) => {
                if (key !== 'DEL') {
                  e.currentTarget.style.backgroundColor = accentColor;
                } else {
                  e.currentTarget.style.backgroundColor = '#ff1744';
                }
              }}
              onMouseLeave={(e) => {
                e.currentTarget.style.backgroundColor = '#16161d';
              }}
            >
              {key}
            </button>
          ))}
        </div>

        {/* Submit Button */}
        <button
          onClick={handleSubmit}
          disabled={input === ""}
          className="w-full py-6 border-4 border-[#F0F0F0] text-[#0a0a0f] hover:opacity-90 disabled:bg-[#1f1f2a] disabled:text-[#505050] disabled:border-[#505050] disabled:cursor-not-allowed transition-all"
          style={{ 
            fontFamily: 'var(--font-mono)',
            backgroundColor: input === "" ? undefined : accentColor
          }}
        >
          SUBMIT ANSWER
        </button>
      </div>
    </div>
  );
}
