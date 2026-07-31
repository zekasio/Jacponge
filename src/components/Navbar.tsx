import React from 'react';
import { 
  Sparkles, 
  Trash2, 
  Volume2, 
  VolumeX, 
  Smartphone, 
  Monitor, 
  Upload, 
  PieChart,
  Droplet
} from 'lucide-react';
import { soundEngine } from '../utils/audio';

interface NavbarProps {
  cleanedMB: number;
  pendingCount: number;
  isDeviceFrame: boolean;
  onToggleDeviceFrame: () => void;
  onOpenUpload: () => void;
  onOpenAnalytics: () => void;
  onOpenPendingSummary?: () => void;
}

export const Navbar: React.FC<NavbarProps> = ({
  cleanedMB,
  pendingCount,
  isDeviceFrame,
  onToggleDeviceFrame,
  onOpenUpload,
  onOpenAnalytics,
  onOpenPendingSummary
}) => {
  const [soundEnabled, setSoundEnabled] = React.useState(true);

  const toggleSound = () => {
    const next = !soundEnabled;
    setSoundEnabled(next);
    soundEngine.setEnabled(next);
    if (next) soundEngine.playGlassTap();
  };

  return (
    <header className="w-full px-4 py-3 sticky top-0 z-50">
      <div className="max-w-6xl mx-auto liquid-glass px-4 py-2.5 flex items-center justify-between">
        
        {/* Brand Logo */}
        <div className="flex items-center gap-3">
          <div className="relative w-10 h-10 rounded-2xl bg-gradient-to-tr from-cyan-500 via-blue-600 to-indigo-500 flex items-center justify-center shadow-lg shadow-cyan-500/20 border border-white/40 overflow-hidden group">
            <div className="absolute inset-0 bg-white/20 opacity-0 group-hover:opacity-100 transition-opacity" />
            <Droplet className="w-5 h-5 text-white animate-pulse" />
          </div>
          <div>
            <div className="flex items-center gap-1.5">
              <span className="font-bold tracking-tight text-white text-base font-mono">Liquid</span>
              <span className="text-cyan-300 font-extrabold text-base tracking-wide">Clean</span>
              <span className="px-1.5 py-0.5 rounded-full text-[10px] uppercase font-bold tracking-widest bg-cyan-400/20 border border-cyan-300/40 text-cyan-200">
                PRO
              </span>
            </div>
            <p className="text-[11px] text-slate-300/80">Apple Liquid Glass Optics</p>
          </div>
        </div>

        {/* Action Controls */}
        <div className="flex items-center gap-2 sm:gap-3">
          
          {/* Storage Cleaned Badge */}
          {cleanedMB > 0 && (
            <div 
              onClick={onOpenAnalytics}
              className="cursor-pointer px-3 py-1.5 rounded-full bg-emerald-500/15 border border-emerald-400/40 text-emerald-300 text-xs font-semibold flex items-center gap-1.5 hover:bg-emerald-500/25 transition-all"
            >
              <Sparkles className="w-3.5 h-3.5 text-emerald-400" />
              <span>{cleanedMB.toFixed(1)} MB Temizlendi</span>
            </div>
          )}

          {/* Pending Delete Badge */}
          {pendingCount > 0 && (
            <button 
              onClick={onOpenPendingSummary}
              className="px-3 py-1.5 rounded-full bg-rose-500/20 border border-rose-400/40 text-rose-300 text-xs font-bold flex items-center gap-1.5 hover:bg-rose-500/30 transition-all animate-bounce"
            >
              <Trash2 className="w-3.5 h-3.5 text-rose-400" />
              <span>{pendingCount} Çöp</span>
            </button>
          )}

          {/* Analytics Trigger */}
          <button
            onClick={() => {
              soundEngine.playGlassTap();
              onOpenAnalytics();
            }}
            className="p-2 rounded-xl bg-white/10 hover:bg-white/20 border border-white/20 text-slate-200 hover:text-white transition-all text-xs flex items-center gap-1"
            title="Depolama Analizi"
          >
            <PieChart className="w-4 h-4 text-cyan-300" />
            <span className="hidden md:inline font-medium">Analiz</span>
          </button>

          {/* Upload Trigger */}
          <button
            onClick={() => {
              soundEngine.playGlassTap();
              onOpenUpload();
            }}
            className="p-2 rounded-xl bg-gradient-to-r from-blue-500/30 to-cyan-500/30 hover:from-blue-500/40 hover:to-cyan-500/40 border border-cyan-400/40 text-cyan-200 text-xs font-medium flex items-center gap-1.5 transition-all shadow-sm"
          >
            <Upload className="w-4 h-4 text-cyan-300" />
            <span className="hidden sm:inline">Fotoğraf Ekle</span>
          </button>

          {/* Device Frame Toggle */}
          <button
            onClick={() => {
              soundEngine.playGlassTap();
              onToggleDeviceFrame();
            }}
            className="p-2 rounded-xl bg-white/10 hover:bg-white/20 border border-white/20 text-slate-200 transition-all"
            title={isDeviceFrame ? "Tam Ekran Görünümüne Geç" : "iPhone 16 Pro Çerçevesine Geç"}
          >
            {isDeviceFrame ? (
              <Monitor className="w-4 h-4 text-slate-300" />
            ) : (
              <Smartphone className="w-4 h-4 text-slate-300" />
            )}
          </button>

          {/* Sound Toggle */}
          <button
            onClick={toggleSound}
            className="p-2 rounded-xl bg-white/10 hover:bg-white/20 border border-white/20 text-slate-200 transition-all"
            title={soundEnabled ? "Sesi Kapat" : "Sesi Aç"}
          >
            {soundEnabled ? (
              <Volume2 className="w-4 h-4 text-cyan-400" />
            ) : (
              <VolumeX className="w-4 h-4 text-slate-400" />
            )}
          </button>
        </div>

      </div>
    </header>
  );
};
