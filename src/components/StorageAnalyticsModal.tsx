import React from 'react';
import type { MonthGroup } from '../types/photo';
import { 
  X, 
  PieChart, 
  HardDrive, 
  Copy, 
  Smartphone, 
  Sparkles
} from 'lucide-react';
import { soundEngine } from '../utils/audio';

interface StorageAnalyticsModalProps {
  months: MonthGroup[];
  totalCleanedMB: number;
  onClose: () => void;
  onQuickCleanDuplicates: () => void;
}

export const StorageAnalyticsModal: React.FC<StorageAnalyticsModalProps> = ({
  months,
  totalCleanedMB,
  onClose,
  onQuickCleanDuplicates
}) => {
  const allPhotos = months.flatMap(m => m.photos);

  const duplicates = allPhotos.filter(p => p.isDuplicate || p.isBlurry);
  const duplicatesMB = duplicates.reduce((acc, p) => acc + p.sizeMB, 0);

  const screenshots = allPhotos.filter(p => p.isScreenshot);
  const screenshotsMB = screenshots.reduce((acc, p) => acc + p.sizeMB, 0);

  const largePhotos = allPhotos.filter(p => p.sizeMB > 6);
  const largePhotosMB = largePhotos.reduce((acc, p) => acc + p.sizeMB, 0);

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/80 backdrop-blur-md animate-fadeIn">
      <div className="relative w-full max-w-xl liquid-glass p-6 md:p-8 rounded-3xl space-y-6 shadow-2xl border border-white/30 overflow-hidden">
        
        {/* Header */}
        <div className="flex items-center justify-between border-b border-white/10 pb-4">
          <div className="flex items-center gap-3">
            <div className="p-3 rounded-2xl bg-cyan-500/20 text-cyan-300 border border-cyan-400/40">
              <PieChart className="w-6 h-6" />
            </div>
            <div>
              <h2 className="text-2xl font-extrabold text-white tracking-tight">Depolama Analizi</h2>
              <p className="text-xs text-slate-300">Yapay Zeka Destekli Galeri Temizlik Raporu</p>
            </div>
          </div>

          <button
            onClick={onClose}
            className="p-2 rounded-xl bg-white/10 hover:bg-white/20 text-slate-300 hover:text-white transition-all cursor-pointer"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Cleaned Storage Banner */}
        <div className="p-4 rounded-2xl bg-gradient-to-r from-emerald-500/20 via-cyan-500/20 to-blue-500/20 border border-emerald-400/30 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <Sparkles className="w-6 h-6 text-emerald-400 animate-pulse" />
            <div>
              <p className="text-xs text-slate-300">Toplam Temizlenen Alan</p>
              <p className="text-2xl font-extrabold text-white font-mono">{totalCleanedMB.toFixed(1)} MB</p>
            </div>
          </div>
          <span className="px-3 py-1 rounded-full bg-emerald-400/20 text-emerald-300 text-xs font-bold border border-emerald-400/40">
            Aktif Koruma
          </span>
        </div>

        {/* Storage Breakdown Cards */}
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
          {/* Duplicates */}
          <div className="p-4 rounded-2xl bg-amber-500/10 border border-amber-400/30 space-y-2">
            <div className="flex items-center justify-between text-amber-300">
              <Copy className="w-5 h-5" />
              <span className="text-xs font-bold font-mono">{duplicatesMB.toFixed(1)} MB</span>
            </div>
            <h4 className="text-sm font-bold text-white">Tekrarlar & Bulanık</h4>
            <p className="text-xs text-slate-300">{duplicates.length} Adet Kötü Kalite Kare</p>
          </div>

          {/* Screenshots */}
          <div className="p-4 rounded-2xl bg-purple-500/10 border border-purple-400/30 space-y-2">
            <div className="flex items-center justify-between text-purple-300">
              <Smartphone className="w-5 h-5" />
              <span className="text-xs font-bold font-mono">{screenshotsMB.toFixed(1)} MB</span>
            </div>
            <h4 className="text-sm font-bold text-white">Ekran Görüntüleri</h4>
            <p className="text-xs text-slate-300">{screenshots.length} Geçici Ekran Kaydı</p>
          </div>

          {/* Large Files */}
          <div className="p-4 rounded-2xl bg-cyan-500/10 border border-cyan-400/30 space-y-2">
            <div className="flex items-center justify-between text-cyan-300">
              <HardDrive className="w-5 h-5" />
              <span className="text-xs font-bold font-mono">{largePhotosMB.toFixed(1)} MB</span>
            </div>
            <h4 className="text-sm font-bold text-white">Büyük Fotoğraflar</h4>
            <p className="text-xs text-slate-300">{largePhotos.length} Yüksek Çözünürlük</p>
          </div>
        </div>

        {/* Quick Action Button */}
        <div className="pt-2 flex justify-end">
          <button
            onClick={() => {
              soundEngine.playGlassTap();
              onQuickCleanDuplicates();
              onClose();
            }}
            className="liquid-button-primary px-6 py-3.5 rounded-2xl font-bold text-white text-sm flex items-center gap-2 cursor-pointer shadow-lg w-full sm:w-auto text-center justify-center"
          >
            <Sparkles className="w-4 h-4 text-cyan-300" />
            <span>Gereksiz Kareleri Doğrudan Temizle</span>
          </button>
        </div>

      </div>
    </div>
  );
};
