import 'package:permission_handler/permission_handler.dart';

class Utils {
  static Future<List<Permission>> getPermissions() async {
    return [
      Permission.photos,
      Permission.camera,
      Permission.contacts,
      Permission.location,
      Permission.notification
    ];
  }
}
