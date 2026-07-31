export interface Photo {
  id: string;
  url: string;
  title: string;
  date: string; // ISO format e.g. "2025-08-15"
  monthKey: string; // e.g. "2025-08"
  monthName: string; // e.g. "Ağustos 2025"
  sizeMB: number;
  width: number;
  height: number;
  location?: string;
  camera?: string;
  isDuplicate?: boolean;
  isBlurry?: boolean;
  isScreenshot?: boolean;
  qualityScore: number; // 0-100
  tags: string[];
}

export interface MonthGroup {
  key: string; // "2025-08"
  name: string; // "Ağustos 2025"
  year: number;
  monthNumber: number;
  photos: Photo[];
  totalSizeMB: number;
  duplicateCount: number;
  coverPhotoUrl: string;
}

export type ViewMode = 'dashboard' | 'swipe' | 'summary' | 'analytics';

export type SwipeDirection = 'left' | 'right' | null;

export interface TrashState {
  pendingDeleteIds: Set<string>;
  deletedIds: Set<string>;
  keptIds: Set<string>;
}
