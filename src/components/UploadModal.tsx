import React, { useState } from 'react';
import type { Photo } from '../types/photo';
import { X, Upload, Image as ImageIcon, Sparkles } from 'lucide-react';
import { soundEngine } from '../utils/audio';

interface UploadModalProps {
  onAddPhotos: (newPhotos: Photo[]) => void;
  onClose: () => void;
}

export const UploadModal: React.FC<UploadModalProps> = ({ onAddPhotos, onClose }) => {
  const [dragOver, setDragOver] = useState(false);

  const handleFiles = (files: FileList | null) => {
    if (!files || files.length === 0) return;

    soundEngine.playKeepSound();
    const newPhotos: Photo[] = [];
    const today = new Date().toISOString().split('T')[0];
    const monthKey = today.substring(0, 7);
    const [year, month] = monthKey.split('-');
    
    const monthsTr = ['Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran', 'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'];
    const monthName = `${monthsTr[parseInt(month, 10) - 1]} ${year}`;

    Array.from(files).forEach((file, index) => {
      const url = URL.createObjectURL(file);
      const sizeMB = parseFloat((file.size / (1024 * 1024)).toFixed(2)) || 3.2;

      newPhotos.push({
        id: `custom-upload-${Date.now()}-${index}`,
        url,
        title: file.name.replace(/\.[^/.]+$/, ""),
        date: today,
        monthKey,
        monthName,
        sizeMB,
        width: 3840,
        height: 2160,
        qualityScore: Math.floor(Math.random() * 30) + 70,
        tags: ['Yüklenen', 'Cihaz'],
        isDuplicate: index % 3 === 1
      });
    });

    onAddPhotos(newPhotos);
    onClose();
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/80 backdrop-blur-md animate-fadeIn">
      <div className="relative w-full max-w-lg liquid-glass p-6 md:p-8 rounded-3xl space-y-6 shadow-2xl border border-white/30 overflow-hidden">
        
        {/* Header */}
        <div className="flex items-center justify-between border-b border-white/10 pb-4">
          <div className="flex items-center gap-3">
            <div className="p-3 rounded-2xl bg-cyan-500/20 text-cyan-300 border border-cyan-400/40">
              <Upload className="w-6 h-6" />
            </div>
            <div>
              <h2 className="text-2xl font-extrabold text-white tracking-tight">Kendi Fotoğraflarınızı Yükleyin</h2>
              <p className="text-xs text-slate-300">Yerel fotoğraflarınızı sıvı temizleyiciye aktarın</p>
            </div>
          </div>

          <button
            onClick={onClose}
            className="p-2 rounded-xl bg-white/10 hover:bg-white/20 text-slate-300 hover:text-white transition-all cursor-pointer"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Drag & Drop Area */}
        <div
          onDragOver={(e) => { e.preventDefault(); setDragOver(true); }}
          onDragLeave={() => setDragOver(false)}
          onDrop={(e) => {
            e.preventDefault();
            setDragOver(false);
            handleFiles(e.dataTransfer.files);
          }}
          className={`p-8 rounded-3xl border-2 border-dashed transition-all flex flex-col items-center justify-center text-center space-y-3 cursor-pointer ${
            dragOver
              ? 'border-cyan-400 bg-cyan-500/20 scale-102'
              : 'border-white/30 bg-white/5 hover:bg-white/10'
          }`}
        >
          <div className="w-16 h-16 rounded-2xl bg-cyan-400/20 text-cyan-300 flex items-center justify-center border border-cyan-400/40 shadow-inner">
            <ImageIcon className="w-8 h-8 animate-pulse" />
          </div>

          <div className="space-y-1">
            <h3 className="text-lg font-bold text-white">Fotoğrafları Sürükleyin & Bırakın</h3>
            <p className="text-xs text-slate-400">veya bilgisayarınızdan dosya seçin</p>
          </div>

          <label className="liquid-button-primary px-6 py-2.5 rounded-xl font-bold text-white text-xs cursor-pointer shadow-md flex items-center gap-2">
            <Sparkles className="w-4 h-4 text-cyan-200" />
            <span>Fotoğrafları Seç</span>
            <input
              type="file"
              multiple
              accept="image/*"
              className="hidden"
              onChange={(e) => handleFiles(e.target.files)}
            />
          </label>
        </div>

      </div>
    </div>
  );
};
