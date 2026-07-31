import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:video_player/video_player.dart';
import 'package:glassmorphism/glassmorphism.dart';

class LiquidCard extends StatefulWidget {
  final AssetEntity photo;

  const LiquidCard({Key? key, required this.photo}) : super(key: key);

  @override
  State<LiquidCard> createState() => _LiquidCardState();
}

class _LiquidCardState extends State<LiquidCard> {
  VideoPlayerController? _videoController;
  bool _isPlaying = false;
  bool _isInitializing = false;

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    if (_videoController != null) {
      if (_videoController!.value.isPlaying) {
        _videoController!.pause();
        setState(() => _isPlaying = false);
      } else {
        _videoController!.play();
        setState(() => _isPlaying = true);
      }
      return;
    }

    setState(() {
      _isInitializing = true;
    });

    File? file = await widget.photo.file;
    if (file != null) {
      _videoController = VideoPlayerController.file(file)
        ..initialize().then((_) {
          setState(() {
            _isInitializing = false;
            _isPlaying = true;
          });
          _videoController!.setLooping(true);
          _videoController!.play();
        });
    } else {
      setState(() {
        _isInitializing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: FutureBuilder<Uint8List?>(
        future: widget.photo.thumbnailDataWithSize(const ThumbnailSize(540, 540)), // Video kalitesi 540p siniri icin thumbnail'i de 540 yapiyoruz
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
                  // 1. Thumbnail Background
                  if (snapshot.hasData)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: Image.memory(snapshot.data!, fit: BoxFit.cover),
                    ),
                    
                  // 2. Video Player Overlay
                  if (_videoController != null && _videoController!.value.isInitialized)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: FittedBox(
                        fit: BoxFit.cover,
                        child: SizedBox(
                          width: _videoController!.value.size.width,
                          height: _videoController!.value.size.height,
                          child: VideoPlayer(_videoController!),
                        ),
                      ),
                    ),

                  // 3. Play Button for Videos
                  if (widget.photo.type == AssetType.video)
                    Center(
                      child: GestureDetector(
                        onTap: _togglePlay,
                        child: Container(
                          width: 72, height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black.withOpacity(0.4),
                            border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.5),
                          ),
                          child: _isInitializing 
                            ? const CupertinoActivityIndicator(color: Colors.white)
                            : Icon(
                                _isPlaying ? CupertinoIcons.pause_fill : CupertinoIcons.play_fill, 
                                color: Colors.white, 
                                size: 36
                              ),
                        ),
                      ),
                    ),
                  
                  // 4. Advanced Specular Edge Highlight
                  IgnorePointer(
                    child: Container(
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
