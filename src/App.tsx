import { useState, useMemo } from 'react';
import type { Photo, ViewMode } from './types/photo';
import { INITIAL_PHOTOS, groupPhotosByMonth } from './utils/mockData';
import { LiquidGlassOverlay } from './components/LiquidGlassOverlay';
import { Navbar } from './components/Navbar';
import { Dashboard } from './components/Dashboard';
import { LiquidCardStack } from './components/LiquidCardStack';
import { MonthSummaryModal } from './components/MonthSummaryModal';
import { NativeTrashDialog } from './components/NativeTrashDialog';
import { StorageAnalyticsModal } from './components/StorageAnalyticsModal';
import { PhotoInfoModal } from './components/PhotoInfoModal';
import { UploadModal } from './components/UploadModal';
import { DeviceFrame } from './components/DeviceFrame';

export function App() {
  // Master Photo Store
  const [photos, setPhotos] = useState<Photo[]>(INITIAL_PHOTOS);
  const [cleanedStorageMB, setCleanedStorageMB] = useState<number>(0);
  
  // Navigation & View State
  const [viewMode, setViewMode] = useState<ViewMode>('dashboard');
  const [activeMonthKey, setActiveMonthKey] = useState<string | null>(null);

  // Active Trash Operations
  const [pendingTrashPhotos, setPendingTrashPhotos] = useState<Photo[]>([]);
  
  // Modal Triggers
  const [showSummaryModal, setShowSummaryModal] = useState<boolean>(false);
  const [showNativeTrashDialog, setShowNativeTrashDialog] = useState<boolean>(false);
  const [showAnalyticsModal, setShowAnalyticsModal] = useState<boolean>(false);
  const [showUploadModal, setShowUploadModal] = useState<boolean>(false);
  const [selectedInfoPhoto, setSelectedInfoPhoto] = useState<Photo | null>(null);

  // Device Frame Toggle
  const [isDeviceFrame, setIsDeviceFrame] = useState<boolean>(false);

  // Group photos by month
  const monthGroups = useMemo(() => {
    return groupPhotosByMonth(photos);
  }, [photos]);

  const activeMonthGroup = useMemo(() => {
    if (!activeMonthKey) return monthGroups[0] || null;
    return monthGroups.find(m => m.key === activeMonthKey) || monthGroups[0] || null;
  }, [monthGroups, activeMonthKey]);

  // Total stats
  const totalPhotosCount = photos.length;
  const totalStorageMB = photos.reduce((acc, p) => acc + p.sizeMB, 0);

  // Handlers
  const handleSelectMonth = (monthKey: string) => {
    setActiveMonthKey(monthKey);
    setViewMode('swipe');
  };

  const handleFinishStack = (pendingDeleteIds: string[]) => {
    const photosToDelete = photos.filter(p => pendingDeleteIds.includes(p.id));
    setPendingTrashPhotos(photosToDelete);
    setShowSummaryModal(true);
  };

  const handleConfirmSummaryDelete = (photosToDelete: Photo[]) => {
    setPendingTrashPhotos(photosToDelete);
    setShowSummaryModal(false);
    setShowNativeTrashDialog(true);
  };

  const handleConfirmNativeDelete = () => {
    const idsToRemove = new Set(pendingTrashPhotos.map(p => p.id));
    const freedMB = pendingTrashPhotos.reduce((acc, p) => acc + p.sizeMB, 0);

    setPhotos(prev => prev.filter(p => !idsToRemove.has(p.id)));
    setCleanedStorageMB(prev => prev + freedMB);
    setPendingTrashPhotos([]);
    setShowNativeTrashDialog(false);
    setViewMode('dashboard');
  };

  const handleAddPhotos = (newPhotos: Photo[]) => {
    setPhotos(prev => [...newPhotos, ...prev]);
  };

  const handleQuickCleanDuplicates = () => {
    const dups = photos.filter(p => p.isDuplicate || p.isBlurry);
    if (dups.length === 0) return;
    setPendingTrashPhotos(dups);
    setShowNativeTrashDialog(true);
  };

  const handleQuickCleanAll = () => {
    if (monthGroups.length > 0) {
      setActiveMonthKey(monthGroups[0].key);
      setViewMode('swipe');
    }
  };

  return (
    <DeviceFrame enabled={isDeviceFrame}>
      <div className="min-h-screen w-full relative overflow-x-hidden text-slate-100 flex flex-col justify-between">
        
        {/* SVG Liquid Refraction Filters */}
        <LiquidGlassOverlay />

        {/* Global Ambient Fluid Light Orbs */}
        <div className="fixed top-0 left-1/4 w-96 h-96 rounded-full bg-cyan-500/10 blur-[120px] pointer-events-none z-0" />
        <div className="fixed bottom-10 right-1/4 w-[500px] h-[500px] rounded-full bg-blue-600/10 blur-[150px] pointer-events-none z-0" />

        {/* Navigation Bar */}
        <Navbar
          cleanedMB={cleanedStorageMB}
          pendingCount={pendingTrashPhotos.length}
          isDeviceFrame={isDeviceFrame}
          onToggleDeviceFrame={() => setIsDeviceFrame(!isDeviceFrame)}
          onOpenUpload={() => setShowUploadModal(true)}
          onOpenAnalytics={() => setShowAnalyticsModal(true)}
          onOpenPendingSummary={() => setShowSummaryModal(true)}
        />

        {/* Main Content Router */}
        <main className="flex-1 w-full relative z-10">
          {viewMode === 'dashboard' && (
            <Dashboard
              months={monthGroups}
              totalPhotos={totalPhotosCount}
              totalStorageMB={totalStorageMB}
              onSelectMonth={handleSelectMonth}
              onOpenQuickCleanAll={handleQuickCleanAll}
            />
          )}

          {viewMode === 'swipe' && activeMonthGroup && (
            <LiquidCardStack
              month={activeMonthGroup}
              onFinishStack={handleFinishStack}
              onBackToDashboard={() => setViewMode('dashboard')}
              onOpenInfo={(photo) => setSelectedInfoPhoto(photo)}
            />
          )}
        </main>

        {/* Footer */}
        <footer className="w-full py-4 text-center text-xs text-slate-400 border-t border-white/10 backdrop-blur-md relative z-10">
          <p className="font-mono">Apple Liquid Glass Optics Engine • Tinder Photo Cleaner</p>
        </footer>

        {/* Modals & Overlays */}
        {showSummaryModal && (
          <MonthSummaryModal
            monthName={activeMonthGroup?.name || 'Ağustos 2025'}
            pendingPhotos={pendingTrashPhotos}
            onConfirmDelete={handleConfirmSummaryDelete}
            onClose={() => setShowSummaryModal(false)}
          />
        )}

        {showNativeTrashDialog && (
          <NativeTrashDialog
            photosToDelete={pendingTrashPhotos}
            onConfirmNativeDelete={handleConfirmNativeDelete}
            onCancel={() => setShowNativeTrashDialog(false)}
          />
        )}

        {showAnalyticsModal && (
          <StorageAnalyticsModal
            months={monthGroups}
            totalCleanedMB={cleanedStorageMB}
            onClose={() => setShowAnalyticsModal(false)}
            onQuickCleanDuplicates={handleQuickCleanDuplicates}
          />
        )}

        {selectedInfoPhoto && (
          <PhotoInfoModal
            photo={selectedInfoPhoto}
            onClose={() => setSelectedInfoPhoto(null)}
          />
        )}

        {showUploadModal && (
          <UploadModal
            onAddPhotos={handleAddPhotos}
            onClose={() => setShowUploadModal(false)}
          />
        )}

      </div>
    </DeviceFrame>
  );
}

export default App;
