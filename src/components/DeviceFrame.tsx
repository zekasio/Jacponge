import React from 'react';
import { Wifi, Battery, Signal } from 'lucide-react';

interface DeviceFrameProps {
  enabled: boolean;
  children: React.ReactNode;
}

export const DeviceFrame: React.FC<DeviceFrameProps> = ({ enabled, children }) => {
  if (!enabled) {
    return <div className="w-full min-h-screen">{children}</div>;
  }

  return (
    <div className="w-full min-h-screen py-6 flex items-center justify-center bg-gradient-to-b from-slate-950 via-slate-900 to-black overflow-x-hidden">
      
      {/* iPhone 16 Pro Outer Titanium Body */}
      <div className="relative w-full max-w-[430px] h-[890px] rounded-[55px] bg-slate-900 border-[10px] border-slate-800 ring-1 ring-white/30 shadow-[0_0_80px_rgba(56,189,248,0.25)] flex flex-col overflow-hidden">
        
        {/* Dynamic Island Status Bar Header */}
        <div className="relative w-full h-12 bg-black px-7 pt-3 flex items-center justify-between text-white z-50 select-none">
          <span className="text-xs font-semibold font-mono tracking-tight">9:41</span>
          
          {/* Dynamic Island Pill */}
          <div className="absolute left-1/2 -translate-x-1/2 top-2.5 w-28 h-7 bg-black rounded-full border border-white/10 flex items-center justify-between px-2.5 shadow-md">
            <div className="w-2.5 h-2.5 rounded-full bg-cyan-400/40 animate-pulse" />
            <div className="w-3.5 h-3.5 rounded-full bg-blue-950 border border-blue-500/50" />
          </div>

          <div className="flex items-center gap-1.5 text-xs text-slate-300">
            <Signal className="w-3.5 h-3.5" />
            <Wifi className="w-3.5 h-3.5" />
            <Battery className="w-4 h-4 text-emerald-400" />
          </div>
        </div>

        {/* Screen Content Wrapper */}
        <div className="relative flex-1 overflow-y-auto overflow-x-hidden bg-slate-950">
          {children}
        </div>

        {/* iOS Home Indicator Bar */}
        <div className="w-full h-5 bg-black flex items-center justify-center z-50">
          <div className="w-32 h-1 bg-white/40 rounded-full" />
        </div>

      </div>

    </div>
  );
};
