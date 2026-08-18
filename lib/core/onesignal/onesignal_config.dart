import 'package:flutter_dotenv/flutter_dotenv.dart';

/// App ID publico do OneSignal (Settings > Keys & IDs).
class OneSignalConfig {
  static const fallbackAppId = '6eb88ea6-38cf-4df3-bab5-76beb7e7580d';

  static String get appId {
    const fromDefine = String.fromEnvironment('ONESIGNAL_APP_ID');
    if (fromDefine.isNotEmpty) return fromDefine;

    if (dotenv.isInitialized) {
      final fromEnv = dotenv.maybeGet('ONESIGNAL_APP_ID');
      if (fromEnv != null && fromEnv.isNotEmpty) return fromEnv;
    }
    return fallbackAppId;
  }

  static bool get isConfigured => appId.isNotEmpty;
}
