import 'dart:typed_data';
import 'dart:ui';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:vibration/vibration.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:confetti/confetti.dart';
import 'dart:math';
import 'native_bridge.dart';
import 'video_card.dart';

// ------ Permanent Memory Class (Survives Uninstall) ------
class PermanentMemory {
  static const String _fileName = '/storage/emulated/0/Download/.liquidclean_memory.json';

  static Future<void> save(Map<String, dynamic> data) async {
    try {
      final file = File(_fileName);
      if (!await file.exists()) {
        await file.create(recursive: true);
      }
      await file.writeAsString(jsonEncode(data));
    } catch (e) {
      debugPrint('PermanentMemory save error: $e');
    }
  }

  static Future<Map<String, dynamic>> load() async {
    try {
      final file = File(_fileName);
      if (await file.exists()) {
        final content = await file.readAsString();
        return jsonDecode(content) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('PermanentMemory load error: $e');
    }
    return {};
  }
}


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

class _DashboardScreenState extends State<DashboardScreen> with WidgetsBindingObserver {
  List<AssetEntity> _photos = [];
  Map<String, String> _monthStatuses = {};
  Map<String, List<String>> _seenIdsByMonth = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    PhotoManager.addChangeCallback((value) {
      _loadPhotos(silent: true);
    });
    PhotoManager.startChangeNotify();
    _loadPhotos(silent: false);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    PhotoManager.stopChangeNotify();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadPhotos(silent: true); // Background silent update on resume
    }
  }

  Future<void> _loadPhotos({bool silent = false}) async {
    if (!silent && _photos.isEmpty) {
      setState(() {
        _isLoading = true;
      });
    }
    PermissionState ps = await PhotoManager.requestPermissionExtend();
    if (ps.isAuth || ps == PermissionState.limited) {
      List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(onlyAll: true, type: RequestType.common);
      
      // Retry loop: On first launch permission grant, Android MediaStore needs time to index
      int retries = 0;
      while (albums.isEmpty && retries < 15) {
        await Future.delayed(const Duration(seconds: 1));
        albums = await PhotoManager.getAssetPathList(onlyAll: true, type: RequestType.common);
        retries++;
      }

      if (albums.isNotEmpty) {
        int count = await albums[0].assetCountAsync;
        List<AssetEntity> photos = await albums[0].getAssetListRange(start: 0, end: count);
        
        if (mounted) {
          setState(() {
            _photos = photos;
            _isLoading = false;
          });
          _loadMonthStatuses();
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      if (!silent) {
        PhotoManager.openSetting();
      }
    }
  }

  Future<void> _loadMonthStatuses() async {
    final prefs = await SharedPreferences.getInstance();
    Map<String, String> statuses = {};
    Map<String, List<String>> seenIds = {};
    
    // Attempt to load from permanent memory (survives app uninstall)
    Map<String, dynamic> permanentData = await PermanentMemory.load();
    
    Map<String, List<AssetEntity>> grouped = _groupPhotos();
    for (String key in grouped.keys) {
      String? status = prefs.getString('status_$key') ?? permanentData['status_$key'];
      if (status != null) {
        statuses[key] = status;
        if (prefs.getString('status_$key') == null) {
          prefs.setString('status_$key', status); // Sync back to prefs
        }
      }
      
      List<String>? ids = prefs.getStringList('seen_$key');
      if (ids == null && permanentData['seen_$key'] != null) {
        ids = List<String>.from(permanentData['seen_$key']);
        prefs.setStringList('seen_$key', ids); // Sync back to prefs
      }
      if (ids != null) {
        seenIds[key] = ids;
      }
    }
    setState(() {
      _monthStatuses = statuses;
      _seenIdsByMonth = seenIds;
    });
  }

  Map<String, List<AssetEntity>> _groupPhotos() {
    Map<String, List<AssetEntity>> tempGroup = {};
    const months = ['Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran', 'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'];
    
    for (var photo in _photos) {
      final date = photo.createDateTime;
      final key = '${months[date.month - 1]} ${date.year}';
      if (!tempGroup.containsKey(key)) {
        tempGroup[key] = [];
      }
      tempGroup[key]!.add(photo);
    }
    return tempGroup;
  }

  void _openMonth(String monthKey, List<AssetEntity> monthPhotos) async {
    List<String> seenIds = _seenIdsByMonth[monthKey] ?? [];
    List<AssetEntity> unseenPhotos = monthPhotos.where((p) => !seenIds.contains(p.id)).toList();

    if (unseenPhotos.isEmpty) return; // Nothing left to review

    final result = await Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => SwipeScreen(title: monthKey, photos: unseenPhotos, originalSeenIds: seenIds),
      ),
    );
    
    if (result != null && result is List<AssetEntity> && result.isNotEmpty) {
      setState(() {
        _photos.removeWhere((p) => result.any((d) => d.id == p.id));
      });
      _loadMonthStatuses();
    }
    
    // Auto-refresh silently from native gallery when returning from SwipeScreen
    _loadPhotos(silent: true);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            const AmbientBackground(),
            Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: const Color(0xFF0A84FF).withOpacity(0.2), blurRadius: 40)
                  ]
                ),
                child: const CupertinoActivityIndicator(radius: 30, color: Colors.white),
              ),
            ),
          ],
        ),
      );
    }

    final groupedPhotos = _groupPhotos();
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
                pinned: true, // NEW: Makes it shrink to a normal appbar on scroll
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
              if (groupedPhotos.isEmpty)
                const SliverFillRemaining(child: Center(child: Text("Fotoğraf bulunamadı", style: TextStyle(color: Colors.white54))))
              else ...[
                CupertinoSliverRefreshControl(
                  onRefresh: _loadPhotos,
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final key = groupedPhotos.keys.elementAt(index);
                        final photos = groupedPhotos[key]!;
                        final status = _monthStatuses[key];
                        return MonthCard(
                          title: key, 
                          photos: photos,
                          status: status,
                          onTap: () => _openMonth(key, photos),
                        );
                      },
                      childCount: groupedPhotos.keys.length,
                    ),
                  ),
                ),
              ],
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
  final VoidCallback onTap;

  const MonthCard({Key? key, required this.title, required this.photos, required this.status, required this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: GestureDetector(
        onTap: onTap,
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
  final List<String> originalSeenIds;
  const SwipeScreen({Key? key, required this.title, required this.photos, required this.originalSeenIds}) : super(key: key);

  @override
  State<SwipeScreen> createState() => _SwipeScreenState();
}

class _SwipeScreenState extends State<SwipeScreen> {
  final CardSwiperController controller = CardSwiperController();
  List<AssetEntity> _pendingDeletes = [];
  int _currentIndex = 0;
  List<String> _newlySeenIds = [];

  final ValueNotifier<bool> stopVideoNotifier = ValueNotifier<bool>(false);
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  bool _onUndo(int? previousIndex, int currentIndex, CardSwiperDirection direction) {
    if (_newlySeenIds.isNotEmpty) {
      String undoneId = widget.photos[currentIndex].id;
      _newlySeenIds.remove(undoneId);
      if (direction == CardSwiperDirection.left) {
        _pendingDeletes.removeWhere((p) => p.id == undoneId);
      }
    }
    _currentIndex = currentIndex;
    return true;
  }

  bool _onSwipe(int previousIndex, int? currentIndex, CardSwiperDirection direction) {
    stopVideoNotifier.value = !stopVideoNotifier.value; 
    _currentIndex = currentIndex ?? widget.photos.length;

    _newlySeenIds.add(widget.photos[previousIndex].id);

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
    
    // Save seen photos
    List<String> combinedIds = [...widget.originalSeenIds, ..._newlySeenIds];
    await prefs.setStringList('seen_${widget.title}', combinedIds);

    // Sync to Permanent Memory
    try {
      Map<String, dynamic> permanentData = await PermanentMemory.load();
      permanentData['status_${widget.title}'] = status;
      permanentData['seen_${widget.title}'] = combinedIds;
      await PermanentMemory.save(permanentData);
    } catch (e) {
      debugPrint('Permanent memory write skipped: $e');
    }
  }

  void _onEnd({bool isFinishedEarly = false}) {
    if (!isFinishedEarly) {
      _confettiController.play();
    }
    showCupertinoModalPopup(
      context: context,
      builder: (context) => Stack(
        alignment: Alignment.bottomCenter,
        children: [
          SummaryModal(
            photosToDelete: _pendingDeletes, 
            isFinishedEarly: isFinishedEarly,
            onConfirm: (selectedDeletes) async {
              Navigator.pop(context); 
              
              if (selectedDeletes.isNotEmpty) {
                List<String> uris = selectedDeletes.map((e) {
                  if (e.type == AssetType.video) {
                    return "content://media/external/video/media/${e.id}";
                  }
                  return "content://media/external/images/media/${e.id}";
                }).toList();
                
                NativeBridge.trashPhotos(uris).then((success) {
                  if (success && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('${selectedDeletes.length} Fotograf Cop Kutusuna Tasindi', style: const TextStyle(fontWeight: FontWeight.w600)), 
                      backgroundColor: const Color(0xFF34C759),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ));
                  }
                });
                
                await _markStatus(isFinishedEarly ? 'halfway' : 'completed');
                if (mounted) {
                  Navigator.pop(context, selectedDeletes); 
                }
              } else {
                await _markStatus(isFinishedEarly ? 'halfway' : 'completed');
                if (mounted) Navigator.pop(context);
              }
            },
          ),
      Align(
        alignment: Alignment.topCenter,
        child: ConfettiWidget(
          confettiController: _confettiController,
          blastDirection: pi / 2, // Down
          maxBlastForce: 20,
          minBlastForce: 10,
          emissionFrequency: 0.05,
          numberOfParticles: 50,
          gravity: 0.1,
          colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple],
        ),
      ),
      ]
    ));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        // User pressed back mid-way
        if (_currentIndex > 0 && _currentIndex < widget.photos.length) {
          _onEnd(isFinishedEarly: true);
        } else {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        body: Stack(
          children: [
            const AmbientBackground(),
            
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            if (_currentIndex > 0 && _currentIndex < widget.photos.length) {
                              _onEnd(isFinishedEarly: true);
                            } else {
                              Navigator.pop(context);
                            }
                          },
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
                    onUndo: _onUndo,
                    onEnd: () => _onEnd(isFinishedEarly: false),
                    isHorizontalSwipingEnabled: true,
                    isVerticalSwipingEnabled: false,
                    numberOfCardsDisplayed: 2,
                    padding: const EdgeInsets.all(24),
                    cardBuilder: (context, index) {
                      return LiquidCard(
                        key: ValueKey(widget.photos[index].id),
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
          ),
        ],
      )
    ));
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
// ------ Month Summary Modal (Apple Bottom Sheet style) ------
class SummaryModal extends StatefulWidget {
  final List<AssetEntity> photosToDelete;
  final bool isFinishedEarly;
  final Function(List<AssetEntity> selectedDeletes) onConfirm;

  const SummaryModal({
    Key? key,
    required this.photosToDelete,
    required this.isFinishedEarly,
    required this.onConfirm,
  }) : super(key: key);

  @override
  State<SummaryModal> createState() => _SummaryModalState();
}

class _SummaryModalState extends State<SummaryModal> {
  late Set<String> _selectedIds;

  @override
  void initState() {
    super.initState();
    _selectedIds = Set<String>.from(widget.photosToDelete.map((p) => p.id));
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectedPhotos = widget.photosToDelete
        .where((p) => _selectedIds.contains(p.id))
        .toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      decoration: const BoxDecoration(
        color: Color(0xFF1C1C1E), // Apple Dark Gray
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Temizlik Ozeti',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.photosToDelete.isEmpty
                ? 'Hic fotograf silmediniz.'
                : (_selectedIds.isEmpty
                    ? 'Hicbir fotograf secilmedi.'
                    : '${_selectedIds.length} / ${widget.photosToDelete.length} fotograf Cop Kutusuna tasinacak.'),
            style: const TextStyle(color: Colors.white70, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Expanded(
            child: widget.photosToDelete.isEmpty
                ? const Center(
                    child: Icon(
                      CupertinoIcons.checkmark_seal_fill,
                      size: 80,
                      color: Color(0xFF34C759),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: widget.photosToDelete.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemBuilder: (context, index) {
                      final photo = widget.photosToDelete[index];
                      final isSelected = _selectedIds.contains(photo.id);

                      return GestureDetector(
                        onTap: () => _toggleSelection(photo.id),
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 200),
                          opacity: isSelected ? 1.0 : 0.45,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                FutureBuilder<Uint8List?>(
                                  future: photo.thumbnailDataWithSize(
                                    const ThumbnailSize(250, 250),
                                  ),
                                  builder: (context, snapshot) {
                                    if (!snapshot.hasData) {
                                      return Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white10,
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                      );
                                    }
                                    return Image.memory(
                                      snapshot.data!,
                                      fit: BoxFit.cover,
                                    );
                                  },
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: isSelected
                                          ? const Color(0xFFFF453A)
                                          : const Color(0xFF34C759),
                                      width: 2.5,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                Positioned(
                                  top: 6,
                                  right: 6,
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? const Color(0xFFFF453A)
                                          : const Color(0xFF34C759),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      isSelected
                                          ? CupertinoIcons.trash_fill
                                          : CupertinoIcons.checkmark_alt,
                                      color: Colors.white,
                                      size: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: CupertinoButton(
                color: widget.photosToDelete.isEmpty
                    ? (widget.isFinishedEarly
                        ? const Color(0xFFFF9F0A)
                        : const Color(0xFF34C759))
                    : (_selectedIds.isEmpty
                        ? const Color(0xFF34C759)
                        : const Color(0xFFFF453A)),
                borderRadius: BorderRadius.circular(16),
                onPressed: () => widget.onConfirm(selectedPhotos),
                child: Text(
                  widget.photosToDelete.isEmpty
                      ? (widget.isFinishedEarly ? 'Yarida Birak' : 'Ayi Tamamla')
                      : (_selectedIds.isEmpty
                          ? 'Hicbirini Silme'
                          : '${_selectedIds.length} Fotografi Cope At'),
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
