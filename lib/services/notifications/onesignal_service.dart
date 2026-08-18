import 'package:flutter/foundation.dart';
import 'package:padoca_express/core/onesignal/onesignal_config.dart';
import 'package:padoca_express/services/notifications/onesignal_bridge.dart';

class OneSignalService {
  OneSignalService._();

  static final OneSignalBridge _bridge = createOneSignalBridge();
  static bool _initialized = false;

  static OneSignalBridge get bridge => _bridge;

  static Future<void> initialize() async {
    if (_initialized || !OneSignalConfig.isConfigured) return;
    if (kIsWeb == false &&
        (defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS)) {
      return;
    }
    try {
      await _bridge.initialize(OneSignalConfig.appId);
      _initialized = true;
    } catch (e) {
      debugPrint('[OneSignal] initialize: $e');
    }
  }
}
