import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:ecommerce/services/integrated_navigation_service.dart';
import 'package:ecommerce/services/tracking_service.dart';

class IntegratedNavigationScreen extends StatefulWidget {
  final LatLng destination;
  final String destinationName;
  final String? driverId;

  const IntegratedNavigationScreen({
    super.key,
    required this.destination,
    required this.destinationName,
    this.driverId,
  });

  @override
  State<IntegratedNavigationScreen> createState() => _IntegratedNavigationScreenState();
}

class _IntegratedNavigationScreenState extends State<IntegratedNavigationScreen> {
  GoogleMapController? _mapController;
  NavigationRoute? _route;
  LatLng? _currentLocation;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  bool _isLoading = true;
  String? _error;
  Timer? _locationTimer;
  List<String> _instructions = [];
  int _currentStepIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeNavigation();
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _initializeNavigation() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Obtenir la position actuelle
      await _getCurrentLocation();

      if (_currentLocation != null) {
        // Calculer l'itinéraire
        await _calculateRoute();
        
        // Démarrer le suivi de position
        _startLocationTracking();
      } else {
        setState(() {
          _error = 'Impossible d\'obtenir votre position actuelle';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Erreur lors de l\'initialisation: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Services de localisation désactivés');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Permission de localisation refusée');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Permission de localisation refusée définitivement');
      }

      final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
      });

      _updateMapMarkers();
    } catch (e) {
      print('❌ [NAVIGATION] Erreur position actuelle: $e');
      rethrow;
    }
  }

  Future<void> _calculateRoute() async {
    if (_currentLocation == null) return;

    try {
      final route = await IntegratedNavigationService.calculateRoute(
        origin: _currentLocation!,
        destination: widget.destination,
        mode: 'driving',
      );

      if (route != null) {
        setState(() {
          _route = route;
          _instructions = _extractInstructions(route);
        });

        _updateMapMarkers();
        _updatePolylines();
        _centerMapOnRoute();
      } else {
        setState(() {
          _error = 'Impossible de calculer l\'itinéraire';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Erreur lors du calcul de l\'itinéraire: $e';
      });
    }
  }

  List<String> _extractInstructions(NavigationRoute route) {
    // Instructions simplifiées basées sur les points de l'itinéraire
    List<String> instructions = [];
    
    if (route.points.length > 1) {
      instructions.add('Départ vers la destination');
      
      // Ajouter quelques instructions basées sur les changements de direction
      int instructionCount = 0;
      for (int i = 1; i < route.points.length - 1 && instructionCount < 3; i++) {
        final prev = route.points[i - 1];
        final current = route.points[i];
        final next = route.points[i + 1];
        
        final bearing1 = IntegratedNavigationService.calculateBearing(prev, current);
        final bearing2 = IntegratedNavigationService.calculateBearing(current, next);
        
        final angleDiff = (bearing2 - bearing1).abs();
        if (angleDiff > 30) { // Changement de direction significatif
          final direction = IntegratedNavigationService.getCardinalDirection(bearing2);
          instructions.add('Tourner $direction');
          instructionCount++;
        }
      }
      
      instructions.add('Arrivée à destination');
    }
    
    return instructions;
  }

  void _startLocationTracking() {
    _locationTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      await _updateCurrentLocation();
    });
  }

  Future<void> _updateCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
      });
      _updateMapMarkers();
      _updateCurrentStep();
    } catch (e) {
      print('❌ [NAVIGATION] Erreur mise à jour position: $e');
    }
  }

  void _updateCurrentStep() {
    if (_route == null || _currentLocation == null) return;

    // Trouver l'étape actuelle basée sur la position
    double minDistance = double.infinity;
    int closestStepIndex = 0;

    for (int i = 0; i < _route!.points.length; i++) {
      final distance = IntegratedNavigationService.calculateDirectDistance(
        _currentLocation!,
        _route!.points[i],
      );
      
      if (distance < minDistance) {
        minDistance = distance;
        closestStepIndex = i;
      }
    }

    if (closestStepIndex != _currentStepIndex) {
      setState(() {
        _currentStepIndex = closestStepIndex;
      });
    }
  }

  void _updateMapMarkers() {
    final markers = <Marker>{};

    // Marqueur de position actuelle
    if (_currentLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('current'),
          position: _currentLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(
            title: 'Votre position',
            snippet: 'Position actuelle',
          ),
        ),
      );
    }

    // Marqueur de destination
    markers.add(
      Marker(
        markerId: const MarkerId('destination'),
        position: widget.destination,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(
          title: 'Destination',
          snippet: widget.destinationName,
        ),
      ),
    );

    setState(() {
      _markers = markers;
    });
  }

  void _updatePolylines() {
    if (_route == null) return;

    final polylines = <Polyline>{};

    polylines.add(
      Polyline(
        polylineId: const PolylineId('route'),
        points: _route!.points,
        color: Colors.blue,
        width: 5,
      ),
    );

    setState(() {
      _polylines = polylines;
    });
  }

  void _centerMapOnRoute() {
    if (_mapController == null || _route == null) return;

    if (_route!.points.length > 1) {
      final bounds = _getBoundsForPoints(_route!.points);
      _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
    } else {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(widget.destination, 15),
      );
    }
  }

  LatLngBounds _getBoundsForPoints(List<LatLng> points) {
    double? minLat, maxLat, minLng, maxLng;

    for (final point in points) {
      minLat = minLat == null ? point.latitude : min(minLat, point.latitude);
      maxLat = maxLat == null ? point.latitude : max(maxLat, point.latitude);
      minLng = minLng == null ? point.longitude : min(minLng, point.longitude);
      maxLng = maxLng == null ? point.longitude : max(maxLng, point.longitude);
    }

    return LatLngBounds(
      southwest: LatLng(minLat!, minLng!),
      northeast: LatLng(maxLat!, maxLng!),
    );
  }

  double min(double a, double b) => a < b ? a : b;
  double max(double a, double b) => a > b ? a : b;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Navigation'),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _initializeNavigation,
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingWidget()
          : _error != null
              ? _buildErrorWidget()
              : _buildNavigationContent(),
    );
  }

  Widget _buildLoadingWidget() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Calcul de l\'itinéraire...'),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    final theme = Theme.of(context);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Erreur de navigation',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Une erreur est survenue',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _initializeNavigation,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationContent() {
    return Column(
      children: [
        // Carte
        Expanded(
          flex: 3,
          child: _buildMap(),
        ),

        // Informations de navigation
        Container(
          height: 200,
          child: SingleChildScrollView(
            child: _buildNavigationInfo(),
          ),
        ),
      ],
    );
  }

  Widget _buildMap() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: GoogleMap(
          initialCameraPosition: CameraPosition(
            target: _currentLocation ?? widget.destination,
            zoom: 15,
          ),
          onMapCreated: (controller) {
            _mapController = controller;
            _centerMapOnRoute();
          },
          markers: _markers,
          polylines: _polylines,
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
        ),
      ),
    );
  }

  Widget _buildNavigationInfo() {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // En-tête avec destination
          Row(
            children: [
              Icon(
                Icons.navigation,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Navigation vers ${widget.destinationName}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Informations de l'itinéraire
          if (_route != null) ...[
            Row(
              children: [
                Expanded(
                  child: _buildInfoCard(
                    'Distance',
                    IntegratedNavigationService.formatDistance(_route!.distance),
                    Icons.straighten,
                    theme,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildInfoCard(
                    'Durée',
                    IntegratedNavigationService.formatDuration(_route!.duration),
                    Icons.access_time,
                    theme,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],

          // Instructions de navigation
          if (_instructions.isNotEmpty) ...[
            Text(
              'Instructions',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _instructions.length,
                itemBuilder: (context, index) {
                  final isCurrentStep = index == _currentStepIndex;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isCurrentStep 
                          ? theme.colorScheme.primaryContainer
                          : theme.colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(6),
                      border: isCurrentStep 
                          ? Border.all(color: theme.colorScheme.primary)
                          : null,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isCurrentStep ? Icons.navigation : Icons.arrow_forward,
                          color: isCurrentStep 
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurfaceVariant,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _instructions[index],
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: isCurrentStep ? FontWeight.w600 : FontWeight.normal,
                              color: isCurrentStep 
                                  ? theme.colorScheme.onPrimaryContainer
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: theme.colorScheme.onPrimaryContainer,
            size: 16,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onPrimaryContainer,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
