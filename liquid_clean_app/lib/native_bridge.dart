import 'package:flutter/services.dart';

class NativeBridge {
  static const MethodChannel _channel = MethodChannel('com.jacponge.liquidclean/trash');

  /// Invokes the native Android MediaStore createTrashRequest
  /// [uris] is a list of MediaStore content URIs (e.g., content://media/external/images/media/123)
  static Future<bool> trashPhotos(List<String> uris) async {
    try {
      final bool? success = await _channel.invokeMethod('trashPhotos', {'uris': uris});
      return success ?? false;
    } on PlatformException catch (e) {
      print("Failed to trash photos: '${e.message}'.");
      return false;
    }
  }
}
