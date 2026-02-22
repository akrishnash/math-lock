import { useState } from "react";
import { useNavigate } from "react-router";
import { Settings } from "lucide-react";

interface App {
  id: string;
  name: string;
  icon: string;
  enabled: boolean;
}

export function Dashboard() {
  const navigate = useNavigate();
  const [hours, setHours] = useState(2);
  const [minutes, setMinutes] = useState(0);
  const [apps, setApps] = useState<App[]>([
    { id: "tiktok", name: "TikTok", icon: "📱", enabled: true },
    { id: "instagram", name: "Instagram", icon: "📷", enabled: true },
    { id: "reddit", name: "Reddit", icon: "🗨️", enabled: false },
    { id: "youtube", name: "YouTube", icon: "▶️", enabled: false },
  ]);

  const toggleApp = (id: string) => {
    setApps(apps.map(app => 
      app.id === id ? { ...app, enabled: !app.enabled } : app
    ));
  };

  const startLockdown = () => {
    const totalSeconds = (hours * 3600) + (minutes * 60);
    if (totalSeconds === 0) return;
    
    const enabledApps = apps.filter(app => app.enabled);
    if (enabledApps.length === 0) return;

    // Store lockdown state in localStorage
    const endTime = Date.now() + (totalSeconds * 1000);
    localStorage.setItem('lockdownEnd', endTime.toString());
    localStorage.setItem('lockedApps', JSON.stringify(enabledApps));
    
    navigate('/intervention');
  };

  return (
    <div className="min-h-screen bg-black flex flex-col max-w-md mx-auto">
      {/* Top Nav */}
      <div className="flex items-center justify-between p-6 border-b-4 border-[#F0F0F0]">
        <h1 className="text-[#F0F0F0] tracking-tight" style={{ fontFamily: 'var(--font-mono)' }}>
          MATH-LOCK
        </h1>
        <button className="text-[#F0F0F0] hover:text-[#39FF14] transition-colors">
          <Settings size={28} strokeWidth={2.5} />
        </button>
      </div>

      {/* Time Selector */}
      <div className="flex-1 flex flex-col p-6">
        <div className="flex-1 flex items-center justify-center">
          <div className="text-center">
            <div className="mb-4 text-[#F0F0F0] text-sm tracking-wider" style={{ fontFamily: 'var(--font-sans)' }}>
              LOCK DURATION
            </div>
            <div className="flex items-center justify-center gap-4">
              {/* Hours */}
              <div className="flex flex-col items-center">
                <button
                  onClick={() => setHours(Math.min(23, hours + 1))}
                  className="w-16 h-16 border-4 border-[#F0F0F0] text-[#F0F0F0] hover:bg-[#F0F0F0] hover:text-black transition-colors"
                  style={{ fontFamily: 'var(--font-mono)' }}
                >
                  ▲
                </button>
                <div className="my-4 text-8xl text-[#F0F0F0] tabular-nums" style={{ fontFamily: 'var(--font-mono)' }}>
                  {String(hours).padStart(2, '0')}
                </div>
                <button
                  onClick={() => setHours(Math.max(0, hours - 1))}
                  className="w-16 h-16 border-4 border-[#F0F0F0] text-[#F0F0F0] hover:bg-[#F0F0F0] hover:text-black transition-colors"
                  style={{ fontFamily: 'var(--font-mono)' }}
                >
                  ▼
                </button>
                <div className="mt-2 text-[#F0F0F0] text-xs" style={{ fontFamily: 'var(--font-sans)' }}>
                  HOURS
                </div>
              </div>

              <div className="text-8xl text-[#F0F0F0] mb-8" style={{ fontFamily: 'var(--font-mono)' }}>:</div>

              {/* Minutes */}
              <div className="flex flex-col items-center">
                <button
                  onClick={() => setMinutes(Math.min(59, minutes + 5))}
                  className="w-16 h-16 border-4 border-[#F0F0F0] text-[#F0F0F0] hover:bg-[#F0F0F0] hover:text-black transition-colors"
                  style={{ fontFamily: 'var(--font-mono)' }}
                >
                  ▲
                </button>
                <div className="my-4 text-8xl text-[#F0F0F0] tabular-nums" style={{ fontFamily: 'var(--font-mono)' }}>
                  {String(minutes).padStart(2, '0')}
                </div>
                <button
                  onClick={() => setMinutes(Math.max(0, minutes - 5))}
                  className="w-16 h-16 border-4 border-[#F0F0F0] text-[#F0F0F0] hover:bg-[#F0F0F0] hover:text-black transition-colors"
                  style={{ fontFamily: 'var(--font-mono)' }}
                >
                  ▼
                </button>
                <div className="mt-2 text-[#F0F0F0] text-xs" style={{ fontFamily: 'var(--font-sans)' }}>
                  MINUTES
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* Apps to Block */}
        <div className="mt-8">
          <div className="mb-4 text-[#F0F0F0] tracking-wider" style={{ fontFamily: 'var(--font-mono)' }}>
            THE ENEMY (Apps to Block)
          </div>
          <div className="space-y-3">
            {apps.map((app) => (
              <div
                key={app.id}
                className="flex items-center justify-between p-4 border-4 border-[#F0F0F0] bg-[#121212]"
              >
                <div className="flex items-center gap-3">
                  <span className="text-3xl grayscale">{app.icon}</span>
                  <span className="text-[#F0F0F0]" style={{ fontFamily: 'var(--font-sans)' }}>
                    {app.name}
                  </span>
                </div>
                <button
                  onClick={() => toggleApp(app.id)}
                  className={`relative w-16 h-8 border-4 border-[#F0F0F0] transition-colors ${
                    app.enabled ? 'bg-[#39FF14]' : 'bg-[#2a2a2a]'
                  }`}
                >
                  <div
                    className={`absolute top-0 bottom-0 w-6 border-2 border-[#F0F0F0] bg-black transition-all ${
                      app.enabled ? 'right-0' : 'left-0'
                    }`}
                  />
                </button>
              </div>
            ))}
          </div>
        </div>

        {/* Lockdown Button */}
        <button
          onClick={startLockdown}
          disabled={hours === 0 && minutes === 0}
          className="mt-6 w-full py-6 border-4 border-[#F0F0F0] bg-[#39FF14] text-black hover:bg-[#2BCC0F] disabled:bg-[#1a1a1a] disabled:text-[#505050] disabled:cursor-not-allowed transition-colors"
          style={{ fontFamily: 'var(--font-mono)' }}
        >
          INITIATE LOCKDOWN
        </button>
      </div>
    </div>
  );
}
