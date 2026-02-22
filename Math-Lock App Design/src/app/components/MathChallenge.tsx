import { useState, useEffect } from "react";
import { useNavigate } from "react-router";

interface MathProblem {
  equation: string;
  answer: number;
}

const generateProblem = (): MathProblem => {
  const operations = [
    () => {
      // (a / b) * c + d
      const b = [2, 4, 8, 12][Math.floor(Math.random() * 4)];
      const a = b * (Math.floor(Math.random() * 10) + 5);
      const c = Math.floor(Math.random() * 15) + 5;
      const d = Math.floor(Math.random() * 50) + 10;
      const answer = (a / b) * c + d;
      return { equation: `(${a} / ${b}) * ${c} + ${d} = ?`, answer };
    },
    () => {
      // a * b - c + d
      const a = Math.floor(Math.random() * 15) + 5;
      const b = Math.floor(Math.random() * 12) + 4;
      const c = Math.floor(Math.random() * 30) + 10;
      const d = Math.floor(Math.random() * 25) + 5;
      const answer = a * b - c + d;
      return { equation: `${a} * ${b} - ${c} + ${d} = ?`, answer };
    },
    () => {
      // (a + b) * c - d
      const a = Math.floor(Math.random() * 20) + 10;
      const b = Math.floor(Math.random() * 20) + 10;
      const c = Math.floor(Math.random() * 8) + 3;
      const d = Math.floor(Math.random() * 40) + 20;
      const answer = (a + b) * c - d;
      return { equation: `(${a} + ${b}) * ${c} - ${d} = ?`, answer };
    },
  ];

  const operation = operations[Math.floor(Math.random() * operations.length)];
  return operation();
};

export function MathChallenge() {
  const navigate = useNavigate();
  const [problem, setProblem] = useState<MathProblem>(generateProblem());
  const [input, setInput] = useState("");
  const [error, setError] = useState(false);
  const [showError, setShowError] = useState(false);

  useEffect(() => {
    if (error) {
      setShowError(true);
      const timer = setTimeout(() => {
        setShowError(false);
        setError(false);
      }, 1000);
      return () => clearTimeout(timer);
    }
  }, [error]);

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
      // Wrong answer - add 5 minutes to timer
      const lockdownEnd = localStorage.getItem('lockdownEnd');
      if (lockdownEnd) {
        const newEnd = parseInt(lockdownEnd) + (5 * 60 * 1000);
        localStorage.setItem('lockdownEnd', newEnd.toString());
      }
      
      setError(true);
      setInput("");
      setProblem(generateProblem());
    } else {
      // Correct answer - grant 60 seconds of access
      localStorage.removeItem('lockdownEnd');
      localStorage.removeItem('lockedApps');
      
      // Set a new 60-second temporary unlock
      const tempEnd = Date.now() + (60 * 1000);
      localStorage.setItem('tempUnlock', tempEnd.toString());
      
      // Navigate to a success page or back
      navigate('/');
    }
  };

  return (
    <div className={`min-h-screen flex flex-col max-w-md mx-auto transition-colors duration-200 ${
      showError ? 'bg-[#ff1744]' : 'bg-black'
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
            className="mb-4 p-4 border-4 border-[#F0F0F0] bg-black text-[#F0F0F0] text-center animate-pulse"
            style={{ fontFamily: 'var(--font-mono)' }}
          >
            ACCESS DENIED. +5 MINS ADDED TO TIMER.
          </div>
        )}

        {/* Problem Display */}
        <div className="flex-1 flex items-center justify-center">
          <div className="w-full">
            <div className="mb-8 p-8 border-4 border-[#F0F0F0] bg-[#121212]">
              <div 
                className="text-4xl text-[#F0F0F0] text-center break-words"
                style={{ fontFamily: 'var(--font-mono)' }}
              >
                {problem.equation}
              </div>
            </div>

            {/* Input Field */}
            <div className="mb-8 p-6 border-4 border-[#F0F0F0] bg-[#121212]">
              <div 
                className="text-5xl text-[#39FF14] text-center min-h-[60px] flex items-center justify-center tabular-nums"
                style={{ fontFamily: 'var(--font-mono)' }}
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
              className="h-16 border-4 border-[#F0F0F0] bg-[#121212] text-[#F0F0F0] hover:bg-[#F0F0F0] hover:text-black transition-colors text-2xl"
              style={{ fontFamily: 'var(--font-mono)' }}
            >
              {key}
            </button>
          ))}
        </div>

        {/* Submit Button */}
        <button
          onClick={handleSubmit}
          disabled={input === ""}
          className="w-full py-6 border-4 border-[#F0F0F0] bg-[#39FF14] text-black hover:bg-[#2BCC0F] disabled:bg-[#1a1a1a] disabled:text-[#505050] disabled:border-[#505050] disabled:cursor-not-allowed transition-colors"
          style={{ fontFamily: 'var(--font-mono)' }}
        >
          SUBMIT ANSWER
        </button>
      </div>
    </div>
  );
}
