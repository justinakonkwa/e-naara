import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ecommerce/services/supabase_service.dart';
import 'package:ecommerce/services/navigation_service.dart';
import 'package:ecommerce/screens/integrated_navigation_screen.dart';
import 'package:ecommerce/models/order.dart';
import 'package:ecommerce/models/user.dart';
import 'package:ecommerce/services/tracking_service.dart';

class DriverDeliveryDetailsScreen extends StatefulWidget {
  final String orderId;

  const DriverDeliveryDetailsScreen({super.key, required this.orderId});

  @override
  State<DriverDeliveryDetailsScreen> createState() => _DriverDeliveryDetailsScreenState();
}

class _DriverDeliveryDetailsScreenState extends State<DriverDeliveryDetailsScreen> {
  SimpleOrder? _order;
  AppUser? _customer;
  Map<String, dynamic>? _driverLocation;
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  bool _isLoading = true;
  String? _error;
  Timer? _locationTimer;

  // Coordonnées par défaut (Kinshasa)
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
      try {
        // Essayer d'abord avec getOrderByIdForDriver (pour les livreurs)
        var order = await SupabaseService.getOrderByIdForDriver(widget.orderId);
        
        // Si pas trouvé, essayer avec getOrderById (pour les clients)
        if (order == null) {
          print('⚠️ [DRIVER_DELIVERY] Commande non trouvée avec getOrderByIdForDriver, essai avec getOrderById');
          order = await SupabaseService.getOrderById(widget.orderId);
        }
        
        if (order != null) {
          setState(() {
            _order = order;
          });

          // Charger les informations du client
          await _loadCustomerInfo(order.userId);

          // Charger la position actuelle du livreur
          await _loadDriverLocation();
          _updateMapMarkers();
        } else {
          print('❌ [DRIVER_DELIVERY] Commande non trouvée: ${widget.orderId}');
          
          // Debug: Lister toutes les commandes pour diagnostic
          final allOrders = await SupabaseService.debugGetAllOrders();
          print('🔍 [DRIVER_DELIVERY] Commandes disponibles: ${allOrders.length}');
          
          setState(() {
            _error = 'Commande non trouvée. Vérifiez que la commande existe dans la base de données.';
          });
        }
      } catch (e) {
        print('❌ [DRIVER_DELIVERY] Erreur chargement commande: $e');
        setState(() {
          _error = 'Erreur lors du chargement de la commande: $e';
        });
      }
    } catch (e) {
      print('❌ [DRIVER_DELIVERY] Erreur chargement: $e');
      setState(() {
        _error = 'Erreur lors du chargement des données: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadCustomerInfo(String userId) async {
    try {
      // Récupérer les informations utilisateur depuis la table users
      final response = await Supabase.instance.client
          .from('users')
          .select('*')
          .eq('id', userId)
          .single();
      
      if (mounted) {
        setState(() {
          _customer = AppUser.fromJson(response);
        });
      }
    } catch (e) {
      print('❌ [DRIVER_DELIVERY] Erreur chargement client: $e');
      // En cas d'erreur, on continue sans les informations du client
    }
  }

  void _startLocationTracking() {
    _locationTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _loadDriverLocation();
    });
  }

  Future<void> _loadDriverLocation() async {
    try {
      final userId = SupabaseService.getCurrentSession()?.user.id;
      if (userId != null) {
        final location = await TrackingService.getDriverLocation(userId);
        if (mounted) {
          setState(() {
            _driverLocation = location;
          });
          _updateMapMarkers();
        }
      }
    } catch (e) {
      print('❌ [DRIVER_DELIVERY] Erreur chargement position: $e');
      // Si pas de position, on utilise une position par défaut (Paris)
      if (mounted && _driverLocation == null) {
        setState(() {
          _driverLocation = {
            'latitude': 48.8566,
            'longitude': 2.3522,
            'heading': 0,
            'speed': 0,
            'accuracy': 0,
            'battery_level': null,
            'updated_at': DateTime.now().toIso8601String(),
          };
        });
        _updateMapMarkers();
      }
    }
  }

  void _updateMapMarkers() {
    final markers = <Marker>{};

    // Marqueur de la position actuelle du livreur
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
            title: 'Votre position',
            snippet: 'Position actuelle',
          ),
        ),
      );
    }

                    // Marqueur de l'adresse de livraison
                if (_order != null) {
                  LatLng deliveryLatLng;
                  
                  // Utiliser les coordonnées GPS si disponibles, sinon géocoder l'adresse
                  if (_order!.shippingLatitude != null && _order!.shippingLongitude != null) {
                    deliveryLatLng = LatLng(_order!.shippingLatitude!, _order!.shippingLongitude!);
                  } else {
                    // Fallback: géocoder l'adresse ou utiliser la position par défaut
                    deliveryLatLng = _defaultLocation;
                  }
                  
                  markers.add(
                    Marker(
                      markerId: const MarkerId('delivery'),
                      position: deliveryLatLng,
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

    // Centrer la carte sur le livreur si disponible
    if (_driverLocation != null && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(_driverLocation!['latitude'], _driverLocation!['longitude']),
          15,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails de livraison'),
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
              : _buildDeliveryDetails(),
    );
  }

  Widget _buildLoadingWidget() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Chargement des détails...'),
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

  Widget _buildDeliveryDetails() {
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
                              Icons.delivery_dining,
                              color: theme.colorScheme.primary,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Détails de livraison',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        if (_order != null) ...[
                          _buildInfoRow('Commande', '#${_order!.id.substring(0, 8)}', Icons.receipt),
                          _buildInfoRow('Client', _customer?.displayName ?? 'Client', Icons.person),
                          _buildInfoRow('Téléphone', _customer?.phoneNumber ?? 'Non disponible', Icons.phone),
                          _buildInfoRow('Adresse', _order!.shippingAddress, Icons.location_on),
                          _buildInfoRow('Montant', '${_order!.totalAmount.toStringAsFixed(2)} €', Icons.euro),
                          _buildInfoRow('Statut', _getStatusText(_order!.status), Icons.info),
                          _buildInfoRow('Date', _formatDate(_order!.createdAt), Icons.calendar_today),
                        ],

                        // Message informatif pour le tracking
                        if (_driverLocation == null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: theme.colorScheme.onPrimaryContainer,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Activez le tracking GPS pour voir votre position sur la carte',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onPrimaryContainer,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                                    const SizedBox(height: 20),
            _buildActionButtons(),
            
            // Bouton de debug (temporaire)
            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    print('🔍 [DEBUG] Test de récupération de toutes les commandes');
                    final allOrders = await SupabaseService.debugGetAllOrders();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Debug: ${allOrders.length} commandes trouvées'),
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  },
                  icon: const Icon(Icons.bug_report),
                  label: const Text('Debug: Lister toutes les commandes'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
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
            onPressed: _callCustomer,
            icon: const Icon(Icons.phone),
            label: const Text('Appeler client'),
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
            onPressed: _openNavigation,
            icon: const Icon(Icons.navigation),
            label: const Text('Navigation'),
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
        return 'Assignée à vous';
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

  void _callCustomer() async {
    if (_customer?.phoneNumber == null || _customer!.phoneNumber!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Numéro de téléphone du client non disponible'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final success = await NavigationService.openPhoneCall(_customer!.phoneNumber!);
    
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible d\'ouvrir l\'application téléphone'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _openNavigation() async {
    if (_order == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Informations de livraison non disponibles'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Utiliser les coordonnées GPS si disponibles
    if (_order!.shippingLatitude != null && _order!.shippingLongitude != null) {
      final destination = LatLng(_order!.shippingLatitude!, _order!.shippingLongitude!);
      
      // Ouvrir l'écran de navigation intégrée
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => IntegratedNavigationScreen(
            destination: destination,
            destinationName: _order!.shippingAddress,
            driverId: _order!.driverId,
          ),
        ),
      );
    } else {
      // Fallback: utiliser l'adresse textuelle avec Google Maps
      final success = await NavigationService.openMapsWithAddress(_order!.shippingAddress);
      
      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible d\'ouvrir Google Maps'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
