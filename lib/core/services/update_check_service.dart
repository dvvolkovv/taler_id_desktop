import 'dart:io';
import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../config/app_config.dart';

class UpdateInfo {
  final bool isAvailable;
  final String downloadUrl;
  final String latestVersion;

  const UpdateInfo({
    required this.isAvailable,
    required this.downloadUrl,
    required this.latestVersion,
  });
}

class UpdateCheckService {
  static const _baseDownloadUrl = 'https://id.taler.tirol/download';

  final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  Future<UpdateInfo?> checkForUpdate() async {
    if (!Platform.isAndroid) return null;
    try {
      final versionFile = AppConfig.isDev ? 'version-dev.json' : 'version.json';
      final response = await _dio.get<Map<String, dynamic>>(
        '$_baseDownloadUrl/$versionFile',
      );
      final data = response.data!;
      final remoteBuild = data['buildNumber'] as int? ?? 0;
      final downloadUrl = data['downloadUrl'] as String? ?? '';
      final remoteVersion = data['version'] as String? ?? '';

      final info = await PackageInfo.fromPlatform();
      final localBuild = int.tryParse(info.buildNumber) ?? 0;

      return UpdateInfo(
        isAvailable: remoteBuild > localBuild,
        downloadUrl: downloadUrl,
        latestVersion: remoteVersion,
      );
    } catch (_) {
      return null;
    }
  }
}
