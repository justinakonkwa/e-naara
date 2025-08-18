import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:ecommerce/services/driver_tracking_service.dart';
import 'package:ecommerce/services/tracking_service.dart';
import 'package:ecommerce/services/location_service.dart';

class DriverTrackingWidget extends StatefulWidget {
  final String driverId;
  final VoidCallback? onTrackingStatusChanged;

  const DriverTrackingWidget({
    super.key,
    required this.driverId,
    this.onTrackingStatusChanged,
  });

  @override
  State<DriverTrackingWidget> createState() => _DriverTrackingWidgetState();
}

class _DriverTrackingWidgetState extends State<DriverTrackingWidget> {
  bool _isTracking = false;
  bool _isOnline = false;
  Map<String, dynamic>? _currentLocation;
  Timer? _statusTimer;

  @override
  void initState() {
    super.initState();
    _loadTrackingStatus();
    _startStatusUpdates();
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    super.dispose();
  }

  void _startStatusUpdates() {
    _statusTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _loadTrackingStatus();
    });
  }

  Future<void> _loadTrackingStatus() async {
    final status = DriverTrackingService.getTrackingStatus();
    final location = await TrackingService.getDriverLocation(widget.driverId);

    if (mounted) {
      setState(() {
        _isTracking = status['isTracking'] ?? false;
        _isOnline = status['isOnline'] ?? false;
        _currentLocation = location;
      });
    }
  }

  Future<void> _toggleTracking() async {
    if (_isTracking) {
      await DriverTrackingService.stopTracking();
    } else {
      await DriverTrackingService.startTracking(widget.driverId);
    }
    
    _loadTrackingStatus();
    widget.onTrackingStatusChanged?.call();
  }

  Future<void> _toggleOnlineStatus() async {
    if (_isOnline) {
      await DriverTrackingService.pauseTracking();
    } else {
      await DriverTrackingService.resumeTracking();
    }
    
    _loadTrackingStatus();
    widget.onTrackingStatusChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isTracking 
              ? theme.colorScheme.primary.withValues(alpha: 0.3)
              : theme.colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête avec statut
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _isTracking 
                      ? theme.colorScheme.primaryContainer
                      : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _isTracking ? Icons.gps_fixed : Icons.gps_off,
                  size: 20,
                  color: _isTracking 
                      ? theme.colorScheme.onPrimaryContainer
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tracking GPS',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _isTracking ? 'Actif' : 'Inactif',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: _isTracking 
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _isTracking,
                onChanged: (value) => _toggleTracking(),
                activeColor: theme.colorScheme.primary,
              ),
            ],
          ),

          if (_isTracking) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),

            // Informations de position
            if (_currentLocation != null) ...[
              _buildLocationInfo(),
              const SizedBox(height: 16),
            ],

            // Contrôles
            _buildControls(),
          ],
        ],
      ),
    );
  }

  Widget _buildLocationInfo() {
    final theme = Theme.of(context);
    final locationInfo = TrackingService.formatLocationInfo(_currentLocation!);

    return Column(
      children: [
        _buildInfoRow('Position', locationInfo['position']!, Icons.location_on),
        const SizedBox(height: 8),
        _buildInfoRow('Précision', locationInfo['accuracy']!, Icons.gps_fixed),
        const SizedBox(height: 8),
        _buildInfoRow('Vitesse', locationInfo['speed']!, Icons.speed),
        const SizedBox(height: 8),
        _buildInfoRow('Direction', locationInfo['heading']!, Icons.compass_calibration),
        const SizedBox(height: 8),
        _buildInfoRow('Batterie', locationInfo['battery']!, Icons.battery_full),
        const SizedBox(height: 8),
        _buildInfoRow('Dernière mise à jour', locationInfo['lastSeen']!, Icons.access_time),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    final theme = Theme.of(context);
    
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildControls() {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Statut en ligne/hors ligne
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _toggleOnlineStatus,
                icon: Icon(
                  _isOnline ? Icons.visibility : Icons.visibility_off,
                  size: 18,
                ),
                label: Text(_isOnline ? 'En ligne' : 'Hors ligne'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _isOnline 
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                  side: BorderSide(
                    color: _isOnline 
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showAccuracySettings(),
                icon: const Icon(Icons.settings, size: 18),
                label: const Text('Précision'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.primary,
                  side: BorderSide(color: theme.colorScheme.primary),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Boutons d'action
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _forceLocationUpdate(),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Actualiser'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showTrackingStats(),
                icon: const Icon(Icons.analytics, size: 18),
                label: const Text('Stats'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.primary,
                  side: BorderSide(color: theme.colorScheme.primary),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showAccuracySettings() {
    showModalBottomSheet(
      context: context,
      builder: (context) => _buildAccuracySettingsSheet(),
    );
  }

  Widget _buildAccuracySettingsSheet() {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Précision GPS',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildAccuracyOption(
            'Haute précision',
            'Meilleure précision, plus de batterie',
            LocationAccuracy.best,
            Icons.gps_fixed,
          ),
          const SizedBox(height: 8),
          _buildAccuracyOption(
            'Précision moyenne',
            'Bon équilibre précision/batterie',
            LocationAccuracy.high,
            Icons.gps_not_fixed,
          ),
          const SizedBox(height: 8),
          _buildAccuracyOption(
            'Économie batterie',
            'Moins précis, économise la batterie',
            LocationAccuracy.medium,
            Icons.battery_saver,
          ),
        ],
      ),
    );
  }

  Widget _buildAccuracyOption(String title, String subtitle, LocationAccuracy accuracy, IconData icon) {
    final theme = Theme.of(context);

    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.primary),
      title: Text(title),
      subtitle: Text(subtitle),
      onTap: () {
        DriverTrackingService.setAccuracy(accuracy);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Précision changée: $title'),
            backgroundColor: theme.colorScheme.primary,
          ),
        );
      },
    );
  }

  void _forceLocationUpdate() async {
    final position = await LocationService.getCurrentLocation();
    if (position != null) {
      await TrackingService.updateDriverLocationFromPosition(
        driverId: widget.driverId,
        position: position,
      );
      _loadTrackingStatus();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Position actualisée'),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible de récupérer la position'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showTrackingStats() {
    final status = DriverTrackingService.getTrackingStatus();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Statistiques de tracking'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatRow('Tracking actif', status['isTracking'] ? 'Oui' : 'Non'),
            _buildStatRow('En ligne', status['isOnline'] ? 'Oui' : 'Non'),
            _buildStatRow('ID livreur', status['driverId'] ?? 'N/A'),
            _buildStatRow('Stream GPS', status['hasLocationSubscription'] ? 'Actif' : 'Inactif'),
            _buildStatRow('Timer mise à jour', status['hasUpdateTimer'] ? 'Actif' : 'Inactif'),
            _buildStatRow('Timer batterie', status['hasBatteryTimer'] ? 'Actif' : 'Inactif'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
