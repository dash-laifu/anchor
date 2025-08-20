class Logger {
  static bool enabled = true; // flip to false to silence debug logs

  static void d(String msg) {
    if (!enabled) return;
    // Keep messages concise
    // ignore: avoid_print
    print(msg);
  }
}
