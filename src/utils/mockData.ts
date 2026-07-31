import type { Photo, MonthGroup } from '../types/photo';

export const INITIAL_PHOTOS: Photo[] = [
  // AUGUST 2025
  {
    id: 'p-aug-1',
    url: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?q=80&w=1000&auto=format&fit=crop',
    title: 'Ege Kıyıları - Gün Batımı',
    date: '2025-08-28',
    monthKey: '2025-08',
    monthName: 'Ağustos 2025',
    sizeMB: 6.4,
    width: 4032,
    height: 3024,
    location: 'Bodrum, Muğla',
    camera: 'iPhone 16 Pro (24mm, f/1.78, ISO 50)',
    qualityScore: 94,
    tags: ['Tatil', 'Deniz', 'Manzara'],
    isDuplicate: false
  },
  {
    id: 'p-aug-2',
    url: 'https://images.unsplash.com/photo-1519046904884-53103b34b206?q=80&w=1000&auto=format&fit=crop',
    title: 'Ege Kıyıları - Bulanık Kare (Tekrar)',
    date: '2025-08-28',
    monthKey: '2025-08',
    monthName: 'Ağustos 2025',
    sizeMB: 5.8,
    width: 4032,
    height: 3024,
    location: 'Bodrum, Muğla',
    camera: 'iPhone 16 Pro (24mm, f/1.78, ISO 64)',
    qualityScore: 42,
    isBlurry: true,
    isDuplicate: true,
    tags: ['Tekrar', 'Bulanık']
  },
  {
    id: 'p-aug-3',
    url: 'https://images.unsplash.com/photo-1540555700478-4be289fbecef?q=80&w=1000&auto=format&fit=crop',
    title: 'Sahil Kahvaltısı Tablosu',
    date: '2025-08-24',
    monthKey: '2025-08',
    monthName: 'Ağustos 2025',
    sizeMB: 4.9,
    width: 3840,
    height: 2880,
    location: 'Çeşme, İzmir',
    camera: 'iPhone 16 Pro (13mm Ultra Wide, ISO 80)',
    qualityScore: 88,
    tags: ['Yemek', 'Kahvaltı']
  },
  {
    id: 'p-aug-4',
    url: 'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?q=80&w=1000&auto=format&fit=crop',
    title: 'Kiralık Ev Ekran Görüntüsü',
    date: '2025-08-18',
    monthKey: '2025-08',
    monthName: 'Ağustos 2025',
    sizeMB: 2.3,
    width: 1179,
    height: 2556,
    location: 'İstanbul',
    camera: 'Screen Capture',
    qualityScore: 35,
    isScreenshot: true,
    tags: ['Ekran Görüntüsü', 'Geçici']
  },
  {
    id: 'p-aug-5',
    url: 'https://images.unsplash.com/photo-1506744038136-46273834b3fb?q=80&w=1000&auto=format&fit=crop',
    title: 'Dağ Göleti Doğa Yürüyüşü',
    date: '2025-08-10',
    monthKey: '2025-08',
    monthName: 'Ağustos 2025',
    sizeMB: 7.1,
    width: 4032,
    height: 3024,
    location: 'Kaçkar Dağları',
    camera: 'Sony A7 IV (35mm f/2.0)',
    qualityScore: 98,
    tags: ['Manzara', 'Dağ', 'Doğa']
  },

  // JULY 2025
  {
    id: 'p-jul-1',
    url: 'https://images.unsplash.com/photo-1492691527719-9d1e07e534b4?q=80&w=1000&auto=format&fit=crop',
    title: 'Yaz Konseri Işıkları',
    date: '2025-07-29',
    monthKey: '2025-07',
    monthName: 'Temmuz 2025',
    sizeMB: 5.2,
    width: 4032,
    height: 3024,
    location: 'KüçükÇiftlik Park, İstanbul',
    camera: 'iPhone 16 Pro (77mm Telephoto, ISO 400)',
    qualityScore: 86,
    tags: ['Etkinlik', 'Gece', 'Müzik']
  },
  {
    id: 'p-jul-2',
    url: 'https://images.unsplash.com/photo-1499856871958-5b9627545d1a?q=80&w=1000&auto=format&fit=crop',
    title: 'Paris Eyfel Kulesi Gezisi',
    date: '2025-07-20',
    monthKey: '2025-07',
    monthName: 'Temmuz 2025',
    sizeMB: 6.8,
    width: 4032,
    height: 3024,
    location: 'Paris, Fransa',
    camera: 'iPhone 16 Pro (24mm, f/1.78)',
    qualityScore: 96,
    tags: ['Seyahat', 'Mimari']
  },
  {
    id: 'p-jul-3',
    url: 'https://images.unsplash.com/photo-1502602898657-3e91760cbb34?q=80&w=1000&auto=format&fit=crop',
    title: 'Paris Eyfel Kulesi (Kötü Açı Tekrarı)',
    date: '2025-07-20',
    monthKey: '2025-07',
    monthName: 'Temmuz 2025',
    sizeMB: 6.1,
    width: 4032,
    height: 3024,
    location: 'Paris, Fransa',
    camera: 'iPhone 16 Pro (24mm, f/1.78)',
    qualityScore: 40,
    isDuplicate: true,
    isBlurry: true,
    tags: ['Tekrar', 'Seyahat']
  },
  {
    id: 'p-jul-4',
    url: 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?q=80&w=1000&auto=format&fit=crop',
    title: 'İtalyan Restoranı Akşam Yemeği',
    date: '2025-07-14',
    monthKey: '2025-07',
    monthName: 'Temmuz 2025',
    sizeMB: 3.9,
    width: 3024,
    height: 4032,
    location: 'Roma, İtalya',
    camera: 'iPhone 16 Pro (24mm, ISO 200)',
    qualityScore: 82,
    tags: ['Yemek', 'Akşam']
  },

  // JUNE 2025
  {
    id: 'p-jun-1',
    url: 'https://images.unsplash.com/photo-1501785888041-af3ef285b470?q=80&w=1000&auto=format&fit=crop',
    title: 'Kapadokya Balon Şöleni',
    date: '2025-06-22',
    monthKey: '2025-06',
    monthName: 'Haziran 2025',
    sizeMB: 8.4,
    width: 4032,
    height: 3024,
    location: 'Göreme, Kapadokya',
    camera: 'Fujifilm X-T5 (16-55mm f/2.8)',
    qualityScore: 99,
    tags: ['Doğa', 'Seyahat', 'Favori']
  },
  {
    id: 'p-jun-2',
    url: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?q=80&w=1000&auto=format&fit=crop',
    title: 'Otel Rezervasyon Makbuzu',
    date: '2025-06-15',
    monthKey: '2025-06',
    monthName: 'Haziran 2025',
    sizeMB: 1.8,
    width: 1179,
    height: 2556,
    location: 'Nevşehir',
    camera: 'Screen Capture',
    qualityScore: 20,
    isScreenshot: true,
    tags: ['Ekran Görüntüsü']
  },
  {
    id: 'p-jun-3',
    url: 'https://images.unsplash.com/photo-1470071459604-3b5ec3a7fe05?q=80&w=1000&auto=format&fit=crop',
    title: 'Sisli Orman Yolu',
    date: '2025-06-02',
    monthKey: '2025-06',
    monthName: 'Haziran 2025',
    sizeMB: 6.5,
    width: 4032,
    height: 3024,
    location: 'Bolu, Abant',
    camera: 'iPhone 16 Pro (48mm, f/2.8)',
    qualityScore: 91,
    tags: ['Doğa', 'Orman']
  },

  // MAY 2025
  {
    id: 'p-may-1',
    url: 'https://images.unsplash.com/photo-1534447677768-be436bb09401?q=80&w=1000&auto=format&fit=crop',
    title: 'Bahar Çiçekleri Makro',
    date: '2025-05-19',
    monthKey: '2025-05',
    monthName: 'Mayıs 2025',
    sizeMB: 5.9,
    width: 4032,
    height: 3024,
    location: 'Emirgan Parkı, İstanbul',
    camera: 'iPhone 16 Pro Macro Mode',
    qualityScore: 90,
    tags: ['Çiçek', 'Bahar']
  },
  {
    id: 'p-may-2',
    url: 'https://images.unsplash.com/photo-1513836279014-a89f7a76ae86?q=80&w=1000&auto=format&fit=crop',
    title: 'Park Sırasındaki Kediler',
    date: '2025-05-04',
    monthKey: '2025-05',
    monthName: 'Mayıs 2025',
    sizeMB: 4.8,
    width: 3024,
    height: 4032,
    location: 'Moda, Kadıköy',
    camera: 'iPhone 16 Pro (77mm Telephoto)',
    qualityScore: 89,
    tags: ['Evcil Hayvan', 'Kedi']
  }
];

export function groupPhotosByMonth(photos: Photo[]): MonthGroup[] {
  const map = new Map<string, Photo[]>();

  photos.forEach(photo => {
    if (!map.has(photo.monthKey)) {
      map.set(photo.monthKey, []);
    }
    map.get(photo.monthKey)!.push(photo);
  });

  const sortedKeys = Array.from(map.keys()).sort((a, b) => b.localeCompare(a));

  return sortedKeys.map(key => {
    const list = map.get(key)!;
    const name = list[0]?.monthName || key;
    const [yearStr, monthStr] = key.split('-');
    const totalSizeMB = list.reduce((acc, p) => acc + p.sizeMB, 0);
    const duplicateCount = list.filter(p => p.isDuplicate || p.isBlurry || p.isScreenshot).length;

    return {
      key,
      name,
      year: parseInt(yearStr, 10),
      monthNumber: parseInt(monthStr, 10),
      photos: list,
      totalSizeMB: parseFloat(totalSizeMB.toFixed(1)),
      duplicateCount,
      coverPhotoUrl: list[0]?.url || ''
    };
  });
}
