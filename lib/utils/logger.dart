import 'package:anchor/config/debug_config.dart';

class Logger {
  static bool get enabled => DebugConfig.enableDebugLogging;

  // ANSI color codes
  static const String _reset = '\x1B[0m';
  static const String _red = '\x1B[31m';
  static const String _green = '\x1B[32m';
  static const String _yellow = '\x1B[33m';
  static const String _blue = '\x1B[34m';
  static const String _magenta = '\x1B[35m';
  static const String _cyan = '\x1B[36m';
  static const String _gray = '\x1B[90m';

  static void _log(String level, String color, String msg) {
    if (!enabled) return;
    final timestamp = DateTime.now().toString().substring(11, 23); // HH:mm:ss.SSS
    // ignore: avoid_print
    print('$color[$level] $timestamp: $msg$_reset');
  }

  // Debug (blue)
  static void d(String msg) => _log('DEBUG', _blue, msg);
  
  // Info (green)
  static void i(String msg) => _log('INFO', _green, msg);
  
  // Warning (yellow)
  static void w(String msg) => _log('WARN', _yellow, msg);
  
  // Error (red)
  static void e(String msg) => _log('ERROR', _red, msg);
  
  // Success (bright green)
  static void s(String msg) => _log('SUCCESS', _green, msg);
  
  // Network (cyan)
  static void n(String msg) => _log('NET', _cyan, msg);
  
  // UI (magenta)
  static void ui(String msg) => _log('UI', _magenta, msg);
  
  // System (gray)
  static void sys(String msg) => _log('SYS', _gray, msg);
}
