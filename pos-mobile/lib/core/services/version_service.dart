import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:package_info_plus/package_info_plus.dart';

enum UpdateStatus {
  upToDate,
  optionalUpdate,
  forceUpdate,
}

class VersionInfo {
  final UpdateStatus status;
  final String updateUrl;

  VersionInfo(this.status, this.updateUrl);
}

class VersionService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static Future<VersionInfo> checkUpdate() async {
    try {
      final snapshot = await _db.collection('settings').doc('app_config').get();
      if (!snapshot.exists) {
        return VersionInfo(UpdateStatus.upToDate, '');
      }

      final data = snapshot.data()!;
      final minVersion = data['minimum_version'] ?? 1;
      final latestVersion = data['latest_version'] ?? 1;
      final updateUrl = data['update_url'] ?? '';

      final packageInfo = await PackageInfo.fromPlatform();
      
      // Parse build number safely
      int currentVersion = 1;
      if (packageInfo.buildNumber.isNotEmpty) {
        currentVersion = int.tryParse(packageInfo.buildNumber) ?? 1;
      }

      if (currentVersion < minVersion) {
        return VersionInfo(UpdateStatus.forceUpdate, updateUrl);
      } else if (currentVersion < latestVersion) {
        return VersionInfo(UpdateStatus.optionalUpdate, updateUrl);
      }

      return VersionInfo(UpdateStatus.upToDate, updateUrl);
    } catch (e) {
      print('Error checking update: $e');
      return VersionInfo(UpdateStatus.upToDate, '');
    }
  }
}
