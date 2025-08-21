class DebugConfig {
  // This will be set based on environment variables or build flags
  static bool get isDebugMode {
    // Check for environment variable first
    const debugEnv = String.fromEnvironment('DEBUG_MODE', defaultValue: 'false');
    if (debugEnv.toLowerCase() == 'true') return true;
    
    // Check for debug build flag
    const debugBuild = bool.fromEnvironment('DEBUG_BUILD', defaultValue: false);
    if (debugBuild) return true;
    
    // Default to false for production
    return false;
  }
  
  // Individual feature flags
  static bool get showDebugReminders => isDebugMode;
  static bool get showNotificationTests => isDebugMode;
  static bool get enableDebugLogging => isDebugMode;
  
  // Debug reminder options (1-5 minutes)
  static const debugReminderOptions = [
    (1, '1 min - DEBUG'),
    (2, '2 min - DEBUG'),
    (3, '3 min - DEBUG'),
    (5, '5 min - DEBUG'),
  ];
  
  // Production reminder options
  static const productionReminderOptions = [
    (30, '30 min'),
    (60, '1 hour'),
    (120, '2 hours'),
    (240, '4 hours'),
  ];
  
  // Get appropriate reminder options based on mode
  static List<(int, String)> get reminderOptions {
    if (showDebugReminders) {
      return [...debugReminderOptions, ...productionReminderOptions];
    }
    return productionReminderOptions;
  }
  
  // Get appropriate default duration options for settings
  static List<(int, String)> get defaultDurationOptions {
    final baseOptions = [(-1, 'No default'), ...productionReminderOptions];
    if (showDebugReminders) {
      return [(-1, 'No default'), ...debugReminderOptions, ...productionReminderOptions];
    }
    return baseOptions;
  }
}
