import 'package:permission_handler/permission_handler.dart';

class PermissionsService {
  static Future<bool> requestCamera() async {
    final status = await Permission.camera.request();
    if (status.isPermanentlyDenied) await openAppSettings();
    return status.isGranted;
  }

  static Future<bool> requestLocation() async {
    final status = await Permission.locationWhenInUse.request();
    if (status.isPermanentlyDenied) await openAppSettings();
    return status.isGranted;
  }

  static Future<bool> requestStorage() async {
    PermissionStatus status = await Permission.photos.request();
    if (!status.isGranted) {
      status = await Permission.storage.request();
    }
    if (status.isPermanentlyDenied) await openAppSettings();
    return status.isGranted;
  }

  static Future<bool> isCameraGranted() => Permission.camera.isGranted;
  static Future<bool> isLocationGranted() =>
      Permission.locationWhenInUse.isGranted;

  // Solicita cámara y almacenamiento juntos para flujo de fotos
  static Future<bool> requestCameraAndStorage() async {
    final camera = await requestCamera();
    final storage = await requestStorage();
    return camera && storage;
  }
}
