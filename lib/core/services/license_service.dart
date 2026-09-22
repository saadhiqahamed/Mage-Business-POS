import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

class LicenseService {
  static const String _secretSalt = "MAGE_POS_SECURE_2026_PRO";
  
  static Future<String> getDeviceID() async {
    final prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString('device_id');
    if (deviceId == null) {
      // Generate a random 6-character alphanumeric device ID
      const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // removed confusing chars like I,1,O,0
      final rnd = Random.secure();
      deviceId = String.fromCharCodes(Iterable.generate(6, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
      await prefs.setString('device_id', deviceId);
    }
    return deviceId;
  }

  static String generateExpectedKey(String deviceId) {
    // Generate an MD5 hash of the device ID + Secret Salt
    var bytes = utf8.encode(deviceId + _secretSalt);
    var digest = md5.convert(bytes);
    // Return the first 8 characters of the hex string, formatted with a dash
    String hexStr = digest.toString().toUpperCase();
    return "${hexStr.substring(0, 4)}-${hexStr.substring(4, 8)}";
  }

  static Future<bool> isLicensed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('is_licensed') ?? false;
  }

  static Future<bool> activateLicense(String inputKey) async {
    final deviceId = await getDeviceID();
    final expectedKey = generateExpectedKey(deviceId);
    
    if (inputKey.trim().toUpperCase() == expectedKey) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_licensed', true);
      return true;
    }
    return false;
  }
}
