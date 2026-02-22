import { useEffect, useState } from "react";
import { useNavigate } from "react-router";
import { Lock } from "lucide-react";

export function Intervention() {
  const navigate = useNavigate();
  const [timeRemaining, setTimeRemaining] = useState("");

  useEffect(() => {
    const lockdownEnd = localStorage.getItem('lockdownEnd');
    if (!lockdownEnd) {
      navigate('/');
      return;
    }

    const updateTimer = () => {
      const now = Date.now();
      const end = parseInt(lockdownEnd);
      const diff = end - now;

      if (diff <= 0) {
        localStorage.removeItem('lockdownEnd');
        localStorage.removeItem('lockedApps');
        navigate('/');
        return;
      }

      const hours = Math.floor(diff / (1000 * 60 * 60));
      const minutes = Math.floor((diff % (1000 * 60 * 60)) / (1000 * 60));
      const seconds = Math.floor((diff % (1000 * 60)) / 1000);

      setTimeRemaining(`${hours}h ${minutes}m ${seconds}s`);
    };

    updateTimer();
    const interval = setInterval(updateTimer, 1000);

    return () => clearInterval(interval);
  }, [navigate]);

  const handleDesperateClick = () => {
    navigate('/challenge');
  };

  return (
    <div className="min-h-screen bg-black flex flex-col items-center justify-center p-6 max-w-md mx-auto">
      <div className="flex flex-col items-center justify-center flex-1">
        {/* Lock Icon */}
        <div className="mb-8">
          <Lock size={120} strokeWidth={3} className="text-[#F0F0F0]" />
        </div>

        {/* Primary Text */}
        <div 
          className="text-6xl text-[#F0F0F0] mb-6 tracking-tight text-center"
          style={{ fontFamily: 'var(--font-mono)' }}
        >
          NICE TRY.
        </div>

        {/* Secondary Text */}
        <div 
          className="text-xl text-[#F0F0F0] text-center mb-2"
          style={{ fontFamily: 'var(--font-sans)' }}
        >
          Time remaining:
        </div>
        <div 
          className="text-4xl text-[#39FF14] mb-12 tabular-nums"
          style={{ fontFamily: 'var(--font-mono)' }}
        >
          {timeRemaining}
        </div>

        {/* Alternative message */}
        <div 
          className="text-[#a0a0a0] text-center mb-8 max-w-xs"
          style={{ fontFamily: 'var(--font-sans)' }}
        >
          Go do something productive. Read a book. Touch grass. Your choice.
        </div>
      </div>

      {/* Desperate Button */}
      <button
        onClick={handleDesperateClick}
        className="w-full py-4 border-2 border-[#505050] bg-[#1a1a1a] text-[#a0a0a0] hover:border-[#F0F0F0] hover:text-[#F0F0F0] transition-colors text-sm"
        style={{ fontFamily: 'var(--font-sans)' }}
      >
        I'm desperate. Let me do math for 60s access.
      </button>
    </div>
  );
}
