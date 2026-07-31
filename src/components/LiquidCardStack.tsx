import React, { useState } from 'react';
import type { Photo, MonthGroup } from '../types/photo';
import { LiquidCard } from './LiquidCard';
import { 
  X, 
  Check, 
  RotateCcw, 
  ArrowLeft, 
  Sparkles, 
  Layers
} from 'lucide-react';
import { soundEngine } from '../utils/audio';

interface LiquidCardStackProps {
  month: MonthGroup;
  onFinishStack: (pendingDeleteIds: string[], monthKey: string) => void;
  onBackToDashboard: () => void;
  onOpenInfo: (photo: Photo) => void;
}

export const LiquidCardStack: React.FC<LiquidCardStackProps> = ({
  month,
  onFinishStack,
  onBackToDashboard,
  onOpenInfo
}) => {
  const [currentIndex, setCurrentIndex] = useState(0);
  const [pendingDeleteIds, setPendingDeleteIds] = useState<string[]>([]);
  const [swipeHistory, setSwipeHistory] = useState<{ id: string; action: 'keep' | 'delete' }[]>([]);

  const photos = month.photos;
  const currentPhoto = photos[currentIndex];
  const totalCount = photos.length;
  const remainingCount = totalCount - currentIndex;

  const handleSwipe = (direction: 'left' | 'right') => {
    if (!currentPhoto) return;

    if (direction === 'left') {
      // Delete
      setPendingDeleteIds(prev => [...prev, currentPhoto.id]);
      setSwipeHistory(prev => [...prev, { id: currentPhoto.id, action: 'delete' }]);
    } else {
      // Keep
      setSwipeHistory(prev => [...prev, { id: currentPhoto.id, action: 'keep' }]);
    }

    const nextIndex = currentIndex + 1;
    setCurrentIndex(nextIndex);

    // If stack complete, trigger summary
    if (nextIndex >= totalCount) {
      setTimeout(() => {
        onFinishStack(
          direction === 'left' ? [...pendingDeleteIds, currentPhoto.id] : pendingDeleteIds,
          month.key
        );
      }, 300);
    }
  };

  const handleUndo = () => {
    if (currentIndex === 0 || swipeHistory.length === 0) return;
    soundEngine.playRestoreSound();

    const last = swipeHistory[swipeHistory.length - 1];
    setSwipeHistory(prev => prev.slice(0, -1));

    if (last.action === 'delete') {
      setPendingDeleteIds(prev => prev.filter(id => id !== last.id));
    }

    setCurrentIndex(prev => prev - 1);
  };

  return (
    <div className="w-full max-w-xl mx-auto px-4 py-4 flex flex-col items-center justify-between min-h-[80vh] animate-fadeIn">
      
      {/* Top Header Controls */}
      <div className="w-full flex items-center justify-between mb-4">
        <button
          onClick={() => {
            soundEngine.playGlassTap();
            onBackToDashboard();
          }}
          className="p-3 rounded-2xl liquid-glass border border-white/20 text-slate-200 hover:text-white flex items-center gap-2 text-xs font-semibold cursor-pointer transition-all"
        >
          <ArrowLeft className="w-4 h-4" />
          <span>Kategorilere Dön</span>
        </button>

        <div className="text-center">
          <h2 className="font-extrabold text-white text-lg tracking-tight">
            {month.name}
          </h2>
          <p className="text-xs text-cyan-300 font-mono">
            {currentIndex + 1} / {totalCount} Fotoğraf
          </p>
        </div>

        {/* Stack Counter Indicator */}
        <div className="px-3 py-1.5 rounded-full bg-white/10 border border-white/20 text-xs text-slate-300 font-mono flex items-center gap-1.5">
          <Layers className="w-3.5 h-3.5 text-cyan-400" />
          <span>Kalan: {remainingCount}</span>
        </div>
      </div>

      {/* Main Tinder Card Deck Area */}
      <div className="relative w-full max-w-sm h-[480px] sm:h-[520px] flex items-center justify-center">
        
        {currentIndex < totalCount ? (
          <>
            {/* Background Card 3 */}
            {currentIndex + 2 < totalCount && (
              <div className="absolute w-[86%] h-[90%] rounded-3xl liquid-glass border border-white/10 bg-slate-900/60 transform translate-y-6 scale-90 opacity-40 blur-[1px]" />
            )}

            {/* Background Card 2 */}
            {currentIndex + 1 < totalCount && (
              <div className="absolute w-[93%] h-[95%] rounded-3xl liquid-glass border border-white/20 bg-slate-900/80 transform translate-y-3 scale-95 opacity-75 shadow-xl" />
            )}

            {/* Active Interactive Top Card */}
            <LiquidCard
              key={currentPhoto.id}
              photo={currentPhoto}
              isTop={true}
              onSwipe={handleSwipe}
              onOpenInfo={onOpenInfo}
            />
          </>
        ) : (
          /* Stack Finished Placeholder */
          <div className="liquid-glass p-8 text-center flex flex-col items-center justify-center space-y-4 w-full h-full rounded-3xl">
            <div className="w-16 h-16 rounded-full bg-emerald-500/20 border border-emerald-400/40 flex items-center justify-center text-emerald-300 animate-pulse">
              <Sparkles className="w-8 h-8" />
            </div>
            <h3 className="text-2xl font-bold text-white">Deste Tamamlandı!</h3>
            <p className="text-xs text-slate-300 max-w-xs">
              Bu aydaki tüm fotoğrafları incelediniz. Silinecek fotoğrafları onaylamak için devam edin.
            </p>
            <button
              onClick={() => onFinishStack(pendingDeleteIds, month.key)}
              className="liquid-button-primary px-6 py-3 rounded-2xl text-white font-bold text-sm cursor-pointer shadow-lg"
            >
              Özet Ekranına Geç
            </button>
          </div>
        )}
      </div>

      {/* Swipe Action Controls Bar */}
      {currentIndex < totalCount && (
        <div className="w-full max-w-sm flex items-center justify-between mt-6 px-4">
          
          {/* DELETE BUTTON (LEFT) */}
          <button
            onClick={() => {
              soundEngine.playDeleteSound();
              handleSwipe('left');
            }}
            className="w-16 h-16 rounded-full liquid-button-danger flex items-center justify-center text-white cursor-pointer group shadow-xl transition-all"
            title="Sil (Sola Kaydır)"
          >
            <X className="w-8 h-8 group-hover:scale-125 transition-transform" />
          </button>

          {/* UNDO BUTTON (CENTER) */}
          <button
            onClick={handleUndo}
            disabled={currentIndex === 0}
            className={`w-12 h-12 rounded-2xl liquid-glass border border-white/30 flex items-center justify-center text-slate-200 transition-all cursor-pointer ${
              currentIndex === 0 ? 'opacity-40 cursor-not-allowed' : 'hover:bg-white/20 hover:text-white'
            }`}
            title="Geri Al"
          >
            <RotateCcw className="w-5 h-5" />
          </button>

          {/* KEEP BUTTON (RIGHT) */}
          <button
            onClick={() => {
              soundEngine.playKeepSound();
              handleSwipe('right');
            }}
            className="w-16 h-16 rounded-full liquid-button-success flex items-center justify-center text-white cursor-pointer group shadow-xl transition-all"
            title="Sakla (Sağa Kaydır)"
          >
            <Check className="w-8 h-8 group-hover:scale-125 transition-transform" />
          </button>

        </div>
      )}

    </div>
  );
};
