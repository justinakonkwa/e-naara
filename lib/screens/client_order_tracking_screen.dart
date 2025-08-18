import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ecommerce/services/supabase_service.dart';
import 'package:ecommerce/models/order.dart';
import 'package:ecommerce/services/tracking_service.dart';
import 'package:ecommerce/services/integrated_navigation_service.dart';
import 'package:ecommerce/services/geocoding_service.dart';

class ClientOrderTrackingScreen extends StatefulWidget {
  final String orderId;

  const ClientOrderTrackingScreen({super.key, required this.orderId});

  @override
  State<ClientOrderTrackingScreen> createState() => _ClientOrderTrackingScreenState();
}

class _ClientOrderTrackingScreenState extends State<ClientOrderTrackingScreen> {
  SimpleOrder? _order;
  Map<String, dynamic>? _driverLocation;
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  bool _isLoading = true;
  String? _error;
  Timer? _locationTimer;
  String? _routeDistanceText;
  String? _routeDurationText;
  String? _driverAddress;

  // Coordonnées par défaut (Kinshasa centre)
  static const LatLng _defaultLocation = LatLng(-4.441, 15.266);

  @override
  void initState() {
    super.initState();
    _loadOrderDetails();
    _startLocationTracking();
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _loadOrderDetails() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Charger les détails de la commande
      final order = await SupabaseService.getOrderById(widget.orderId);
      if (order != null) {
        setState(() {
          _order = order;
        });

        // Charger la position du livreur si la commande est assignée
        if (order.driverId != null) {
          await _loadDriverLocation(order.driverId!);
        }
        _updateMapMarkers();
      } else {
        setState(() {
          _error = 'Commande non trouvée';
        });
      }
    } catch (e) {
      print('❌ [CLIENT_TRACKING] Erreur chargement: $e');
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
    _locationTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      if (_order?.driverId != null) {
        _loadDriverLocation(_order!.driverId!);
      }
    });
  }

  Future<void> _loadDriverLocation(String driverId) async {
    try {
      final location = await TrackingService.getDriverLocation(driverId);
      if (mounted) {
        setState(() {
          _driverLocation = location;
        });
        _updateMapMarkers();
        await _updateRoutePolyline();
        await _reverseGeocodeDriver();
      }
    } catch (e) {
      print('❌ [CLIENT_TRACKING] Erreur chargement position livreur: $e');
    }
  }

  Future<void> _reverseGeocodeDriver() async {
    try {
      if (_driverLocation == null) {
        setState(() {
          _driverAddress = null;
        });
        return;
      }

      final addr = await GeocodingService.reverseGeocode(
        LatLng(_driverLocation!['latitude'], _driverLocation!['longitude']),
      );
      if (!mounted) return;
      setState(() {
        _driverAddress = addr;
      });
    } catch (e) {
      // silencieux
    }
  }

  void _updateMapMarkers() {
    final markers = <Marker>{};

    // Marqueur de la position du livreur
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

    // Marqueur de l'adresse de livraison (votre adresse)
    if (_order != null) {
      // Utiliser les coordonnées GPS si disponibles, sinon fallback
      final deliveryLatLng = (_order!.shippingLatitude != null && _order!.shippingLongitude != null)
          ? LatLng(_order!.shippingLatitude!, _order!.shippingLongitude!)
          : _defaultLocation;
      
      markers.add(
        Marker(
          markerId: const MarkerId('delivery'),
          position: deliveryLatLng,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: 'Votre adresse',
            snippet: _order!.shippingAddress,
          ),
        ),
      );
    }

    setState(() {
      _markers = markers;
    });

    // Centrer la carte intelligemment
    if (_mapController != null) {
      final hasDriver = _driverLocation != null;
      final hasDelivery = _order?.shippingLatitude != null && _order?.shippingLongitude != null;

      if (hasDriver && hasDelivery) {
        final driver = LatLng(_driverLocation!['latitude'], _driverLocation!['longitude']);
        final delivery = LatLng(_order!.shippingLatitude!, _order!.shippingLongitude!);
        final bounds = _getBoundsForPoints([driver, delivery]);
        _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 60));
      } else if (hasDriver) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(_driverLocation!['latitude'], _driverLocation!['longitude']),
            15,
          ),
        );
      } else if (_order != null) {
        final delivery = (_order!.shippingLatitude != null && _order!.shippingLongitude != null)
            ? LatLng(_order!.shippingLatitude!, _order!.shippingLongitude!)
            : _defaultLocation;
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(delivery, 12),
        );
      }
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

      if (_order!.shippingLatitude == null || _order!.shippingLongitude == null) {
        setState(() {
          _polylines = {};
          _routeDistanceText = null;
          _routeDurationText = null;
        });
        return;
      }

      final origin = LatLng(_driverLocation!['latitude'], _driverLocation!['longitude']);
      final destination = LatLng(_order!.shippingLatitude!, _order!.shippingLongitude!);

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
      print('❌ [CLIENT_TRACKING] Erreur calcul itinéraire: $e');
    }
  }

  LatLngBounds _getBoundsForPoints(List<LatLng> points) {
    double? minLat, maxLat, minLng, maxLng;
    for (final p in points) {
      minLat = minLat == null ? p.latitude : (p.latitude < minLat ? p.latitude : minLat);
      maxLat = maxLat == null ? p.latitude : (p.latitude > maxLat ? p.latitude : maxLat);
      minLng = minLng == null ? p.longitude : (p.longitude < minLng ? p.longitude : minLng);
      maxLng = maxLng == null ? p.longitude : (p.longitude > maxLng ? p.longitude : maxLng);
    }
    return LatLngBounds(
      southwest: LatLng(minLat!, minLng!),
      northeast: LatLng(maxLat!, maxLng!),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Suivi de ma commande'),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOrderDetails,
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
              onPressed: _loadOrderDetails,
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

        // Informations de suivi
        Expanded(
          flex: 1,
          child: _buildTrackingInfo(),
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

  Widget _buildTrackingInfo() {
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
                  'Suivi de livraison',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            if (_order != null) ...[
              _buildInfoRow('Commande', '#${_order!.id.substring(0, 8)}', Icons.receipt),
              _buildInfoRow('Statut', _getStatusText(_order!.status), Icons.info),
              _buildInfoRow('Adresse', _order!.shippingAddress, Icons.location_on),
              if (_driverAddress != null)
                _buildInfoRow('Adresse livreur', _driverAddress!, Icons.delivery_dining),
              _buildInfoRow('Montant', '${_order!.totalAmount.toStringAsFixed(2)} €', Icons.euro),
              _buildInfoRow('Date', _formatDate(_order!.createdAt), Icons.calendar_today),
              if (_routeDistanceText != null && _routeDurationText != null)
                _buildInfoRow('Itinéraire', '${_routeDistanceText!} • ${_routeDurationText!}', Icons.alt_route),
            ],

            // Statut du livreur
            const SizedBox(height: 16),
            _buildDriverStatus(),

            // Boutons d'action
            const SizedBox(height: 20),
            _buildActionButtons(),
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

  Widget _buildDriverStatus() {
    final theme = Theme.of(context);
    
    if (_order?.driverId == null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              Icons.schedule,
              color: theme.colorScheme.onSecondaryContainer,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'En attente d\'un livreur',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSecondaryContainer,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_driverLocation == null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              Icons.location_off,
              color: theme.colorScheme.onPrimaryContainer,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Livreur assigné - Position non disponible',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.location_on,
            color: theme.colorScheme.onTertiaryContainer,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Livreur en route',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onTertiaryContainer,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (_driverLocation != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Dernière mise à jour: ${_formatTime(_driverLocation!['updated_at'])}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onTertiaryContainer.withValues(alpha: 0.8),
                    ),
                  ),
                ],
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
            onPressed: _contactSupport,
            icon: const Icon(Icons.support_agent),
            label: const Text('Support'),
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
            onPressed: _shareOrder,
            icon: const Icon(Icons.share),
            label: const Text('Partager'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} à ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatTime(String isoString) {
    try {
      final date = DateTime.parse(isoString);
      return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Récemment';
    }
  }

  void _contactSupport() {
    // TODO: Implémenter le contact support
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fonctionnalité de support à implémenter'),
      ),
    );
  }

  void _shareOrder() {
    // TODO: Implémenter le partage
    if (_order != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Partager le suivi de la commande #${_order!.id.substring(0, 8)}'),
        ),
      );
    }
  }
}

