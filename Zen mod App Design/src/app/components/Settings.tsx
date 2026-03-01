import { useState, useEffect } from "react";
import { useNavigate } from "react-router";
import { ArrowLeft, Save } from "lucide-react";

export interface AppSettings {
  questionTopic: 'mixed' | 'arithmetic' | 'algebra' | 'geometry';
  difficulty: 'easy' | 'medium' | 'hard';
  penaltyMinutes: number;
  rewardSeconds: number;
  accentColor: 'pink' | 'cyan' | 'purple' | 'yellow' | 'green';
  enableSounds: boolean;
  enableVibration: boolean;
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

const colorMap = {
  pink: '#FF006E',
  cyan: '#00F5FF',
  purple: '#B537FF',
  yellow: '#FFD60A',
  green: '#39FF14',
};

export function Settings() {
  const navigate = useNavigate();
  const [settings, setSettings] = useState<AppSettings>(defaultSettings);

  useEffect(() => {
    const saved = localStorage.getItem('mathLockSettings');
    if (saved) {
      setSettings(JSON.parse(saved));
    }
  }, []);

  const handleSave = () => {
    localStorage.setItem('mathLockSettings', JSON.stringify(settings));
    navigate('/');
  };

  const updateSetting = <K extends keyof AppSettings>(key: K, value: AppSettings[K]) => {
    setSettings(prev => ({ ...prev, [key]: value }));
  };

  return (
    <div className="min-h-screen bg-[#0a0a0f] flex flex-col max-w-md mx-auto">
      {/* Header */}
      <div className="flex items-center justify-between p-6 border-b-4 border-[#F0F0F0]">
        <button 
          onClick={() => navigate('/')}
          className="text-[#F0F0F0] hover:text-[#FF006E] transition-colors"
        >
          <ArrowLeft size={28} strokeWidth={2.5} />
        </button>
        <h1 className="text-[#F0F0F0] tracking-tight" style={{ fontFamily: 'var(--font-mono)' }}>
          SETTINGS
        </h1>
        <div className="w-7" /> {/* Spacer for center alignment */}
      </div>

      <div className="flex-1 overflow-y-auto p-6 space-y-6">
        {/* Question Topic */}
        <div>
          <label className="block text-[#F0F0F0] mb-3 tracking-wider" style={{ fontFamily: 'var(--font-mono)' }}>
            QUESTION TOPIC
          </label>
          <div className="grid grid-cols-2 gap-3">
            {(['mixed', 'arithmetic', 'algebra', 'geometry'] as const).map((topic) => (
              <button
                key={topic}
                onClick={() => updateSetting('questionTopic', topic)}
                className={`p-4 border-4 transition-all ${
                  settings.questionTopic === topic
                    ? 'border-[#FF006E] bg-[#FF006E] text-[#F0F0F0]'
                    : 'border-[#F0F0F0] bg-[#16161d] text-[#F0F0F0] hover:border-[#FF006E]'
                }`}
                style={{ fontFamily: 'var(--font-sans)' }}
              >
                {topic.toUpperCase()}
              </button>
            ))}
          </div>
        </div>

        {/* Difficulty Level */}
        <div>
          <label className="block text-[#F0F0F0] mb-3 tracking-wider" style={{ fontFamily: 'var(--font-mono)' }}>
            DIFFICULTY LEVEL
          </label>
          <div className="grid grid-cols-3 gap-3">
            {(['easy', 'medium', 'hard'] as const).map((diff) => (
              <button
                key={diff}
                onClick={() => updateSetting('difficulty', diff)}
                className={`p-4 border-4 transition-all ${
                  settings.difficulty === diff
                    ? 'border-[#00F5FF] bg-[#00F5FF] text-[#0a0a0f]'
                    : 'border-[#F0F0F0] bg-[#16161d] text-[#F0F0F0] hover:border-[#00F5FF]'
                }`}
                style={{ fontFamily: 'var(--font-sans)' }}
              >
                {diff.toUpperCase()}
              </button>
            ))}
          </div>
        </div>

        {/* Penalty Minutes */}
        <div>
          <label className="block text-[#F0F0F0] mb-3 tracking-wider" style={{ fontFamily: 'var(--font-mono)' }}>
            PENALTY (Minutes Added for Wrong Answer)
          </label>
          <div className="flex items-center gap-4">
            <button
              onClick={() => updateSetting('penaltyMinutes', Math.max(1, settings.penaltyMinutes - 1))}
              className="w-12 h-12 border-4 border-[#F0F0F0] text-[#F0F0F0] hover:bg-[#F0F0F0] hover:text-black transition-colors"
              style={{ fontFamily: 'var(--font-mono)' }}
            >
              -
            </button>
            <div className="flex-1 p-4 border-4 border-[#F0F0F0] bg-[#16161d] text-center">
              <span className="text-4xl text-[#FF006E] tabular-nums" style={{ fontFamily: 'var(--font-mono)' }}>
                {settings.penaltyMinutes}
              </span>
              <span className="text-[#F0F0F0] ml-2" style={{ fontFamily: 'var(--font-sans)' }}>min</span>
            </div>
            <button
              onClick={() => updateSetting('penaltyMinutes', Math.min(30, settings.penaltyMinutes + 1))}
              className="w-12 h-12 border-4 border-[#F0F0F0] text-[#F0F0F0] hover:bg-[#F0F0F0] hover:text-black transition-colors"
              style={{ fontFamily: 'var(--font-mono)' }}
            >
              +
            </button>
          </div>
        </div>

        {/* Reward Seconds */}
        <div>
          <label className="block text-[#F0F0F0] mb-3 tracking-wider" style={{ fontFamily: 'var(--font-mono)' }}>
            REWARD (Seconds of Access for Correct Answer)
          </label>
          <div className="flex items-center gap-4">
            <button
              onClick={() => updateSetting('rewardSeconds', Math.max(30, settings.rewardSeconds - 30))}
              className="w-12 h-12 border-4 border-[#F0F0F0] text-[#F0F0F0] hover:bg-[#F0F0F0] hover:text-black transition-colors"
              style={{ fontFamily: 'var(--font-mono)' }}
            >
              -
            </button>
            <div className="flex-1 p-4 border-4 border-[#F0F0F0] bg-[#16161d] text-center">
              <span className="text-4xl text-[#B537FF] tabular-nums" style={{ fontFamily: 'var(--font-mono)' }}>
                {settings.rewardSeconds}
              </span>
              <span className="text-[#F0F0F0] ml-2" style={{ fontFamily: 'var(--font-sans)' }}>sec</span>
            </div>
            <button
              onClick={() => updateSetting('rewardSeconds', Math.min(300, settings.rewardSeconds + 30))}
              className="w-12 h-12 border-4 border-[#F0F0F0] text-[#F0F0F0] hover:bg-[#F0F0F0] hover:text-black transition-colors"
              style={{ fontFamily: 'var(--font-mono)' }}
            >
              +
            </button>
          </div>
        </div>

        {/* Accent Color */}
        <div>
          <label className="block text-[#F0F0F0] mb-3 tracking-wider" style={{ fontFamily: 'var(--font-mono)' }}>
            ACCENT COLOR
          </label>
          <div className="grid grid-cols-5 gap-3">
            {(Object.keys(colorMap) as Array<keyof typeof colorMap>).map((color) => (
              <button
                key={color}
                onClick={() => updateSetting('accentColor', color)}
                className={`h-16 border-4 transition-all ${
                  settings.accentColor === color
                    ? 'border-[#F0F0F0] scale-110'
                    : 'border-[#F0F0F0] opacity-50 hover:opacity-100'
                }`}
                style={{ backgroundColor: colorMap[color] }}
                title={color.toUpperCase()}
              />
            ))}
          </div>
        </div>

        {/* Toggle Settings */}
        <div className="space-y-4">
          {/* Sounds */}
          <div className="flex items-center justify-between p-4 border-4 border-[#F0F0F0] bg-[#16161d]">
            <span className="text-[#F0F0F0]" style={{ fontFamily: 'var(--font-sans)' }}>
              Enable Sounds
            </span>
            <button
              onClick={() => updateSetting('enableSounds', !settings.enableSounds)}
              className={`relative w-16 h-8 border-4 border-[#F0F0F0] transition-colors ${
                settings.enableSounds ? 'bg-[#FFD60A]' : 'bg-[#2a2a3a]'
              }`}
            >
              <div
                className={`absolute top-0 bottom-0 w-6 border-2 border-[#F0F0F0] bg-[#0a0a0f] transition-all ${
                  settings.enableSounds ? 'right-0' : 'left-0'
                }`}
              />
            </button>
          </div>

          {/* Vibration */}
          <div className="flex items-center justify-between p-4 border-4 border-[#F0F0F0] bg-[#16161d]">
            <span className="text-[#F0F0F0]" style={{ fontFamily: 'var(--font-sans)' }}>
              Enable Vibration
            </span>
            <button
              onClick={() => updateSetting('enableVibration', !settings.enableVibration)}
              className={`relative w-16 h-8 border-4 border-[#F0F0F0] transition-colors ${
                settings.enableVibration ? 'bg-[#FFD60A]' : 'bg-[#2a2a3a]'
              }`}
            >
              <div
                className={`absolute top-0 bottom-0 w-6 border-2 border-[#F0F0F0] bg-[#0a0a0f] transition-all ${
                  settings.enableVibration ? 'right-0' : 'left-0'
                }`}
              />
            </button>
          </div>
        </div>
      </div>

      {/* Save Button */}
      <div className="p-6 border-t-4 border-[#F0F0F0]">
        <button
          onClick={handleSave}
          className="w-full py-6 border-4 border-[#F0F0F0] bg-[#39FF14] text-black hover:bg-[#2BCC0F] transition-colors flex items-center justify-center gap-3"
          style={{ fontFamily: 'var(--font-mono)' }}
        >
          <Save size={24} strokeWidth={2.5} />
          SAVE SETTINGS
        </button>
      </div>
    </div>
  );
}
