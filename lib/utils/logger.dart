import 'package:anchor/config/debug_config.dart';

class Logger {
  static bool get enabled => DebugConfig.enableDebugLogging;

  static void d(String msg) {
    if (!enabled) return;
    // Keep messages concise
    // ignore: avoid_print
    print(msg);
  }
}
