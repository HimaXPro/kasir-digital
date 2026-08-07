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

class AppConfigModel {
  final int minVersion;
  final int latestVersion;
  final String updateUrl;
  final bool isMaintenance;
  final String maintenanceMessage;
  final bool isScheduled;
  final String? maintenanceStart;
  final String? maintenanceEnd;

  AppConfigModel({
    required this.minVersion,
    required this.latestVersion,
    required this.updateUrl,
    required this.isMaintenance,
    required this.maintenanceMessage,
    required this.isScheduled,
    this.maintenanceStart,
    this.maintenanceEnd,
  });

  factory AppConfigModel.fromMap(Map<String, dynamic> data) {
    return AppConfigModel(
      minVersion: data['minimum_version'] ?? 1,
      latestVersion: data['latest_version'] ?? 1,
      updateUrl: data['update_url'] ?? '',
      isMaintenance: data['is_maintenance'] ?? false,
      maintenanceMessage: data['maintenance_message'] ?? 'Sistem sedang dalam perbaikan.',
      isScheduled: data['is_scheduled'] ?? false,
      maintenanceStart: data['maintenance_start'],
      maintenanceEnd: data['maintenance_end'],
    );
  }
}

class VersionService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static Stream<AppConfigModel?> streamAppConfig() {
    return _db.collection('settings').doc('app_config').snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      return AppConfigModel.fromMap(snap.data()!);
    });
  }

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
