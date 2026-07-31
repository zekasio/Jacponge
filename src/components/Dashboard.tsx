import React, { useState } from 'react';
import type { MonthGroup } from '../types/photo';
import { 
  Calendar, 
  Layers, 
  Sparkles, 
  ArrowRight, 
  Copy, 
  Image as ImageIcon, 
  Smartphone,
  HardDrive
} from 'lucide-react';
import { soundEngine } from '../utils/audio';

interface DashboardProps {
  months: MonthGroup[];
  totalPhotos: number;
  totalStorageMB: number;
  onSelectMonth: (monthKey: string) => void;
  onOpenQuickCleanAll: () => void;
}

export const Dashboard: React.FC<DashboardProps> = ({
  months,
  totalPhotos,
  totalStorageMB,
  onSelectMonth,
  onOpenQuickCleanAll
}) => {
  const [filterType, setFilterType] = useState<'all' | 'duplicates' | 'screenshots'>('all');

  const filteredMonths = months.map(m => {
    if (filterType === 'duplicates') {
      const dups = m.photos.filter(p => p.isDuplicate || p.isBlurry);
      return { ...m, photos: dups, count: dups.length };
    }
    if (filterType === 'screenshots') {
      const screens = m.photos.filter(p => p.isScreenshot);
      return { ...m, photos: screens, count: screens.length };
    }
    return { ...m, count: m.photos.length };
  }).filter(m => m.photos.length > 0);

  const totalDuplicates = months.reduce((acc, m) => acc + m.duplicateCount, 0);

  return (
    <div className="w-full max-w-6xl mx-auto px-4 py-6 space-y-8 animate-fadeIn">
      
      {/* Hero Liquid Glass Analytics Card */}
      <div className="liquid-glass p-6 md:p-8 relative overflow-hidden group">
        {/* Animated Background Fluid Orb */}
        <div className="absolute -top-24 -right-24 w-80 h-80 rounded-full bg-gradient-to-br from-cyan-500/20 via-blue-600/10 to-purple-600/20 blur-3xl animate-liquid-wave pointer-events-none" />

        <div className="relative z-10 flex flex-col md:flex-row items-start md:items-center justify-between gap-6">
          <div className="space-y-2">
            <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-cyan-400/10 border border-cyan-400/30 text-cyan-300 text-xs font-semibold">
              <Sparkles className="w-3.5 h-3.5" />
              <span>Apple Liquid Glass AI Fotoğraf Temizleme Engine</span>
            </div>
            <h1 className="text-3xl md:text-4xl font-extrabold text-white tracking-tight">
              Galeri Kütüphaneniz
            </h1>
            <p className="text-slate-300 text-sm max-w-lg leading-relaxed">
              Tarihe göre gruplanmış sıvı cam destelerini swipe ederek telefonunuzda yer açın. Gereksiz kopyaları, ekran görüntülerini ve bulanık kareleri anında tespit edin.
            </p>
          </div>

          {/* Quick Metrics & Quick Clean Button */}
          <div className="flex flex-col sm:flex-row items-stretch sm:items-center gap-3 w-full md:w-auto">
            <div className="liquid-glass px-4 py-3 rounded-2xl border border-white/20 flex items-center gap-4">
              <div className="p-3 rounded-xl bg-cyan-500/20 text-cyan-300 border border-cyan-400/30">
                <HardDrive className="w-6 h-6" />
              </div>
              <div>
                <p className="text-xs text-slate-400 font-medium">Toplam Galeri</p>
                <p className="text-xl font-bold text-white font-mono">{(totalStorageMB / 1024).toFixed(2)} GB</p>
                <p className="text-[11px] text-cyan-300">{totalPhotos} Fotoğraf</p>
              </div>
            </div>

            <button
              onClick={() => {
                soundEngine.playGlassTap();
                onOpenQuickCleanAll();
              }}
              className="liquid-button-primary px-6 py-4 rounded-2xl font-bold text-white text-sm flex items-center justify-center gap-2 group cursor-pointer shadow-lg shadow-cyan-500/25"
            >
              <span>Tümünü Temizlemeye Başla</span>
              <ArrowRight className="w-4 h-4 group-hover:translate-x-1 transition-transform" />
            </button>
          </div>
        </div>
      </div>

      {/* Filter Tabs */}
      <div className="flex items-center justify-between flex-wrap gap-4 border-b border-white/10 pb-4">
        <div className="flex items-center gap-2 overflow-x-auto py-1">
          <button
            onClick={() => { soundEngine.playGlassTap(); setFilterType('all'); }}
            className={`px-4 py-2 rounded-xl text-xs font-semibold transition-all flex items-center gap-2 cursor-pointer ${
              filterType === 'all'
                ? 'bg-cyan-500/25 border border-cyan-400/50 text-cyan-200 shadow-md shadow-cyan-500/20'
                : 'bg-white/5 hover:bg-white/10 text-slate-300 border border-white/10'
            }`}
          >
            <Calendar className="w-3.5 h-3.5" />
            <span>Tüm Aylar ({months.length})</span>
          </button>

          <button
            onClick={() => { soundEngine.playGlassTap(); setFilterType('duplicates'); }}
            className={`px-4 py-2 rounded-xl text-xs font-semibold transition-all flex items-center gap-2 cursor-pointer ${
              filterType === 'duplicates'
                ? 'bg-amber-500/25 border border-amber-400/50 text-amber-200 shadow-md shadow-amber-500/20'
                : 'bg-white/5 hover:bg-white/10 text-slate-300 border border-white/10'
            }`}
          >
            <Copy className="w-3.5 h-3.5 text-amber-400" />
            <span>Kopyalar & Bulanık ({totalDuplicates})</span>
          </button>

          <button
            onClick={() => { soundEngine.playGlassTap(); setFilterType('screenshots'); }}
            className={`px-4 py-2 rounded-xl text-xs font-semibold transition-all flex items-center gap-2 cursor-pointer ${
              filterType === 'screenshots'
                ? 'bg-purple-500/25 border border-purple-400/50 text-purple-200 shadow-md shadow-purple-500/20'
                : 'bg-white/5 hover:bg-white/10 text-slate-300 border border-white/10'
            }`}
          >
            <Smartphone className="w-3.5 h-3.5 text-purple-400" />
            <span>Ekran Görüntüleri</span>
          </button>
        </div>

        <div className="text-xs text-slate-400 flex items-center gap-1.5 font-medium">
          <Layers className="w-4 h-4 text-cyan-400" />
          <span>Sıvı Cam Kart Gridi (Liquid Tinder Deste Modu)</span>
        </div>
      </div>

      {/* Liquid Glass Card Grid (Month / Category List) */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
        {filteredMonths.map((group) => {
          const count = group.photos.length;
          const cover = group.coverPhotoUrl;

          return (
            <div
              key={group.key}
              onClick={() => {
                soundEngine.playGlassTap();
                onSelectMonth(group.key);
              }}
              className="liquid-glass group cursor-pointer p-5 flex flex-col justify-between h-72 hover:border-cyan-400/60 hover:shadow-2xl hover:shadow-cyan-500/20 transition-all duration-300 transform hover:-translate-y-1.5"
            >
              {/* Card Header */}
              <div className="flex items-start justify-between z-10">
                <div>
                  <h3 className="font-extrabold text-white text-xl tracking-tight group-hover:text-cyan-300 transition-colors">
                    {group.name}
                  </h3>
                  <p className="text-xs text-slate-300 font-mono mt-0.5">
                    {group.totalSizeMB.toFixed(1)} MB • {count} Fotoğraf
                  </p>
                </div>

                <div className="p-2.5 rounded-2xl bg-white/10 border border-white/20 text-cyan-300 group-hover:bg-cyan-500 group-hover:text-white transition-all shadow-md">
                  <ArrowRight className="w-4 h-4" />
                </div>
              </div>

              {/* Stacked Thumbnail Lens Preview */}
              <div className="relative w-full h-32 my-auto flex items-center justify-center">
                {/* Back card 2 */}
                <div className="absolute w-44 h-28 rounded-2xl bg-white/10 border border-white/20 transform translate-y-3 scale-90 blur-[1px] opacity-40 shadow-lg" />
                {/* Back card 1 */}
                <div className="absolute w-48 h-30 rounded-2xl bg-white/20 border border-white/30 transform translate-y-1.5 scale-95 opacity-70 shadow-lg" />
                
                {/* Main Front Liquid Card */}
                <div className="relative w-52 h-32 rounded-2xl overflow-hidden border-2 border-white/40 shadow-xl group-hover:border-cyan-300/80 transition-all">
                  <img
                    src={cover}
                    alt={group.name}
                    className="w-full h-full object-cover group-hover:scale-110 transition-transform duration-500"
                  />
                  
                  {/* Liquid specular edge shimmer */}
                  <div className="absolute inset-0 bg-gradient-to-tr from-cyan-500/20 via-transparent to-white/30 opacity-70 group-hover:opacity-100 transition-opacity" />

                  <div className="absolute bottom-2 left-2 px-2.5 py-1 rounded-xl bg-black/60 backdrop-filter backdrop-blur-md border border-white/20 text-[11px] text-white font-medium flex items-center gap-1">
                    <ImageIcon className="w-3 h-3 text-cyan-400" />
                    <span>Deste Aç ({count})</span>
                  </div>
                </div>
              </div>

              {/* Card Footer Metrics */}
              <div className="pt-3 border-t border-white/10 flex items-center justify-between text-xs z-10">
                <div className="flex items-center gap-1.5 text-amber-300 font-medium">
                  {group.duplicateCount > 0 && (
                    <>
                      <Copy className="w-3.5 h-3.5" />
                      <span>{group.duplicateCount} Gereksiz Kare</span>
                    </>
                  )}
                </div>

                <span className="text-[11px] font-bold text-cyan-300 uppercase tracking-wider group-hover:underline">
                  Temizle &rarr;
                </span>
              </div>
            </div>
          );
        })}
      </div>

    </div>
  );
};
