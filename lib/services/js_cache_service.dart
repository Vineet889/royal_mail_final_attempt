import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import '../config/address_now_config.dart';
import '../utils/address_now_exceptions.dart';

class JsCacheService {
  static const String _cacheFileName = 'addressnow.js';
  static const String _cacheMetaFileName = 'addressnow_meta.json';

  Future<String> getJavaScriptCode() async {
    try {
      final cachedFile = await _getCachedFile();
      if (await _isCacheValid(cachedFile)) {
        return await cachedFile.readAsString();
      }
      return await _downloadAndCacheJs();
    } catch (e) {
      throw AddressNowException(
        'Failed to load AddressNow JavaScript',
        originalError: e,
      );
    }
  }

  Future<File> _getCachedFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_cacheFileName');
  }

  Future<bool> _isCacheValid(File file) async {
    try {
      if (!await file.exists()) return false;
      
      final metaFile = File('${file.parent.path}/$_cacheMetaFileName');
      if (!await metaFile.exists()) return false;

      final metadata = await metaFile.readAsString();
      final cacheTime = DateTime.parse(metadata);
      return DateTime.now().difference(cacheTime) < AddressNowConfig.cacheExpiration;
    } catch (e) {
      return false;
    }
  }

  Future<String> _downloadAndCacheJs() async {
    try {
      final response = await http.get(
        Uri.parse(AddressNowConfig.jsUrl),
      ).timeout(AddressNowConfig.timeoutDuration);

      if (response.statusCode != 200) {
        throw AddressNowNetworkException(
          'Failed to download JavaScript file',
          code: response.statusCode.toString(),
        );
      }

      final file = await _getCachedFile();
      await file.writeAsString(response.body);
      
      final metaFile = File('${file.parent.path}/$_cacheMetaFileName');
      await metaFile.writeAsString(DateTime.now().toIso8601String());

      return response.body;
    } catch (e) {
      throw AddressNowNetworkException(
        'Network error while downloading JavaScript file',
        originalError: e,
      );
    }
  }
} 