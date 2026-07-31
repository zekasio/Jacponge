import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:vibration/vibration.dart';
import 'native_bridge.dart';

void main() {
  runApp(const LiquidCleanApp());
}

class LiquidCleanApp extends StatelessWidget {
  const LiquidCleanApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LiquidClean PRO',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF030712),
        primarySwatch: Colors.cyan,
      ),
      home: const DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<AssetEntity> _photos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPhotos();
  }

  Future<void> _fetchPhotos() async {
    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    if (ps.isAuth) {
      List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(onlyAll: true, type: RequestType.image);
      if (albums.isNotEmpty) {
        List<AssetEntity> photos = await albums[0].getAssetListPaged(page: 0, size: 50);
        setState(() {
          _photos = photos;
          _isLoading = false;
        });
      }
    } else {
      PhotoManager.openSetting();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Ambient Background Orbs
          Positioned(
            top: -100, left: -100,
            child: Container(width: 400, height: 400, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.cyan.withOpacity(0.15), filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100))),
          ),
          
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Text('Ağustos 2025\nSıvı Deste', style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: Colors.white, height: 1.1)),
                ),
                
                Expanded(
                  child: _isLoading 
                    ? const Center(child: CircularProgressIndicator()) 
                    : _photos.isEmpty 
                      ? const Center(child: Text("Fotoğraf bulunamadı"))
                      : Center(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => SwipeScreen(photos: _photos)));
                            },
                            child: GlassmorphicContainer(
                              width: 300,
                              height: 350,
                              borderRadius: 30,
                              blur: 25,
                              alignment: Alignment.bottomCenter,
                              border: 1.5,
                              linearGradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Colors.white.withOpacity(0.15), Colors.white.withOpacity(0.05)]),
                              borderGradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Colors.white.withOpacity(0.5), Colors.white.withOpacity(0.1)]),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.style, size: 60, color: Colors.cyanAccent),
                                    const SizedBox(height: 16),
                                    Text('${_photos.length} Fotoğraf', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                                    const Text('Temizlemeye Başla', style: TextStyle(fontSize: 16, color: Colors.white70)),
                                  ],
                                )
                              ),
                            ),
                          ),
                        ),
                )
              ],
            ),
          )
        ],
      )
    );
  }
}

// ------ Swipe Screen ------
class SwipeScreen extends StatefulWidget {
  final List<AssetEntity> photos;
  const SwipeScreen({Key? key, required this.photos}) : super(key: key);

  @override
  State<SwipeScreen> createState() => _SwipeScreenState();
}

class _SwipeScreenState extends State<SwipeScreen> {
  final CardSwiperController controller = CardSwiperController();
  List<AssetEntity> _pendingDeletes = [];

  bool _onSwipe(int previousIndex, int? currentIndex, CardSwiperDirection direction) {
    if (direction == CardSwiperDirection.left) {
      _pendingDeletes.add(widget.photos[previousIndex]);
      _triggerHaptic(true); // Heavy haptic for delete
    } else {
      _triggerHaptic(false); // Light haptic for keep
    }
    return true;
  }

  void _triggerHaptic(bool heavy) async {
    if (await Vibration.hasVibrator() ?? false) {
      if (heavy) {
        Vibration.vibrate(duration: 80, amplitude: 255);
      } else {
        Vibration.vibrate(duration: 40, amplitude: 100);
      }
    }
  }

  void _onEnd() {
    // Show summary modal when stack finishes
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => SummaryModal(
        photosToDelete: _pendingDeletes, 
        onConfirm: () async {
          Navigator.pop(context); // Close modal
          
          // MAP Asset IDs to Android MediaStore URIs
          // In actual app, get MediaURI from AssetEntity using flutter plugin
          // For demo, we use placeholder format logic: "content://media/external/images/media/{id}"
          List<String> uris = _pendingDeletes.map((e) => "content://media/external/images/media/${e.id}").toList();
          
          bool success = await NativeBridge.trashPhotos(uris);
          
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cihaz Çöp Kutusuna Taşındı! 🎉'), backgroundColor: Colors.green));
            Navigator.pop(context); // Return to dashboard
          } else {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Silme işlemi iptal edildi veya hata oluştu.'), backgroundColor: Colors.red));
          }
        }
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Liquid Stack'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: CardSwiper(
              controller: controller,
              cardsCount: widget.photos.length,
              onSwipe: _onSwipe,
              onEnd: _onEnd,
              numberOfCardsDisplayed: 3,
              backCardOffset: const Offset(0, 40),
              cardBuilder: (context, index, percentThresholdX, percentThresholdY) {
                final photo = widget.photos[index];
                return LiquidCard(photo: photo, percentX: percentThresholdX);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 40, top: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                FloatingActionButton(
                  heroTag: 'btn_del',
                  onPressed: () => controller.swipe(CardSwiperDirection.left),
                  backgroundColor: Colors.redAccent.withOpacity(0.2),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30), side: BorderSide(color: Colors.redAccent.withOpacity(0.5))),
                  child: const Icon(Icons.close, color: Colors.redAccent, size: 30),
                ),
                FloatingActionButton(
                  heroTag: 'btn_undo',
                  onPressed: () => controller.undo(),
                  backgroundColor: Colors.white.withOpacity(0.1),
                  elevation: 0,
                  child: const Icon(Icons.undo, color: Colors.white),
                ),
                FloatingActionButton(
                  heroTag: 'btn_keep',
                  onPressed: () => controller.swipe(CardSwiperDirection.right),
                  backgroundColor: Colors.greenAccent.withOpacity(0.2),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30), side: BorderSide(color: Colors.greenAccent.withOpacity(0.5))),
                  child: const Icon(Icons.check, color: Colors.greenAccent, size: 30),
                ),
              ],
            ),
          )
        ],
      )
    );
  }
}

// ------ Liquid Card Widget ------
class LiquidCard extends StatelessWidget {
  final AssetEntity photo;
  final int percentX;

  const LiquidCard({Key? key, required this.photo, required this.percentX}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double deleteOpacity = percentX < 0 ? (-percentX / 1000).clamp(0.0, 1.0) : 0;
    double keepOpacity = percentX > 0 ? (percentX / 1000).clamp(0.0, 1.0) : 0;

    return FutureBuilder<Uint8List?>(
      future: photo.thumbnailDataWithSize(const ThumbnailSize(800, 800)),
      builder: (context, snapshot) {
        return GlassmorphicContainer(
          width: double.infinity,
          height: double.infinity,
          borderRadius: 30,
          blur: 15,
          alignment: Alignment.center,
          border: 1.5,
          linearGradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Colors.white.withOpacity(0.2), Colors.white.withOpacity(0.05)]),
          borderGradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Colors.white.withOpacity(0.7), Colors.white.withOpacity(0.2)]),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (snapshot.hasData)
                ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Image.memory(snapshot.data!, fit: BoxFit.cover),
                ),
              
              // Dynamic Specular Overlay mimicking Liquid Glass refraction
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.white.withOpacity(0.3), Colors.transparent, Colors.black.withOpacity(0.8)],
                    stops: const [0.0, 0.4, 1.0]
                  )
                ),
              ),

              // Badges
              if (deleteOpacity > 0.1)
                Positioned(
                  top: 30, right: 30,
                  child: Opacity(
                    opacity: deleteOpacity,
                    child: Transform.rotate(
                      angle: 0.2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.8), borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.white, width: 2)),
                        child: const Text('SİL', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 2)),
                      ),
                    ),
                  ),
                ),

              if (keepOpacity > 0.1)
                Positioned(
                  top: 30, left: 30,
                  child: Opacity(
                    opacity: keepOpacity,
                    child: Transform.rotate(
                      angle: -0.2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(color: Colors.greenAccent.withOpacity(0.8), borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.white, width: 2)),
                        child: const Text('SAKLA', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 2)),
                      ),
                    ),
                  ),
                )
            ],
          )
        );
      }
    );
  }
}

// ------ Month Summary Modal ------
class SummaryModal extends StatelessWidget {
  final List<AssetEntity> photosToDelete;
  final VoidCallback onConfirm;

  const SummaryModal({Key? key, required this.photosToDelete, required this.onConfirm}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: const Color(0xFF111827).withOpacity(0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        border: Border.all(color: Colors.white.withOpacity(0.2))
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white30, borderRadius: BorderRadius.circular(2)), margin: const EdgeInsets.bottom(24)),
          const Text('Temizlik Özeti', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 8),
          Text('${photosToDelete.length} fotoğrafı cihazın Çöp Kutusuna taşımak üzeresiniz.', style: const TextStyle(color: Colors.white70, fontSize: 14), textAlign: TextAlign.center),
          const SizedBox(height: 24),
          
          Expanded(
            child: GridView.builder(
              itemCount: photosToDelete.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, crossAxisSpacing: 8, mainAxisSpacing: 8),
              itemBuilder: (context, index) {
                return FutureBuilder<Uint8List?>(
                  future: photosToDelete[index].thumbnailDataWithSize(const ThumbnailSize(200, 200)),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return Container(color: Colors.white10);
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.memory(snapshot.data!, fit: BoxFit.cover),
                          Container(decoration: BoxDecoration(border: Border.all(color: Colors.redAccent.withOpacity(0.8), width: 2), borderRadius: BorderRadius.circular(12))),
                          const Positioned(top: 4, right: 4, child: Icon(Icons.close, color: Colors.white, size: 16))
                        ],
                      )
                    );
                  }
                );
              }
            )
          ),
          
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton.icon(
              onPressed: photosToDelete.isEmpty ? null : onConfirm,
              icon: const Icon(Icons.delete_outline, size: 24),
              label: Text('${photosToDelete.length} Fotoğrafı Sil (Native Intent)', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))
              ),
            ),
          )
        ],
      ),
    );
  }
}
