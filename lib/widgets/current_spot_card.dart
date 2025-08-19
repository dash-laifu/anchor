import 'dart:io';
import 'package:flutter/material.dart';
import 'package:anchor/models/parking_spot.dart';
import 'package:anchor/services/location_service.dart';
import 'package:anchor/services/storage_service.dart';
import 'package:geolocator/geolocator.dart';

class CurrentSpotCard extends StatefulWidget {
  final ParkingSpot spot;
  final AppSettings settings;
  final VoidCallback onDelete;
  final VoidCallback onNavigate;
  final VoidCallback onArrived;

  const CurrentSpotCard({
    super.key,
    required this.spot,
    required this.settings,
    required this.onDelete,
    required this.onNavigate,
    required this.onArrived,
  });

  @override
  State<CurrentSpotCard> createState() => _CurrentSpotCardState();
}

class _CurrentSpotCardState extends State<CurrentSpotCard> {
  void _showArrivedConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark as Finished'),
        content: const Text('Are you sure you want to mark this spot as finished? You can still navigate again if needed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onArrived();
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.tertiary,
            ),
            child: const Text('Finish'),
          ),
        ],
      ),
    );
  }
  double? _distanceToSpot;
  String? _photoPath;

  @override
  void initState() {
    super.initState();
    _calculateDistance();
    _loadPhoto();
  }

  Future<void> _calculateDistance() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      final distance = LocationService.calculateDistance(
        position.latitude,
        position.longitude,
        widget.spot.latitude,
        widget.spot.longitude,
      );
      
      setState(() {
        _distanceToSpot = distance;
      });
    } catch (e) {
      // Distance calculation failed - continue without it
    }
  }

  Future<void> _loadPhoto() async {
    if (widget.spot.mediaIds.isNotEmpty) {
      final mediaAssets = await StorageService.getMediaForSpot(widget.spot.id);
      if (mediaAssets.isNotEmpty && mediaAssets.first.exists) {
        setState(() {
          _photoPath = mediaAssets.first.localPath;
        });
      }
    }
  }

  Color _getAccuracyColor() {
    switch (widget.spot.accuracy) {
      case ParkingLocationAccuracy.high:
        return Theme.of(context).colorScheme.primary;
      case ParkingLocationAccuracy.medium:
        return Theme.of(context).colorScheme.tertiary;
      case ParkingLocationAccuracy.low:
        return Theme.of(context).colorScheme.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with accuracy indicator
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getAccuracyColor().withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.gps_fixed,
                        size: 14,
                        color: _getAccuracyColor(),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.spot.accuracyLabel,
                        style: textTheme.labelSmall?.copyWith(
                          color: _getAccuracyColor(),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: colorScheme.onSurface.withValues(alpha: 0.6)),
                  onSelected: (value) {
                    switch (value) {
                      case 'navigate':
                        widget.onNavigate();
                        break;
                      case 'delete':
                        _showDeleteConfirmation();
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'navigate',
                      child: Row(
                        children: [
                          Icon(Icons.navigation, color: colorScheme.primary),
                          const SizedBox(width: 8),
                          const Text('Navigate'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: colorScheme.error),
                          const SizedBox(width: 8),
                          const Text('Delete'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Main content row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Photo thumbnail (if available)
                if (_photoPath != null) ...[
                  GestureDetector(
                    onTap: _showPhoto,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(_photoPath!),
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],

                // Spot details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Address or coordinates
                      if (widget.spot.address?.isNotEmpty == true)
                        Text(
                          widget.spot.address!,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        )
                      else
                        Text(
                          '${widget.spot.latitude.toStringAsFixed(6)}, ${widget.spot.longitude.toStringAsFixed(6)}',
                          style: textTheme.bodyMedium?.copyWith(
                            fontFamily: 'monospace',
                            color: colorScheme.onSurface.withValues(alpha: 0.8),
                          ),
                        ),

                      const SizedBox(height: 8),

                      // Distance and time info
                      Row(
                        children: [
                          if (_distanceToSpot != null) ...[
                            Icon(
                              Icons.straighten,
                              size: 16,
                              color: colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              LocationService.formatDistance(_distanceToSpot!, widget.settings.distanceUnit),
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurface.withValues(alpha: 0.8),
                              ),
                            ),
                            const SizedBox(width: 16),
                          ],
                          Icon(
                            Icons.schedule,
                            size: 16,
                            color: colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            widget.spot.timeAgoLabel,
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurface.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),

                      // Note preview
                      if (widget.spot.note?.isNotEmpty == true) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainer,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.note,
                                size: 14,
                                color: colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  widget.spot.note!,
                                  style: textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurface.withValues(alpha: 0.8),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Level/spot info
                      if (widget.spot.levelOrSpot?.isNotEmpty == true) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.local_parking,
                                size: 14,
                                color: colorScheme.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                widget.spot.levelOrSpot!,
                                style: textTheme.bodySmall?.copyWith(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),

            // Quick actions
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: widget.onNavigate,
                    icon: Icon(Icons.navigation, color: colorScheme.primary),
                    label: Text(
                      'Navigate',
                      style: TextStyle(color: colorScheme.primary),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: colorScheme.primary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _showArrivedConfirmation,
                    icon: Icon(Icons.check_circle, color: colorScheme.tertiary),
                    label: Text(
                      'Arrived',
                      style: TextStyle(color: colorScheme.tertiary),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: colorScheme.tertiary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
            ),

            // Accuracy hint for low accuracy
            if (widget.spot.accuracy == ParkingLocationAccuracy.low && widget.settings.showAccuracyHints) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: colorScheme.error.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info,
                      size: 16,
                      color: colorScheme.error,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.spot.accuracyHint,
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Parking Spot'),
        content: const Text('Are you sure you want to delete this parking spot? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onDelete();
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showPhoto() {
    if (_photoPath == null) return;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            Center(
              child: Image.file(
                File(_photoPath!),
                fit: BoxFit.contain,
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.white),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black.withValues(alpha: 0.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}