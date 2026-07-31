import React, { useState, useRef, useEffect } from 'react';
import type { Photo } from '../types/photo';
import { 
  Check, 
  Trash2, 
  Info, 
  ZoomIn, 
  MapPin, 
  Calendar, 
  Copy,
  AlertTriangle
} from 'lucide-react';
import { soundEngine } from '../utils/audio';

interface LiquidCardProps {
  photo: Photo;
  isTop: boolean;
  onSwipe: (direction: 'left' | 'right') => void;
  onOpenInfo: (photo: Photo) => void;
}

export const LiquidCard: React.FC<LiquidCardProps> = ({
  photo,
  isTop,
  onSwipe,
  onOpenInfo
}) => {
  const cardRef = useRef<HTMLDivElement>(null);
  
  // Drag physics state
  const [isDragging, setIsDragging] = useState(false);
  const [dragOffset, setDragOffset] = useState({ x: 0, y: 0 });
  const [startPos, setStartPos] = useState({ x: 0, y: 0 });
  
  // Dynamic Specular Highlight coordinates relative to card
  const [specularPos, setSpecularPos] = useState({ x: '50%', y: '30%' });
  
  // Zoom lens feature
  const [isLensActive, setIsLensActive] = useState(false);
  const [lensPos, setLensPos] = useState({ x: 0, y: 0 });

  // Reset offset on photo change
  useEffect(() => {
    setDragOffset({ x: 0, y: 0 });
    setIsDragging(false);
  }, [photo.id]);

  // Pointer event handlers for drag physics
  const handlePointerDown = (e: React.PointerEvent) => {
    if (!isTop) return;
    setIsDragging(true);
    setStartPos({ x: e.clientX, y: e.clientY });
    if (cardRef.current) {
      cardRef.current.setPointerCapture(e.pointerId);
    }
  };

  const handlePointerMove = (e: React.PointerEvent) => {
    if (!cardRef.current) return;

    // Calculate specular sheen coordinates
    const rect = cardRef.current.getBoundingClientRect();
    const relX = ((e.clientX - rect.left) / rect.width) * 100;
    const relY = ((e.clientY - rect.top) / rect.height) * 100;
    setSpecularPos({ x: `${relX}%`, y: `${relY}%` });
    setLensPos({ x: e.clientX - rect.left, y: e.clientY - rect.top });

    if (!isDragging || !isTop) return;

    const dx = e.clientX - startPos.x;
    const dy = e.clientY - startPos.y;
    setDragOffset({ x: dx, y: dy });

    // Haptic feedback tick on threshold reach
    if (Math.abs(dx) > 120 && Math.abs(dx) < 130) {
      soundEngine.playGlassTap();
    }
  };

  const handlePointerUp = () => {
    if (!isDragging || !isTop) return;
    setIsDragging(false);

    const threshold = 110;
    if (dragOffset.x > threshold) {
      // Swipe Right -> Keep
      soundEngine.playKeepSound();
      onSwipe('right');
    } else if (dragOffset.x < -threshold) {
      // Swipe Left -> Delete
      soundEngine.playDeleteSound();
      onSwipe('left');
    } else {
      // Fluid Spring Snapback
      setDragOffset({ x: 0, y: 0 });
    }
  };

  // Fluid spring physics & liquid deformation transforms
  const rotateDeg = dragOffset.x * 0.08;
  const skewDeg = (dragOffset.x * 0.02);
  const scaleRatio = isDragging ? 1.02 : 1;
  const deleteOpacity = Math.min(Math.max(-dragOffset.x / 140, 0), 1);
  const keepOpacity = Math.min(Math.max(dragOffset.x / 140, 0), 1);

  return (
    <div
      ref={cardRef}
      onPointerDown={handlePointerDown}
      onPointerMove={handlePointerMove}
      onPointerUp={handlePointerUp}
      onPointerCancel={handlePointerUp}
      style={{
        transform: `translate3d(${dragOffset.x}px, ${dragOffset.y}px, 0) rotate(${rotateDeg}deg) skewX(${skewDeg}deg) scale(${scaleRatio})`,
        transition: isDragging ? 'none' : 'transform 0.5s cubic-bezier(0.175, 0.885, 0.32, 1.275)',
        touchAction: 'none',
        '--mouse-x': specularPos.x,
        '--mouse-y': specularPos.y,
      } as React.CSSProperties}
      className={`absolute inset-0 w-full h-full rounded-3xl liquid-glass liquid-card-specular overflow-hidden select-none cursor-grab active:cursor-grabbing shadow-2xl ${
        isDragging ? 'liquid-dragging' : ''
      }`}
    >
      {/* Photo Background Image */}
      <img
        src={photo.url}
        alt={photo.title}
        className="w-full h-full object-cover pointer-events-none transition-transform duration-300"
      />

      {/* Fluid Lens Distortion Effect Circle */}
      {isLensActive && (
        <div 
          className="fluid-lens-spotlight"
          style={{
            left: `${lensPos.x}px`,
            top: `${lensPos.y}px`,
            backgroundImage: `url(${photo.url})`,
            backgroundSize: `${cardRef.current?.offsetWidth ? cardRef.current.offsetWidth * 1.6 : 600}px auto`,
            backgroundPosition: `-${lensPos.x * 1.6 - 70}px -${lensPos.y * 1.6 - 70}px`
          }}
        />
      )}

      {/* Dynamic Specular Highlights Overlay */}
      <div className="absolute inset-0 bg-gradient-to-br from-white/30 via-transparent to-black/40 pointer-events-none mix-blend-overlay" />
      
      {/* Specular Rim Gleam Edge */}
      <div className="absolute inset-x-0 top-0 h-1.5 bg-gradient-to-r from-transparent via-white to-transparent opacity-90 pointer-events-none" />

      {/* Swipe Badges Overlay */}
      
      {/* KEEP BADGE (RIGHT) */}
      <div 
        style={{ opacity: keepOpacity }}
        className="absolute top-8 left-8 transform -rotate-12 px-6 py-2.5 rounded-2xl bg-emerald-500/80 backdrop-filter backdrop-blur-xl border-2 border-white/80 text-white font-extrabold text-2xl tracking-wider uppercase shadow-2xl flex items-center gap-2 pointer-events-none z-30 transition-opacity"
      >
        <Check className="w-7 h-7 stroke-[3]" />
        <span>SAKLA</span>
      </div>

      {/* DELETE BADGE (LEFT) */}
      <div 
        style={{ opacity: deleteOpacity }}
        className="absolute top-8 right-8 transform rotate-12 px-6 py-2.5 rounded-2xl bg-rose-500/80 backdrop-filter backdrop-blur-xl border-2 border-white/80 text-white font-extrabold text-2xl tracking-wider uppercase shadow-2xl flex items-center gap-2 pointer-events-none z-30 transition-opacity"
      >
        <Trash2 className="w-7 h-7 stroke-[3]" />
        <span>SİL</span>
      </div>

      {/* Smart Warning Badges */}
      <div className="absolute top-4 left-4 right-4 flex items-center justify-between pointer-events-none z-20">
        <div className="flex items-center gap-2">
          {photo.isDuplicate && (
            <span className="px-3 py-1 rounded-xl bg-amber-500/80 backdrop-blur-md border border-white/40 text-amber-950 font-bold text-xs flex items-center gap-1 shadow-lg">
              <Copy className="w-3.5 h-3.5" />
              Gereksiz Kare
            </span>
          )}

          {photo.isScreenshot && (
            <span className="px-3 py-1 rounded-xl bg-purple-500/80 backdrop-blur-md border border-white/40 text-white font-bold text-xs shadow-lg">
              Ekran Görüntüsü
            </span>
          )}

          {photo.isBlurry && (
            <span className="px-3 py-1 rounded-xl bg-red-500/80 backdrop-blur-md border border-white/40 text-white font-bold text-xs flex items-center gap-1 shadow-lg">
              <AlertTriangle className="w-3.5 h-3.5" />
              Bulanık Fotoğraf
            </span>
          )}
        </div>

        {/* Quality Score Lens Badge */}
        <span className="px-3 py-1 rounded-xl bg-black/60 backdrop-blur-md border border-white/30 text-cyan-300 font-mono text-xs font-bold shadow-md">
          {photo.qualityScore}/100 Kalite
        </span>
      </div>

      {/* Liquid Card Bottom Bar */}
      <div className="absolute bottom-0 inset-x-0 p-5 bg-gradient-to-t from-black/90 via-black/50 to-transparent backdrop-blur-xs flex items-end justify-between z-20">
        <div className="space-y-1 text-white max-w-[70%]">
          <h3 className="font-extrabold text-lg tracking-tight leading-snug drop-shadow-md">
            {photo.title}
          </h3>

          <div className="flex flex-wrap items-center gap-3 text-xs text-slate-300/90 font-medium">
            <span className="flex items-center gap-1">
              <Calendar className="w-3.5 h-3.5 text-cyan-400" />
              {photo.date}
            </span>
            <span className="flex items-center gap-1 font-mono text-cyan-200">
              {photo.sizeMB} MB
            </span>
            {photo.location && (
              <span className="flex items-center gap-1 text-slate-300">
                <MapPin className="w-3.5 h-3.5 text-rose-400" />
                {photo.location}
              </span>
            )}
          </div>
        </div>

        {/* Action Utility Controls */}
        <div className="flex items-center gap-2">
          {/* Zoom Lens Toggle */}
          <button
            type="button"
            onClick={(e) => {
              e.stopPropagation();
              soundEngine.playGlassTap();
              setIsLensActive(!isLensActive);
            }}
            className={`p-3 rounded-2xl border transition-all cursor-pointer ${
              isLensActive
                ? 'bg-cyan-500 text-white border-cyan-300 shadow-lg shadow-cyan-500/40'
                : 'bg-white/15 hover:bg-white/25 text-white border-white/30'
            }`}
            title="Sıvı Mercek Büyüteci"
          >
            <ZoomIn className="w-4 h-4" />
          </button>

          {/* EXIF Info Button */}
          <button
            type="button"
            onClick={(e) => {
              e.stopPropagation();
              soundEngine.playGlassTap();
              onOpenInfo(photo);
            }}
            className="p-3 rounded-2xl bg-white/15 hover:bg-white/25 border border-white/30 text-white transition-all cursor-pointer"
            title="Fotoğraf Detayları"
          >
            <Info className="w-4 h-4" />
          </button>
        </div>
      </div>
    </div>
  );
};
