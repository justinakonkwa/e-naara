import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:ecommerce/services/tracking_service.dart';
import 'package:ecommerce/services/integrated_navigation_service.dart';
import 'package:ecommerce/services/supabase_service.dart';
import 'package:ecommerce/models/order.dart';
import 'package:ecommerce/services/geocoding_service.dart';
import 'package:ecommerce/services/geo_restriction_service.dart';


class OrderTrackingScreen extends StatefulWidget {
  final String orderId;

  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  Map<String, dynamic>? _driverLocation;
  SimpleOrder? _order;
  String? _driverId;
  Timer? _locationTimer;
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  bool _isLoading = true;
  String? _error;
  LatLng? _clientLatLng;
  String? _routeDistanceText;
  String? _routeDurationText;
  LatLng? _deliveryLatLng;

  // Coordonnées par défaut (Kinshasa)
  static const LatLng _defaultLocation = LatLng(-4.441, 15.266);

  @override
  void initState() {
    super.initState();
    _loadOrderAndDriver();
    _startLocationTracking();
    _initClientLocation();
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _loadOrderAndDriver() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Charger la commande
      final order = await SupabaseService.getOrderById(widget.orderId);
      if (order != null) {
        setState(() {
          _order = order;
          _driverId = order.driverId;
        });

        // Déterminer la position de livraison (coords ou géocodage)
        if (order.shippingLatitude != null && order.shippingLongitude != null) {
          _deliveryLatLng = LatLng(order.shippingLatitude!, order.shippingLongitude!);
        } else {
          final geo = await GeocodingService.geocodeAddress(order.shippingAddress);
          if (mounted) setState(() => _deliveryLatLng = geo);
        }

        // Charger la position du livreur
        if (_driverId != null) {
          await _loadDriverLocation();
        }
      } else {
        setState(() {
          _error = 'Commande non trouvée';
        });
      }
    } catch (e) {
      print('❌ [TRACKING] Erreur chargement: $e');
      setState(() {
        _error = 'Erreur lors du chargement des données';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
      // Tenter un calcul d'itinéraire si on a déjà la position du livreur
      if (_driverLocation != null) {
        await _updateRoutePolyline();
      }
    }
  }

  void _startLocationTracking() {
    _locationTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (_driverId != null) {
        _loadDriverLocation();
      }
    });
  }

  Future<void> _initClientLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return;
      }

      final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      if (mounted) {
        setState(() {
          _clientLatLng = LatLng(position.latitude, position.longitude);
        });
        _updateMapMarkers();
      }
    } catch (e) {
      // Silencieux: si indisponible, on continue sans la position client
    }
  }

  Future<void> _loadDriverLocation() async {
    if (_driverId != null) {
      try {
        print('🔍 [TRACKING] Chargement position pour driverId: $_driverId');
        final location = await TrackingService.getDriverLocation(_driverId!);
        
        print('🔍 [TRACKING] Location reçue: $location');
        
        if (mounted) {
          setState(() {
            _driverLocation = location;
          });
          print('🔍 [TRACKING] _driverLocation mis à jour: $_driverLocation');
          _updateMapMarkers();
          _updateRoutePolyline();
        }
      } catch (e) {
        print('❌ [TRACKING] Erreur chargement position: $e');
      }
    } else {
      print('⚠️ [TRACKING] _driverId est null');
    }
  }

  Future<void> _updateRoutePolyline() async {
    try {
      if (_driverLocation == null || _order == null) {
        setState(() {
          _polylines = {};
          _routeDistanceText = null;
          _routeDurationText = null;
        });
        return;
      }

      // Déterminer la destination (adresse de livraison)
      if (_order!.shippingLatitude == null || _order!.shippingLongitude == null) {
        // Pas de coordonnées de livraison → pas d'itinéraire
        setState(() {
          _polylines = {};
          _routeDistanceText = null;
          _routeDurationText = null;
        });
        return;
      }

      final origin = LatLng(
        _driverLocation!['latitude'],
        _driverLocation!['longitude'],
      );
      final destination = LatLng(
        _order!.shippingLatitude!,
        _order!.shippingLongitude!,
      );

      final route = await IntegratedNavigationService.calculateRoute(
        origin: origin,
        destination: destination,
        mode: 'driving',
      );

      if (!mounted) return;

      if (route != null) {
        final polyline = Polyline(
          polylineId: const PolylineId('driver_to_delivery'),
          points: route.points,
          color: Colors.blue,
          width: 5,
        );

        setState(() {
          _polylines = {polyline};
          _routeDistanceText = IntegratedNavigationService.formatDistance(route.distance);
          _routeDurationText = IntegratedNavigationService.formatDuration(route.duration);
        });

        // Centrer la carte sur l'itinéraire
        if (_mapController != null && route.points.isNotEmpty) {
          final bounds = _getBoundsForPoints(route.points);
          _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 60));
        }
      } else {
        // Fallback: tracer une ligne directe entre le livreur et la destination
        final fallbackPoints = [origin, destination];
        final directDistance = IntegratedNavigationService.calculateDirectDistance(origin, destination);
        // Estimation simple de durée: 30 km/h
        final estSeconds = (directDistance / (30 * 1000) * 3600).round();

        final fallbackPolyline = Polyline(
          polylineId: const PolylineId('driver_to_delivery_fallback'),
          points: fallbackPoints,
          color: Colors.blueAccent,
          width: 4,
        );

        setState(() {
          _polylines = {fallbackPolyline};
          _routeDistanceText = IntegratedNavigationService.formatDistance(directDistance);
          _routeDurationText = IntegratedNavigationService.formatDuration(estSeconds);
        });
      }
    } catch (e) {
      print('❌ [TRACKING] Erreur calcul itinéraire: $e');
    }
  }

  void _updateMapMarkers() {
    final markers = <Marker>{};

    // Marqueur du livreur
    if (_driverLocation != null) {
      final driverLatLng = LatLng(
        _driverLocation!['latitude'],
        _driverLocation!['longitude'],
      );

      markers.add(
        Marker(
          markerId: const MarkerId('driver'),
          position: driverLatLng,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: InfoWindow(
            title: 'Livreur',
            snippet: 'En route vers vous',
          ),
        ),
      );
    }

    // Marqueur de la position du client (uniquement si en RDC)
    if (_clientLatLng != null && GeoRestrictionService.isInRDC(_clientLatLng!)) {
      markers.add(
        Marker(
          markerId: const MarkerId('client'),
          position: _clientLatLng!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: const InfoWindow(
            title: 'Votre position',
          ),
        ),
      );
    }

    // Marqueur de destination (adresse de livraison)
    if (_order != null && _deliveryLatLng != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('delivery'),
          position: _deliveryLatLng!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: 'Adresse de livraison',
            snippet: _order!.shippingAddress,
          ),
        ),
      );
    }

    setState(() {
      _markers = markers;
    });

    // Centrer la carte intelligemment selon les positions disponibles (priorité: livreur + livraison)
    if (_mapController != null) {
      final hasDriver = _driverLocation != null;
      final hasDelivery = _deliveryLatLng != null;
      final hasClient = _clientLatLng != null && GeoRestrictionService.isInRDC(_clientLatLng!);

      if (hasDriver && hasDelivery) {
        final sw = LatLng(
          _min(_driverLocation!['latitude'], _deliveryLatLng!.latitude),
          _min(_driverLocation!['longitude'], _deliveryLatLng!.longitude),
        );
        final ne = LatLng(
          _max(_driverLocation!['latitude'], _deliveryLatLng!.latitude),
          _max(_driverLocation!['longitude'], _deliveryLatLng!.longitude),
        );
        final bounds = LatLngBounds(southwest: sw, northeast: ne);
        _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 60));
      } else if (hasDriver) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(_driverLocation!['latitude'], _driverLocation!['longitude']),
            15,
          ),
        );
      } else if (_deliveryLatLng != null) {
        _mapController!.animateCamera(CameraUpdate.newLatLngZoom(_deliveryLatLng!, 14));
      } else {
        _mapController!.animateCamera(CameraUpdate.newLatLngZoom(_defaultLocation, 12));
      }
    }
  }

  LatLngBounds _getBoundsForPoints(List<LatLng> points) {
    double? minLat, maxLat, minLng, maxLng;
    for (final p in points) {
      minLat = minLat == null ? p.latitude : _min(minLat, p.latitude);
      maxLat = maxLat == null ? p.latitude : _max(maxLat, p.latitude);
      minLng = minLng == null ? p.longitude : _min(minLng, p.longitude);
      maxLng = maxLng == null ? p.longitude : _max(maxLng, p.longitude);
    }
    return LatLngBounds(
      southwest: LatLng(minLat!, minLng!),
      northeast: LatLng(maxLat!, maxLng!),
    );
  }

  double _min(double a, double b) => a < b ? a : b;
  double _max(double a, double b) => a > b ? a : b;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Suivi de livraison'),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOrderAndDriver,
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingWidget()
          : _error != null
              ? _buildErrorWidget()
              : _buildTrackingContent(),
    );
  }

  Widget _buildLoadingWidget() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Chargement du suivi...'),
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
              'Erreur',
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
              onPressed: _loadOrderAndDriver,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackingContent() {
    return Column(
      children: [
        // Carte Google Maps
        Expanded(
          flex: 2,
          child: _buildMap(),
        ),

        // Informations de livraison
        Expanded(
          flex: 1,
          child: _buildDeliveryInfo(),
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
          initialCameraPosition: const CameraPosition(
            target: _defaultLocation,
            zoom: 12,
          ),
          onMapCreated: (controller) {
            _mapController = controller;
            _updateMapMarkers();
          },
          markers: _markers,
          polylines: _polylines,
          myLocationEnabled: false,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
        ),
      ),
    );
  }

  Widget _buildDeliveryInfo() {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
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
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.local_shipping,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Informations de livraison',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Debug: Afficher l'état de _driverLocation
            _buildInfoRow('Debug', '_driverLocation: ${_driverLocation != null ? "Non null" : "Null"}', Icons.bug_report),
            
            if (_driverLocation != null) ...[
              _buildInfoRow('Livreur', 'En route', Icons.person),
              _buildInfoRow('Position', _formatPosition(_driverLocation!), Icons.location_on),
              _buildInfoRow('Dernière mise à jour', _formatLastSeen(_driverLocation!['last_updated']), Icons.access_time),
            ] else ...[
              _buildInfoRow('Livreur', 'Position non disponible', Icons.person),
            ],

            if (_order != null) ...[
              const SizedBox(height: 16),
              _buildInfoRow('Statut', _getStatusText(_order!.status), Icons.info),
              _buildInfoRow('Adresse', _order!.shippingAddress, Icons.home),
              if (_routeDistanceText != null && _routeDurationText != null) ...[
                const SizedBox(height: 8),
                _buildInfoRow('Itinéraire', '${_routeDistanceText!} • ${_routeDurationText!}', Icons.alt_route),
              ],
            ],

            const SizedBox(height: 20),
            _buildActionButtons(),
            
            // Bouton de debug (temporaire)
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  print('🔍 [DEBUG] Rechargement forcé de la position du livreur');
                  await _loadDriverLocation();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Debug: Recharger position'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 16,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final theme = Theme.of(context);
    
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _callDriver,
            icon: const Icon(Icons.phone),
            label: const Text('Appeler'),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _messageDriver,
            icon: const Icon(Icons.message),
            label: const Text('Message'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  String _formatPosition(Map<String, dynamic> location) {
    final lat = location['latitude']?.toStringAsFixed(6) ?? 'N/A';
    final lng = location['longitude']?.toStringAsFixed(6) ?? 'N/A';
    return '$lat, $lng';
  }

  String _formatLastSeen(String? lastUpdated) {
    if (lastUpdated == null) {
      return 'N/A';
    }

    final lastSeen = DateTime.parse(lastUpdated);
    final now = DateTime.now();
    final difference = now.difference(lastSeen);

    if (difference.inMinutes < 1) {
      return 'À l\'instant';
    } else if (difference.inMinutes < 60) {
      return 'Il y a ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'Il y a ${difference.inHours} h';
    } else {
      return 'Il y a ${difference.inDays} j';
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'En attente';
      case 'confirmed':
        return 'Confirmée';
      case 'assigned':
        return 'Assignée à un livreur';
      case 'picked_up':
        return 'Colis récupéré';
      case 'out_for_delivery':
        return 'En livraison';
      case 'delivered':
        return 'Livrée';
      case 'cancelled':
        return 'Annulée';
      default:
        return status;
    }
  }

  void _callDriver() {
    // TODO: Implémenter l'appel du livreur
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fonctionnalité d\'appel à implémenter'),
      ),
    );
  }

  void _messageDriver() {
    // TODO: Implémenter le message au livreur
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fonctionnalité de message à implémenter'),
      ),
    );
  }
}
