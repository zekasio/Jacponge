import React, { useState } from 'react';
import type { Photo } from '../types/photo';
import confetti from 'canvas-confetti';
import { soundEngine } from '../utils/audio';

interface NativeTrashDialogProps {
  photosToDelete: Photo[];
  onConfirmNativeDelete: () => void;
  onCancel: () => void;
}

export const NativeTrashDialog: React.FC<NativeTrashDialogProps> = ({
  photosToDelete,
  onConfirmNativeDelete,
  onCancel
}) => {
  const [osStyle, setOsStyle] = useState<'ios' | 'android'>('ios');
  const count = photosToDelete.length;
  const totalMB = photosToDelete.reduce((acc, p) => acc + p.sizeMB, 0);

  const handleConfirm = () => {
    try {
      confetti({
        particleCount: 80,
        spread: 70,
        origin: { y: 0.6 }
      });
    } catch {
      // Ignored if confetti fails
    }

    soundEngine.playDeleteSound();
    onConfirmNativeDelete();
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/80 backdrop-blur-xl animate-fadeIn">
      
      {/* OS Style Switcher Pill */}
      <div className="absolute top-6 flex items-center gap-2 bg-white/10 p-1.5 rounded-2xl border border-white/20">
        <button
          onClick={() => setOsStyle('ios')}
          className={`px-3 py-1.5 rounded-xl text-xs font-bold transition-all ${
            osStyle === 'ios' ? 'bg-cyan-500 text-white shadow-md' : 'text-slate-300 hover:text-white'
          }`}
        >
          Apple iOS Intent (PHAsset)
        </button>
        <button
          onClick={() => setOsStyle('android')}
          className={`px-3 py-1.5 rounded-xl text-xs font-bold transition-all ${
            osStyle === 'android' ? 'bg-emerald-500 text-white shadow-md' : 'text-slate-300 hover:text-white'
          }`}
        >
          Android Intent (MediaStore)
        </button>
      </div>

      {osStyle === 'ios' ? (
        /* APPLE iOS 19 NATIVE SYSTEM INTENT DIALOG (PHAssetChangeRequest.deleteAssets) */
        <div className="relative w-full max-w-sm rounded-[32px] bg-slate-900/90 backdrop-filter backdrop-blur-3xl border border-white/30 p-6 text-center shadow-2xl space-y-5 animate-scaleUp">
          
          <div className="w-14 h-14 rounded-2xl bg-rose-500/20 border border-rose-400/40 text-rose-400 flex items-center justify-center mx-auto shadow-inner">
            <svg className="w-7 h-7 fill-current" viewBox="0 0 24 24">
              <path d="M19 4h-3.5l-1-1h-5l-1 1H5v2h14M6 19a2 2 0 002 2h8a2 2 0 002-2V7H6v12z"/>
            </svg>
          </div>

          <div className="space-y-2">
            <h3 className="font-extrabold text-white text-xl tracking-tight">
              "{count} Fotoğraf" Silinsin mi?
            </h3>
            <p className="text-xs text-slate-300 leading-relaxed font-sans">
              Bu fotoğraflar cihazınızın galerisinden silinecek ve <strong className="text-white">Fotoğraflar "Son Silinenler"</strong> klasörüne taşınacaktır. (30 gün içinde geri yüklenebilir).
            </p>
          </div>

          {/* Mini Thumbnail Stack */}
          <div className="flex items-center justify-center gap-1.5 py-1">
            {photosToDelete.slice(0, 4).map(p => (
              <img
                key={p.id}
                src={p.url}
                alt=""
                className="w-12 h-12 rounded-xl object-cover border border-white/30 shadow-md"
              />
            ))}
            {count > 4 && (
              <div className="w-12 h-12 rounded-xl bg-white/10 border border-white/20 flex items-center justify-center text-xs font-mono text-cyan-300">
                +{count - 4}
              </div>
            )}
          </div>

          <div className="text-[11px] font-mono text-emerald-400">
            Geri Kazanılacak Alan: {totalMB.toFixed(1)} MB
          </div>

          {/* Action Buttons (iOS Action Sheet style) */}
          <div className="pt-2 space-y-2.5">
            <button
              onClick={handleConfirm}
              className="w-full py-3.5 rounded-2xl bg-rose-600 hover:bg-rose-500 active:scale-95 text-white font-bold text-sm transition-all shadow-lg shadow-rose-600/30 cursor-pointer"
            >
              Fotoğrafları Sil
            </button>

            <button
              onClick={onCancel}
              className="w-full py-3 rounded-2xl bg-white/10 hover:bg-white/20 text-slate-300 text-sm font-semibold cursor-pointer transition-all"
            >
              Vazgeç
            </button>
          </div>

          <p className="text-[10px] text-slate-500 uppercase tracking-widest font-semibold pt-1">
            iOS PHAssetChangeRequest.deleteAssets()
          </p>
        </div>
      ) : (
        /* ANDROID NATIVE MEDIASTORE TRASH INTENT DIALOG (createTrashRequest) */
        <div className="relative w-full max-w-sm rounded-3xl bg-slate-900 border border-slate-700 p-6 text-left shadow-2xl space-y-4 animate-scaleUp">
          
          <div className="flex items-center gap-3">
            <div className="p-2.5 rounded-full bg-rose-500/20 text-rose-400">
              <svg className="w-6 h-6 fill-current" viewBox="0 0 24 24">
                <path d="M19 4h-3.5l-1-1h-5l-1 1H5v2h14M6 19a2 2 0 002 2h8a2 2 0 002-2V7H6v12z"/>
              </svg>
            </div>
            <div>
              <h3 className="font-bold text-white text-lg">Öğeler Çöp Kutusuna Taşınsın mı?</h3>
              <p className="text-xs text-slate-400">Android MediaStore createTrashRequest</p>
            </div>
          </div>

          <p className="text-xs text-slate-300 leading-relaxed">
            Seçilen {count} fotoğraf ({totalMB.toFixed(1)} MB) cihazınızdaki Çöp Kutusu'na gönderilecektir.
          </p>

          <div className="flex items-center justify-end gap-3 pt-3">
            <button
              onClick={onCancel}
              className="px-5 py-2.5 rounded-xl text-slate-300 hover:bg-white/10 text-xs font-bold transition-all cursor-pointer"
            >
              İPTAL
            </button>

            <button
              onClick={handleConfirm}
              className="px-6 py-2.5 rounded-xl bg-rose-600 hover:bg-rose-500 text-white text-xs font-bold transition-all shadow-md cursor-pointer"
            >
              ÇÖP KUTUSUNA TAŞI
            </button>
          </div>
        </div>
      )}

    </div>
  );
};
