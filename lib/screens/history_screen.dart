import 'dart:io';
import 'package:flutter/material.dart';
import 'package:anchor/models/parking_spot.dart';
import 'package:anchor/services/storage_service.dart';
import 'package:anchor/services/location_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<ParkingSpot> _historySpots = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    
    try {
      final spots = await StorageService.getHistorySpots(
        limit: 50,
        searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
      );
      
      setState(() {
        _historySpots = spots;
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _onSearchChanged(String query) {
    setState(() => _searchQuery = query);
    _loadHistory();
  }

  Future<void> _deleteSpot(ParkingSpot spot) async {
    await StorageService.deleteSpot(spot.id);
    _loadHistory();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Parking spot deleted'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () {
              // TODO: Implement undo functionality
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Parking History'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by location, note, or level...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                        icon: const Icon(Icons.clear),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          
          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _historySpots.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _historySpots.length,
                        itemBuilder: (context, index) => HistorySpotCard(
                          spot: _historySpots[index],
                          onNavigate: () => _navigateToSpot(_historySpots[index]),
                          onDelete: () => _showDeleteConfirmation(_historySpots[index]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty ? 'No parking history yet' : 'No spots found',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isEmpty 
                  ? 'Start saving your parking spots to see them here'
                  : 'Try a different search term',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(ParkingSpot spot) {
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
              _deleteSpot(spot);
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

  Future<void> _navigateToSpot(ParkingSpot spot) async {
    try {
      final navigationUrl = await LocationService.launchNavigation(
        spot.latitude,
        spot.longitude,
        null, // Use default navigation app
      );

      final uri = Uri.parse(navigationUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to open navigation')),
        );
      }
    }
  }
}

class HistorySpotCard extends StatefulWidget {
  final ParkingSpot spot;
  final VoidCallback onNavigate;
  final VoidCallback onDelete;

  const HistorySpotCard({
    super.key,
    required this.spot,
    required this.onNavigate,
    required this.onDelete,
  });

  @override
  State<HistorySpotCard> createState() => _HistorySpotCardState();
}

class _HistorySpotCardState extends State<HistorySpotCard> {
  String? _photoPath;

  @override
  void initState() {
    super.initState();
    _loadPhoto();
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
    final dateFormatter = DateFormat('MMM d, y • h:mm a');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                // Date and time
                Expanded(
                  child: Text(
                    dateFormatter.format(widget.spot.createdAt),
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                
                // Accuracy badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getAccuracyColor().withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.spot.accuracyLabel,
                    style: textTheme.labelSmall?.copyWith(
                      color: _getAccuracyColor(),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                
                // More menu
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'navigate':
                        widget.onNavigate();
                        break;
                      case 'delete':
                        widget.onDelete();
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

            const SizedBox(height: 12),

            // Content row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Photo thumbnail
                if (_photoPath != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(_photoPath!),
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),
                ],

                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Address
                      if (widget.spot.address?.isNotEmpty == true)
                        Text(
                          widget.spot.address!,
                          style: textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        )
                      else
                        Text(
                          '${widget.spot.latitude.toStringAsFixed(6)}, ${widget.spot.longitude.toStringAsFixed(6)}',
                          style: textTheme.bodySmall?.copyWith(
                            fontFamily: 'monospace',
                            color: colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),

                      const SizedBox(height: 4),

                      // Note
                      if (widget.spot.note?.isNotEmpty == true) ...[
                        Row(
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
                                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                      ],

                      // Level/spot
                      if (widget.spot.levelOrSpot?.isNotEmpty == true)
                        Row(
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
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Action button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: widget.onNavigate,
                icon: Icon(Icons.navigation, size: 18, color: colorScheme.primary),
                label: Text(
                  'Navigate to this spot',
                  style: TextStyle(color: colorScheme.primary),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: colorScheme.primary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}