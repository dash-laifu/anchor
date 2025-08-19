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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  ParkingSpot? _currentSpot;
  bool _isLoading = false;
  AppSettings _settings = AppSettings();
  late AnimationController _buttonAnimationController;
  late Animation<double> _buttonScaleAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadData();
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
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final spot = await StorageService.getActiveSpot();
      final settings = await StorageService.getSettings();
      
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
    final result = await showModalBottomSheet<ParkingSpot?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SaveSpotSheet(settings: _settings),
    );

    if (result != null) {
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
    }
  }

  Future<void> _navigateToSpot() async {
    if (_currentSpot == null) return;

    try {
      final navigationUrl = await LocationService.launchNavigation(
        _currentSpot!.latitude,
        _currentSpot!.longitude,
        _settings.defaultNavigationApp,
      );

      final uri = Uri.parse(navigationUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          _showNavigationOptionsSheet();
        }
      }
    } catch (e) {
      if (mounted) {
        _showNavigationOptionsSheet();
      }
    }
  }

  void _showNavigationOptionsSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => NavigationOptionsSheet(spot: _currentSpot!),
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
            : Column(
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
                  
                  // Main Content Area
                  Expanded(
                    child: Padding(
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
                            ),
                            const SizedBox(height: 32),
                          ],
                          
                          const Spacer(),
                          
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
                          
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class NavigationOptionsSheet extends StatelessWidget {
  final ParkingSpot spot;

  const NavigationOptionsSheet({super.key, required this.spot});

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
              if (context.mounted) Navigator.pop(context);
            },
          ),
          
          _NavigationOption(
            icon: Icons.explore,
            title: 'Compass Mode',
            subtitle: 'Direction and distance only',
            onTap: () {
              Navigator.pop(context);
              _showCompassMode(context, spot);
            },
          ),
          
          _NavigationOption(
            icon: Icons.content_copy,
            title: 'Copy Coordinates',
            subtitle: 'Share location manually',
            onTap: () {
              // TODO: Copy coordinates to clipboard
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Coordinates copied to clipboard')),
              );
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

  void _showCompassMode(BuildContext context, ParkingSpot spot) {
    showDialog(
      context: context,
      builder: (context) => CompassModeDialog(spot: spot),
    );
  }
}

class _NavigationOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _NavigationOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title),
        subtitle: Text(subtitle),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
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