import 'package:flutter/material.dart';
import 'package:anchor/models/parking_spot.dart';
import 'package:anchor/services/location_service.dart';
import 'package:anchor/services/storage_service.dart';
import 'package:anchor/widgets/primary_action_button.dart';
import 'package:anchor/widgets/current_spot_card.dart';
import 'package:anchor/widgets/save_spot_sheet.dart';
import 'package:anchor/screens/history_screen.dart';
import 'package:anchor/screens/settings_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin, WidgetsBindingObserver {
  late final WidgetsBinding _binding;
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      print('[HomeScreen] App resumed, reloading data');
      _loadData();
    }
  }
  ParkingSpot? _currentSpot;
  bool _isLoading = false;
  AppSettings _settings = AppSettings();
  late AnimationController _buttonAnimationController;
  late Animation<double> _buttonScaleAnimation;
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadData();
  _binding = WidgetsBinding.instance;
  _binding.addObserver(this);
    _initNotifications();
    _requestNotificationPermission();
  }

  Future<void> _requestNotificationPermission() async {
    // Android 13+ requires runtime notification permission
    final deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;
    if (androidInfo.version.sdkInt >= 33) {
      final status = await Permission.notification.request();
      print('[HomeScreen] Notification permission requested, status: $status');
    }
  }

  Future<void> _initNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: androidSettings);
    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) {
        debugPrint('[HomeScreen] Notification action received: ${response.actionId}');
        switch (response.actionId) {
          case 'finish':
            debugPrint('[HomeScreen] Finish action pressed');
            _handleArrived();
            break;
          case 'open_app':
            debugPrint('[HomeScreen] Open App action pressed');
            // Optionally bring app to foreground
            break;
          default:
            debugPrint('[HomeScreen] Unknown notification action: ${response.actionId}');
        }
      },
    );
    // Create notification channel for navigation actions
    const navChannel = AndroidNotificationChannel(
      'navigation_channel',
      'Navigation',
      description: 'Navigation actions',
      importance: Importance.max,
    );
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(navChannel);
      debugPrint('[HomeScreen] Navigation notification channel created');
    } else {
      debugPrint('[HomeScreen] AndroidFlutterLocalNotificationsPlugin not available');
    }
  }

  void _initializeAnimations() {
    _buttonAnimationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _buttonScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _buttonAnimationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _buttonAnimationController.dispose();
  _binding.removeObserver(this);
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    print('[HomeScreen] Loading data...');
    try {
      final spot = await StorageService.getActiveSpot();
      final settings = await StorageService.getSettings();
      print('[HomeScreen] Loaded spot: ${spot?.id}, settings: $settings');
      setState(() {
        _currentSpot = spot;
        _settings = settings;
      });

      // Update address if needed
      if (spot != null && spot.address == null) {
        _updateSpotAddress(spot);
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateSpotAddress(ParkingSpot spot) async {
    final address = await LocationService.reverseGeocode(spot.latitude, spot.longitude);
    if (address != null) {
      await StorageService.updateSpotAddress(spot.id, address);
      setState(() {
        _currentSpot = spot.copyWith(address: address);
      });
    }
  }

  Future<void> _handlePrimaryAction() async {
    await _buttonAnimationController.forward();
    await _buttonAnimationController.reverse();

    if (_currentSpot == null) {
      await _saveNewSpot();
    } else {
      await _navigateToSpot();
    }
  }

  Future<void> _saveNewSpot() async {
    print('[HomeScreen] Saving new spot...');
    final result = await showModalBottomSheet<ParkingSpot?> (
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SaveSpotSheet(settings: _settings),
    );

    if (result != null) {
      print('[HomeScreen] New spot saved: id=${result.id}, lat=${result.latitude}, lon=${result.longitude}');
      setState(() => _currentSpot = result);
      if (!mounted) return;
      final timeText = result.createdAt.hour.toString().padLeft(2, '0') + 
                     ':' + result.createdAt.minute.toString().padLeft(2, '0');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saved your spot • $timeText'),
          duration: const Duration(seconds: 2),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    } else {
      print('[HomeScreen] Spot save cancelled or failed');
    }
  }

  Future<void> _navigateToSpot() async {
    if (_currentSpot == null) {
      print('[HomeScreen] No spot to navigate to');
      return;
    }
    // If default navigation app is set, launch directly, else show options
    if (_settings.defaultNavigationApp != null && _settings.defaultNavigationApp != 'ask') {
      final navigationUrl = await LocationService.launchNavigation(
        _currentSpot!.latitude,
        _currentSpot!.longitude,
        _settings.defaultNavigationApp,
      );
      print('[HomeScreen] Launching default navigation app: ${_settings.defaultNavigationApp}');
      final uri = Uri.parse(navigationUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        await _showNavigationNotification();
        return;
      }
    }
    // Otherwise, show options sheet
    _showNavigationOptionsSheet();
    // await _showNavigationNotification();
  }

  Future<void> _showNavigationNotification() async {
    debugPrint('[HomeScreen] Showing navigation notification...');
    const androidDetails = AndroidNotificationDetails(
      'navigation_channel',
      'Navigation',
      channelDescription: 'Navigation actions',
      importance: Importance.max,
      priority: Priority.high,
      actions: [
        AndroidNotificationAction(
          'open_app',
          'Open App',
          showsUserInterface: true,
          // Add more options if needed
        ),
        AndroidNotificationAction(
          'finish',
          'Finish',
          showsUserInterface: true,
        ),
      ],
    );
    const details = NotificationDetails(android: androidDetails);
    await _notifications.show(
      1,
      'Navigation Started',
      'Tap to return to Anchor or mark as finished.',
      details,
    );
    debugPrint('[HomeScreen] Notification show call completed');
  }

  Future<void> _handleArrived() async {
    if (_currentSpot == null) return;
    await StorageService.deactivateCurrentSpot();
    await _loadData();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Marked as finished!')),
    );
  }

  void _showNavigationOptionsSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => NavigationOptionsSheet(
        spot: _currentSpot!,
        onShowNotification: _showNavigationNotification,
      ),
    );
  }

  String _getStatusText() {
    if (_currentSpot == null) {
      return 'No spot saved';
    }
    return 'Spot saved ${_currentSpot!.timeAgoLabel}';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Anchor',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const HistoryScreen()),
            ),
            icon: Icon(Icons.history, color: colorScheme.onPrimaryContainer),
          ),
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            ).then((_) => _loadData()),
            icon: Icon(Icons.settings, color: colorScheme.onPrimaryContainer),
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadData,
                displacement: 32,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    // Status Header
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        _getStatusText(),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          // Current Spot Card
                          if (_currentSpot != null) ...[
                            CurrentSpotCard(
                              spot: _currentSpot!,
                              settings: _settings,
                              onDelete: () async {
                                await StorageService.deleteSpot(_currentSpot!.id);
                                setState(() => _currentSpot = null);
                              },
                              onNavigate: _navigateToSpot,
                              onArrived: _handleArrived,
                            ),
                            const SizedBox(height: 32),
                          ],
                          const SizedBox(height: 32),
                          // Primary Action Button
                          ScaleTransition(
                            scale: _buttonScaleAnimation,
                            child: PrimaryActionButton(
                              hasActiveSpot: _currentSpot != null,
                              onPressed: _handlePrimaryAction,
                              isLoading: _isLoading,
                            ),
                          ),
                          const SizedBox(height: 48),
                          // Hint Text
                          if (_currentSpot == null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              child: Text(
                                '🅿️ Tap to save your parking spot with one touch',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class NavigationOptionsSheet extends StatelessWidget {
  final ParkingSpot spot;
  final Future<void> Function() onShowNotification;

  const NavigationOptionsSheet({super.key, required this.spot, required this.onShowNotification});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Choose Navigation',
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          _NavigationOption(
            icon: Icons.map,
            title: 'Google Maps',
            subtitle: 'Walking directions',
            onTap: () async {
              final url = 'https://www.google.com/maps/dir/?api=1&destination=${spot.latitude},${spot.longitude}&travelmode=walking';
              final uri = Uri.parse(url);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
              if (context.mounted) {
                Navigator.pop(context);
                await onShowNotification();
              }
            },
          ),
          _NavigationOption(
            icon: Icons.explore,
            title: 'Compass Mode',
            subtitle: 'Direction and distance only',
            onTap: () async {
              Navigator.pop(context);
              // TODO: Implement compass mode logic here
              await onShowNotification();
              // showCompassMode(context, spot); // Uncomment when implemented
            },
          ),
          _NavigationOption(
            icon: Icons.content_copy,
            title: 'Copy Coordinates',
            subtitle: 'Share location manually',
            onTap: () async {
              final coords = '${spot.latitude}, ${spot.longitude}';
              await copyToClipboard(context, coords);
              Navigator.pop(context);
              await onShowNotification();
            },
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> copyToClipboard(BuildContext context, String text) async {
    
    try {
      await Clipboard.setData(ClipboardData(text: text));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Coordinates copied: $text')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to copy coordinates')),
      );
    }
  }
}

class _NavigationOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _NavigationOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title),
      subtitle: Text(subtitle),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }
}

class CompassModeDialog extends StatelessWidget {
  final ParkingSpot spot;

  const CompassModeDialog({super.key, required this.spot});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('🧭 Compass Mode'),
      content: const Text('Compass mode requires device sensors. This is a simplified version showing coordinates.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}