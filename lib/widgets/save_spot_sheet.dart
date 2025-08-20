import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:anchor/models/parking_spot.dart';
import 'package:anchor/services/location_service.dart';
import 'package:anchor/services/storage_service.dart';
import 'package:path/path.dart' as path;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:flutter/services.dart';

class SaveSpotSheet extends StatefulWidget {
  final AppSettings settings;

  const SaveSpotSheet({super.key, required this.settings});

  @override
  State<SaveSpotSheet> createState() => _SaveSpotSheetState();
}

class _SaveSpotSheetState extends State<SaveSpotSheet> with TickerProviderStateMixin {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    tzdata.initializeTimeZones();
  }
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  final _noteController = TextEditingController();
  final _levelController = TextEditingController();
  final _imagePicker = ImagePicker();

  Position? _currentPosition;
  ParkingLocationAccuracy? _accuracy;
  String? _address;
  XFile? _selectedImage;
  int? _reminderMinutes;
  bool _isLoading = false;
  bool _isExpanded = false;

  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _getCurrentLocation();
    
    if (widget.settings.askDurationOnSave && widget.settings.defaultDurationMinutes != null) {
      _reminderMinutes = widget.settings.defaultDurationMinutes;
    }
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    // Start animation
    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _noteController.dispose();
    _levelController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);

    try {
      final position = await LocationService.getCurrentLocation();
      
      if (position != null) {
        _currentPosition = position;
        _accuracy = LocationService.getAccuracyLevel(position.accuracy);
        
        // Get address in background
        LocationService.reverseGeocode(position.latitude, position.longitude)
            .then((address) {
          if (mounted) {
            setState(() => _address = address);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to get location. Please check permissions.'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() => _selectedImage = image);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to take photo')),
        );
      }
    }
  }

  void _removeImage() {
    setState(() => _selectedImage = null);
  }

  Future<void> _saveSpot() async {
    debugPrint('[SaveSpotSheet] _saveSpot called');
    if (_currentPosition == null) {
      debugPrint('[SaveSpotSheet] No location available');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No location available')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final spotId = DateTime.now().millisecondsSinceEpoch.toString();
      
      // Save image if selected
      List<String> mediaIds = [];
      if (_selectedImage != null) {
        final mediaDir = await StorageService.getMediaDirectory();
        final fileName = 'spot_${spotId}_photo.jpg';
        final localPath = path.join(mediaDir, fileName);
        
        await File(_selectedImage!.path).copy(localPath);
        
        final mediaAsset = MediaAsset(
          id: 'media_${DateTime.now().millisecondsSinceEpoch}',
          spotId: spotId,
          type: 'photo',
          localPath: localPath,
          createdAt: DateTime.now(),
        );
        
        await StorageService.saveMediaAsset(mediaAsset);
        mediaIds.add(mediaAsset.id);
      }
      
      // Create parking spot
      final reminderAt = _reminderMinutes != null 
          ? DateTime.now().add(Duration(minutes: _reminderMinutes!))
          : null;
      final spot = ParkingSpot(
        id: spotId,
        createdAt: DateTime.now(),
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        accuracyMeters: _currentPosition!.accuracy,
        address: _address,
        note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
        levelOrSpot: _levelController.text.trim().isEmpty ? null : _levelController.text.trim(),
        mediaIds: mediaIds,
        reminderAt: reminderAt,
        source: SaveSource.manual,
        isActive: true,
      );

      await StorageService.saveParkingSpot(spot);

      // Schedule reminder notification if needed
      if (reminderAt != null) {
        final notifId = spot.id.hashCode;
        try {
          // cancel any previous pending notification for this spot id
          await _notifications.cancel(notifId);
          await _notifications.zonedSchedule(
            notifId,
            'Parking Reminder',
            'Your parking time is about to expire.',
            tz.TZDateTime.from(reminderAt, tz.local),
            NotificationDetails(
              android: AndroidNotificationDetails(
                'reminder_channel',
                'Parking Reminders',
                channelDescription: 'Reminders for parking duration',
                importance: Importance.max,
                priority: Priority.high,
              ),
            ),
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          );
          final pending = await _notifications.pendingNotificationRequests();
          debugPrint('[SaveSpotSheet] Scheduled notification. Pending count=${pending.length} ids=${pending.map((p) => p.id).toList()}');
        } on PlatformException catch (e) {
          debugPrint('[SaveSpotSheet] PlatformException scheduling notification: $e');
          // If exact alarms are not permitted, try a fallback to inexact scheduling
          try {
            await _notifications.zonedSchedule(
              notifId,
              'Parking Reminder',
              'Your parking time is about to expire.',
              tz.TZDateTime.from(reminderAt, tz.local),
              NotificationDetails(
                android: AndroidNotificationDetails(
                  'reminder_channel',
                  'Parking Reminders',
                  channelDescription: 'Reminders for parking duration',
                  importance: Importance.max,
                  priority: Priority.high,
                ),
              ),
              androidScheduleMode: AndroidScheduleMode.inexact,
            );
            final pending = await _notifications.pendingNotificationRequests();
            debugPrint('[SaveSpotSheet] Scheduled (fallback) notification. Pending count=${pending.length} ids=${pending.map((p) => p.id).toList()}');
          } catch (e2) {
            debugPrint('[SaveSpotSheet] Failed to schedule fallback notification: $e2');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Could not schedule reminder; check exact alarm permission')),
              );
            }
          }
        } catch (e) {
          debugPrint('[SaveSpotSheet] Unexpected error scheduling notification: $e');
        }
      }

      if (mounted) {
        debugPrint('[SaveSpotSheet] Attempting to close modal with spot: id=${spot.id}');
        Navigator.of(context, rootNavigator: true).pop(spot);
        debugPrint('[SaveSpotSheet] Modal close called');
      }
    } catch (e) {
      debugPrint('[SaveSpotSheet] Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save parking spot')),
        );
      }
    } finally {
      debugPrint('[SaveSpotSheet] finally block reached');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Color _getAccuracyColor() {
    if (_accuracy == null) return Theme.of(context).colorScheme.onSurface;
    
    switch (_accuracy!) {
      case ParkingLocationAccuracy.high:
        return Theme.of(context).colorScheme.primary;
      case ParkingLocationAccuracy.medium:
        return Theme.of(context).colorScheme.tertiary;
      case ParkingLocationAccuracy.low:
        return Theme.of(context).colorScheme.error;
    }
  }

  String _getAccuracyLabel() {
    if (_accuracy == null) return 'Getting location...';
    
    switch (_accuracy!) {
      case ParkingLocationAccuracy.high:
        return 'High Accuracy';
      case ParkingLocationAccuracy.medium:
        return 'Medium Accuracy';
      case ParkingLocationAccuracy.low:
        return 'Low Accuracy';
    }
  }

  Widget _buildReminderOptions() {
    const options = [
      (30, '30 min'),
      (60, '1 hour'),
      (120, '2 hours'),
      (240, '4 hours'),
    ];

    return Wrap(
      spacing: 8,
      children: [
        FilterChip(
          label: const Text('No reminder'),
          selected: _reminderMinutes == null,
          onSelected: (selected) {
            setState(() => _reminderMinutes = selected ? null : _reminderMinutes);
          },
        ),
        ...options.map((option) {
          return FilterChip(
            label: Text(option.$2),
            selected: _reminderMinutes == option.$1,
            onSelected: (selected) {
              setState(() => _reminderMinutes = selected ? option.$1 : null);
            },
          );
        }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.onSurface.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Title
              Text(
                'Save Parking Spot',
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 24),
              
              // Location accuracy indicator
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _getAccuracyColor().withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _getAccuracyColor().withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.gps_fixed,
                          color: _getAccuracyColor(),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _getAccuracyLabel(),
                          style: textTheme.titleMedium?.copyWith(
                            color: _getAccuracyColor(),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (_isLoading) ...[
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: _getAccuracyColor(),
                            ),
                          ),
                        ],
                      ],
                    ),
                    
                    if (_accuracy == ParkingLocationAccuracy.low) ...[
                      const SizedBox(height: 8),
                      Text(
                        'GPS weak (indoors?). Consider adding a photo or level/section.',
                        style: textTheme.bodySmall?.copyWith(
                          color: _getAccuracyColor().withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                    
                    if (_address != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _address!,
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.8),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Photo section
              if (_selectedImage != null) ...[
                Container(
                  height: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    image: DecorationImage(
                      image: FileImage(File(_selectedImage!.path)),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        top: 8,
                        right: 8,
                        child: IconButton(
                          onPressed: _removeImage,
                          icon: const Icon(Icons.close, color: Colors.white),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.black.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ] else ...[
                OutlinedButton.icon(
                  onPressed: _pickImage,
                  icon: Icon(Icons.camera_alt, color: colorScheme.primary),
                  label: Text('Add Photo', style: TextStyle(color: colorScheme.primary)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: colorScheme.primary),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              // Expandable options
              ExpansionTile(
                title: const Text('Additional Options'),
                initiallyExpanded: _isExpanded,
                onExpansionChanged: (expanded) => setState(() => _isExpanded = expanded),
                children: [
                  // Note field with top margin
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: TextField(
                      controller: _noteController,
                      decoration: InputDecoration(
                        labelText: 'Note (optional)',
                        hintText: 'e.g., Near the elevator',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.note),
                      ),
                      maxLines: 2,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Level/spot field
                  TextField(
                    controller: _levelController,
                    decoration: InputDecoration(
                      labelText: 'Level/Spot (optional)',
                      hintText: 'e.g., P2 Blue, Level 3',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.local_parking),
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Reminder options
                  if (widget.settings.askDurationOnSave) ...[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Parking Reminder',
                        style: textTheme.titleSmall,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildReminderOptions(),
                    const SizedBox(height: 16),
                  ],
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                      child: const Text('Cancel'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: (_isLoading || _currentPosition == null) ? null : _saveSpot,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Save Spot'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}