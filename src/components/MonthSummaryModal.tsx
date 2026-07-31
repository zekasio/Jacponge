import React, { useState } from 'react';
import type { Photo } from '../types/photo';
import { 
  X, 
  Trash2, 
  RotateCcw, 
  CheckCircle2, 
  HardDrive
} from 'lucide-react';
import { soundEngine } from '../utils/audio';

interface MonthSummaryModalProps {
  monthName: string;
  pendingPhotos: Photo[];
  onConfirmDelete: (photosToDelete: Photo[]) => void;
  onClose: () => void;
}

export const MonthSummaryModal: React.FC<MonthSummaryModalProps> = ({
  monthName,
  pendingPhotos,
  onConfirmDelete,
  onClose
}) => {
  const [selectedPhotoIds, setSelectedPhotoIds] = useState<Set<string>>(
    new Set(pendingPhotos.map(p => p.id))
  );

  const toggleRestore = (id: string) => {
    soundEngine.playRestoreSound();
    const next = new Set(selectedPhotoIds);
    if (next.has(id)) {
      next.delete(id);
    } else {
      next.add(id);
    }
    setSelectedPhotoIds(next);
  };

  const activeDeletePhotos = pendingPhotos.filter(p => selectedPhotoIds.has(p.id));
  const activeDeleteMB = activeDeletePhotos.reduce((acc, p) => acc + p.sizeMB, 0);

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/75 backdrop-blur-md animate-fadeIn">
      
      {/* Liquid Glass Modal Container */}
      <div className="relative w-full max-w-2xl max-h-[90vh] liquid-glass p-6 md:p-8 flex flex-col justify-between overflow-hidden shadow-2xl border border-white/30 rounded-3xl">
        
        {/* Animated Shimmer Lens Header */}
        <div className="flex items-center justify-between border-b border-white/10 pb-4 mb-4">
          <div className="flex items-center gap-3">
            <div className="p-3 rounded-2xl bg-rose-500/20 text-rose-400 border border-rose-400/40">
              <Trash2 className="w-6 h-6" />
            </div>
            <div>
              <h2 className="text-2xl font-extrabold text-white tracking-tight">
                {monthName} — Temizlik Özeti
              </h2>
              <p className="text-xs text-slate-300">
                Silinmek üzere işaretlenmiş fotoğrafları inceleyin ve onaylayın
              </p>
            </div>
          </div>

          <button
            onClick={onClose}
            className="p-2 rounded-xl bg-white/10 hover:bg-white/20 text-slate-300 hover:text-white transition-all cursor-pointer"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* ÜST BÖLÜM: Silinecek Fotoğrafların Ufak Önizleme Grid'i */}
        <div className="flex-1 overflow-y-auto pr-1 my-2 space-y-4">
          
          {pendingPhotos.length > 0 ? (
            <div>
              <div className="flex items-center justify-between text-xs text-slate-400 mb-3">
                <span>Seçilen Fotoğraflar (İptal etmek için fotoğrafa tıklayın)</span>
                <span className="font-mono text-cyan-300 font-bold">
                  {activeDeletePhotos.length} / {pendingPhotos.length} Seçili
                </span>
              </div>

              {/* Grid Preview */}
              <div className="grid grid-cols-3 sm:grid-cols-4 gap-3">
                {pendingPhotos.map(photo => {
                  const isSelected = selectedPhotoIds.has(photo.id);

                  return (
                    <div
                      key={photo.id}
                      onClick={() => toggleRestore(photo.id)}
                      className={`relative aspect-square rounded-2xl overflow-hidden cursor-pointer border-2 transition-all group ${
                        isSelected
                          ? 'border-rose-500/80 opacity-100 ring-2 ring-rose-500/40'
                          : 'border-white/20 opacity-40 hover:opacity-80 scale-95'
                      }`}
                    >
                      <img
                        src={photo.url}
                        alt={photo.title}
                        className="w-full h-full object-cover group-hover:scale-105 transition-transform"
                      />
                      <div className="absolute inset-0 bg-black/30" />

                      {/* Selection Badge Overlay */}
                      <div className="absolute top-1.5 right-1.5">
                        {isSelected ? (
                          <div className="p-1 rounded-full bg-rose-600 text-white shadow-md">
                            <X className="w-3.5 h-3.5" />
                          </div>
                        ) : (
                          <div className="p-1 rounded-full bg-emerald-500 text-white shadow-md">
                            <RotateCcw className="w-3.5 h-3.5" />
                          </div>
                        )}
                      </div>

                      <div className="absolute bottom-1 left-1.5 text-[10px] font-mono text-white font-bold drop-shadow">
                        {photo.sizeMB} MB
                      </div>
                    </div>
                  );
                })}
              </div>
            </div>
          ) : (
            /* No photos marked for delete */
            <div className="p-8 text-center space-y-3">
              <CheckCircle2 className="w-12 h-12 text-emerald-400 mx-auto" />
              <h3 className="text-xl font-bold text-white">Harika! Silinecek Fotoğraf Yok</h3>
              <p className="text-xs text-slate-300">
                Bu aydaki tüm fotoğraflar saklandı.
              </p>
            </div>
          )}

        </div>

        {/* ALT BÖLÜM: Sabit Duran Sıvı Cam Kaplamalı Baskın "X Fotoğrafı Cihazdan Sil" Butonu */}
        <div className="pt-4 border-t border-white/10 flex flex-col sm:flex-row items-center justify-between gap-4">
          <div className="flex items-center gap-3 text-xs text-slate-300">
            <HardDrive className="w-4 h-4 text-cyan-400" />
            <span>Kazanılacak Depolama: <strong className="text-white font-mono text-sm">{activeDeleteMB.toFixed(1)} MB</strong></span>
          </div>

          <div className="flex items-center gap-3 w-full sm:w-auto">
            <button
              onClick={onClose}
              className="px-4 py-3 rounded-2xl bg-white/10 hover:bg-white/20 text-slate-200 text-xs font-semibold cursor-pointer w-full sm:w-auto text-center"
            >
              Vazgeç
            </button>

            <button
              onClick={() => {
                if (activeDeletePhotos.length === 0) return;
                soundEngine.playTrashIntentSound();
                onConfirmDelete(activeDeletePhotos);
              }}
              disabled={activeDeletePhotos.length === 0}
              className={`liquid-button-danger px-6 py-3.5 rounded-2xl font-bold text-white text-sm flex items-center justify-center gap-2 cursor-pointer w-full sm:w-auto shadow-xl ${
                activeDeletePhotos.length === 0 ? 'opacity-40 cursor-not-allowed' : 'hover:scale-105'
              }`}
            >
              <Trash2 className="w-4.5 h-4.5 text-white" />
              <span>
                {activeDeletePhotos.length > 0
                  ? `${activeDeletePhotos.length} Fotoğrafı Cihazdan Sil (${activeDeleteMB.toFixed(1)} MB)`
                  : 'Fotoğraf Seçilmedi'}
              </span>
            </button>
          </div>
        </div>

      </div>
    </div>
  );
};
