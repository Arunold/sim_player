import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

/// Service for handling platform permissions
class PermissionService {
  /// Request storage permission
  Future<bool> requestStoragePermission() async {
    if (Platform.isAndroid) {
      // For Android 13+ (API 33+), use audio permission
      // For older versions, use storage permission
      final status = await Permission.audio.request();
      if (status.isGranted) return true;

      // Fallback to storage permission for older Android versions
      final storageStatus = await Permission.storage.request();
      return storageStatus.isGranted;
    } else if (Platform.isIOS) {
      // iOS handles music library access differently
      final status = await Permission.mediaLibrary.request();
      return status.isGranted;
    }
    
    // Desktop platforms don't need special permissions
    return true;
  }

  /// Check if storage permission is granted
  Future<bool> hasStoragePermission() async {
    if (Platform.isAndroid) {
      final audioStatus = await Permission.audio.status;
      if (audioStatus.isGranted) return true;
      
      final storageStatus = await Permission.storage.status;
      return storageStatus.isGranted;
    } else if (Platform.isIOS) {
      final status = await Permission.mediaLibrary.status;
      return status.isGranted;
    }
    
    return true;
  }

  /// Request notification permission (for background playback)
  Future<bool> requestNotificationPermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.notification.request();
      return status.isGranted;
    }
    return true;
  }

  /// Check if notification permission is granted
  Future<bool> hasNotificationPermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.notification.status;
      return status.isGranted;
    }
    return true;
  }

  /// Open app settings
  Future<bool> openSettings() async {
    return await openAppSettings();
  }

  /// Check if permission is permanently denied
  Future<bool> isStoragePermissionPermanentlyDenied() async {
    if (Platform.isAndroid) {
      final audioStatus = await Permission.audio.status;
      final storageStatus = await Permission.storage.status;
      return audioStatus.isPermanentlyDenied || storageStatus.isPermanentlyDenied;
    } else if (Platform.isIOS) {
      final status = await Permission.mediaLibrary.status;
      return status.isPermanentlyDenied;
    }
    return false;
  }
}
