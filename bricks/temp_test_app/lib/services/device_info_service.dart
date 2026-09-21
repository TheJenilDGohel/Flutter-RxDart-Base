/// Device info service stub. Fill in per-project requirements.
///
/// Uses `device_info_plus` to gather platform-specific device information.
class DeviceInfoService {
  DeviceInfoService._();
  static final DeviceInfoService instance = DeviceInfoService._();

  /// Returns a map of device information (model, OS version, etc.).
  Future<Map<String, dynamic>> getDeviceInfo() async {
    // TODO: Use DeviceInfoPlugin to gather device info.
    // final deviceInfo = DeviceInfoPlugin();
    // if (Platform.isAndroid) {
    //   final android = await deviceInfo.androidInfo;
    //   return {'model': android.model, 'version': android.version.release};
    // } else if (Platform.isIOS) {
    //   final ios = await deviceInfo.iosInfo;
    //   return {'model': ios.model, 'version': ios.systemVersion};
    // }
    return {};
  }

  /// Returns a unique device identifier.
  Future<String> getDeviceId() async {
    // TODO: Extract device-specific unique ID.
    return '';
  }
}
