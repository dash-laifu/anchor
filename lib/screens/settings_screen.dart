import 'package:flutter/material.dart';
import 'package:anchor/models/parking_spot.dart';
import 'package:anchor/services/storage_service.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  AppSettings _settings = AppSettings();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    
    try {
      final settings = await StorageService.getSettings();
      setState(() => _settings = settings);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    await StorageService.saveSettings(_settings);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved')),
      );
    }
  }

  Future<void> _updateSettings(AppSettings newSettings) async {
    // If enabling askDurationOnSave, require exact alarm permission
    if (!(_settings.askDurationOnSave) && newSettings.askDurationOnSave) {
      final status = await _requestExactAlarmPermission();
      if (!status) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Exact alarm permission required for reminders. Enable in system settings.')),
          );
        }
        // Do not enable if permission not granted
        setState(() => _settings = _settings.copyWith(askDurationOnSave: false));
        return;
      }
    }
    setState(() => _settings = newSettings);
    _saveSettings();
  }

  Future<bool> _requestExactAlarmPermission() async {
    // Only needed for Android 13+
    try {
      final deviceInfo = await DeviceInfoPlugin().androidInfo;
      if (deviceInfo.version.sdkInt >= 33) {
        final status = await Permission.scheduleExactAlarm.request();
        return status.isGranted;
      }
      return true;
    } catch (e) {
      debugPrint('[SettingsScreen] Error requesting exact alarm permission: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSection(
                  'Reminders',
                  Icons.notifications,
                  [
                    _buildSwitchTile(
                      'Ask for parking duration when saving',
                      'Get reminded when your parking time is about to expire',
                      _settings.askDurationOnSave,
                      (value) => _updateSettings(_settings.copyWith(askDurationOnSave: value)),
                    ),
                    if (_settings.askDurationOnSave)
                      _buildDropdownTile<int>(
                        'Default parking duration',
                        _settings.defaultDurationMinutes ?? -1,
                        [
                          (-1, 'No default'),
                          (30, '30 minutes'),
                          (60, '1 hour'),
                          (120, '2 hours'),
                          (240, '4 hours'),
                        ],
                        (value) => _updateSettings(_settings.copyWith(defaultDurationMinutes: value)),
                      ),
                  ],
                ),

                const SizedBox(height: 24),

                _buildSection(
                  'Units & Formatting',
                  Icons.straighten,
                  [
                    _buildDropdownTile(
                      'Distance unit',
                      _settings.distanceUnit,
                      [
                        ('km', 'Kilometers (km)'),
                        ('mi', 'Miles (mi)'),
                      ],
                      (value) => _updateSettings(_settings.copyWith(distanceUnit: value)),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                _buildSection(
                  'Navigation',
                  Icons.navigation,
                  [
                    _buildDropdownTile<String>(
                      'Default navigation app',
                      _settings.defaultNavigationApp ?? 'ask',
                      [
                        ('ask', 'Ask every time'),
                        ('google_maps', 'Google Maps'),
                        ('apple_maps', 'Apple Maps'),
                      ],
                      (value) => _updateSettings(_settings.copyWith(defaultNavigationApp: value)),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                _buildSection(
                  'Privacy & Data',
                  Icons.privacy_tip,
                  [
                    _buildInfoTile(
                      'Data storage',
                      'All your data is stored locally on this device only',
                      Icons.phone_android,
                    ),
                    _buildSwitchTile(
                      'Show accuracy hints',
                      'Display helpful tips when GPS accuracy is low',
                      _settings.showAccuracyHints,
                      (value) => _updateSettings(_settings.copyWith(showAccuracyHints: value)),
                    ),
                    _buildActionTile(
                      'Export data',
                      'Save your parking history to a file',
                      Icons.download,
                      _exportData,
                    ),
                    _buildActionTile(
                      'Delete all data',
                      'Permanently remove all parking spots and settings',
                      Icons.delete_forever,
                      _showDeleteAllConfirmation,
                      textColor: colorScheme.error,
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                _buildSection(
                  'About',
                  Icons.info,
                  [
                    _buildInfoTile(
                      'Anchor - Parking Saver',
                      'Never wander a parking lot again',
                      Icons.anchor,
                    ),
                    _buildInfoTile(
                      'Version',
                      '1.0.0',
                      Icons.tag,
                    ),
                    _buildActionTile(
                      'Help & Tips',
                      'Learn how to use the app effectively',
                      Icons.help,
                      _showHelpDialog,
                    ),
                  ],
                ),

                const SizedBox(height: 32),
              ],
            ),
    );
  }

  Widget _buildSection(String title, IconData icon, List<Widget> children) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildDropdownTile<T>(String title, T value, List<(T, String)> options, ValueChanged<T> onChanged) {
    String subtitle = options.firstWhere((opt) => opt.$1 == value, orElse: () => options.first).$2;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: DropdownButton<T>(
        value: options.any((opt) => opt.$1 == value) ? value : options.first.$1,
        underline: const SizedBox(),
        items: options.map((option) {
          return DropdownMenuItem<T>(
            value: option.$1,
            child: Text(option.$2),
          );
        }).toList(),
        onChanged: (selected) {
          onChanged(selected!);
        },
      ),
    );
  }

  Widget _buildActionTile(String title, String subtitle, IconData icon, VoidCallback onTap, {Color? textColor}) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: textColor ?? Theme.of(context).colorScheme.onSurface),
      title: Text(title, style: TextStyle(color: textColor)),
      subtitle: Text(subtitle),
      trailing: Icon(Icons.chevron_right, color: textColor ?? Theme.of(context).colorScheme.onSurface),
      onTap: onTap,
    );
  }

  Widget _buildInfoTile(String title, String subtitle, IconData icon) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
      title: Text(title),
      subtitle: Text(subtitle),
    );
  }

  void _exportData() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Data'),
        content: const Text('This feature will be available in a future update.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAllConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Data'),
        content: const Text(
          'This will permanently delete all your parking spots, photos, and settings. This action cannot be undone.\n\nAre you sure you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteAllData();
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAllData() async {
    try {
      await StorageService.deleteAllData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All data deleted')),
        );
        
        // Reset settings to defaults
        setState(() => _settings = AppSettings());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete data')),
        );
      }
    }
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help & Tips'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '🅿️ Saving Your Spot',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Tap the big button to save your parking location\n• Take a photo for easy identification\n• Add notes like "near elevator" or level info'),
              SizedBox(height: 16),
              
              Text(
                '🧭 Finding Your Car',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Tap the navigation button to get walking directions\n• Use your preferred maps app or copy coordinates'),
              SizedBox(height: 16),
              
              Text(
                '📍 Indoor Parking',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• GPS may be weak indoors - that\'s OK!\n• Take a photo of nearby signs or landmarks\n• Note the level, section, or spot number'),
              SizedBox(height: 16),
              
              Text(
                '🔒 Privacy',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• All data stays on your device\n• No accounts or cloud storage required\n• Your location is never shared'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }
}