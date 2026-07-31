import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:vibration/vibration.dart';
import 'native_bridge.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const LiquidCleanApp());
}

class LiquidCleanApp extends StatelessWidget {
  const LiquidCleanApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LiquidClean PRO',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF000000), // OLED Black
        fontFamily: 'System',
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF0A84FF), // Apple Blue
          surface: Color(0xFF1C1C1E), // Apple Dark Gray
        ),
      ),
      home: const DashboardScreen(),
    );
  }
}

// ------ Ambient Background Widget ------
class AmbientBackground extends StatelessWidget {
  const AmbientBackground({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -150, left: -100,
          child: Container(
            width: 400, height: 400,
            decoration: BoxDecoration(
              shape: BoxShape.circle, 
              gradient: RadialGradient(
                colors: [const Color(0xFF5E5CE6).withOpacity(0.6), Colors.transparent],
              )
            ), 
          ),
        ),
        Positioned(
          bottom: -100, right: -150,
          child: Container(
            width: 500, height: 500,
            decoration: BoxDecoration(
              shape: BoxShape.circle, 
              gradient: RadialGradient(
                colors: [const Color(0xFF0A84FF).withOpacity(0.6), Colors.transparent],
              )
            ),
          ),
        ),
      ],
    );
  }
}

// ------ Dashboard Screen ------
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, List<AssetEntity>> _groupedPhotos = {};
  List<String> _monthKeys = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPhotos();
  }

  Future<void> _fetchPhotos() async {
    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    if (ps.isAuth || ps == PermissionState.limited) {
      List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(onlyAll: true, type: RequestType.image);
      if (albums.isNotEmpty) {
        // Fetch up to 1000 recent photos to group
        List<AssetEntity> photos = await albums[0].getAssetListPaged(page: 0, size: 1000);
        
        Map<String, List<AssetEntity>> tempGroup = {};
        const months = ['Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran', 'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'];
        
        for (var photo in photos) {
          final date = photo.createDateTime;
          final key = '${months[date.month - 1]} ${date.year}';
          if (!tempGroup.containsKey(key)) {
            tempGroup[key] = [];
          }
          tempGroup[key]!.add(photo);
        }
        
        setState(() {
          _groupedPhotos = tempGroup;
          _monthKeys = tempGroup.keys.toList();
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
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          const AmbientBackground(),
          CustomScrollView(
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            slivers: [
              SliverAppBar(
                expandedHeight: 140,
                backgroundColor: Colors.transparent,
                elevation: 0,
                stretch: true,
                flexibleSpace: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: FlexibleSpaceBar(
                      titlePadding: const EdgeInsets.only(left: 24, bottom: 16),
                      title: const Text('Fotoğraflar', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 28, letterSpacing: -1, color: Colors.white)),
                      background: Container(color: Colors.black.withOpacity(0.2)),
                    ),
                  ),
                ),
              ),
              if (_isLoading)
                const SliverFillRemaining(child: Center(child: CupertinoActivityIndicator(radius: 16)))
              else if (_monthKeys.isEmpty)
                const SliverFillRemaining(child: Center(child: Text("Fotoğraf bulunamadı", style: TextStyle(color: Colors.white54))))
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final key = _monthKeys[index];
                        final photos = _groupedPhotos[key]!;
                        return MonthCard(title: key, photos: photos);
                      },
                      childCount: _monthKeys.length,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ------ Month Card Widget ------
class MonthCard extends StatelessWidget {
  final String title;
  final List<AssetEntity> photos;

  const MonthCard({Key? key, required this.title, required this.photos}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: GestureDetector(
        onTap: () {
          Navigator.push(context, CupertinoPageRoute(builder: (context) => SwipeScreen(title: title, photos: photos)));
        },
        child: GlassmorphicContainer(
          width: double.infinity,
          height: 120,
          borderRadius: 24,
          blur: 30,
          alignment: Alignment.center,
          border: 1,
          linearGradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Colors.white.withOpacity(0.15), Colors.white.withOpacity(0.02)],
          ),
          borderGradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Colors.white.withOpacity(0.5), Colors.white.withOpacity(0.0)],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Thumbnails Preview Stack
                SizedBox(
                  width: 80,
                  height: 80,
                  child: Stack(
                    children: List.generate(
                      photos.length > 3 ? 3 : photos.length,
                      (i) => Positioned(
                        right: i * 12.0,
                        top: i * 8.0,
                        child: Container(
                          width: 56, height: 56,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white24, width: 1),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: FutureBuilder<Uint8List?>(
                              future: photos[i].thumbnailDataWithSize(const ThumbnailSize(200, 200)),
                              builder: (context, snapshot) {
                                if (snapshot.hasData) {
                                  return Image.memory(snapshot.data!, fit: BoxFit.cover);
                                }
                                return Container(color: Colors.white10);
                              },
                            ),
                          ),
                        ),
                      )
                    ).reversed.toList(),
                  ),
                ),
                const SizedBox(width: 20),
                // Text info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.white, letterSpacing: -0.5)),
                      const SizedBox(height: 4),
                      Text('${photos.length} Fotoğraf', style: const TextStyle(fontSize: 15, color: Colors.white54)),
                    ],
                  ),
                ),
                const Icon(CupertinoIcons.chevron_right, color: Colors.white30, size: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ------ Swipe Screen ------
class SwipeScreen extends StatefulWidget {
  final String title;
  final List<AssetEntity> photos;
  const SwipeScreen({Key? key, required this.title, required this.photos}) : super(key: key);

  @override
  State<SwipeScreen> createState() => _SwipeScreenState();
}

class _SwipeScreenState extends State<SwipeScreen> {
  final CardSwiperController controller = CardSwiperController();
  List<AssetEntity> _pendingDeletes = [];

  bool _onSwipe(int previousIndex, int? currentIndex, CardSwiperDirection direction) {
    if (direction == CardSwiperDirection.left) {
      _pendingDeletes.add(widget.photos[previousIndex]);
      _triggerHaptic(true);
    } else {
      _triggerHaptic(false);
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
    showCupertinoModalPopup(
      context: context,
      builder: (context) => SummaryModal(
        photosToDelete: _pendingDeletes, 
        onConfirm: () async {
          Navigator.pop(context);
          List<String> uris = _pendingDeletes.map((e) => "content://media/external/images/media/${e.id}").toList();
          bool success = await NativeBridge.trashPhotos(uris);
          
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: const Text('Fotoğraflar Çöp Kutusuna Taşındı', style: TextStyle(fontWeight: FontWeight.w600)), 
              backgroundColor: const Color(0xFF34C759), // Apple Green
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ));
            Navigator.pop(context); // Return to dashboard
          }
        }
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          const AmbientBackground(),
          
          SafeArea(
            child: Column(
              children: [
                // Apple Quality Glass Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white24, width: 0.5),
                          ),
                          child: const Icon(CupertinoIcons.back, color: Colors.white, size: 24),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: Colors.white24, width: 0.5),
                          ),
                          child: Center(
                            child: Text(widget.title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Colors.white, letterSpacing: -0.5)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Tinder Swiper
                Expanded(
                  child: CardSwiper(
                    controller: controller,
                    cardsCount: widget.photos.length,
                    onSwipe: _onSwipe,
                    onEnd: _onEnd,
                    numberOfCardsDisplayed: 3,
                    padding: const EdgeInsets.all(24),
                    cardBuilder: (context, index) {
                      return LiquidCard(photo: widget.photos[index]);
                    },
                  ),
                ),
                
                // Floating Action Buttons (Apple aesthetic)
                Padding(
                  padding: const EdgeInsets.only(bottom: 40, top: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildGlassButton(
                        icon: CupertinoIcons.xmark, 
                        color: const Color(0xFFFF453A), // Apple Red
                        onTap: () => controller.swipeLeft()
                      ),
                      const SizedBox(width: 24),
                      _buildGlassButton(
                        icon: CupertinoIcons.arrow_counterclockwise, 
                        color: Colors.white, 
                        onTap: () => controller.undo(),
                        size: 56, iconSize: 24
                      ),
                      const SizedBox(width: 24),
                      _buildGlassButton(
                        icon: CupertinoIcons.heart_fill, 
                        color: const Color(0xFF32ADE6), // Apple Cyan/Blue
                        onTap: () => controller.swipeRight()
                      ),
                    ],
                  ),
                )
              ],
            ),
          )
        ],
      )
    );
  }

  Widget _buildGlassButton({required IconData icon, required Color color, required VoidCallback onTap, double size = 72, double iconSize = 32}) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size / 2),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            width: size, height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.1),
              border: Border.all(color: color.withOpacity(0.5), width: 1.5),
              boxShadow: [
                BoxShadow(color: color.withOpacity(0.15), blurRadius: 20, spreadRadius: 5)
              ]
            ),
            child: Icon(icon, color: color, size: iconSize),
          ),
        ),
      ),
    );
  }
}

// ------ Liquid Card Widget (AAA Quality) ------
class LiquidCard extends StatelessWidget {
  final AssetEntity photo;

  const LiquidCard({Key? key, required this.photo}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: FutureBuilder<Uint8List?>(
        future: photo.thumbnailDataWithSize(const ThumbnailSize(500, 500)),
      builder: (context, snapshot) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 30, offset: const Offset(0, 20))
            ]
          ),
          child: GlassmorphicContainer(
            width: double.infinity,
            height: double.infinity,
            borderRadius: 32,
            blur: 20,
            alignment: Alignment.center,
            border: 1.5,
            linearGradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Colors.white.withOpacity(0.2), Colors.white.withOpacity(0.0)]),
            borderGradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Colors.white.withOpacity(0.6), Colors.white.withOpacity(0.1)]),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (snapshot.hasData)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: Image.memory(snapshot.data!, fit: BoxFit.cover),
                  ),
                
                // Advanced Specular Edge Highlight
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white.withOpacity(0.3), width: 0.5),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.white.withOpacity(0.4), Colors.transparent, Colors.black.withOpacity(0.7)],
                      stops: const [0.0, 0.3, 1.0]
                    )
                  ),
                ),
              ],
            )
          ),
        );
      }
    ),
    );
  }
}

// ------ Month Summary Modal (Apple Bottom Sheet style) ------
class SummaryModal extends StatelessWidget {
  final List<AssetEntity> photosToDelete;
  final VoidCallback onConfirm;

  const SummaryModal({Key? key, required this.photosToDelete, required this.onConfirm}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFF1C1C1E), // Apple Dark Gray
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(3))),
          const SizedBox(height: 24),
          const Text('Temizlik Özeti', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: -0.5)),
          const SizedBox(height: 8),
          Text('${photosToDelete.length} fotoğraf cihazın Çöp Kutusuna taşınacak.', style: const TextStyle(color: Colors.white70, fontSize: 15), textAlign: TextAlign.center),
          const SizedBox(height: 24),
          
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: photosToDelete.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10),
              itemBuilder: (context, index) {
                return FutureBuilder<Uint8List?>(
                  future: photosToDelete[index].thumbnailDataWithSize(const ThumbnailSize(250, 250)),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return Container(decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(16)));
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.memory(snapshot.data!, fit: BoxFit.cover),
                          Container(decoration: BoxDecoration(border: Border.all(color: const Color(0xFFFF453A).withOpacity(0.8), width: 2), borderRadius: BorderRadius.circular(16))),
                          Positioned(top: 6, right: 6, child: Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: Color(0xFFFF453A), shape: BoxShape.circle), child: const Icon(CupertinoIcons.trash_fill, color: Colors.white, size: 12)))
                        ],
                      )
                    );
                  }
                );
              }
            )
          ),
          
          Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: CupertinoButton(
                color: const Color(0xFFFF453A),
                borderRadius: BorderRadius.circular(16),
                onPressed: photosToDelete.isEmpty ? null : onConfirm,
                child: Text('${photosToDelete.length} Fotoğrafı Çöpe At', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Colors.white)),
              ),
            ),
          )
        ],
      ),
    );
  }
}
