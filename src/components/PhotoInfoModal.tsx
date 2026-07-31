import React from 'react';
import type { Photo } from '../types/photo';
import { 
  X, 
  Camera, 
  MapPin, 
  Calendar, 
  HardDrive, 
  Tag, 
  Award 
} from 'lucide-react';

interface PhotoInfoModalProps {
  photo: Photo;
  onClose: () => void;
}

export const PhotoInfoModal: React.FC<PhotoInfoModalProps> = ({ photo, onClose }) => {
  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/80 backdrop-blur-md animate-fadeIn">
      <div className="relative w-full max-w-md liquid-glass p-6 rounded-3xl space-y-5 shadow-2xl border border-white/30 overflow-hidden">
        
        {/* Header */}
        <div className="flex items-center justify-between border-b border-white/10 pb-3">
          <h3 className="font-extrabold text-white text-lg tracking-tight">EXIF Fotoğraf Detayları</h3>
          <button
            onClick={onClose}
            className="p-2 rounded-xl bg-white/10 hover:bg-white/20 text-slate-300 hover:text-white transition-all cursor-pointer"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Photo Thumbnail */}
        <div className="relative w-full h-48 rounded-2xl overflow-hidden border border-white/30 shadow-lg">
          <img src={photo.url} alt={photo.title} className="w-full h-full object-cover" />
          <div className="absolute bottom-2 left-2 px-3 py-1 rounded-xl bg-black/70 backdrop-blur-md border border-white/20 text-xs font-mono text-cyan-300">
            {photo.width} × {photo.height} px
          </div>
        </div>

        {/* Metadata List */}
        <div className="space-y-3 text-xs text-slate-300">
          <div className="flex items-center justify-between p-3 rounded-xl bg-white/5 border border-white/10">
            <span className="flex items-center gap-2 font-medium">
              <Camera className="w-4 h-4 text-cyan-400" />
              Kamera / Ekipman
            </span>
            <span className="font-mono text-white text-right font-semibold">{photo.camera || 'Bilinmiyor'}</span>
          </div>

          <div className="flex items-center justify-between p-3 rounded-xl bg-white/5 border border-white/10">
            <span className="flex items-center gap-2 font-medium">
              <Calendar className="w-4 h-4 text-cyan-400" />
              Çekim Tarihi
            </span>
            <span className="font-mono text-white font-semibold">{photo.date}</span>
          </div>

          <div className="flex items-center justify-between p-3 rounded-xl bg-white/5 border border-white/10">
            <span className="flex items-center gap-2 font-medium">
              <HardDrive className="w-4 h-4 text-cyan-400" />
              Dosya Boyutu
            </span>
            <span className="font-mono text-cyan-300 font-bold">{photo.sizeMB} MB</span>
          </div>

          {photo.location && (
            <div className="flex items-center justify-between p-3 rounded-xl bg-white/5 border border-white/10">
              <span className="flex items-center gap-2 font-medium">
                <MapPin className="w-4 h-4 text-rose-400" />
                Konum
              </span>
              <span className="font-medium text-white">{photo.location}</span>
            </div>
          )}

          <div className="flex items-center justify-between p-3 rounded-xl bg-white/5 border border-white/10">
            <span className="flex items-center gap-2 font-medium">
              <Award className="w-4 h-4 text-amber-400" />
              Yapay Zeka Kalite Skoru
            </span>
            <span className="font-mono text-amber-300 font-bold text-sm">{photo.qualityScore}/100</span>
          </div>
        </div>

        {/* Tags */}
        <div className="flex items-center gap-1.5 flex-wrap pt-1">
          <Tag className="w-3.5 h-3.5 text-slate-400 mr-1" />
          {photo.tags.map((t, idx) => (
            <span key={idx} className="px-2.5 py-1 rounded-lg bg-cyan-400/10 border border-cyan-400/30 text-cyan-200 text-[11px] font-medium">
              #{t}
            </span>
          ))}
        </div>

      </div>
    </div>
  );
};
