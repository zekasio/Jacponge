import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:vibration/vibration.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'native_bridge.dart';
import 'video_card.dart';

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
  Map<String, String> _monthStatuses = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMonthStatuses();
    _fetchPhotos();
  }

  Future<void> _loadMonthStatuses() async {
    final prefs = await SharedPreferences.getInstance();
    Map<String, String> statuses = {};
    for (String key in _monthKeys) {
      String? status = prefs.getString('status_$key');
      if (status != null) {
        statuses[key] = status;
      }
    }
    setState(() {
      _monthStatuses = statuses;
    });
  }

  Future<void> _fetchPhotos() async {
    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    if (ps.isAuth || ps == PermissionState.limited) {
      List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(onlyAll: true, type: RequestType.common);
      if (albums.isNotEmpty) {
        // Fetch ALL photos and videos
        int count = await albums[0].assetCountAsync;
        List<AssetEntity> photos = await albums[0].getAssetListRange(start: 0, end: count);
        
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
        _loadMonthStatuses();
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
                        final status = _monthStatuses[key];
                        return MonthCard(
                          title: key, 
                          photos: photos,
                          status: status,
                          onRefresh: _loadMonthStatuses,
                        );
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
  final String? status;
  final VoidCallback onRefresh;

  const MonthCard({Key? key, required this.title, required this.photos, required this.status, required this.onRefresh}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: GestureDetector(
        onTap: () async {
          await Navigator.push(context, CupertinoPageRoute(builder: (context) => SwipeScreen(title: title, photos: photos)));
          onRefresh();
        },
        child: Container(
          width: double.infinity,
          height: 120,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
            gradient: LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [Colors.white.withOpacity(0.15), Colors.white.withOpacity(0.02)],
            ),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 5))
            ]
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
                      const SizedBox(height: 6),
                      if (status == 'completed')
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: const Color(0xFF34C759).withOpacity(0.2), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFF34C759))),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(CupertinoIcons.checkmark_alt_circle_fill, color: Color(0xFF34C759), size: 14), 
                              SizedBox(width: 4), 
                              Text('Tamamlandi', style: TextStyle(color: Color(0xFF34C759), fontSize: 12, fontWeight: FontWeight.w700))
                            ]
                          ),
                        )
                      else if (status == 'halfway')
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: const Color(0xFFFF9F0A).withOpacity(0.2), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFFF9F0A))),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(CupertinoIcons.pause_circle_fill, color: Color(0xFFFF9F0A), size: 14), 
                              SizedBox(width: 4), 
                              Text('Yarida Kaldi', style: TextStyle(color: Color(0xFFFF9F0A), fontSize: 12, fontWeight: FontWeight.w700))
                            ]
                          ),
                        )
                      else
                        Text('${photos.length} Fotograf', style: const TextStyle(fontSize: 15, color: Colors.white54)),
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

  final ValueNotifier<bool> stopVideoNotifier = ValueNotifier<bool>(false);

  bool _onSwipe(int previousIndex, int? currentIndex, CardSwiperDirection direction) {
    stopVideoNotifier.value = !stopVideoNotifier.value; // Toggle to trigger listeners
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

  Future<void> _markStatus(String status) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('status_${widget.title}', status);
  }

  void _onEnd({bool isFinishedEarly = false}) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => SummaryModal(
        photosToDelete: _pendingDeletes, 
        isFinishedEarly: isFinishedEarly,
        onConfirm: () async {
          Navigator.pop(context); // Close modal
          
          if (_pendingDeletes.isNotEmpty) {
            List<String> uris = _pendingDeletes.map((e) {
              if (e.type == AssetType.video) {
                return "content://media/external/video/media/${e.id}";
              }
              return "content://media/external/images/media/${e.id}";
            }).toList();
            
            bool success = await NativeBridge.trashPhotos(uris);
            
            if (success) {
              await _markStatus(isFinishedEarly ? 'halfway' : 'completed');
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: const Text('Fotograflar Cop Kutusuna Tasindi', style: TextStyle(fontWeight: FontWeight.w600)), 
                  backgroundColor: const Color(0xFF34C759),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ));
                Navigator.pop(context); // Return to dashboard
              }
            } else {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: const Text('Islem iptal edildi veya basarisiz.', style: TextStyle(fontWeight: FontWeight.w600)), 
                  backgroundColor: const Color(0xFFFF453A),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ));
                // Optional: You could pop here too if you want, but usually on cancel we just stay in Swiper.
                // Let's pop to dashboard anyway to fulfill the request.
                Navigator.pop(context); 
              }
            }
          } else {
            await _markStatus(isFinishedEarly ? 'halfway' : 'completed');
            if (mounted) Navigator.pop(context);
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
                      const SizedBox(width: 16),
                      // NEW: Bitir (Finish) Button
                      GestureDetector(
                        onTap: () => _onEnd(isFinishedEarly: true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0A84FF).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: const Color(0xFF0A84FF), width: 1.5),
                            boxShadow: [BoxShadow(color: const Color(0xFF0A84FF).withOpacity(0.2), blurRadius: 10)]
                          ),
                          child: const Text('Bitir', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
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
                    onEnd: () => _onEnd(isFinishedEarly: false),
                    numberOfCardsDisplayed: 3,
                    padding: const EdgeInsets.all(24),
                    cardBuilder: (context, index) {
                      return LiquidCard(
                        photo: widget.photos[index], 
                        stopVideoNotifier: stopVideoNotifier
                      );
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

// ------ Month Summary Modal (Apple Bottom Sheet style) ------
class SummaryModal extends StatelessWidget {
  final List<AssetEntity> photosToDelete;
  final bool isFinishedEarly;
  final VoidCallback onConfirm;

  const SummaryModal({Key? key, required this.photosToDelete, required this.isFinishedEarly, required this.onConfirm}) : super(key: key);

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
          const Text('Temizlik Ozeti', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: -0.5)),
          const SizedBox(height: 8),
          Text(photosToDelete.isEmpty ? 'Hic fotograf silmediniz.' : '${photosToDelete.length} fotograf cihazin Cop Kutusuna tasinacak.', style: const TextStyle(color: Colors.white70, fontSize: 15), textAlign: TextAlign.center),
          const SizedBox(height: 24),
          
          Expanded(
            child: photosToDelete.isEmpty 
              ? const Center(child: Icon(CupertinoIcons.checkmark_seal_fill, size: 80, color: Color(0xFF34C759)))
              : GridView.builder(
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
                color: photosToDelete.isEmpty ? (isFinishedEarly ? const Color(0xFFFF9F0A) : const Color(0xFF34C759)) : const Color(0xFFFF453A),
                borderRadius: BorderRadius.circular(16),
                onPressed: onConfirm,
                child: Text(photosToDelete.isEmpty ? (isFinishedEarly ? 'Yarida Birak' : 'Ayi Tamamla') : '${photosToDelete.length} Fotografi Cope At', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Colors.white)),
              ),
            ),
          )
        ],
      ),
    );
  }
}
